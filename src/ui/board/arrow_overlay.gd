class_name ArrowOverlay
extends Control

# Visual Styles 1:1 ChessAcademy
const COLOR_TIER_1 = Color(34 / 255.0, 197 / 255.0, 94 / 255.0, 0.96)    # Emerald Green (Best)
const COLOR_TIER_2 = Color(245 / 255.0, 185 / 255.0, 30 / 255.0, 0.96)   # Warm Gold Amber (Good)
const COLOR_TIER_3 = Color(249 / 255.0, 115 / 255.0, 22 / 255.0, 0.96)   # Vibrant Orange (Alt)
const COLOR_THREAT_HANGING = Color(239 / 255.0, 68 / 255.0, 68 / 255.0, 0.96) # Crimson Red
const COLOR_THREAT_DEFENDED = Color(236 / 255.0, 72 / 255.0, 153 / 255.0, 0.96) # Electric Fuchsia
const COLOR_SHADOW = Color(0.0, 0.0, 0.0, 0.35)

var engine_arrows: Array[Dictionary] = []
var threat_arrows: Array[Dictionary] = []
var square_size: float = 64.0
var is_flipped: bool = false
var focused_square: String = ""
var arrow_alphas: Dictionary = {} # arrow_key -> float

func get_visible_arrows() -> Array[Dictionary]:
	var vis_arrows: Array[Dictionary] = []
	for a in engine_arrows:
		if not a.get("type", "").begins_with("threat"):
			vis_arrows.append(a)
	for a in threat_arrows:
		vis_arrows.append(a)
	return vis_arrows

func _get_arrow_key(arrow: Dictionary) -> String:
	return "%s->%s:%s:%d" % [
		arrow.get("from", ""),
		arrow.get("to", ""),
		str(arrow.get("type", "")),
		int(arrow.get("rank", 0))
	]

func has_arrows_for_square(sq: String) -> bool:
	if sq.is_empty():
		return false
	var vis_arrows = get_visible_arrows()
	for a in vis_arrows:
		if a.get("from", "") == sq or a.get("to", "") == sq:
			return true
	return false

func set_focused_square(sq: String) -> void:
	var active_sq = sq if has_arrows_for_square(sq) else ""
	if focused_square == active_sq:
		return
	focused_square = active_sq
	set_process(true)

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)

func _process(delta: float) -> void:
	var vis_arrows = get_visible_arrows()
	if vis_arrows.is_empty():
		arrow_alphas.clear()
		set_process(false)
		return

	var needs_redraw = false
	var speed = 5.0 # Kecepatan transisi: (1.0 - 0.25) / 0.15s = 5.0 unit/detik

	var active_keys = {}
	for a in vis_arrows:
		var key = _get_arrow_key(a)
		active_keys[key] = true

		var is_rel = true
		if not focused_square.is_empty():
			is_rel = (a.get("from", "") == focused_square or a.get("to", "") == focused_square)

		var target_alpha = 1.0 if (focused_square.is_empty() or is_rel) else 0.25
		var cur_alpha = arrow_alphas.get(key, 1.0)

		if abs(cur_alpha - target_alpha) > 0.002:
			cur_alpha = move_toward(cur_alpha, target_alpha, delta * speed)
			arrow_alphas[key] = cur_alpha
			needs_redraw = true
		else:
			arrow_alphas[key] = target_alpha

	for k in arrow_alphas.keys():
		if not active_keys.has(k):
			arrow_alphas.erase(k)

	if needs_redraw:
		queue_redraw()
	else:
		set_process(false)

func update_arrows(engine_arr: Array[Dictionary], threat_arr: Array[Dictionary], sq_size: float, flipped: bool) -> void:
	engine_arrows = engine_arr
	threat_arrows = threat_arr
	square_size = sq_size
	is_flipped = flipped
	if not focused_square.is_empty() and not has_arrows_for_square(focused_square):
		focused_square = ""
	set_process(true)
	queue_redraw()

