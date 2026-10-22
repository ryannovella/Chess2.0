class_name OpeningTrainer
extends Control

const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const ChessTypes = preload("res://src/core/chess_types.gd")
const RepertoireService = preload("res://src/core/repertoire/repertoire_service.gd")
const RepertoireTree = preload("res://src/core/repertoire/repertoire_tree.gd")
const RepertoireNode = preload("res://src/core/repertoire/repertoire_node.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const CardPalette = preload("res://src/ui/card_palette.gd")
const GameSettings = preload("res://src/config/game_settings.gd")

const MAIN_MENU_SCENE = "res://src/ui/menu/main_menu.tscn"

# UI Nodes
@onready var btn_back: Button = $CenterContainer/MainLayout/TopBar/BtnBack
@onready var opt_repertoire: OptionButton = $CenterContainer/MainLayout/TopBar/OptRepertoire
@onready var header_card: PanelContainer = $CenterContainer/MainLayout/HeaderCard
@onready var repertoire_title_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/RepertoireTitleLabel
@onready var repertoire_meta_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/RepertoireMetaLabel
@onready var mastery_progress_bar: ProgressBar = $CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryProgressBar
@onready var mastery_percent_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryPercentLabel
@onready var due_badge_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/DueBadgeLabel
@onready var mode_badge_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/ModeBadgeLabel

@onready var chess_board = $CenterContainer/MainLayout/BoardCenter/ChessBoard

@onready var coach_card: PanelContainer = $CenterContainer/MainLayout/CoachCard
@onready var status_label: Label = $CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StatusLabel
@onready var blurb_label: Label = $CenterContainer/MainLayout/CoachCard/VBox/BlurbLabel

@onready var btn_hint: Button = $CenterContainer/MainLayout/ControlsBar/BtnHint
@onready var btn_retry: Button = $CenterContainer/MainLayout/ControlsBar/BtnRetry
@onready var btn_next_line: Button = $CenterContainer/MainLayout/ControlsBar/BtnNextLine
@onready var btn_mode_toggle: Button = $CenterContainer/MainLayout/ControlsBar/BtnModeToggle

# State variables
var current_tree: RepertoireTree = null
var current_rep_id: String = "fried_liver_attack"
var board_state: ChessBoardState = null
var is_flipped: bool = false

var active_line: Array = []
var active_line_index: int = 0
var current_node_index: int = 0

var is_drill_mode: bool = false
var hint_used_on_step: bool = false
var mistakes_on_step: int = 0
var is_waiting_opponent: bool = false
var is_line_completed: bool = false

var progress_tween: Tween = null

func _ready() -> void:
	_ensure_nodes()
	_apply_tactile_styles()
	_populate_repertoire_options()
	_connect_signals()
	start_repertoire(current_rep_id)

func _ensure_nodes() -> void:
	if btn_back == null:
		btn_back = get_node_or_null("CenterContainer/MainLayout/TopBar/BtnBack")
	if opt_repertoire == null:
		opt_repertoire = get_node_or_null("CenterContainer/MainLayout/TopBar/OptRepertoire")
	if header_card == null:
		header_card = get_node_or_null("CenterContainer/MainLayout/HeaderCard")
	if repertoire_title_label == null:
		repertoire_title_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/RepertoireTitleLabel")
	if repertoire_meta_label == null:
		repertoire_meta_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/RepertoireMetaLabel")
	if mastery_progress_bar == null:
		mastery_progress_bar = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryProgressBar")
	if mastery_percent_label == null:
		mastery_percent_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryPercentLabel")
	if due_badge_label == null:
		due_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/DueBadgeLabel")
	if mode_badge_label == null:
		mode_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/ModeBadgeLabel")
	if chess_board == null:
		chess_board = get_node_or_null("CenterContainer/MainLayout/BoardCenter/ChessBoard")
	if coach_card == null:
		coach_card = get_node_or_null("CenterContainer/MainLayout/CoachCard")
	if status_label == null:
		status_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StatusLabel")
	if status_label == null:
		status_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusLabel")
	if blurb_label == null:
		blurb_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/BlurbLabel")
	if btn_hint == null:
		btn_hint = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnHint")
	if btn_retry == null:
		btn_retry = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnRetry")
	if btn_next_line == null:
		btn_next_line = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnNextLine")
	if btn_mode_toggle == null:
		btn_mode_toggle = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnModeToggle")

func _apply_tactile_styles() -> void:
	if btn_back:
		TactileStyles.apply_tactile_button(btn_back, false, false, true)
	if btn_hint:
		TactileStyles.apply_tactile_button(btn_hint, false, false, false)
	if btn_retry:
		TactileStyles.apply_tactile_button(btn_retry, false, false, false)
	if btn_next_line:
		TactileStyles.apply_tactile_button(btn_next_line, true, false, false)
	if btn_mode_toggle:
		TactileStyles.apply_tactile_button(btn_mode_toggle, false, false, false)

func _connect_signals() -> void:
	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if opt_repertoire and not opt_repertoire.item_selected.is_connected(_on_repertoire_selected):
		opt_repertoire.item_selected.connect(_on_repertoire_selected)
	if btn_hint and not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if btn_retry and not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)
	if btn_next_line and not btn_next_line.pressed.is_connected(_on_next_line_pressed):
		btn_next_line.pressed.connect(_on_next_line_pressed)
	if btn_mode_toggle and not btn_mode_toggle.pressed.is_connected(_on_mode_toggle_pressed):
		btn_mode_toggle.pressed.connect(_on_mode_toggle_pressed)
	if chess_board and not chess_board.move_made.is_connected(_on_board_move_made):
		chess_board.move_made.connect(_on_board_move_made)

