class_name TacticsTrainer
extends Control

const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const ChessTypes = preload("res://src/core/chess_types.gd")
const TacticsService = preload("res://src/core/tactics/tactics_service.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const CardPalette = preload("res://src/ui/card_palette.gd")
const CapturedPiecesView = preload("res://src/ui/hud/captured_pieces_view.gd")

const MAIN_MENU_SCENE = "res://src/ui/menu/main_menu.tscn"
const ICON_ROBOT = preload("res://assets/ui/icons/icon_robot.svg")
const ICON_PERSON = preload("res://assets/ui/icons/icon_person.svg")
const ICON_TARGET = preload("res://assets/ui/icons/icon_target.svg")
const ICON_CHECKMARK = preload("res://assets/ui/icons/icon_checkmark.svg")

# UI Nodes
@onready var btn_back: Button = $CenterContainer/MainLayout/TopBar/BtnBack
@onready var set_title_label: Label = $CenterContainer/MainLayout/TopBar/SetTitleLabel
@onready var btn_filter_side: Button = $CenterContainer/MainLayout/TopBar/BtnFilterSide

@onready var header_card: PanelContainer = $CenterContainer/MainLayout/HeaderCard
@onready var puzzle_title_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/PuzzleTitleLabel
@onready var puzzle_meta_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/PuzzleMetaLabel
@onready var stars_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/StarsChip/StarsLabel
@onready var puzzle_counter_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/CountChip/CounterLabel

@onready var top_player_card: PanelContainer = $CenterContainer/MainLayout/BoardArea/TopPlayerCard
@onready var top_avatar_icon: TextureRect = $CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/AvatarIcon
@onready var top_name_label: Label = $CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/NameLabel
@onready var top_badge_label: Label = $CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/BadgeLabel
@onready var top_captured_container: HBoxContainer = $CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/CapturedContainer

@onready var chess_board = $CenterContainer/MainLayout/BoardArea/BoardCenter/ChessBoard

@onready var bottom_player_card: PanelContainer = $CenterContainer/MainLayout/BoardArea/BottomPlayerCard
@onready var bottom_avatar_icon: TextureRect = $CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/AvatarIcon
@onready var bottom_name_label: Label = $CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/NameLabel
@onready var bottom_badge_label: Label = $CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/BadgeLabel
@onready var bottom_captured_container: HBoxContainer = $CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/CapturedContainer

@onready var coach_card: PanelContainer = $CenterContainer/MainLayout/CoachCard
@onready var coach_avatar: TextureRect = $CenterContainer/MainLayout/CoachCard/VBox/StatusRow/Avatar
@onready var status_label: Label = $CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StatusLabel
@onready var step_badge_label: Label = $CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StepBadgeLabel
@onready var blurb_label: Label = $CenterContainer/MainLayout/CoachCard/VBox/BlurbLabel

@onready var btn_prev_move: Button = $CenterContainer/MainLayout/ControlsBar/BtnPrevMove
@onready var btn_next_move: Button = $CenterContainer/MainLayout/ControlsBar/BtnNextMove
@onready var btn_hint: Button = $CenterContainer/MainLayout/ControlsBar/BtnHint
@onready var btn_retry: Button = $CenterContainer/MainLayout/ControlsBar/BtnRetry
@onready var btn_prev_puzzle: Button = $CenterContainer/MainLayout/ControlsBar/BtnPrevPuzzle
@onready var btn_next_puzzle: Button = $CenterContainer/MainLayout/ControlsBar/BtnNextPuzzle

# State variables
var current_set_id: String = "checkmate_patterns"
var active_side_filter: String = "" # "" | "white" | "black"
var active_puzzles: Array[Dictionary] = []
var current_puzzle_index: int = 0
var current_puzzle: Dictionary = {}
var current_run_id: int = 0

var move_history: Array[Dictionary] = []
var history_view_index: int = 0
var max_reached_index: int = 0

var board_state: ChessBoardState = null
var is_flipped: bool = false
var current_step_index: int = 0

var hint_used_on_puzzle: bool = false
var hints_used_count: int = 0
var mistakes_on_puzzle: int = 0
var is_waiting_opponent: bool = false
var is_puzzle_completed: bool = false

var top_card_style: StyleBoxFlat = null
var bottom_card_style: StyleBoxFlat = null
var coach_card_style: StyleBoxFlat = null
var _last_top_captured_key: String = ""
var _last_bottom_captured_key: String = ""

func _ready() -> void:
	_ensure_nodes()
	_init_card_styles()
	_apply_tactile_styles()
	_connect_signals()
	
	var target_puzzle_id: String = ""
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameSettings")
		if gs:
			if "selected_tactics_set_id" in gs and not str(gs.selected_tactics_set_id).is_empty():
				current_set_id = str(gs.selected_tactics_set_id)
			if "selected_tactics_puzzle_id" in gs and not str(gs.selected_tactics_puzzle_id).is_empty():
				target_puzzle_id = str(gs.selected_tactics_puzzle_id)
	
	load_tactics_set(current_set_id, target_puzzle_id)

func _ensure_nodes() -> void:
	if btn_back == null:
		btn_back = get_node_or_null("CenterContainer/MainLayout/TopBar/BtnBack")
	if set_title_label == null:
		set_title_label = get_node_or_null("CenterContainer/MainLayout/TopBar/SetTitleLabel")
	if btn_filter_side == null:
		btn_filter_side = get_node_or_null("CenterContainer/MainLayout/TopBar/BtnFilterSide")
	if header_card == null:
		header_card = get_node_or_null("CenterContainer/MainLayout/HeaderCard")
	if puzzle_title_label == null:
		puzzle_title_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/PuzzleTitleLabel")
	if puzzle_meta_label == null:
		puzzle_meta_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/PuzzleMetaLabel")
	if stars_label == null:
		stars_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/StarsChip/StarsLabel")
	if puzzle_counter_label == null:
		puzzle_counter_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/CountChip/CounterLabel")

	if top_player_card == null:
		top_player_card = get_node_or_null("CenterContainer/MainLayout/BoardArea/TopPlayerCard")
	if top_avatar_icon == null:
		top_avatar_icon = get_node_or_null("CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/AvatarIcon")
	if top_name_label == null:
		top_name_label = get_node_or_null("CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/NameLabel")
	if top_badge_label == null:
		top_badge_label = get_node_or_null("CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/BadgeLabel")
	if top_captured_container == null:
		top_captured_container = get_node_or_null("CenterContainer/MainLayout/BoardArea/TopPlayerCard/HBox/CapturedContainer")

	if chess_board == null:
		chess_board = get_node_or_null("CenterContainer/MainLayout/BoardArea/BoardCenter/ChessBoard")

	if bottom_player_card == null:
		bottom_player_card = get_node_or_null("CenterContainer/MainLayout/BoardArea/BottomPlayerCard")
	if bottom_avatar_icon == null:
		bottom_avatar_icon = get_node_or_null("CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/AvatarIcon")
	if bottom_name_label == null:
		bottom_name_label = get_node_or_null("CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/NameLabel")
	if bottom_badge_label == null:
		bottom_badge_label = get_node_or_null("CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/BadgeLabel")
	if bottom_captured_container == null:
		bottom_captured_container = get_node_or_null("CenterContainer/MainLayout/BoardArea/BottomPlayerCard/HBox/CapturedContainer")

	if coach_card == null:
		coach_card = get_node_or_null("CenterContainer/MainLayout/CoachCard")
	if coach_avatar == null:
		coach_avatar = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusRow/Avatar")
	if status_label == null:
		status_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StatusLabel")
	if step_badge_label == null:
		step_badge_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StepBadgeLabel")
	if blurb_label == null:
		blurb_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/BlurbLabel")

	if btn_prev_move == null:
		btn_prev_move = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnPrevMove")
	if btn_prev_move == null:
		btn_prev_move = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnPrevMove")
	if btn_next_move == null:
		btn_next_move = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnNextMove")
	if btn_next_move == null:
		btn_next_move = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnNextMove")
	if btn_hint == null:
		btn_hint = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnHint")
	if btn_retry == null:
		btn_retry = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnRetry")
	if btn_prev_puzzle == null:
		btn_prev_puzzle = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnPrevPuzzle")
	if btn_next_puzzle == null:
		btn_next_puzzle = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnNextPuzzle")

func _init_card_styles() -> void:
	if top_player_card:
		var sb_top = top_player_card.get_theme_stylebox("panel")
		top_card_style = (sb_top.duplicate() if sb_top is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		top_player_card.add_theme_stylebox_override("panel", top_card_style)
	if bottom_player_card:
		var sb_bot = bottom_player_card.get_theme_stylebox("panel")
		bottom_card_style = (sb_bot.duplicate() if sb_bot is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		bottom_player_card.add_theme_stylebox_override("panel", bottom_card_style)
	if coach_card:
		var sb_coach = coach_card.get_theme_stylebox("panel")
		coach_card_style = (sb_coach.duplicate() if sb_coach is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		coach_card.add_theme_stylebox_override("panel", coach_card_style)

	for icon_node in [top_avatar_icon, bottom_avatar_icon, coach_avatar]:
		if icon_node != null:
			icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _apply_tactile_styles() -> void:
	if btn_back:
		TactileStyles.apply_tactile_button(btn_back, false, false, true)
	if btn_filter_side:
		TactileStyles.apply_tactile_button(btn_filter_side, false, false, false)
	if btn_prev_move:
		TactileStyles.apply_tactile_button(btn_prev_move, false, false, false)
		btn_prev_move.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.45))
	if btn_next_move:
		TactileStyles.apply_tactile_button(btn_next_move, false, false, false)
		btn_next_move.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.45))
	if btn_hint:
		TactileStyles.apply_tactile_button(btn_hint, false, hint_used_on_puzzle, false)
	if btn_retry:
		TactileStyles.apply_tactile_button(btn_retry, false, false, false)
	if btn_prev_puzzle:
		TactileStyles.apply_tactile_button(btn_prev_puzzle, false, false, false)
	if btn_next_puzzle:
		TactileStyles.apply_tactile_button(btn_next_puzzle, true, false, false)