func _draw() -> void:
	var visible_arrows = get_visible_arrows()
	if visible_arrows.is_empty():
		return

	# 1. Deteksi Konflik Jalur (Lane Conflict Detection)
	# oppRoute (serangan & serangan-balik): untuk panah lurus (Benteng, Gajah, Menteri, Pion)
	# sameDir (arah yang sama): satu ambil kiri, satu ambil kanan
	# converging (tujuan sama dengan arah kedatangan yang sejajar): satu ambil kiri, satu ambil kanan
	# segment overlap: deteksi jika ada segmen (orthogonal) yang berbagi jalur pada baris/kolom yang sama
	var arrow_config: Dictionary = {}
	for i in range(visible_arrows.size()):
		arrow_config[i] = { "half_side": "", "leg1_shift": 0.0, "leg2_shift": 0.0, "trim_inner": false }

	# A. Cek OppRoute dan SameDir
	for i in range(visible_arrows.size()):
		var a = visible_arrows[i]
		var is_a_k = is_knight_move(a["from"], a["to"])
		for j in range(i + 1, visible_arrows.size()):
			var b = visible_arrows[j]
			var is_b_k = is_knight_move(b["from"], b["to"])
			var opp_route = a["from"] == b["to"] and a["to"] == b["from"]
			var same_dir = a["from"] == b["from"] and a["to"] == b["to"]

			if opp_route:
				# Hanya untuk panah lurus. Kuda TIDAK saling tabrak rute L secara head-on!
				if not is_a_k and not is_b_k:
					arrow_config[i]["half_side"] = "left"
					arrow_config[j]["half_side"] = "left"
			elif same_dir:
				if arrow_config[i]["half_side"] == "" and arrow_config[j]["half_side"] == "":
					arrow_config[i]["half_side"] = "left"
					arrow_config[j]["half_side"] = "right"

	# B. Segment Overlap Detection: Cek tumpang-tindih segmen antar panah (misal kaki Kuda berdampingan atau duel berlawanan)
	var sw = square_size * 0.11
	var gap = square_size * 0.045
	var lane_shift = (sw + gap) * 0.5

	for i in range(visible_arrows.size()):
		var a = visible_arrows[i]
		if arrow_config[i]["half_side"] != "":
			continue
		var segs_a = get_arrow_segments(a["from"], a["to"], is_flipped)
		for j in range(i + 1, visible_arrows.size()):
			var b = visible_arrows[j]
			if arrow_config[j]["half_side"] != "":
				continue
			# Jika kedua panah berasal dari petak yang sama, biarkan centerline bertumpuk (layering urut terpendek di atas)
			if a["from"] == b["from"]:
				continue

			var segs_b = get_arrow_segments(b["from"], b["to"], is_flipped)

			for sa in segs_a:
				for sb in segs_b:
					if sa["axis"] == sb["axis"] and sa["grid"] == sb["grid"]:
						var ov_min = maxi(sa["min"], sb["min"])
						var ov_max = mini(sa["max"], sb["max"])
						if ov_max > ov_min:
							# Segmen tumpang-tindih di grid yang sama!
							var a_to_c = ChessTypes.square_to_coord(a["to"])
							var b_to_c = ChessTypes.square_to_coord(b["to"])
							var a_head_pos = -1
							var b_head_pos = -1
							if sa["axis"] == "V":
								var a_to_rank = 7 - a_to_c.y
								var b_to_rank = 7 - b_to_c.y
								a_head_pos = (7 - a_to_rank) if is_flipped else a_to_rank
								b_head_pos = (7 - b_to_rank) if is_flipped else b_to_rank
							else:
								var a_to_file = a_to_c.x
								var b_to_file = b_to_c.x
								a_head_pos = (7 - a_to_file) if is_flipped else a_to_file
								b_head_pos = (7 - b_to_file) if is_flipped else b_to_file

							var a_head_in_overlap = (sa["leg"] == 2 or sa["leg"] == 0) and (a_head_pos >= ov_min and a_head_pos <= ov_max)
							var b_head_in_overlap = (sb["leg"] == 2 or sb["leg"] == 0) and (b_head_pos >= ov_min and b_head_pos <= ov_max)

							if sa["dir"] != sb["dir"]:
								# Berlawanan arah: masing-masing ambil lajur kiri dari sudut pandang jalannya
								_apply_leg_shift(arrow_config[i], sa["leg"], lane_shift)
								_apply_leg_shift(arrow_config[j], sb["leg"], lane_shift)
								if a_head_in_overlap:
									arrow_config[i]["trim_inner"] = true
								if b_head_in_overlap:
									arrow_config[j]["trim_inner"] = true
							else:
								# Searah: hanya terapkan shift jika salah satunya adalah langkah Kuda (L-leg)
								# Untuk panah lurus/diagonal searah (leg == 0), biarkan di centerline dengan aturan terpendek di atas
								if sa["leg"] != 0 or sb["leg"] != 0:
									_apply_leg_shift(arrow_config[i], sa["leg"], lane_shift)
									_apply_leg_shift(arrow_config[j], sb["leg"], -lane_shift)
									if a_head_in_overlap:
										arrow_config[i]["trim_inner"] = true
									if b_head_in_overlap:
										arrow_config[j]["trim_inner"] = true

	# 2. Proses geometri polygon untuk setiap panah
	var processed: Array[Dictionary] = []
	for i in range(visible_arrows.size()):
		var arrow = visible_arrows[i]
		var cfg = arrow_config.get(i, { "half_side": "", "leg1_shift": 0.0, "leg2_shift": 0.0, "trim_inner": false })
		var poly = compute_arrow_polygon(
			arrow["from"],
			arrow["to"],
			is_flipped,
			square_size,
			cfg["half_side"],
			cfg["leg1_shift"],
			cfg["leg2_shift"],
			cfg["trim_inner"]
		)
		if poly.is_empty():
			continue

		var arrow_type = arrow.get("type", "best")
		var rank = arrow.get("rank", 1)
		var fill_color = COLOR_TIER_1
		match arrow_type:
			"best": fill_color = COLOR_TIER_1
			"good": fill_color = COLOR_TIER_2
			"alternative": fill_color = COLOR_TIER_3
			"threat-hanging": fill_color = COLOR_THREAT_HANGING
			"threat-defended": fill_color = COLOR_THREAT_DEFENDED
			_:
				if rank == 1: fill_color = COLOR_TIER_1
				elif rank == 2: fill_color = COLOR_TIER_2
				else: fill_color = COLOR_TIER_3

		var key = _get_arrow_key(arrow)
		var cur_alpha = arrow_alphas.get(key, 1.0)
		var is_rel = true
		if not focused_square.is_empty():
			is_rel = (arrow["from"] == focused_square or arrow["to"] == focused_square)

		var dist = get_arrow_dist(arrow["from"], arrow["to"])
		processed.append({
			"polygon": poly,
			"color": fill_color,
			"type": arrow_type,
			"rank": rank,
			"dist": dist,
			"from": arrow["from"],
			"to": arrow["to"],
			"alpha": cur_alpha,
			"is_relevant": is_rel
		})

	# 3. Urutkan: Panah dengan alpha lebih tinggi (fokus) digambar di depan panah yang redup
	processed.sort_custom(func(a, b):
		if abs(a["alpha"] - b["alpha"]) > 0.05:
			return a["alpha"] < b["alpha"]
		if abs(a["dist"] - b["dist"]) > 0.01:
			return a["dist"] > b["dist"]
		var a_threat = str(a["type"]).begins_with("threat")
		var b_threat = str(b["type"]).begins_with("threat")
		if a_threat and not b_threat:
			return false
		if not a_threat and b_threat:
			return true
		return a["rank"] > b["rank"]
	)

	# 4. Gambar Polygon dan Drop-shadow halus dengan alpha per panah
	var shadow_offset = Vector2(0.0, 2.0)
	for item in processed:
		var alpha_mult: float = item["alpha"]
		var fill_col: Color = item["color"]
		fill_col.a *= alpha_mult
		var shadow_col: Color = COLOR_SHADOW
		shadow_col.a *= alpha_mult

		var poly: PackedVector2Array = item["polygon"]
		var shadow_poly = PackedVector2Array()
		for pt in poly:
			shadow_poly.append(pt + shadow_offset)

		draw_colored_polygon(shadow_poly, shadow_col)
		draw_colored_polygon(poly, fill_col)
		if poly.size() > 2:
			var poly_loop = poly.duplicate()
			poly_loop.append(poly[0])
			# draw_colored_polygon tidak punya anti-aliasing; tepi polygon dihaluskan
			# oleh polyline warna identik tepat di atas kelilingnya (badan panah dan
			# bayangannya), sehingga tidak ada tepi bergerigi di sekeliling panah.
			draw_polyline(poly_loop, fill_col, 1.0, true)
			var shadow_loop = shadow_poly.duplicate()
			shadow_loop.append(shadow_poly[0])
			draw_polyline(shadow_loop, shadow_col, 1.0, true)

