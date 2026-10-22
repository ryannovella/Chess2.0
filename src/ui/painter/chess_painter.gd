class_name ChessPainter
extends Control

signal play_position(fen: String, mode: String) # mode: "vs_ai" | "local_2p"
signal back_to_main_menu

@onready var board_viewport: Control = $MainLayout/BoardSection/BoardViewport
@onready var ranks_container: VBoxContainer = $MainLayout/BoardSection/RanksContainer
@onready var files_container: HBoxContainer = $MainLayout/BoardSection/FilesContainer

@onready var opt_turn: OptionButton = $MainLayout/ToolsSection/VBoxContainer/TurnRow/OptTurn
@onready var chk_wk: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkWK
@onready var chk_wq: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkWQ
@onready var chk_bk: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkBk
@onready var chk_bq: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkBq

@onready var btn_play_ai: Button = $MainLayout/ToolsSection/VBoxContainer/BtnPlayAI
@onready var btn_play_local: Button = $MainLayout/ToolsSection/VBoxContainer/BtnPlayLocal
@onready var btn_clear: Button = $MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnClear
@onready var btn_reset: Button = $MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnReset
@onready var btn_back: Button = $MainLayout/ToolsSection/VBoxContainer/BtnBack

@onready var white_palette: HBoxContainer = $MainLayout/ToolsSection/VBoxContainer/PaletteGroup/WhitePalette
@onready var black_palette: HBoxContainer = $MainLayout/ToolsSection/VBoxContainer/PaletteGroup/BlackPalette

const BOARD_PIXELS: float = 560.0
var square_size: float = 65.0 # 560 / 8
var painter_state: ChessBoardState = null
var square_cells: Dictionary = {}
var piece_views: Dictionary = {}

# Kuas yang sedang aktif: {"color": int, "type": int} atau null (eraser)
var active_brush: Variant = {"color": ChessTypes.PieceColor.WHITE, "type": ChessTypes.PieceType.PAWN}
var is_eraser: bool = false

var _palette_buttons: Array[Button] = []
var _style_palette_normal: StyleBoxFlat
var _style_palette_hover: StyleBoxFlat
var _style_palette_selected: StyleBoxFlat

func _init_palette_styles() -> void:
	if _style_palette_normal != null:
		return
	_style_palette_normal = StyleBoxFlat.new()
	_style_palette_normal.bg_color = Color(0.18, 0.17, 0.16, 1.0)
	_style_palette_normal.set_corner_radius_all(8)
	_style_palette_normal.content_margin_left = 3.0
	_style_palette_normal.content_margin_right = 3.0
	_style_palette_normal.content_margin_top = 3.0
	_style_palette_normal.content_margin_bottom = 3.0
	_style_palette_normal.border_width_bottom = 2
	_style_palette_normal.border_color = Color(0.12, 0.11, 0.10, 1.0)

	_style_palette_hover = _style_palette_normal.duplicate()
	_style_palette_hover.bg_color = Color(0.25, 0.24, 0.22, 1.0)

	_style_palette_selected = StyleBoxFlat.new()
	_style_palette_selected.bg_color = Color(0.20, 0.25, 0.18, 1.0)
	_style_palette_selected.set_corner_radius_all(8)
	_style_palette_selected.content_margin_left = 3.0
	_style_palette_selected.content_margin_right = 3.0
	_style_palette_selected.content_margin_top = 3.0
	_style_palette_selected.content_margin_bottom = 3.0
	_style_palette_selected.border_width_left = 2
	_style_palette_selected.border_width_top = 2
	_style_palette_selected.border_width_right = 2
	_style_palette_selected.border_width_bottom = 3
	_style_palette_selected.border_color = Color(0.506, 0.714, 0.298, 1.0)

func _ready() -> void:
	square_size = BOARD_PIXELS / 8.0
	painter_state = ChessBoardState.new(ChessBoardState.DEFAULT_FEN)
	_build_board()
	_setup_palette()
	_setup_signals()

func _build_board() -> void:
	for child in board_viewport.get_children():
		child.queue_free()
	square_cells.clear()

	for r in range(8):
		for f in range(8):
			var sq_name = ChessTypes.coord_to_square(f, r)
			var is_dark = (f + r) % 2 == 0
			var cell = SquareCell.new()
			cell.setup(sq_name, is_dark, square_size)
			cell.position = Vector2(f * square_size, (7 - r) * square_size)
			cell.gui_input.connect(_on_cell_input.bind(sq_name))
			board_viewport.add_child(cell)
			square_cells[sq_name] = cell

	_refresh_pieces()

func _setup_palette() -> void:
	_init_palette_styles()
	_palette_buttons.clear()
	for c in white_palette.get_children(): c.queue_free()
	for c in black_palette.get_children(): c.queue_free()

	var types = [
		ChessTypes.PieceType.KING, ChessTypes.PieceType.QUEEN, ChessTypes.PieceType.ROOK,
		ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.PAWN
	]

	for t in types:
		_add_palette_button(white_palette, ChessTypes.PieceColor.WHITE, t)
		_add_palette_button(black_palette, ChessTypes.PieceColor.BLACK, t)

	_update_palette_selection()