func _connect_signals() -> void:
	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if btn_filter_side and not btn_filter_side.pressed.is_connected(_on_filter_side_pressed):
		btn_filter_side.pressed.connect(_on_filter_side_pressed)
	if btn_prev_move and not btn_prev_move.pressed.is_connected(_on_prev_move_pressed):
		btn_prev_move.pressed.connect(_on_prev_move_pressed)
	if btn_next_move and not btn_next_move.pressed.is_connected(_on_next_move_pressed):
		btn_next_move.pressed.connect(_on_next_move_pressed)
	if btn_hint and not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if btn_retry and not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)
	if btn_prev_puzzle and not btn_prev_puzzle.pressed.is_connected(_on_prev_puzzle_pressed):
		btn_prev_puzzle.pressed.connect(_on_prev_puzzle_pressed)
	if btn_next_puzzle and not btn_next_puzzle.pressed.is_connected(_on_next_puzzle_pressed):
		btn_next_puzzle.pressed.connect(_on_next_puzzle_pressed)
	if chess_board and not chess_board.move_made.is_connected(_on_board_move_made):
		chess_board.move_made.connect(_on_board_move_made)

	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameSettings")
		if gs:
			if gs.has_signal("settings_changed") and not gs.settings_changed.is_connected(_on_settings_changed):
				gs.settings_changed.connect(_on_settings_changed)
			if gs.has_signal("piece_set_changed") and not gs.piece_set_changed.is_connected(_on_piece_set_changed):
				gs.piece_set_changed.connect(_on_piece_set_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.is_command_or_control_pressed():
			if event.keycode == KEY_Z and not event.shift_pressed:
				if btn_prev_move and not btn_prev_move.disabled:
					_on_prev_move_pressed()
				if get_viewport():
					get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_Y or (event.keycode == KEY_Z and event.shift_pressed):
				if btn_next_move and not btn_next_move.disabled:
					_on_next_move_pressed()
				if get_viewport():
					get_viewport().set_input_as_handled()
				return
		elif event.keycode == KEY_LEFT:
			if btn_prev_move and not btn_prev_move.disabled:
				_on_prev_move_pressed()
			if get_viewport():
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_RIGHT:
			if btn_next_move and not btn_next_move.disabled:
				_on_next_move_pressed()
			if get_viewport():
				get_viewport().set_input_as_handled()

func _on_piece_set_changed(_p: String) -> void:
	_on_settings_changed()

func _on_settings_changed() -> void:
	CapturedPiecesView.clear_texture_cache()
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	if chess_board and board_state:
		var prev_last_move = chess_board.last_move.duplicate()
		var state_to_use = board_state if (history_view_index == max_reached_index or move_history.is_empty()) else move_history[history_view_index].state
		chess_board.setup_board(state_to_use, is_flipped)
		if not prev_last_move.is_empty():
			chess_board.set_last_move(prev_last_move.get("from", ""), prev_last_move.get("to", ""))
	_update_player_cards()

func load_tactics_set(set_id: String, target_puzzle_id: String = "") -> void:
	current_set_id = set_id
	var set_data = TacticsService.load_set(set_id)
	if set_title_label:
		set_title_label.text = set_data.get("title", "Tactics Trainer")
	_refresh_puzzles_list(target_puzzle_id)

func _refresh_puzzles_list(target_puzzle_id: String = "") -> void:
	active_puzzles = TacticsService.get_puzzles(current_set_id, active_side_filter)
	if active_puzzles.is_empty():
		active_puzzles = TacticsService.get_puzzles(current_set_id, "")
		active_side_filter = ""

	_update_filter_button_label()
	current_puzzle_index = 0
	if not target_puzzle_id.is_empty():
		for i in range(active_puzzles.size()):
			if active_puzzles[i].get("id", "") == target_puzzle_id:
				current_puzzle_index = i
				break

	_load_current_puzzle()

func _update_filter_button_label() -> void:
	if not btn_filter_side:
		return
	match active_side_filter:
		"white":
			btn_filter_side.text = "Side: White"
		"black":
			btn_filter_side.text = "Side: Black"
		_:
			btn_filter_side.text = "Side: All"

func _on_filter_side_pressed() -> void:
	match active_side_filter:
		"":
			active_side_filter = "white"
		"white":
			active_side_filter = "black"
		"black":
			active_side_filter = ""
	_refresh_puzzles_list()

func _load_current_puzzle() -> void:
	if active_puzzles.is_empty():
		return
	current_run_id += 1
	current_puzzle_index = posmod(current_puzzle_index, active_puzzles.size())
	current_puzzle = active_puzzles[current_puzzle_index]
	
	current_step_index = 0
	hint_used_on_puzzle = false
	hints_used_count = 0
	mistakes_on_puzzle = 0
	is_waiting_opponent = false
	is_puzzle_completed = false
	
	var fen: String = current_puzzle.get("fen", "")
	var side_str: String = current_puzzle.get("side", "white").to_lower()
	is_flipped = (side_str == "black")
	
	board_state = ChessBoardState.new(fen)
	move_history.clear()
	move_history.append({
		"state": board_state.clone(),
		"from_sq": "",
		"to_sq": "",
		"san": "",
		"blurb": "",
		"is_cap": false,
		"is_castle": false,
		"is_ep": false,
		"promo": ChessTypes.PieceType.NONE
	})
	history_view_index = 0
	max_reached_index = 0
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	
	if chess_board:
		chess_board.setup_board(board_state, is_flipped)
		chess_board.clear_last_move()
		chess_board.clear_review_badge()
		_clear_arrows()
		chess_board.is_interactive = true

	_update_nav_buttons()

	if btn_prev_puzzle:
		btn_prev_puzzle.disabled = (active_puzzles.size() <= 1)
		TactileStyles.apply_tactile_button(btn_prev_puzzle, false, false, false)
	if btn_next_puzzle:
		btn_next_puzzle.disabled = (active_puzzles.size() <= 1)
		TactileStyles.apply_tactile_button(btn_next_puzzle, true, false, false)

	_update_puzzle_header()
	_update_player_cards()
	_setup_player_turn()

func _update_puzzle_header() -> void:
	if puzzle_title_label:
		puzzle_title_label.text = current_puzzle.get("title", "Puzzle")
	if puzzle_meta_label:
		var theme = current_puzzle.get("theme", "").replace("_", " ").capitalize()
		var side = "White to Move" if current_puzzle.get("side", "") == "white" else "Black to Move"
		puzzle_meta_label.text = "%s  •  %s" % [theme, side]
	
	if puzzle_counter_label:
		puzzle_counter_label.text = "Puzzle %d/%d" % [current_puzzle_index + 1, active_puzzles.size()]
	
	if stars_label:
		var pid = current_puzzle.get("id", "")
		var prog = TacticsService.get_puzzle_progress(pid)
		var stars = int(prog.get("stars", 0))
		if stars == 3:
			stars_label.text = "[***] Solved"
		elif stars == 2:
			stars_label.text = "[** ] Solved"
		elif stars == 1:
			stars_label.text = "[*  ] Solved"
		else:
			stars_label.text = "New"

func _set_coach_card_accent(state: String) -> void:
	if coach_card_style == null:
		return
	match state:
		"correct":
			coach_card_style.border_color = Color(0.506, 0.714, 0.298, 0.85)
			if coach_avatar:
				coach_avatar.texture = ICON_CHECKMARK
		"incorrect":
			coach_card_style.border_color = Color(0.85, 0.35, 0.30, 0.85)
			if coach_avatar:
				coach_avatar.texture = ICON_TARGET
		_:
			coach_card_style.border_color = Color(0.28, 0.27, 0.25, 0.85)
			if coach_avatar:
				coach_avatar.texture = ICON_TARGET

func _clear_arrows() -> void:
	if chess_board:
		var empty_a: Array[Dictionary] = []
		var empty_b: Array[Dictionary] = []
		chess_board.update_arrows(empty_a, empty_b)

func _setup_player_turn() -> void:
	is_waiting_opponent = false
	if is_puzzle_completed:
		if chess_board:
			chess_board.is_interactive = false
		return

	if chess_board:
		chess_board.is_interactive = true

	_set_coach_card_accent("neutral")
	var side_str = "White" if current_puzzle.get("side", "") == "white" else "Black"
	
	if status_label:
		var moves: Array = current_puzzle.get("moves", [])
		var total_moves = (moves.size() + 1) / 2
		var current_turn = (current_step_index / 2) + 1
		if total_moves > 1:
			status_label.text = "Giliran Anda (%s): Temukan langkah %d/%d" % [side_str, current_turn, total_moves]
		else:
			status_label.text = "Giliran Anda (%s): Temukan langkah taktik terbaik!" % side_str
		status_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1))

	if blurb_label:
		blurb_label.text = current_puzzle.get("blurb", "")

	if step_badge_label:
		step_badge_label.text = "Difficulty %d" % int(current_puzzle.get("difficulty", 1))

	if btn_hint:
		btn_hint.disabled = false
		TactileStyles.apply_tactile_button(btn_hint, false, false, false)
	if btn_retry:
		btn_retry.disabled = (current_step_index == 0 and mistakes_on_puzzle == 0)