static func is_knight_move(from_sq: String, to_sq: String) -> bool:
	var c1 = ChessTypes.square_to_coord(from_sq)
	var c2 = ChessTypes.square_to_coord(to_sq)
	if c1.x < 0 or c2.x < 0:
		return false
	var df = abs(c2.x - c1.x)
	var dr = abs(c2.y - c1.y)
	return (df == 1 and dr == 2) or (df == 2 and dr == 1)

static func get_arrow_segments(from_sq: String, to_sq: String, flipped: bool) -> Array[Dictionary]:
	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	if from_coord.x < 0 or to_coord.x < 0:
		return []

	var from_file = from_coord.x
	var from_rank = 7 - from_coord.y
	var to_file = to_coord.x
	var to_rank = 7 - to_coord.y

	var vff = (7 - from_file) if flipped else from_file
	var vfr = (7 - from_rank) if flipped else from_rank
	var vtf = (7 - to_file) if flipped else to_file
	var vtr = (7 - to_rank) if flipped else to_rank

	var d_file = vtf - vff
	var d_rank = vtr - vfr
	var is_knight = (abs(d_file) == 1 and abs(d_rank) == 2) or (abs(d_file) == 2 and abs(d_rank) == 1)

	var segs: Array[Dictionary] = []
	if is_knight:
		if abs(d_rank) == 2:
			segs.append({
				"axis": "V",
				"grid": vff,
				"min": mini(vfr, vtr),
				"max": maxi(vfr, vtr),
				"dir": int(signf(d_rank)),
				"leg": 1
			})
			segs.append({
				"axis": "H",
				"grid": vtr,
				"min": mini(vff, vtf),
				"max": maxi(vff, vtf),
				"dir": int(signf(d_file)),
				"leg": 2
			})
		else:
			segs.append({
				"axis": "H",
				"grid": vfr,
				"min": mini(vff, vtf),
				"max": maxi(vff, vtf),
				"dir": int(signf(d_file)),
				"leg": 1
			})
			segs.append({
				"axis": "V",
				"grid": vtf,
				"min": mini(vfr, vtr),
				"max": maxi(vfr, vtr),
				"dir": int(signf(d_rank)),
				"leg": 2
			})
	elif d_file == 0:
		segs.append({
			"axis": "V",
			"grid": vff,
			"min": mini(vfr, vtr),
			"max": maxi(vfr, vtr),
			"dir": int(signf(d_rank)),
			"leg": 0
		})
	elif d_rank == 0:
		segs.append({
			"axis": "H",
			"grid": vfr,
			"min": mini(vff, vtf),
			"max": maxi(vff, vtf),
			"dir": int(signf(d_file)),
			"leg": 0
		})
	elif abs(d_file) == abs(d_rank) and abs(d_file) > 0:
		if d_file * d_rank > 0:
			segs.append({
				"axis": "D1",
				"grid": vff - vfr,
				"min": mini(vff, vtf),
				"max": maxi(vff, vtf),
				"dir": int(signf(d_file)),
				"leg": 0
			})
		else:
			segs.append({
				"axis": "D2",
				"grid": vff + vfr,
				"min": mini(vff, vtf),
				"max": maxi(vff, vtf),
				"dir": int(signf(d_file)),
				"leg": 0
			})
	return segs