func _populate_repertoire_options() -> void:
	if opt_repertoire == null:
		return
	opt_repertoire.clear()
	var reps = RepertoireService.get_available_repertoires()
	for i in range(reps.size()):
		var r = reps[i]
		var side_str = "White" if r.get("color", "white") == "white" else "Black"
		var label = "%s (%s - %s)" % [r.get("name", ""), r.get("eco", ""), side_str]
		opt_repertoire.add_item(label, i)
		opt_repertoire.set_item_metadata(i, r.get("id", ""))
		if r.get("id", "") == current_rep_id:
			opt_repertoire.select(i)

func start_repertoire(rep_id: String) -> void:
	current_rep_id = rep_id
	current_tree = RepertoireService.load_repertoire(rep_id)
	if current_tree == null:
		return
		
	is_flipped = (current_tree.color == "black")
	active_line_index = 0
	
	_update_header_ui()
	_load_line(0)

func _update_header_ui() -> void:
	if current_tree == null:
		return
	if repertoire_title_label:
		repertoire_title_label.text = current_tree.name
	if repertoire_meta_label:
		var side_name = "White" if current_tree.color == "white" else "Black"
		repertoire_meta_label.text = "%s · Playing as %s · %d Key Positions" % [
			current_tree.eco,
			side_name,
			current_tree.get_total_player_moves()
		]
	if mode_badge_label:
		mode_badge_label.text = "MODE: DRILL" if is_drill_mode else "MODE: LEARN"
	if btn_mode_toggle:
		btn_mode_toggle.text = "Learn Mode" if is_drill_mode else "Drill Mode"
		
	_refresh_stats()

func _refresh_stats() -> void:
	if current_tree == null:
		return
	var stats = RepertoireService.get_repertoire_stats(current_rep_id)
	var mastery_pct = float(stats.get("mastery_percent", 0.0))
	var due_count = int(stats.get("due_count", 0))
	
	if mastery_percent_label:
		mastery_percent_label.text = "%.0f%% Mastered" % mastery_pct
	if due_badge_label:
		due_badge_label.text = "%d moves due" % due_count if due_count > 0 else "All caught up"
		
	if mastery_progress_bar:
		if progress_tween and progress_tween.is_valid():
			progress_tween.kill()
		progress_tween = create_tween()
		if progress_tween:
			progress_tween.tween_property(mastery_progress_bar, "value", mastery_pct, 0.16)

func _clear_arrows() -> void:
	if chess_board:
		var empty_a: Array[Dictionary] = []
		var empty_b: Array[Dictionary] = []
		chess_board.update_arrows(empty_a, empty_b)

func _load_line(line_idx: int) -> void:
	if current_tree == null or current_tree.flattened_lines.is_empty():
		return
		
	active_line_index = posmod(line_idx, current_tree.flattened_lines.size())
	active_line = current_tree.flattened_lines[active_line_index]
	current_node_index = 0
	is_line_completed = false
	hint_used_on_step = false
	mistakes_on_step = 0
	is_waiting_opponent = false
	
	board_state = ChessBoardState.new()
	if chess_board:
		chess_board.setup_board(board_state, is_flipped)
		chess_board.clear_last_move()
		chess_board.clear_review_badge()
		_clear_arrows()
		
	if btn_next_line:
		btn_next_line.disabled = true
	if btn_retry:
		btn_retry.disabled = true
		
	_process_current_step()

func _process_current_step() -> void:
	if active_line.is_empty() or current_node_index >= active_line.size():
		_on_line_completed()
		return
		
	var node = active_line[current_node_index]
	hint_used_on_step = false
	mistakes_on_step = 0
	
	if node.is_player_move:
		_setup_player_turn(node)
	else:
		_setup_opponent_turn(node)