func _extract_move_info(move: Variant) -> Dictionary:
	if move is ChessMove:
		return {
			"from": move.from_sq,
			"to": move.to_sq,
			"promo": move.promotion,
			"is_castle": move.is_castling,
			"is_ep": move.is_en_passant
		}
	elif move is Dictionary:
		var d = move as Dictionary
		return {
			"from": d.get("from", d.get("from_sq", "")),
			"to": d.get("to", d.get("to_sq", "")),
			"promo": d.get("promotion", ChessTypes.PieceType.NONE),
			"is_castle": d.get("is_castling", false),
			"is_ep": d.get("is_en_passant", false)
		}
	return {"from": "", "to": "", "promo": ChessTypes.PieceType.NONE, "is_castle": false, "is_ep": false}

func _on_board_move_made(move: Variant) -> void:
	if is_waiting_opponent or is_puzzle_completed:
		return
	if history_view_index < max_reached_index:
		return
	
	var info = _extract_move_info(move)
	var played_uci = info["from"] + info["to"]
	if info["promo"] != ChessTypes.PieceType.NONE:
		played_uci += ChessTypes.piece_type_to_san_char(info["promo"]).to_lower()

	var val_result = TacticsService.validate_player_move(current_puzzle, current_step_index, played_uci)
	
	if val_result.get("is_correct", false):
		_handle_correct_player_move(val_result, move)
	else:
		_handle_incorrect_player_move(move)