func _add_palette_button(container: HBoxContainer, color: int, type: int) -> void:
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 52)
	btn.focus_mode = Control.FOCUS_NONE
	btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn.expand_icon = true
	btn.set_meta("color", color)
	btn.set_meta("type", type)

	var color_char = "w" if color == ChessTypes.PieceColor.WHITE else "b"
	var type_char = ChessTypes.piece_type_to_san_char(type)
	if type == ChessTypes.PieceType.PAWN: type_char = "P"

	var icon_path = "res://assets/pieces/%s/%s%s.png" % [GameSettings.piece_set, color_char, type_char]
	if not ResourceLoader.exists(icon_path):
		icon_path = "res://assets/pieces/%s/%s%s.svg" % [GameSettings.piece_set, color_char, type_char]
	if ResourceLoader.exists(icon_path):
		btn.icon = load(icon_path)

	_palette_buttons.append(btn)
	_apply_palette_button_style(btn)

	btn.pressed.connect(func():
		is_eraser = false
		active_brush = {"color": color, "type": type}
		_update_palette_selection()
	)
	container.add_child(btn)

func _update_palette_selection() -> void:
	for b in _palette_buttons:
		_apply_palette_button_style(b)

func _apply_palette_button_style(btn: Button) -> void:
	var is_sel = false
	if not is_eraser and active_brush != null:
		if btn.get_meta("color") == active_brush["color"] and btn.get_meta("type") == active_brush["type"]:
			is_sel = true

	var current_normal = _style_palette_selected if is_sel else _style_palette_normal
	var current_hover = _style_palette_selected if is_sel else _style_palette_hover
	btn.add_theme_stylebox_override("normal", current_normal)
	btn.add_theme_stylebox_override("hover", current_hover)
	btn.add_theme_stylebox_override("pressed", current_normal)

func _setup_signals() -> void:
	opt_turn.clear()
	opt_turn.add_item("White to move", 0)
	opt_turn.add_item("Black to move", 1)
	opt_turn.select(0)

	btn_clear.pressed.connect(func():
		painter_state.squares.fill(null)
		_refresh_pieces()
	)

	btn_reset.pressed.connect(func():
		painter_state.load_fen(ChessBoardState.DEFAULT_FEN)
		_refresh_pieces()
	)

	btn_back.pressed.connect(func():
		back_to_main_menu.emit()
	)

	btn_play_ai.pressed.connect(func():
		_launch_game("vs_ai")
	)

	btn_play_local.pressed.connect(func():
		_launch_game("local_2p")
	)

func _launch_game(mode: String) -> void:
	# Update status rokade & giliran sebelum launch
	painter_state.turn = ChessTypes.PieceColor.BLACK if opt_turn.selected == 1 else ChessTypes.PieceColor.WHITE
	painter_state.castling["wK"] = chk_wk.button_pressed
	painter_state.castling["wQ"] = chk_wq.button_pressed
	painter_state.castling["bK"] = chk_bk.button_pressed
	painter_state.castling["bQ"] = chk_bq.button_pressed

	var final_fen = painter_state.to_fen()
	play_position.emit(final_fen, mode)

var is_mouse_pressed: bool = false
var pressed_button_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		is_mouse_pressed = false
		pressed_button_index = -1

func _get_square_from_position(pos: Vector2) -> String:
	var f = int(pos.x / square_size)
	var r = 7 - int(pos.y / square_size)
	if f >= 0 and f < 8 and r >= 0 and r < 8:
		return ChessTypes.coord_to_square(f, r)
	return ""

func _on_cell_input(event: InputEvent, sq: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			is_mouse_pressed = true
			pressed_button_index = event.button_index
			_apply_brush(sq, pressed_button_index)
		else:
			is_mouse_pressed = false
			pressed_button_index = -1
	elif event is InputEventMouseMotion and is_mouse_pressed:
		if board_viewport:
			var local_pos = board_viewport.get_local_mouse_position()
			var target_sq = _get_square_from_position(local_pos)
			if not target_sq.is_empty():
				_apply_brush(target_sq, pressed_button_index)


func _apply_brush(sq: String, button_index: int) -> void:
	var current_piece = painter_state.get_piece(sq)
	if button_index == MOUSE_BUTTON_LEFT:
		if is_eraser or active_brush == null:
			if current_piece != null:
				painter_state.set_piece(sq, null)
				_refresh_pieces()
		else:
			var target_color: int = active_brush["color"]
			var target_type: int = active_brush["type"]
			if current_piece == null or current_piece["color"] != target_color or current_piece["type"] != target_type:
				painter_state.set_piece(sq, {"color": target_color, "type": target_type})
				_refresh_pieces()
	elif button_index == MOUSE_BUTTON_RIGHT:
		if current_piece != null:
			painter_state.set_piece(sq, null)
			_refresh_pieces()

func _refresh_pieces() -> void:
	for p in piece_views.values():
		p.queue_free()
	piece_views.clear()

	for i in range(64):
		var p = painter_state.squares[i]
		if p != null:
			var sq_name = ChessTypes.index_to_square(i)
			var view = PieceView.new()
			view.setup(p["color"], p["type"], sq_name, GameSettings.piece_set, square_size)
			var coord = ChessTypes.square_to_coord(sq_name)
			view.position = Vector2(coord.x * square_size, (7 - coord.y) * square_size)
			view.size = Vector2(square_size, square_size)
			view.custom_minimum_size = Vector2(square_size, square_size)
			board_viewport.add_child(view)
			piece_views[sq_name] = view
