class_name PromotionDialog
extends Control

signal piece_selected(piece_type: int)
signal canceled()

var promotion_color: int = ChessTypes.PieceColor.WHITE

@onready var backdrop: ColorRect = $Backdrop
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var buttons_container: VBoxContainer = $PopupPanel/ButtonsContainer

func _ready() -> void:
	backdrop.gui_input.connect(_on_backdrop_gui_input)

func select_piece(piece_type: int) -> void:
	piece_selected.emit(piece_type)
	queue_free()

func setup(color: int, piece_set: String, target_pos: Vector2 = Vector2.ZERO) -> void:
	promotion_color = color
	for child in buttons_container.get_children():
		child.queue_free()

	var panel_width = 80.0
	var panel_height = 284.0

	# Posisikan popup terpusat secara horizontal di atas kolom/file pion promosi
	var is_top_rank = target_pos.y < 280.0
	var center_x = target_pos.x + (70.0 - panel_width) * 0.5
	popup_panel.position.x = clampf(center_x, 4.0, 560.0 - panel_width - 4.0)
	popup_panel.position.y = 0.0 if is_top_rank else (560.0 - panel_height)

	# Urutan bidak: Ratu selalu berada di petak kedatangan pion promosi
	var types: Array[int]
	if is_top_rank:
		types = [
			ChessTypes.PieceType.QUEEN,
			ChessTypes.PieceType.KNIGHT,
			ChessTypes.PieceType.ROOK,
			ChessTypes.PieceType.BISHOP
		]
	else:
		types = [
			ChessTypes.PieceType.BISHOP,
			ChessTypes.PieceType.ROOK,
			ChessTypes.PieceType.KNIGHT,
			ChessTypes.PieceType.QUEEN
		]

	var color_char = "w" if color == ChessTypes.PieceColor.WHITE else "b"

	var normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.14, 0.17, 0.22, 0.5)
	normal_style.set_corner_radius_all(8)

	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.22, 0.45, 0.75, 0.85)
	hover_style.set_corner_radius_all(8)
	hover_style.border_width_left = 1
	hover_style.border_width_top = 1
	hover_style.border_width_right = 1
	hover_style.border_width_bottom = 2
	hover_style.border_color = Color(0.45, 0.75, 1.0, 0.95)

	var pressed_style = StyleBoxFlat.new()
	pressed_style.bg_color = Color(0.3, 0.55, 0.85, 0.95)
	pressed_style.set_corner_radius_all(8)

	for p_type in types:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(64, 64)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_theme_stylebox_override("normal", normal_style)
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		btn.add_theme_constant_override("icon_max_width", 48)

		var type_char = ChessTypes.piece_type_to_san_char(p_type)
		var texture_path = "res://assets/pieces/%s/%s%s.png" % [piece_set, color_char, type_char]
		if not ResourceLoader.exists(texture_path):
			texture_path = "res://assets/pieces/%s/%s%s.svg" % [piece_set, color_char, type_char]
		if ResourceLoader.exists(texture_path):
			btn.icon = load(texture_path)
			btn.expand_icon = true

		match p_type:
			ChessTypes.PieceType.QUEEN: btn.tooltip_text = "Queen"
			ChessTypes.PieceType.KNIGHT: btn.tooltip_text = "Knight"
			ChessTypes.PieceType.ROOK: btn.tooltip_text = "Rook"
			ChessTypes.PieceType.BISHOP: btn.tooltip_text = "Bishop"

		btn.pressed.connect(select_piece.bind(p_type))
		buttons_container.add_child(btn)

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		canceled.emit()
		queue_free()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		canceled.emit()
		queue_free()
		get_viewport().set_input_as_handled()