func _handle_correct_player_move(val_result: Dictionary, move: Variant) -> void:
	var info = _extract_move_info(move)
	var to_sq = info["to"]
	var is_ep = info["is_ep"]
	var is_castle = info["is_castle"]
	var promo = info["promo"]
	var is_promo = promo != ChessTypes.PieceType.NONE

	var next_state = board_state.clone()
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	ChessMoveGenerator.apply_move_unchecked(next_state, move)

	var p_san = ChessSAN.move_to_san(board_state, move) if move is ChessMove else ""
	move_history.append({
		"state": next_state.clone(),
		"from_sq": info["from"],
		"to_sq": info["to"],
		"san": p_san,
		"blurb": "",
		"is_cap": is_cap,
		"is_castle": is_castle,
		"is_ep": is_ep,
		"promo": promo
	})
	max_reached_index = move_history.size() - 1
	history_view_index = max_reached_index
	_update_nav_buttons()

	if chess_board:
		_clear_arrows()
		chess_board.animate_move(
			move,
			next_state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			Callable(self, "_on_player_move_animation_done").bind(val_result, next_state),
			func(): _play_move_sfx(next_state, is_cap, is_castle, is_promo)
		)
	else:
		_play_move_sfx(next_state, is_cap, is_castle, is_promo)
		_on_player_move_animation_done(val_result, next_state)

