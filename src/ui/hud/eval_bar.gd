class_name EvalBar
extends Control

@onready var panel: Panel = $Panel
@onready var white_fill: ColorRect = $Panel/WhiteFill
@onready var score_label: Label = $Panel/ScoreLabel

var current_score_cp: int = 0
var is_mate: bool = false
var mate_in: int = 0
var is_flipped: bool = false
var _fill_tween: Tween

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(24, 512)
	size = custom_minimum_size
	if size.x > size.y:
		white_fill.position = Vector2(0, 0)
		white_fill.size = Vector2(size.x * 0.5, size.y)
	else:
		white_fill.position = Vector2(0, size.y * 0.5)
		white_fill.size = Vector2(size.x, size.y * 0.5)
	set_eval(0, false, 0)

func set_eval(score_cp: int, mate: bool, mate_cnt: int, depth: int = 0) -> void:
	# Filter noise pada depth sangat rendah (depth < 6) agar bar tidak melonjak-lonjak
	if not mate and depth > 0 and depth < 6:
		return
	current_score_cp = score_cp
	is_mate = mate
	mate_in = mate_cnt
	_update_visuals()

func set_flipped(flipped: bool) -> void:
	is_flipped = flipped
	_update_visuals()

func _update_visuals() -> void:
	if not is_inside_tree() or not is_node_ready():
		return

	if is_mate:
		var is_white_win: bool = (mate_in > 0) or (mate_in == 0 and current_score_cp > 0)
		var prefix: String = "+" if is_white_win else "-"
		if mate_in == 0:
			score_label.text = "%s#" % prefix
		else:
			score_label.text = "%sM%d" % [prefix, abs(mate_in)]
		_animate_fill(1.0 if is_white_win else 0.0)
	else:
		# Centipawns to pawns (e.g. 150 -> +1.5)
		var pawns = float(current_score_cp) / 100.0
		var prefix = "+" if pawns > 0.05 else ""
		if abs(pawns) < 0.05:
			score_label.text = "0.0"
		else:
			score_label.text = "%s%.1f" % [prefix, pawns]

		# Sigmoid formula: centipawns -> white winning percentage (0.04 - 0.96)
		var win_chance = 1.0 / (1.0 + exp(-0.00368208 * current_score_cp))
		var white_ratio = clampf(win_chance, 0.04, 0.96)
		_animate_fill(white_ratio)

func _animate_fill(white_ratio: float) -> void:
	var is_horizontal = size.x > size.y
	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()
	_fill_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	if is_horizontal:
		var total_w: float = size.x if size.x > 0 else 688.0
		var white_w: float = total_w * white_ratio
		var target_x: float = (total_w - white_w) if is_flipped else 0.0
		_fill_tween.tween_property(white_fill, "position:x", target_x, 0.35)
		_fill_tween.tween_property(white_fill, "size:x", white_w, 0.35)
		_fill_tween.tween_property(white_fill, "position:y", 0.0, 0.35)
		_fill_tween.tween_property(white_fill, "size:y", size.y, 0.35)

		var white_is_dominant = white_ratio > 0.5
		if white_is_dominant:
			score_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.14, 0.95))
		else:
			score_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 0.95))
		var center_lead_x = (target_x + white_w * 0.5) if white_is_dominant else ((target_x * 0.5) if not is_flipped else (target_x + (total_w - target_x) * 0.5))
		score_label.position.x = clampf(center_lead_x - 18.0, 4.0, total_w - 40.0)
		score_label.position.y = maxf(0.0, (size.y - score_label.size.y) * 0.5)
	else:
		var total_h: float = size.y if size.y > 0 else 512.0
		var white_h: float = total_h * white_ratio
		var target_y: float = (total_h - white_h) if not is_flipped else 0.0

		_fill_tween.tween_property(white_fill, "position:y", target_y, 0.35)
		_fill_tween.tween_property(white_fill, "size:y", white_h, 0.35)
		_fill_tween.tween_property(white_fill, "position:x", 0.0, 0.35)
		_fill_tween.tween_property(white_fill, "size:x", size.x, 0.35)

		var white_is_dominant = white_ratio > 0.5
		var label_target_y: float
		if white_is_dominant:
			score_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.14, 0.95))
			label_target_y = (total_h - 24.0) if not is_flipped else 6.0
		else:
			score_label.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96, 0.95))
			label_target_y = 6.0 if not is_flipped else (total_h - 24.0)

		score_label.position.y = label_target_y