static func _apply_leg_shift(cfg: Dictionary, leg: int, shift: float) -> void:
	if leg == 1:
		cfg["leg1_shift"] = shift
	elif leg == 2:
		cfg["leg2_shift"] = shift
	elif leg == 0:
		cfg["leg1_shift"] = shift
		cfg["leg2_shift"] = shift

static func get_arrow_dist(from_sq: String, to_sq: String) -> float:
	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	var df = to_coord.x - from_coord.x
	var dr = to_coord.y - from_coord.y
	return sqrt(df * df + dr * dr)

static func get_approach_dir(from_sq: String, to_sq: String, flipped: bool) -> Vector2:
	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	if from_coord.x < 0 or to_coord.x < 0:
		return Vector2.ZERO

	var from_file = from_coord.x
	var from_rank = 7 - from_coord.y
	var to_file = to_coord.x
	var to_rank = 7 - to_coord.y

	var vff = (7 - from_file) if flipped else from_file
	var vfr = (7 - from_rank) if flipped else from_rank
	var vtf = (7 - to_file) if flipped else to_file
	var vtr = (7 - to_rank) if flipped else to_rank

	var d_file = vtf - vff
	var d_rank = vtr - vfr
	var is_knight = (abs(d_file) == 1 and abs(d_rank) == 2) or (abs(d_file) == 2 and abs(d_rank) == 1)

	if is_knight:
		if abs(d_rank) == 2:
			return Vector2(signf(d_file), 0.0)
		else:
			return Vector2(0.0, signf(d_rank))
	else:
		var v = Vector2(d_file, d_rank)
		return v.normalized() if v.length_squared() > 0.0 else Vector2.ZERO