func _on_player_move_animation_done(val_result: Dictionary, next_state: ChessBoardState) -> void:
	board_state = next_state
	_update_player_cards()

	var is_final = val_result.get("is_final_step", false)
	if is_final:
		_on_puzzle_completed(next_state)
		if chess_board:
			chess_board.is_interactive = false
	else:
		var next_opp_uci = val_result.get("next_opponent_uci", "")
		if not next_opp_uci.is_empty():
			_execute_opponent_step(next_opp_uci)

func _execute_opponent_step(opp_uci: String) -> void:
	is_waiting_opponent = true
	_update_nav_buttons()
	if chess_board:
		chess_board.is_interactive = false
	
	var run_id = current_run_id
	current_step_index += 1
	var opp_move = ChessSAN.uci_to_move(board_state, opp_uci)
	if opp_move == null or opp_move.is_empty():
		push_warning("TacticsTrainer: Could not parse opponent move '%s' for FEN '%s'" % [opp_uci, board_state.to_fen()])
		is_waiting_opponent = false
		if chess_board:
			chess_board.is_interactive = true
		return

	if not is_inside_tree() or not get_tree():
		return
	await get_tree().create_timer(0.2, false).timeout
	if not is_inside_tree() or not is_instance_valid(self) or current_run_id != run_id:
		return

	var next_state = board_state.clone()
	var to_sq = opp_move.to_sq
	var is_ep = opp_move.is_en_passant
	var is_castle = opp_move.is_castling
	var promo = opp_move.promotion
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	var is_promo = promo != ChessTypes.PieceType.NONE
	ChessMoveGenerator.apply_move_unchecked(next_state, opp_move)

	var o_san = ChessSAN.move_to_san(board_state, opp_move)
	move_history.append({
		"state": next_state.clone(),
		"from_sq": opp_move.from_sq,
		"to_sq": opp_move.to_sq,
		"san": o_san,
		"blurb": "",
		"is_cap": is_cap,
		"is_castle": is_castle,
		"is_ep": is_ep,
		"promo": promo
	})
	max_reached_index = move_history.size() - 1
	history_view_index = max_reached_index
	_update_nav_buttons()

	if chess_board:
		chess_board.animate_move(
			opp_move,
			next_state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			Callable(self, "_on_opponent_move_done").bind(opp_uci, next_state),
			func(): _play_move_sfx(next_state, is_cap, is_castle, is_promo)
		)
	else:
		_on_opponent_move_done(opp_uci, next_state)