func _setup_player_turn(node: Variant) -> void:
	is_waiting_opponent = false
	if chess_board:
		chess_board.is_interactive = true
		
	var side_str = "White" if current_tree.color == "white" else "Black"
	
	if status_label:
		if is_drill_mode:
			status_label.text = "Your Turn (%s): Play the best opening move" % side_str
		else:
			status_label.text = "Play %s (%s to move)" % [node.san, side_str]
		status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
		
	if blurb_label:
		if is_drill_mode:
			blurb_label.text = "Recall the correct opening move for this position. Tap Show Hint if needed."
		else:
			blurb_label.text = node.blurb if not node.blurb.is_empty() else "Play %s to follow the repertoire." % node.san
			
	if btn_hint:
		btn_hint.disabled = false
	if btn_retry:
		btn_retry.disabled = true
		
	if not is_drill_mode and chess_board:
		_show_hint_arrows(node.move_uci)

func _setup_opponent_turn(node: Variant) -> void:
	is_waiting_opponent = true
	if chess_board:
		chess_board.is_interactive = false
	var opp_side = "Black" if current_tree.color == "white" else "White"
	
	if status_label:
		status_label.text = "Opponent (%s) is playing..." % opp_side
		status_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
		
	if btn_hint:
		btn_hint.disabled = true
	if btn_retry:
		btn_retry.disabled = true
		
	# Natural opponent timing (crisp and immediate, ~180ms)
	var t = get_tree() if is_inside_tree() else null
	if t:
		var timer = t.create_timer(0.18)
		timer.timeout.connect(func(): _execute_opponent_move(node))
	else:
		_execute_opponent_move(node)

func _execute_opponent_move(node: Variant) -> void:
	if not is_inside_tree() or board_state == null:
		return
		
	var move = ChessSAN.uci_to_move(board_state, node.move_uci)
	if move == null or move.is_empty():
		push_warning("OpeningTrainer: Could not parse opponent move '%s' for FEN '%s'" % [node.move_uci, board_state.to_fen()])
		is_waiting_opponent = false
		if chess_board:
			chess_board.is_interactive = true
		current_node_index += 1
		_process_current_step()
		return
		
	var next_state = board_state.clone()
	var to_sq = move.to_sq
	var is_ep = move.is_en_passant
	var is_castle = move.is_castling
	var promo = move.promotion
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	ChessMoveGenerator.apply_move_unchecked(next_state, move)
	
	if chess_board:
		chess_board.animate_move(
			move,
			next_state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			Callable(self, "_on_opponent_move_animation_done").bind(node, next_state)
		)
	else:
		_on_opponent_move_animation_done(node, next_state)

func _play_sfx(method_name: String) -> void:
	if not is_inside_tree():
		return
	var t = get_tree()
	if not t or not t.root:
		return
	if t.root.has_node("GameSettings"):
		var gs = t.root.get_node("GameSettings")
		if not gs.sound_enabled:
			return
	if t.root.has_node("AudioService"):
		var audio = t.root.get_node("AudioService")
		if audio.has_method(method_name):
			audio.call(method_name)

func _on_opponent_move_animation_done(node: Variant, next_state: ChessBoardState) -> void:
	board_state = next_state
	if chess_board:
		chess_board.set_last_move(node.move_uci.substr(0, 2), node.move_uci.substr(2, 2))
		chess_board.is_interactive = true
		
	_play_sfx("play_move")
	
	if blurb_label and not node.blurb.is_empty():
		blurb_label.text = node.blurb
	elif node.is_blunder and blurb_label:
		blurb_label.text = "Opponent played %s?! A common club mistake to punish." % node.san
		
	current_node_index += 1
	_process_current_step()

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
	if is_waiting_opponent or is_line_completed:
		return
	if current_node_index >= active_line.size():
		return
		
	var expected_node = active_line[current_node_index]
	if not expected_node.is_player_move:
		return
		
	var info = _extract_move_info(move)
	var played_uci = info["from"] + info["to"]
	if info["promo"] != ChessTypes.PieceType.NONE:
		played_uci += ChessTypes.piece_type_to_san_char(info["promo"]).to_lower()
		
	var is_correct = (played_uci == expected_node.move_uci)
	
	if is_correct:
		_handle_correct_player_move(expected_node, move)
	else:
		_handle_incorrect_player_move(expected_node, move)

