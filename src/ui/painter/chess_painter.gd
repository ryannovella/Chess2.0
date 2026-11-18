class_name ChessPainter
extends Control

signal play_position(fen: String, mode: String) # mode: "vs_ai" | "local_2p"
signal back_to_main_menu

@onready var board_viewport: Control = get_node_or_null("MainLayout/BoardSection/BoardCol/BoardViewport")
@onready var ranks_container: VBoxContainer = get_node_or_null("MainLayout/BoardSection/RanksContainer")
@onready var files_container: HBoxContainer = get_node_or_null("MainLayout/BoardSection/BoardCol/FilesContainer")

@onready var opt_turn: OptionButton = $MainLayout/ToolsSection/VBoxContainer/TurnRow/OptTurn
@onready var opt_side: OptionButton = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/SideRow/OptSide")
@onready var chk_wk: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkWK
@onready var chk_wq: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkWQ
@onready var chk_bk: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkBk
@onready var chk_bq: CheckBox = $MainLayout/ToolsSection/VBoxContainer/CastlingGrid/ChkBq

@onready var btn_play_ai: Button = $MainLayout/ToolsSection/VBoxContainer/BtnPlayAI
@onready var btn_play_local: Button = $MainLayout/ToolsSection/VBoxContainer/BtnPlayLocal
@onready var btn_clear: Button = $MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnClear
@onready var btn_reset: Button = $MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnReset
@onready var btn_sync_game: Button = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnSyncGame")
@onready var btn_back: Button = $MainLayout/ToolsSection/VBoxContainer/BtnBack
@onready var status_banner: PanelContainer = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner")
@onready var status_label: Label = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner/BannerHBox/StatusLabel")
@onready var banner_icon: TextureRect = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner/BannerHBox/BannerIcon")

@onready var white_palette: HBoxContainer = $MainLayout/ToolsSection/VBoxContainer/PaletteGroup/WhitePalette
@onready var black_palette: HBoxContainer = $MainLayout/ToolsSection/VBoxContainer/PaletteGroup/BlackPalette

const BOARD_PIXELS: float = 560.0
var square_size: float = 65.0 # 560 / 8
var painter_state: ChessBoardState = null
var square_cells: Dictionary = {}
var piece_views: Dictionary = {}
var painter_flipped: bool = false

# Kuas yang sedang aktif: {"color": int, "type": int} atau null (eraser)
var active_brush: Variant = {"color": ChessTypes.PieceColor.WHITE, "type": ChessTypes.PieceType.PAWN}
var is_eraser: bool = false

var _palette_buttons: Array[Button] = []
var _style_palette_normal: StyleBoxFlat
var _style_palette_hover: StyleBoxFlat
var _style_palette_selected: StyleBoxFlat
var _style_banner_box: StyleBoxFlat

func _init_banner_style() -> void:
	if _style_banner_box != null:
		return
	_style_banner_box = StyleBoxFlat.new()
	_style_banner_box.bg_color = Color(0.24, 0.14, 0.12, 0.95)
	_style_banner_box.set_corner_radius_all(6)
	_style_banner_box.content_margin_left = 10.0
	_style_banner_box.content_margin_right = 10.0
	_style_banner_box.content_margin_top = 8.0
	_style_banner_box.content_margin_bottom = 8.0
	_style_banner_box.border_width_left = 1
	_style_banner_box.border_width_top = 1
	_style_banner_box.border_width_right = 1
	_style_banner_box.border_width_bottom = 2
	_style_banner_box.border_color = Color(0.85, 0.35, 0.25, 0.8)
	if status_banner != null:
		status_banner.add_theme_stylebox_override("panel", _style_banner_box)
	if banner_icon != null:
		banner_icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

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