func _on_opponent_move_done(opp_uci: String, next_state: ChessBoardState) -> void:
	board_state = next_state
	_update_player_cards()
	if chess_board:
		chess_board.set_last_move(opp_uci.substr(0, 2), opp_uci.substr(2, 2))
	current_step_index += 1
	_setup_player_turn()

func _handle_incorrect_player_move(move: Variant) -> void:
	mistakes_on_puzzle += 1
	_set_coach_card_accent("incorrect")
	_play_sfx("play_illegal")
	
	if status_label:
		status_label.text = "Langkah salah (Incorrect)! Coba cari langkah lain, atau tekan Hint."
		status_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.4, 1))

	if btn_retry:
		btn_retry.disabled = false

	# Reset board visually back to current state
	if chess_board:
		chess_board.setup_board(board_state, is_flipped)
		chess_board.is_interactive = true

func _on_puzzle_completed(final_state: ChessBoardState = null) -> void:
	is_puzzle_completed = true
	if chess_board:
		chess_board.is_interactive = false
	
	_set_coach_card_accent("correct")
	var pid = current_puzzle.get("id", "")
	var stars = TacticsService.record_puzzle_completion(pid, mistakes_on_puzzle, hints_used_count)

	var st = final_state if final_state != null else board_state
	var cat = current_puzzle.get("category", "")
	var is_mate = st != null and ChessMoveGenerator.is_checkmate(st)
	if status_label:
		if is_mate or cat == "checkmate":
			status_label.text = "Checkmate! Pola skakmat berhasil dieksekusi dengan sempurna."
		else:
			status_label.text = "Correct! Taktik berhasil diselesaikan."
		status_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.35, 1))

	if blurb_label:
		var tip = current_puzzle.get("tip", "")
		blurb_label.text = "Tip Coach: " + tip

	if step_badge_label:
		step_badge_label.text = "Earned %d Stars!" % stars

	_update_puzzle_header()
	if btn_hint:
		btn_hint.disabled = true
	if btn_retry:
		btn_retry.disabled = false
	if btn_next_puzzle:
		btn_next_puzzle.disabled = false

	_update_nav_buttons()

	if is_mate:
		_play_sfx("play_checkmate")
		if chess_board and st != null:
			chess_board.topple_king(st.turn)

func _on_hint_pressed() -> void:
	if is_puzzle_completed or is_waiting_opponent:
		return
	hint_used_on_puzzle = true
	hints_used_count += 1
	TactileStyles.apply_tactile_button(btn_hint, false, true, false)

	var hint = TacticsService.get_hint(current_puzzle, current_step_index)
	var from_sq = hint.get("from", "")
	var to_sq = hint.get("to", "")
	if not from_sq.is_empty() and not to_sq.is_empty() and chess_board:
		var green_arrow: Dictionary = {
			"from": from_sq,
			"to": to_sq,
			"type": "best",
			"color": Color(0.506, 0.714, 0.298, 0.9)
		}
		var empty_arrows: Array[Dictionary] = []
		chess_board.update_arrows([green_arrow], empty_arrows)
	
	if blurb_label:
		blurb_label.text = "Hint: Gerakkan bidak dari petak %s ke petak %s." % [from_sq.to_upper(), to_sq.to_upper()]

func _on_retry_pressed() -> void:
	_load_current_puzzle()

func _on_prev_puzzle_pressed() -> void:
	current_puzzle_index -= 1
	_load_current_puzzle()

func _on_next_puzzle_pressed() -> void:
	current_puzzle_index += 1
	_load_current_puzzle()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_prev_move_pressed() -> void:
	if is_waiting_opponent or history_view_index <= 0:
		return
	var from_idx = history_view_index
	history_view_index -= 1
	var to_idx = history_view_index

	var move_entry = move_history[from_idx]
	var target_entry = move_history[to_idx]

	_update_nav_buttons()
	_update_history_labels(to_idx)

	if chess_board:
		chess_board.is_interactive = false
		var undo_info = {
			"from_sq": move_entry.get("from_sq", ""),
			"to_sq": move_entry.get("to_sq", ""),
			"is_castle": move_entry.get("is_castle", false),
			"is_ep": move_entry.get("is_ep", false),
			"promo": move_entry.get("promo", ChessTypes.PieceType.NONE)
		}
		_play_sfx("play_move")
		chess_board.animate_undo_move(undo_info, target_entry.state, func():
			_finalize_history_position(to_idx)
		)
	else:
		_finalize_history_position(to_idx)