func _handle_correct_player_move(expected_node: Variant, move: Variant) -> void:
	var info = _extract_move_info(move)
	var to_sq = info["to"]
	var is_ep = info["is_ep"]
	var is_castle = info["is_castle"]
	var promo = info["promo"]
	
	var next_state = board_state.clone()
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	ChessMoveGenerator.apply_move_unchecked(next_state, move)
	
	# Compute quality for SRS: 5=perfect, 4=one mistake, 3=hint used, etc.
	var quality = 5
	if hint_used_on_step:
		quality = 3
	elif mistakes_on_step > 0:
		quality = 4
		
	RepertoireService.get_srs_engine().record_attempt(expected_node.id, quality)
	_refresh_stats()
	
	if status_label:
		status_label.text = "Correct! %s" % expected_node.san
		status_label.add_theme_color_override("font_color", Color(0.51, 0.72, 0.30, 1)) # Green
		
	if blurb_label and not expected_node.blurb.is_empty():
		blurb_label.text = expected_node.blurb
		
	if chess_board:
		_clear_arrows()
		chess_board.animate_move(
			move,
			next_state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			Callable(self, "_on_player_move_animation_done").bind(next_state)
		)
	else:
		_on_player_move_animation_done(next_state)

func _on_player_move_animation_done(next_state: ChessBoardState) -> void:
	board_state = next_state
	_play_sfx("play_move")
	if chess_board:
		chess_board.is_interactive = true
	current_node_index += 1
	
	var t = get_tree() if is_inside_tree() else null
	if t:
		var timer = t.create_timer(0.08)
		timer.timeout.connect(_process_current_step)
	else:
		_process_current_step()

func _handle_incorrect_player_move(expected_node: Variant, _move: Variant) -> void:
	mistakes_on_step += 1
	RepertoireService.get_srs_engine().record_attempt(expected_node.id, 1)
	_refresh_stats()
	
	_play_sfx("play_illegal")
	
	if status_label:
		if is_drill_mode:
			status_label.text = "Incorrect move. Try again, or tap Show Hint."
		else:
			status_label.text = "Incorrect. Play %s to continue." % expected_node.san
		status_label.add_theme_color_override("font_color", Color(0.85, 0.35, 0.30, 1)) # Red
		
	if btn_retry:
		btn_retry.disabled = false
	if btn_hint:
		btn_hint.disabled = false
		
	# Reset board visually to current position
	if chess_board:
		chess_board.setup_board(board_state, is_flipped)
		chess_board.is_interactive = true

func _on_hint_pressed() -> void:
	if current_node_index >= active_line.size():
		return
	var node = active_line[current_node_index]
	if not node.is_player_move:
		return
		
	hint_used_on_step = true
	_show_hint_arrows(node.move_uci)
	
	if blurb_label:
		blurb_label.text = "Hint: Play %s. %s" % [node.san, node.blurb]

func _show_hint_arrows(uci: String) -> void:
	if chess_board == null or uci.length() < 4:
		return
	var from_sq = uci.substr(0, 2)
	var to_sq = uci.substr(2, 2)
	var arrows: Array[Dictionary] = [{"from": from_sq, "to": to_sq, "type": "best"}]
	var threats: Array[Dictionary] = []
	chess_board.update_arrows(arrows, threats)

func _on_retry_pressed() -> void:
	if current_node_index >= active_line.size():
		return
	var node = active_line[current_node_index]
	if chess_board and board_state:
		chess_board.setup_board(board_state, is_flipped)
		_clear_arrows()
	if status_label:
		var side_str = "White" if current_tree.color == "white" else "Black"
		status_label.text = "Your Turn (%s): Play the best repertoire move" % side_str
		status_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))

func _on_line_completed() -> void:
	is_line_completed = true
	if status_label:
		status_label.text = "Line Completed! 100% Accuracy"
		status_label.add_theme_color_override("font_color", Color(0.51, 0.72, 0.30, 1))
	if blurb_label:
		blurb_label.text = "Excellent reps! You have mastered this branch. Tap Next Line to continue."
	if btn_next_line:
		btn_next_line.disabled = false
	if btn_hint:
		btn_hint.disabled = true
	if btn_retry:
		btn_retry.disabled = true
	if chess_board:
		_clear_arrows()
		
	_play_sfx("play_victory")

func _on_next_line_pressed() -> void:
	_load_line(active_line_index + 1)

func _on_mode_toggle_pressed() -> void:
	is_drill_mode = not is_drill_mode
	_update_header_ui()
	if current_node_index < active_line.size():
		var node = active_line[current_node_index]
		if node.is_player_move:
			_setup_player_turn(node)

func _on_repertoire_selected(index: int) -> void:
	if opt_repertoire == null:
		return
	var rep_id = str(opt_repertoire.get_item_metadata(index))
	start_repertoire(rep_id)

func _on_back_pressed() -> void:
	var t = get_tree() if is_inside_tree() else null
	if t:
		t.change_scene_to_file(MAIN_MENU_SCENE)
