class_name SquareCell
extends Control

signal square_clicked(sq: String)

const SQUARE_SHADER = preload("res://src/ui/board/square_cell.gdshader")

var square_name: String = ""
var is_dark: bool = false
var is_selected: bool = false
var is_last_move: bool = false
var is_in_check: bool = false
var is_legal_move: bool = false
var is_capture_target: bool = false
var is_forbidden: bool = false
var is_defender: bool = false
var is_drag_hovered: bool = false

var legal_scale: float = 0.0
var _legal_tween: Tween = null
var selected_scale: float = 0.0
var _selected_tween: Tween = null

var base_color: Color = Color.WHITE
var cell_mat: ShaderMaterial = null

func _ready() -> void:
	clip_contents = true
	mouse_filter = MOUSE_FILTER_PASS
	_ensure_material()
	update_theme_colors()

func _ensure_material() -> void:
	if cell_mat == null:
		cell_mat = ShaderMaterial.new()
		cell_mat.shader = SQUARE_SHADER
		material = cell_mat

func setup(sq: String, dark: bool, sq_size: float) -> void:
	square_name = sq
	is_dark = dark
	clip_contents = true
	custom_minimum_size = Vector2(sq_size, sq_size)
	size = custom_minimum_size
	_ensure_material()
	update_theme_colors()

func update_theme_colors() -> void:
	var th_name = "slate"
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS:
			th_name = GS.board_theme
	var theme_data = BoardThemes.get_theme(th_name)
	base_color = theme_data["dark_color"] if is_dark else theme_data["light_color"]
	queue_redraw()

func animate_legal_indicator(delay: float = 0.0) -> void:
	if _legal_tween and _legal_tween.is_valid():
		_legal_tween.kill()
		_legal_tween = null
	if not is_inside_tree():
		legal_scale = 1.0
		queue_redraw()
		return
	legal_scale = 0.0
	queue_redraw()
	_legal_tween = create_tween()
	if delay > 0.0:
		_legal_tween.tween_interval(delay)
	_legal_tween.tween_method(_set_legal_scale, 0.0, 1.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _set_legal_scale(val: float) -> void:
	legal_scale = val
	queue_redraw()

func set_legal_scale_immediate(val: float = 1.0) -> void:
	if _legal_tween and _legal_tween.is_valid():
		_legal_tween.kill()
		_legal_tween = null
	legal_scale = val
	queue_redraw()

func stop_legal_animation() -> void:
	if _legal_tween and _legal_tween.is_valid():
		_legal_tween.kill()
		_legal_tween = null
	legal_scale = 0.0
	queue_redraw()

func _animate_selection() -> void:
	if _selected_tween and _selected_tween.is_valid():
		_selected_tween.kill()
		_selected_tween = null
	if not is_inside_tree():
		selected_scale = 1.0
		queue_redraw()
		return
	selected_scale = 0.0
	queue_redraw()
	_selected_tween = create_tween()
	_selected_tween.tween_method(_set_selected_scale, 0.0, 1.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _set_selected_scale(val: float) -> void:
	selected_scale = val
	queue_redraw()

func _stop_selection_animation() -> void:
	if _selected_tween and _selected_tween.is_valid():
		_selected_tween.kill()
		_selected_tween = null
	selected_scale = 0.0
	queue_redraw()

func set_drag_hover(val: bool) -> void:
	if is_drag_hovered != val:
		is_drag_hovered = val
		queue_redraw()

func set_highlights(selected: bool, last_move: bool, in_check: bool, legal: bool, capture: bool, forbidden: bool = false, defender: bool = false) -> void:
	var prev_selected = is_selected
	is_selected = selected
	is_last_move = last_move
	is_in_check = in_check
	is_legal_move = legal
	is_capture_target = capture
	is_forbidden = forbidden
	is_defender = defender

	if is_selected and not prev_selected:
		_animate_selection()
	elif not is_selected:
		_stop_selection_animation()

	if not is_legal_move:
		stop_legal_animation()
	queue_redraw()

func _draw() -> void:
	_ensure_material()

	var th_name = "slate"
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS:
			th_name = GS.board_theme
	var theme_data = BoardThemes.get_theme(th_name)
	base_color = theme_data["dark_color"] if is_dark else theme_data["light_color"]

	cell_mat.set_shader_parameter("base_color", base_color)
	cell_mat.set_shader_parameter("last_move_color", theme_data.get("last_move_color", Color(0.9, 0.8, 0.2, 0.4)))
	cell_mat.set_shader_parameter("forbidden_color", theme_data.get("forbidden_color", Color(0.92, 0.2, 0.22, 0.35)))
	cell_mat.set_shader_parameter("defender_color", theme_data.get("defender_color", Color(0.22, 0.65, 1.0, 0.95)))
	cell_mat.set_shader_parameter("check_color", theme_data.get("check_color", Color(0.95, 0.2, 0.2, 0.65)))
	cell_mat.set_shader_parameter("selected_color", theme_data.get("highlight_color", Color(0.2, 0.6, 1.0, 0.45)))
	
	var hint_col = Color(0.1, 0.1, 0.1, 0.32) if not is_dark else Color(0.0, 0.0, 0.0, 0.38)
	cell_mat.set_shader_parameter("legal_color", hint_col)
	cell_mat.set_shader_parameter("capture_dim_alpha", 0.36 if not is_dark else 0.42)

	cell_mat.set_shader_parameter("is_last_move", is_last_move)
	cell_mat.set_shader_parameter("is_forbidden", is_forbidden)
	cell_mat.set_shader_parameter("is_defender", is_defender)
	cell_mat.set_shader_parameter("is_in_check", is_in_check)
	cell_mat.set_shader_parameter("is_selected", is_selected)
	cell_mat.set_shader_parameter("selected_scale", selected_scale)
	cell_mat.set_shader_parameter("is_legal_move", is_legal_move)
	cell_mat.set_shader_parameter("is_capture_target", is_capture_target)
	cell_mat.set_shader_parameter("legal_scale", legal_scale)
	cell_mat.set_shader_parameter("is_drag_hovered", is_drag_hovered)
	cell_mat.set_shader_parameter("cell_size", size)

	var rect = Rect2(Vector2.ZERO, size + Vector2(0.5, 0.5))
	draw_rect(rect, Color.WHITE)