func _on_next_move_pressed() -> void:
	if is_waiting_opponent or history_view_index >= max_reached_index:
		return
	history_view_index = mini(history_view_index + 1, max_reached_index)
	var to_idx = history_view_index

	var redo_entry = move_history[to_idx]

	_update_nav_buttons()
	_update_history_labels(to_idx)

	if chess_board:
		chess_board.is_interactive = false
		var redo_move_info = {
			"from": redo_entry.get("from_sq", ""),
			"to": redo_entry.get("to_sq", "")
		}
		var is_cap = redo_entry.get("is_cap", false)
		var is_castle = redo_entry.get("is_castle", false)
		var is_ep = redo_entry.get("is_ep", false)
		var promo = redo_entry.get("promo", ChessTypes.PieceType.NONE)
		var is_promo = promo != ChessTypes.PieceType.NONE

		chess_board.animate_move(
			redo_move_info,
			redo_entry.state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			func():
				_finalize_history_position(to_idx),
			func():
				_play_move_sfx(redo_entry.state, is_cap, is_castle, is_promo)
		)
	else:
		_finalize_history_position(to_idx)

func _update_nav_buttons() -> void:
	if btn_prev_move:
		btn_prev_move.disabled = (history_view_index <= 0 or is_waiting_opponent)
	if btn_next_move:
		btn_next_move.disabled = (history_view_index >= max_reached_index or is_waiting_opponent)

	var is_at_latest = (history_view_index == max_reached_index)
	if not is_at_latest:
		if btn_hint:
			btn_hint.disabled = true
		if btn_retry:
			btn_retry.disabled = true
	else:
		if btn_hint:
			btn_hint.disabled = is_puzzle_completed or is_waiting_opponent
		if btn_retry:
			btn_retry.disabled = is_waiting_opponent or (current_step_index == 0 and mistakes_on_puzzle == 0 and not is_puzzle_completed)

func _show_history_position(idx: int) -> void:
	_finalize_history_position(idx)
	_update_history_labels(idx)

func _finalize_history_position(idx: int) -> void:
	if idx < 0 or idx >= move_history.size():
		return
	var entry = move_history[idx]
	var is_at_latest = (idx == max_reached_index)

	if chess_board:
		chess_board.setup_board(entry.state, is_flipped)
		var f_sq = str(entry.get("from_sq", ""))
		var t_sq = str(entry.get("to_sq", ""))
		if not f_sq.is_empty() and not t_sq.is_empty():
			chess_board.set_last_move(f_sq, t_sq)
		else:
			chess_board.clear_last_move()
		_clear_arrows()
		chess_board.is_interactive = is_at_latest and not is_waiting_opponent and not is_puzzle_completed

	_update_player_cards()

	if is_at_latest:
		if is_puzzle_completed:
			_on_puzzle_completed(entry.state)
		else:
			_setup_player_turn()

func _update_history_labels(idx: int) -> void:
	if idx < 0 or idx >= move_history.size():
		return
	var entry = move_history[idx]
	var is_at_latest = (idx == max_reached_index)

	if is_at_latest:
		if not is_puzzle_completed:
			_set_coach_card_accent("neutral")
	else:
		_set_coach_card_accent("neutral")
		if status_label:
			if not str(entry.get("san", "")).is_empty():
				status_label.text = "Langkah: %s" % str(entry.get("san", ""))
			else:
				status_label.text = "Posisi Awal Puzzle"
			status_label.add_theme_color_override("font_color", Color(0.74, 0.72, 0.69, 1))

		if blurb_label:
			if idx == 0:
				blurb_label.text = current_puzzle.get("blurb", "")
			else:
				blurb_label.text = "Posisi setelah langkah %s." % str(entry.get("san", ""))

	_update_nav_buttons()

	_update_nav_buttons()

# ==============================================================================
# AUDIO & PLAYER CARDS
# ==============================================================================

func _play_sfx(method_name: String) -> void:
	if not is_inside_tree():
		return
	var t = get_tree()
	if not t or not t.root:
		return
	var gs = t.root.get_node_or_null("GameSettings")
	if gs and not gs.sound_enabled:
		return
	var audio = t.root.get_node_or_null("AudioService")
	if audio and audio.has_method(method_name):
		audio.call(method_name)

func _play_move_sfx(state: ChessBoardState, is_cap: bool, is_castle: bool, is_promo: bool) -> void:
	if state != null and ChessMoveGenerator.is_in_check(state, state.turn):
		_play_sfx("play_check")
	elif is_castle:
		_play_sfx("play_castle")
	elif is_promo:
		_play_sfx("play_promote")
	elif is_cap:
		_play_sfx("play_capture")
	else:
		_play_sfx("play_move")

