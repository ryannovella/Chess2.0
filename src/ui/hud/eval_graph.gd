class_name EvalGraph
extends Control

## Grafik evaluasi bergaya Chess.com untuk Game Review.
##
## Node ini murni presentasi: seluruh data masuk sebagai titik
## { "ply": int, "wp": float (0..1, peluang menang Putih), "classification": int }.
## Titik dengan "classification" = -1 digambar netral (dipakai saat analisis masih
## berjalan, sebelum klasifikasi langkah tersedia).
##
## Tinggi minimum sengaja kecil supaya lantai HUDTabContainer 148 px tetap mengikat
## (invariant B15), lalu node mengembang mengisi sisa ruang strip Review saat review
## aktif. Tidak ada teks mikro di dalam kanvas; angka evaluasi ditampilkan oleh
## label readout di panel agar tetap >= 14 px.

signal ply_clicked(ply: int)
signal hover_changed(ply: int)

const GameReviewService = preload("res://src/core/game_review_service.gd")

const PAD_X := 3.0
const PAD_Y := 2.0
const DOT_RADIUS := 4.2
const DOT_RADIUS_PREVIEW := 1.6

# Warna dan bentuk mengikuti grafik Game Review Chess.com: area keunggulan Putih
# diisi dari tepi bawah sampai kurva, sisa ruang di atas kurva memakai latar gelap
# panel (jadi kurva itu sendiri adalah batas dua warna), plus satu garis acuan 0.0.
const COLOR_AREA_WHITE := Color(0.97, 0.97, 0.97, 1.0)
const COLOR_MIDLINE := Color(0.58, 0.57, 0.55, 0.5)
const COLOR_PENDING := Color(0.06, 0.06, 0.07, 0.62)
const COLOR_PENDING_EDGE := Color(0.55, 0.58, 0.62, 0.7)
const COLOR_CURSOR := Color(0.98, 0.98, 0.98, 0.7)
const COLOR_ACTIVE_DOT := Color(0.98, 0.98, 0.98, 0.95)
const COLOR_PREVIEW_DOT := Color(0.60, 0.74, 0.90, 0.85)

# Chess.com hanya menandai langkah yang "punya cerita" pada grafik: Book,
# Brilliant, Great, Inaccuracy, Mistake, Miss, dan Blunder. Best/Excellent/Good
# tidak diberi titik (terverifikasi dari sampling piksel referensi: tidak ada
# piksel hijau #96bc4b sama sekali, sementara cokelat Book, kuning Inaccuracy,
# oranye Mistake, merah Miss/Blunder, dan biru Great ada).
const MARKER_CLASSIFICATIONS := [
	GameReviewService.Classification.BOOK,
	GameReviewService.Classification.BRILLIANT,
	GameReviewService.Classification.GREAT,
	GameReviewService.Classification.INACCURACY,
	GameReviewService.Classification.MISTAKE,
	GameReviewService.Classification.MISS,
	GameReviewService.Classification.BLUNDER
]

var _points: Array[Dictionary] = []
var _axis_max_ply: int = 1
var _active_ply: int = -1
var _hover_ply: int = -1
var _analysis_pending: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(queue_redraw)
	mouse_exited.connect(_on_mouse_exited)

# -----------------------------------------------------------------------------
# API data
# -----------------------------------------------------------------------------

func clear() -> void:
	_points.clear()
	_axis_max_ply = 1
	_active_ply = -1
	_hover_ply = -1
	_analysis_pending = false
	queue_redraw()

func set_axis_max_ply(ply: int) -> void:
	_axis_max_ply = maxi(1, ply)
	queue_redraw()

func set_points(points: Array) -> void:
	_points.clear()
	for point in points:
		if point is Dictionary:
			_points.append(point)
	queue_redraw()

func append_point(point: Dictionary) -> void:
	_points.append(point)
	queue_redraw()

func get_point_count() -> int:
	return _points.size()

func set_active_ply(ply: int) -> void:
	if _active_ply == ply:
		return
	_active_ply = ply
	queue_redraw()

func get_active_ply() -> int:
	return _active_ply

func set_analysis_pending(pending: bool) -> void:
	if _analysis_pending == pending:
		return
	_analysis_pending = pending
	queue_redraw()

func is_analysis_pending() -> bool:
	return _analysis_pending

func has_ply(ply: int) -> bool:
	return _find_point_index(ply) != -1

# -----------------------------------------------------------------------------
# Geometri
# -----------------------------------------------------------------------------

func _playable_rect() -> Rect2:
	var width: float = maxf(1.0, size.x - PAD_X * 2.0)
	var height: float = maxf(1.0, size.y - PAD_Y * 2.0)
	return Rect2(PAD_X, PAD_Y, width, height)

func _ply_to_x(ply: int, rect: Rect2) -> float:
	var ratio: float = float(clampi(ply, 0, _axis_max_ply)) / float(maxi(1, _axis_max_ply))
	return rect.position.x + ratio * rect.size.x

func _wp_to_y(wp: float, rect: Rect2) -> float:
	var clamped: float = clampf(wp, 0.0, 1.0)
	return rect.position.y + (1.0 - clamped) * rect.size.y

func _find_point_index(ply: int) -> int:
	for i in range(_points.size()):
		if int(_points[i].get("ply", -1)) == ply:
			return i
	return -1