func _ensure_nodes() -> void:
	if board_viewport == null:
		board_viewport = get_node_or_null("MainLayout/BoardSection/BoardCol/BoardViewport")
		if board_viewport == null:
			board_viewport = get_node_or_null("MainLayout/BoardSection/BoardViewport")
	if ranks_container == null:
		ranks_container = get_node_or_null("MainLayout/BoardSection/RanksContainer")
	if files_container == null:
		files_container = get_node_or_null("MainLayout/BoardSection/BoardCol/FilesContainer")
		if files_container == null:
			files_container = get_node_or_null("MainLayout/BoardSection/FilesContainer")
	if opt_turn == null:
		opt_turn = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/TurnRow/OptTurn")
	if opt_side == null:
		opt_side = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/SideRow/OptSide")
	if btn_clear == null:
		btn_clear = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnClear")
	if btn_reset == null:
		btn_reset = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnReset")
	if btn_sync_game == null:
		btn_sync_game = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/ToolButtons/BtnSyncGame")
	if btn_play_ai == null:
		btn_play_ai = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/BtnPlayAI")
	if btn_play_local == null:
		btn_play_local = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/BtnPlayLocal")
	if btn_back == null:
		btn_back = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/BtnBack")
	if status_banner == null:
		status_banner = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner")
	if status_label == null:
		status_label = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner/BannerHBox/StatusLabel")
	if banner_icon == null:
		banner_icon = get_node_or_null("MainLayout/ToolsSection/VBoxContainer/StatusBanner/BannerHBox/BannerIcon")

func _ready() -> void:
	square_size = BOARD_PIXELS / 8.0
	painter_state = ChessBoardState.new(ChessBoardState.DEFAULT_FEN)
	_ensure_nodes()
	_init_banner_style()
	_set_status("")
	_init_side_selection()
	_build_board()
	_build_coordinates()
	_setup_palette()
	_setup_signals()

func _init_side_selection() -> void:
	if opt_side == null:
		return
	opt_side.clear()
	opt_side.add_item("White (Bottom)", 0)
	opt_side.add_item("Black (Bottom)", 1)
	var is_black = false
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS and GS.chosen_side == "black":
			is_black = true
	opt_side.select(1 if is_black else 0)
	painter_flipped = is_black

func _build_board() -> void:
	_ensure_nodes()
	if board_viewport == null:
		return
	for child in board_viewport.get_children():
		child.queue_free()
	square_cells.clear()

	for r in range(8):
		for f in range(8):
			var sq_name = ChessTypes.coord_to_square(f, r)
			var is_dark = (f + r) % 2 == 0
			var cell = SquareCell.new()
			cell.setup(sq_name, is_dark, square_size)
			var visual_f = (7 - f) if painter_flipped else f
			var visual_r = r if painter_flipped else (7 - r)
			cell.position = Vector2(visual_f * square_size, visual_r * square_size)
			cell.gui_input.connect(_on_cell_input.bind(sq_name))
			board_viewport.add_child(cell)
			square_cells[sq_name] = cell

	_update_coordinates()
	_refresh_pieces()

func _build_coordinates() -> void:
	if ranks_container == null or files_container == null:
		return
	for c in ranks_container.get_children():
		c.queue_free()
	for c in files_container.get_children():
		c.queue_free()

	for i in range(8):
		var lbl_r = Label.new()
		lbl_r.custom_minimum_size = Vector2(20, square_size)
		lbl_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_r.add_theme_color_override("font_color", Color(0.65, 0.63, 0.60, 0.85))
		lbl_r.add_theme_font_size_override("font_size", 15)
		ranks_container.add_child(lbl_r)

		var lbl_f = Label.new()
		lbl_f.custom_minimum_size = Vector2(square_size, 20)
		lbl_f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_f.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_f.add_theme_color_override("font_color", Color(0.65, 0.63, 0.60, 0.85))
		lbl_f.add_theme_font_size_override("font_size", 15)
		files_container.add_child(lbl_f)

	_update_coordinates()

func _update_coordinates() -> void:
	if ranks_container == null or files_container == null:
		return
	var ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
	var files = ["a", "b", "c", "d", "e", "f", "g", "h"]
	if painter_flipped:
		ranks.reverse()
		files.reverse()

	var r_children = ranks_container.get_children()
	for i in range(mini(r_children.size(), ranks.size())):
		r_children[i].text = ranks[i]

	var f_children = files_container.get_children()
	for i in range(mini(f_children.size(), files.size())):
		f_children[i].text = files[i]

