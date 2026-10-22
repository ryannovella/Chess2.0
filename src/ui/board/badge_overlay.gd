class_name BadgeOverlay
extends Control

var defender_squares: Dictionary = {}
var selected_square: String = ""
var legal_moves: Array = []
var is_flipped: bool = false
var square_size: float = 64.0

func _ready() -> void:
	custom_minimum_size = Vector2(512, 512)
	mouse_filter = MOUSE_FILTER_IGNORE

func update_badges(p_defenders: Dictionary, p_selected: String, p_legal: Array, p_flipped: bool, p_sq_size: float) -> void:
	defender_squares = p_defenders
	selected_square = p_selected
	legal_moves = p_legal
	is_flipped = p_flipped
	square_size = p_sq_size
	queue_redraw()

func _draw() -> void:
	if defender_squares.is_empty():
		return

	var th_name = "slate"
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS:
			th_name = GS.board_theme
	var theme_data = BoardThemes.get_theme(th_name)
	var def_col = theme_data.get("defender_color", Color(0.22, 0.65, 1.0, 0.95))

	var legal_targets = {}
	for m in legal_moves:
		if m is ChessMove:
			legal_targets[m.to_sq] = true
		elif m is Dictionary:
			legal_targets[m.get("to", "")] = true

	for sq in defender_squares:
		if sq == selected_square or legal_targets.has(sq):
			continue

		var pos = _get_square_position(sq)

		# Render Sleek Minimalist Shield Badge Icon di Bottom-Center LAYER DEPAN PIECE
		var badge_w = square_size * 0.22
		var badge_h = square_size * 0.24
		var center_x = pos.x + square_size * 0.5
		var bottom_y = pos.y + square_size - (square_size * 0.05)
		var top_y = bottom_y - badge_h

		var p_top_l = Vector2(center_x - badge_w * 0.5, top_y)
		var p_top_r = Vector2(center_x + badge_w * 0.5, top_y)
		var p_upper_r = Vector2(center_x + badge_w * 0.5, top_y + badge_h * 0.38)
		var p_lower_r = Vector2(center_x + badge_w * 0.28, top_y + badge_h * 0.78)
		var p_tip = Vector2(center_x, bottom_y)
		var p_lower_l = Vector2(center_x - badge_w * 0.28, top_y + badge_h * 0.78)
		var p_upper_l = Vector2(center_x - badge_w * 0.5, top_y + badge_h * 0.38)

		var shield_pts = PackedVector2Array([p_top_l, p_top_r, p_upper_r, p_lower_r, p_tip, p_lower_l, p_upper_l])
		var shield_bg_col = Color(0.06, 0.09, 0.14, 0.90)
		# draw_colored_polygon tidak punya anti-aliasing, jadi isian digambar sedikit
		# ke dalam supaya tepi bergeriginya tersembunyi di bawah inti outline halus.
		draw_colored_polygon(_inset_polygon(shield_pts, 0.35), shield_bg_col)

		# Outline Perisai Minimalis Bersih (Tanpa crosshair dalam)
		var outline_pts = PackedVector2Array([p_top_l, p_top_r, p_upper_r, p_lower_r, p_tip, p_lower_l, p_upper_l, p_top_l])
		draw_polyline(outline_pts, def_col, 1.6, true)

## Menggeser tiap verteks poligon ke arah dalam sejauh `amount` (sepanjang garis bagi
## sudut) sehingga isian solid tidak menonjol melewati inti garis outline AA.
func _inset_polygon(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	var count := pts.size()
	if count < 3:
		return pts

	var centroid := Vector2.ZERO
	for p in pts:
		centroid += p
	centroid /= float(count)

	var result := PackedVector2Array()
	result.resize(count)
	for i in count:
		var cur := pts[i]
		var to_center := centroid - cur
		if to_center.length_squared() < 0.0001:
			result[i] = cur
			continue

		var prev := pts[(i - 1 + count) % count]
		var next := pts[(i + 1) % count]
		var normal_prev := (cur - prev).orthogonal().normalized()
		var normal_next := (next - cur).orthogonal().normalized()
		if normal_prev.dot(to_center) < 0.0:
			normal_prev = -normal_prev
		if normal_next.dot(to_center) < 0.0:
			normal_next = -normal_next

		var bisector := normal_prev + normal_next
		if bisector.length_squared() < 0.0001:
			bisector = to_center
		bisector = bisector.normalized()

		# Pada verteks tajam offset harus diperbesar agar tepi baru tetap berjarak `amount`.
		var falloff := maxf(bisector.dot(normal_prev), 0.4)
		result[i] = cur + bisector * (amount / falloff)
	return result

func _get_square_position(sq: String) -> Vector2:
	var coord = ChessTypes.square_to_coord(sq)
	var f = coord.x
	var r = coord.y
	var visual_f = (7 - f) if is_flipped else f
	var visual_r = r if is_flipped else (7 - r)
	return Vector2(visual_f * square_size, visual_r * square_size)