func _nearest_point_index(x: float) -> int:
	if _points.is_empty():
		return -1
	var rect: Rect2 = _playable_rect()
	var best_index: int = -1
	var best_distance: float = INF
	for i in range(_points.size()):
		var point_x: float = _ply_to_x(int(_points[i].get("ply", 0)), rect)
		var distance: float = absf(point_x - x)
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

# -----------------------------------------------------------------------------
# Render
# -----------------------------------------------------------------------------

func _draw() -> void:
	var rect: Rect2 = _playable_rect()
	var mid_y: float = rect.position.y + rect.size.y * 0.5
	var bottom_y: float = rect.position.y + rect.size.y

	var curve := PackedVector2Array()
	for point in _points:
		curve.append(Vector2(
			_ply_to_x(int(point.get("ply", 0)), rect),
			_wp_to_y(float(point.get("wp", 0.5)), rect)
		))

	# Area keunggulan Putih diisi dari tepi bawah sampai kurva. Ruang di atas kurva
	# sengaja tidak diisi sehingga latar gelap panel berperan sebagai area keunggulan
	# Hitam, dan kurva itu sendiri menjadi batas kedua warna.
	if curve.size() >= 2:
		var white_area := PackedVector2Array()
		white_area.append(Vector2(curve[0].x, bottom_y))
		for point in curve:
			white_area.append(point)
		white_area.append(Vector2(curve[curve.size() - 1].x, bottom_y))
		draw_colored_polygon(white_area, COLOR_AREA_WHITE)
		# draw_colored_polygon tidak punya anti-aliasing sehingga tepi kurva bergerigi.
		# Tepi itu dihaluskan dengan polyline WARNA IDENTIK (COLOR_AREA_WHITE) tepat di
		# atas kurva: bukan stroke berwarna lain, jadi bentuk/warna grafik Chess.com
		# tidak berubah, hanya tepinya menjadi halus.
		draw_polyline(curve, COLOR_AREA_WHITE, 1.0, true)

	# Garis acuan 0.0 (peluang menang 50%) menyeberangi kedua area.
	draw_line(Vector2(rect.position.x, mid_y), Vector2(rect.position.x + rect.size.x, mid_y), COLOR_MIDLINE, 1.0, true)

	if _analysis_pending and not curve.is_empty():
		var frontier_x: float = curve[curve.size() - 1].x
		var pending_width: float = maxf(0.0, rect.position.x + rect.size.x - frontier_x)
		draw_rect(Rect2(frontier_x, rect.position.y, pending_width, rect.size.y), COLOR_PENDING, true)
		draw_line(Vector2(frontier_x, rect.position.y), Vector2(frontier_x, bottom_y), COLOR_PENDING_EDGE, 1.0, true)

	_draw_dots(rect)

	if _active_ply >= 0:
		_draw_marker(rect, _active_ply, COLOR_CURSOR, DOT_RADIUS + 0.4, true)
	if _hover_ply >= 0 and _hover_ply != _active_ply:
		_draw_marker(rect, _hover_ply, COLOR_ACTIVE_DOT, DOT_RADIUS, false)

func _draw_dots(rect: Rect2) -> void:
	for point in _points:
		var ply: int = int(point.get("ply", 0))
		var wp: float = float(point.get("wp", 0.5))
		var classification: int = int(point.get("classification", -1))
		var position := Vector2(_ply_to_x(ply, rect), _wp_to_y(wp, rect))

		if classification < 0:
			# Titik progresif: posisi sudah dinilai tetapi klasifikasinya baru ada
			# setelah analisis selesai, jadi digambar netral dan kecil.
			if _analysis_pending:
				draw_circle(position, DOT_RADIUS_PREVIEW, COLOR_PREVIEW_DOT, true, -1.0, true)
			continue

		if not classification in MARKER_CLASSIFICATIONS:
			continue
		draw_circle(position, DOT_RADIUS, GameReviewService.classification_to_color(classification), true, -1.0, true)

func _draw_marker(rect: Rect2, ply: int, color: Color, radius: float, with_line: bool) -> void:
	var index: int = _find_point_index(ply)
	if index == -1:
		return
	var position := Vector2(
		_ply_to_x(ply, rect),
		_wp_to_y(float(_points[index].get("wp", 0.5)), rect)
	)
	if with_line:
		draw_line(Vector2(position.x, rect.position.y), Vector2(position.x, rect.position.y + rect.size.y), color, 1.5, true)
	# Cincin gelap tipis supaya penanda tetap terbaca di atas area putih maupun gelap.
	draw_circle(position, radius + 1.0, Color(0.10, 0.10, 0.11, 0.7), true, -1.0, true)
	draw_circle(position, radius, color, true, -1.0, true)

# -----------------------------------------------------------------------------
# Interaksi
# -----------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _analysis_pending:
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.pressed and button.button_index == MOUSE_BUTTON_LEFT:
			var index: int = _nearest_point_index(button.position.x)
			if index != -1:
				ply_clicked.emit(int(_points[index].get("ply", 0)))
				accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var index: int = _nearest_point_index(motion.position.x)
		var ply: int = int(_points[index].get("ply", -1)) if index != -1 else -1
		if ply != _hover_ply:
			_hover_ply = ply
			hover_changed.emit(ply)
			queue_redraw()

func _on_mouse_exited() -> void:
	if _hover_ply == -1:
		return
	_hover_ply = -1
	hover_changed.emit(-1)
	queue_redraw()