func _get_active_piece_set() -> String:
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameSettings")
		if gs and not str(gs.piece_set).is_empty():
			return str(gs.piece_set)
	return "cburnett"

func _apply_card_palette(is_top: bool, is_white_card: bool) -> void:
	var bg = CardPalette.card_bg(is_white_card)
	var border = CardPalette.card_border(bg)
	var style = top_card_style if is_top else bottom_card_style
	if style != null:
		style.bg_color = bg
		style.border_color = border

	var name_label = top_name_label if is_top else bottom_name_label
	var badge_label = top_badge_label if is_top else bottom_badge_label
	var avatar = top_avatar_icon if is_top else bottom_avatar_icon

	if name_label != null:
		name_label.add_theme_color_override("font_color", CardPalette.ink(bg))
	if badge_label != null:
		badge_label.add_theme_color_override("font_color", CardPalette.muted_ink(bg))
	if avatar != null:
		avatar.modulate = CardPalette.icon_tint(bg)

func _clear_captured_section(container: HBoxContainer, is_top: bool) -> void:
	if is_top:
		_last_top_captured_key = ""
	else:
		_last_bottom_captured_key = ""
	if container == null or not is_instance_valid(container):
		return
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	container.visible = false

func _ensure_captured_view(container: HBoxContainer) -> CapturedPiecesView:
	if container == null or not is_instance_valid(container):
		return null
	for child in container.get_children():
		if child is CapturedPiecesView:
			return child
	var view := CapturedPiecesView.new()
	view.name = "CapturedPiecesView"
	container.add_child(view)
	view.custom_minimum_size = view.custom_minimum_size
	view.size = view.custom_minimum_size
	return view

func _render_captured_section(container: HBoxContainer, captured_pieces: Array, piece_color: int, point_advantage: int, is_top: bool, card_bg: Color) -> void:
	if container == null or not is_instance_valid(container):
		return

	var piece_set = _get_active_piece_set()
	var cache_key = "%s_%d_%d_%s_%s" % [str(captured_pieces), piece_color, point_advantage, piece_set, str(card_bg)]
	var last_key = _last_top_captured_key if is_top else _last_bottom_captured_key
	if cache_key == last_key and container.get_child_count() > 0:
		return
	if is_top:
		_last_top_captured_key = cache_key
	else:
		_last_bottom_captured_key = cache_key

	for child in container.get_children():
		if not (child is CapturedPiecesView):
			container.remove_child(child)
			child.queue_free()

	if captured_pieces.is_empty() and point_advantage <= 0:
		container.visible = false
		return

	var view = _ensure_captured_view(container)
	if view == null:
		container.visible = false
		return

	container.visible = true
	container.add_theme_constant_override("separation", 0)
	view.set_captures(captured_pieces, piece_color, point_advantage, piece_set, card_bg)
	view.size = view.custom_minimum_size

func _update_player_cards() -> void:
	var top_is_white = is_flipped
	var bottom_is_white = not is_flipped

	_apply_card_palette(true, top_is_white)
	_apply_card_palette(false, bottom_is_white)

	if top_name_label:
		top_name_label.text = "Opponent"
	if bottom_name_label:
		bottom_name_label.text = "You"

	if top_badge_label:
		top_badge_label.text = "White" if top_is_white else "Black"
	if bottom_badge_label:
		bottom_badge_label.text = "White" if bottom_is_white else "Black"

	if top_avatar_icon:
		top_avatar_icon.texture = ICON_ROBOT
	if bottom_avatar_icon:
		bottom_avatar_icon.texture = ICON_PERSON

	var active_state = board_state if (history_view_index == max_reached_index or move_history.is_empty()) else move_history[history_view_index].state
	if active_state != null:
		var mat_data = ChessBoardState.calculate_material_and_captured(active_state)
		var white_adv = int(mat_data.get("white_advantage", 0))
		var black_cap = mat_data.get("black_captured", [])
		var white_cap = mat_data.get("white_captured", [])

		if top_is_white:
			_render_captured_section(top_captured_container, black_cap, ChessTypes.PieceColor.BLACK, white_adv, true, CardPalette.card_bg(true))
			_render_captured_section(bottom_captured_container, white_cap, ChessTypes.PieceColor.WHITE, -white_adv, false, CardPalette.card_bg(false))
		else:
			_render_captured_section(top_captured_container, white_cap, ChessTypes.PieceColor.WHITE, -white_adv, true, CardPalette.card_bg(false))
			_render_captured_section(bottom_captured_container, black_cap, ChessTypes.PieceColor.BLACK, white_adv, false, CardPalette.card_bg(true))
	else:
		_clear_captured_section(top_captured_container, true)
		_clear_captured_section(bottom_captured_container, false)