func _refresh_board_orientation() -> void:
	for r in range(8):
		for f in range(8):
			var sq_name = ChessTypes.coord_to_square(f, r)
			var cell = square_cells.get(sq_name)
			if cell != null:
				var visual_f = (7 - f) if painter_flipped else f
				var visual_r = r if painter_flipped else (7 - r)
				cell.position = Vector2(visual_f * square_size, visual_r * square_size)
	_update_coordinates()
	for sq_name in piece_views.keys():
		var view = piece_views[sq_name]
		if view != null and is_instance_valid(view):
			var coord = ChessTypes.square_to_coord(sq_name)
			var visual_f = (7 - coord.x) if painter_flipped else coord.x
			var visual_r = coord.y if painter_flipped else (7 - coord.y)
			view.position = Vector2(visual_f * square_size, visual_r * square_size)

func sync_orientation_from_settings() -> void:
	_ensure_nodes()
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS != null:
			var is_black = (GS.chosen_side == "black")
			if opt_side != null:
				opt_side.select(1 if is_black else 0)
			if painter_flipped != is_black:
				painter_flipped = is_black
				_refresh_board_orientation()

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

	if opt_side != null and not opt_side.item_selected.is_connected(_on_side_selected):
		opt_side.item_selected.connect(_on_side_selected)

	btn_clear.pressed.connect(func():
		painter_state.squares.fill(null)
		_refresh_pieces()
	)

	btn_reset.pressed.connect(func():
		painter_state.load_fen(ChessBoardState.DEFAULT_FEN)
		_refresh_pieces()
	)

	if btn_sync_game != null and not btn_sync_game.pressed.is_connected(_on_sync_game_pressed):
		btn_sync_game.pressed.connect(_on_sync_game_pressed)

	btn_back.pressed.connect(func():
		back_to_main_menu.emit()
	)

	btn_play_ai.pressed.connect(func():
		_launch_game("vs_ai")
	)

	btn_play_local.pressed.connect(func():
		_launch_game("local_2p")
	)

func _on_side_selected(idx: int) -> void:
	painter_flipped = (idx == 1)
	_refresh_board_orientation()

func _on_sync_game_pressed() -> void:
	var tree = get_tree()
	if tree != null and tree.root != null:
		var main_node = tree.root.get_node_or_null("Main")
		if main_node != null and "board_state" in main_node and main_node.board_state != null:
			load_position(main_node.board_state.to_fen())

func load_position(fen: String) -> void:
	if painter_state == null:
		painter_state = ChessBoardState.new(fen)
	else:
		painter_state.load_fen(fen)
	if opt_turn != null:
		opt_turn.select(1 if painter_state.turn == ChessTypes.PieceColor.BLACK else 0)
	if chk_wk != null: chk_wk.button_pressed = painter_state.castling.get("wK", false)
	if chk_wq != null: chk_wq.button_pressed = painter_state.castling.get("wQ", false)
	if chk_bk != null: chk_bk.button_pressed = painter_state.castling.get("bK", false)
	if chk_bq != null: chk_bq.button_pressed = painter_state.castling.get("bQ", false)
	_refresh_pieces()

func _launch_game(mode: String) -> void:
	_ensure_nodes()
	# Update status rokade & giliran sebelum launch
	painter_state.turn = ChessTypes.PieceColor.BLACK if opt_turn.selected == 1 else ChessTypes.PieceColor.WHITE
	painter_state.castling["wK"] = chk_wk.button_pressed
	painter_state.castling["wQ"] = chk_wq.button_pressed
	painter_state.castling["bK"] = chk_bk.button_pressed
	painter_state.castling["bQ"] = chk_bq.button_pressed

	var chosen_side_str = "black" if painter_flipped else "white"
	var p_eng = GameSettings.get_player_engine_arrows()
	var o_eng = GameSettings.get_opponent_engine_arrows()
	var p_thr = GameSettings.get_player_threat_arrows()
	var o_thr = GameSettings.get_opponent_threat_arrows()
	GameSettings.set_chosen_side(chosen_side_str)
	GameSettings.set_player_engine_arrows(p_eng)
	GameSettings.set_opponent_engine_arrows(o_eng)
	GameSettings.set_player_threat_arrows(p_thr)
	GameSettings.set_opponent_threat_arrows(o_thr)
	GameSettings.save_settings()

	# Hak rokade yang tidak didukung bidak di papan harus dibuang. FEN "KQkq"
	# tanpa raja/benteng di petak awal membuat Stockfish menolak posisi tanpa
	# pesan apa pun (tidak ada `bestmove` sama sekali), sehingga bot tampak
	# menggantung sampai watchdog memainkan langkah darurat acak.
	PositionRules.sanitize_castling(painter_state)
	_sync_castling_checkboxes()

	# Posisi yang tetap tidak sah (raja kurang/ganda, pion di rank 1 atau 8,
	# lawan sudah skak, tidak ada langkah legal) ditolak di sini dengan alasan
	# yang bisa dibaca pemain, bukan dilempar ke engine.
	var problem := PositionRules.get_playability_error(painter_state)
	if not problem.is_empty():
		_set_status(problem)
		return

	_set_status("")
	play_position.emit(painter_state.to_fen(), mode)