static func compute_arrow_polygon(
	from_sq: String,
	to_sq: String,
	flipped: bool,
	sq_size: float,
	half_side: String = "",
	leg1_shift: float = 0.0,
	leg2_shift: float = 0.0,
	trim_inner_wing: bool = false
) -> PackedVector2Array:
	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	if from_coord.x < 0 or to_coord.x < 0:
		return PackedVector2Array()

	var from_file = from_coord.x
	var from_rank = 7 - from_coord.y # Visual 0 di atas (rank 8)
	var to_file = to_coord.x
	var to_rank = 7 - to_coord.y

	var vff = (7 - from_file) if flipped else from_file
	var vfr = (7 - from_rank) if flipped else from_rank
	var vtf = (7 - to_file) if flipped else to_file
	var vtr = (7 - to_rank) if flipped else to_rank

	var x1 = (vff + 0.5) * sq_size
	var y1 = (vfr + 0.5) * sq_size
	var x2 = (vtf + 0.5) * sq_size
	var y2 = (vtr + 0.5) * sq_size

	# Konstanta ukuran 1:1 ChessAcademy
	var sw = sq_size * 0.11        # Shaft width (ekstra ramping, sleek & proporsional)
	var gap = sq_size * 0.045      # Gap antar panah paralel
	var lane_shift = (sw + gap) * 0.5
	var hl = sq_size * 0.28        # Head length (proporsional untuk langkah 1 petak hingga jarak jauh)
	var head_wing = sq_size * 0.16 # Head wing width (sleek & uniform, mencegah tabrakan sayap antar sudut)
	var start_pad = sq_size * 0.28 # Padding dari titik awal bidak (Global Symmetric: hulu sejajar hilir)
	var end_pad = sq_size * 0.28   # Padding ke titik tujuan (Global Symmetric: hulu sejajar hilir)

	var d_file = vtf - vff
	var d_rank = vtr - vfr
	var is_knight = (abs(d_file) == 1 and abs(d_rank) == 2) or (abs(d_file) == 2 and abs(d_rank) == 1)

	var poly = PackedVector2Array()

	if not is_knight:
		var dx = x2 - x1
		var dy = y2 - y1
		var dist = sqrt(dx * dx + dy * dy)
		if dist < 1.0:
			return poly

		var ux = dx / dist
		var uy = dy / dist
		# Normal kiri (uy, -ux)
		var lx = uy
		var ly = -ux
		# Normal kanan (-uy, ux)
		var rx = -uy
		var ry = ux

		# Bounding-Box Corner Perimeter: proyeksi batas kotak petak untuk panah diagonal/bersudut
		var max_u = maxf(abs(ux), abs(uy))
		var eff_start_pad = (start_pad / max_u) if max_u > 0.001 else start_pad
		var eff_end_pad = (end_pad / max_u) if max_u > 0.001 else end_pad

		# Tentukan mode lajur & trimming
		var eff_half = half_side
		var shift_val = 0.0

		if eff_half == "left":
			shift_val = lane_shift
		elif eff_half == "right":
			shift_val = -lane_shift
		elif abs(leg1_shift) > 0.001:
			shift_val = leg1_shift
			if trim_inner_wing:
				eff_half = "left" if leg1_shift > 0.0 else "right"

		var shift_v = Vector2(lx, ly) * shift_val
		var sx = x1 + ux * eff_start_pad + shift_v.x
		var sy = y1 + uy * eff_start_pad + shift_v.y
		var tip_x = x2 - ux * eff_end_pad + shift_v.x
		var tip_y = y2 - uy * eff_end_pad + shift_v.y
		var eff_hl = minf(hl, (dist - eff_start_pad - eff_end_pad) * 0.55)
		var base_x = tip_x - ux * eff_hl
		var base_y = tip_y - uy * eff_hl

		if eff_half == "":
			# Panah Normal Penuh: Kedua sayap simetris mekar sempurna, batang full width (sw)
			poly.append(Vector2(sx + lx * (sw * 0.5), sy + ly * (sw * 0.5)))
			poly.append(Vector2(base_x + lx * (sw * 0.5), base_y + ly * (sw * 0.5)))
			poly.append(Vector2(base_x + lx * head_wing, base_y + ly * head_wing))
			poly.append(Vector2(tip_x, tip_y))
			poly.append(Vector2(base_x + rx * head_wing, base_y + ry * head_wing))
			poly.append(Vector2(base_x + rx * (sw * 0.5), base_y + ry * (sw * 0.5)))
			poly.append(Vector2(sx + rx * (sw * 0.5), sy + ry * (sw * 0.5)))
		elif eff_half == "left":
			# Lajur Kiri (Chisel Half-Head):
			# Batang panah TETAP berukuran penuh sama persis dengan panah lainnya (sw).
			# Sisi dalam (kanan) lurus rata 100% dari pangkal batang sampai ujung apex tip.
			# Sayap luar (kiri) mekar sempurna (head_wing) dan miring menuju apex tip di tepi dalam.
			var sx_outer = Vector2(sx + lx * (sw * 0.5), sy + ly * (sw * 0.5))
			var base_outer = Vector2(base_x + lx * (sw * 0.5), base_y + ly * (sw * 0.5))
			var wing_outer = Vector2(base_x + lx * head_wing, base_y + ly * head_wing)
			var tip_apex = Vector2(tip_x - lx * (sw * 0.5), tip_y - ly * (sw * 0.5))
			var base_inner = Vector2(base_x - lx * (sw * 0.5), base_y - ly * (sw * 0.5))
			var sx_inner = Vector2(sx - lx * (sw * 0.5), sy - ly * (sw * 0.5))

			poly.append(sx_outer)
			poly.append(base_outer)
			poly.append(wing_outer)
			poly.append(tip_apex)
			poly.append(base_inner)
			poly.append(sx_inner)
		elif eff_half == "right":
			# Lajur Kanan (Chisel Half-Head):
			# Batang panah TETAP berukuran penuh sama persis dengan panah lainnya (sw).
			# Sisi dalam (kiri) lurus rata 100% dari pangkal batang sampai ujung apex tip.
			# Sayap luar (kanan) mekar sempurna (head_wing) dan miring menuju apex tip di tepi dalam.
			var sx_outer = Vector2(sx + rx * (sw * 0.5), sy + ry * (sw * 0.5))
			var base_outer = Vector2(base_x + rx * (sw * 0.5), base_y + ry * (sw * 0.5))
			var wing_outer = Vector2(base_x + rx * head_wing, base_y + ry * head_wing)
			var tip_apex = Vector2(tip_x - rx * (sw * 0.5), tip_y - ry * (sw * 0.5))
			var base_inner = Vector2(base_x - rx * (sw * 0.5), base_y - ry * (sw * 0.5))
			var sx_inner = Vector2(sx - rx * (sw * 0.5), sy - ry * (sw * 0.5))

			poly.append(sx_outer)
			poly.append(base_outer)
			poly.append(wing_outer)
			poly.append(tip_apex)
			poly.append(base_inner)
			poly.append(sx_inner)

	else:
		# Panah Kuda L-Shape 1:1 ChessAcademy dengan miter corner & flat shoulder head
		var u1x = 0.0; var u1y = 0.0; var u2x = 0.0; var u2y = 0.0
		var corner_x = 0.0; var corner_y = 0.0

		if abs(d_rank) == 2:
			u1x = 0.0; u1y = signf(d_rank); u2x = signf(d_file); u2y = 0.0
			corner_x = x1; corner_y = y2
		else:
			u1x = signf(d_file); u1y = 0.0; u2x = 0.0; u2y = signf(d_rank)
			corner_x = x2; corner_y = y1

		var l1x = u1y; var l1y = -u1x
		var l2x = u2y; var l2y = -u2x

		var cross = u1x * u2y - u1y * u2x
		var is_turn_right = cross > 0
		var sgn = 1.0 if is_turn_right else -1.0

		var shift1_vec = Vector2(l1x, l1y) * leg1_shift
		var shift2_vec = Vector2(l2x, l2y) * leg2_shift

		var sx = x1 + u1x * start_pad + shift1_vec.x
		var sy = y1 + u1y * start_pad + shift1_vec.y
		var tip_x = x2 - u2x * end_pad + shift2_vec.x
		var tip_y = y2 - u2y * end_pad + shift2_vec.y
		var base_x = tip_x - u2x * hl
		var base_y = tip_y - u2y * hl

		var c_center_x = corner_x + shift1_vec.x + shift2_vec.x
		var c_center_y = corner_y + shift1_vec.y + shift2_vec.y

		if half_side == "":
			var c_outer_x = c_center_x + sgn * (l1x + l2x) * (sw * 0.5)
			var c_outer_y = c_center_y + sgn * (l1y + l2y) * (sw * 0.5)
			var c_inner_x = c_center_x - sgn * (l1x + l2x) * (sw * 0.5)
			var c_inner_y = c_center_y - sgn * (l1y + l2y) * (sw * 0.5)

			var outer_is_trimmed = false
			var inner_is_trimmed = false
			if trim_inner_wing and abs(leg2_shift) > 0.001:
				var neighbor_side = -signf(leg2_shift)
				if sgn * neighbor_side > 0.0:
					outer_is_trimmed = true
				else:
					inner_is_trimmed = true

			var tip_pt = Vector2(tip_x, tip_y)
			if outer_is_trimmed:
				tip_pt = Vector2(tip_x + sgn * l2x * (sw * 0.5), tip_y + sgn * l2y * (sw * 0.5))
			elif inner_is_trimmed:
				tip_pt = Vector2(tip_x - sgn * l2x * (sw * 0.5), tip_y - sgn * l2y * (sw * 0.5))

			poly.append(Vector2(sx + sgn * l1x * (sw * 0.5), sy + sgn * l1y * (sw * 0.5)))
			poly.append(Vector2(c_outer_x, c_outer_y))
			poly.append(Vector2(base_x + sgn * l2x * (sw * 0.5), base_y + sgn * l2y * (sw * 0.5)))
			if not outer_is_trimmed:
				poly.append(Vector2(base_x + sgn * l2x * head_wing, base_y + sgn * l2y * head_wing))
			poly.append(tip_pt)
			if not inner_is_trimmed:
				poly.append(Vector2(base_x - sgn * l2x * head_wing, base_y - sgn * l2y * head_wing))
			poly.append(Vector2(base_x - sgn * l2x * (sw * 0.5), base_y - sgn * l2y * (sw * 0.5)))
			poly.append(Vector2(c_inner_x, c_inner_y))
			poly.append(Vector2(sx - sgn * l1x * (sw * 0.5), sy - sgn * l1y * (sw * 0.5)))
		else:
			# Segmented Half Arrow untuk Kuda (misal converging ke target yang sama)
			var lane_shift_val = sw * 0.5 + gap * 0.5
			var side_sign = 1.0 if half_side == "left" else -1.0
			var side_v = Vector2(l2x, l2y) * side_sign

			var base_pt = Vector2(base_x, base_y) + side_v * lane_shift_val

			var wing_outer = base_pt + side_v * head_wing
			var shoulder_outer = base_pt + side_v * (sw * 0.5)
			var inner_tip = Vector2(tip_x, tip_y) + side_v * (gap * 0.5)
			var inner_base = Vector2(base_x, base_y) + side_v * (gap * 0.5)

			var c_pt = Vector2(corner_x, corner_y)
			var l1 = Vector2(l1x, l1y)
			var l2 = Vector2(l2x, l2y)

			var off_outer = (sw + gap * 0.5) * side_sign
			var off_inner = (gap * 0.5) * side_sign

			var is_outer_side = (side_sign * sgn) > 0.0
			var off_turn_outer = off_outer if is_outer_side else off_inner
			var off_turn_inner = off_inner if is_outer_side else off_outer

			var c_turn_outer = c_pt + l1 * (sgn * sw * 0.5) + l2 * off_turn_outer
			var c_turn_inner = c_pt - l1 * (sgn * sw * 0.5) + l2 * off_turn_inner

			poly.append(Vector2(sx, sy) + l1 * (sgn * sw * 0.5))
			poly.append(c_turn_outer)
			if is_outer_side:
				poly.append(shoulder_outer)
				poly.append(wing_outer)
				poly.append(inner_tip)
				poly.append(inner_base)
			else:
				poly.append(inner_base)
				poly.append(inner_tip)
				poly.append(wing_outer)
				poly.append(shoulder_outer)
			poly.append(c_turn_inner)
			poly.append(Vector2(sx, sy) - l1 * (sgn * sw * 0.5))

	return poly