## Pesan alasan posisi tidak bisa dimainkan (kosong = bersih).
func _set_status(message: String) -> void:
	if status_banner != null:
		status_banner.visible = not message.is_empty()
	if status_label != null:
		status_label.text = message
	if not message.is_empty():
		_play_illegal_sfx()

func _play_illegal_sfx() -> void:
	var tree = get_tree()
	if tree != null and tree.root != null and tree.root.has_node("AudioService"):
		var audio = tree.root.get_node("AudioService")
		if audio != null and audio.has_method("play_illegal"):
			audio.play_illegal()

## Hak rokade hanya ditawarkan bila raja dan benteng yang bersangkutan masih di
## petak awalnya. Checkbox yang mustahil dimatikan agar papan kosong tidak
## pernah menghasilkan FEN "KQkq" tanpa benteng.
func _sync_castling_checkboxes() -> void:
	_sync_castling_checkbox(chk_wk, PositionRules.RIGHT_KINGSIDE_WHITE)
	_sync_castling_checkbox(chk_wq, PositionRules.RIGHT_QUEENSIDE_WHITE)
	_sync_castling_checkbox(chk_bk, PositionRules.RIGHT_KINGSIDE_BLACK)
	_sync_castling_checkbox(chk_bq, PositionRules.RIGHT_QUEENSIDE_BLACK)

func _sync_castling_checkbox(chk: CheckBox, right: String) -> void:
	if chk == null:
		return
	var possible := PositionRules.castling_available(painter_state, right)
	if not possible:
		chk.button_pressed = false
	chk.disabled = not possible

var is_mouse_pressed: bool = false
var pressed_button_index: int = -1

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		is_mouse_pressed = false
		pressed_button_index = -1

func _get_square_from_position(pos: Vector2) -> String:
	var visual_f = int(pos.x / square_size)
	var visual_r = int(pos.y / square_size)
	if visual_f < 0 or visual_f > 7 or visual_r < 0 or visual_r > 7:
		return ""
	var f = (7 - visual_f) if painter_flipped else visual_f
	var r = visual_r if painter_flipped else (7 - visual_r)
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
	_ensure_nodes()
	for p in piece_views.values():
		p.queue_free()
	piece_views.clear()

	if painter_state == null or board_viewport == null:
		return

	for i in range(64):
		var p = painter_state.squares[i]
		if p != null:
			var sq_name = ChessTypes.index_to_square(i)
			var view = PieceView.new()
			view.setup(p["color"], p["type"], sq_name, GameSettings.piece_set, square_size)
			var coord = ChessTypes.square_to_coord(sq_name)
			var visual_f = (7 - coord.x) if painter_flipped else coord.x
			var visual_r = coord.y if painter_flipped else (7 - coord.y)
			view.position = Vector2(visual_f * square_size, visual_r * square_size)
			view.size = Vector2(square_size, square_size)
			view.custom_minimum_size = Vector2(square_size, square_size)
			board_viewport.add_child(view)
			piece_views[sq_name] = view

	# Setiap perubahan bidak bisa membatalkan/menghidupkan hak rokade dan
	# membatalkan pesan galat sebelumnya.
	_sync_castling_checkboxes()
	_set_status("")
