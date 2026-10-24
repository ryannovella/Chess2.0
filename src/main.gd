class_name MainGame
extends Control

const ChessBoard = preload("res://src/ui/board/chess_board.gd")
const EvalBar = preload("res://src/ui/hud/eval_bar.gd")
const EloSlider = preload("res://src/ui/hud/elo_slider.gd")
const MoveHistory = preload("res://src/ui/hud/move_history.gd")
const GameControls = preload("res://src/ui/hud/game_controls.gd")
const ChessPainter = preload("res://src/ui/painter/chess_painter.gd")
const PauseMenu = preload("res://src/ui/dialogs/pause_menu.gd")
const AnalysisPanel = preload("res://src/ui/hud/analysis_panel.gd")
const ConfettiBurst = preload("res://src/ui/effects/confetti_burst.gd")
const GameOverDialog = preload("res://src/ui/dialogs/game_over_dialog.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessMove = preload("res://src/core/chess_move.gd")
const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const EngineService = preload("res://src/engine/engine_service.gd")
const ThreatDetector = preload("res://src/core/threat_detector.gd")
const GameReviewService = preload("res://src/core/game_review_service.gd")
const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const ReviewSettingsDialog = preload("res://src/ui/hud/review_settings_dialog.gd")
const CapturedPiecesView = preload("res://src/ui/hud/captured_pieces_view.gd")
const CardPalette = preload("res://src/ui/card_palette.gd")

@onready var chess_board: ChessBoard = $CenterContainer/MainLayout/GameLayout/BoardArea/BoardMiddle/ChessBoard
@onready var eval_bar: EvalBar = $CenterContainer/MainLayout/GameLayout/BoardArea/BoardMiddle/EvalBar

@onready var top_player_card: PanelContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard
@onready var top_avatar_icon: TextureRect = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/AvatarIcon
@onready var top_name_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/NameLabel
@onready var top_badge_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/BadgeLabel
@onready var top_mate_badge: PanelContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/MateBadge
@onready var top_mate_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/MateBadge/MateHBox/MateLabel
@onready var top_captured_container: HBoxContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/TopPlayerCard/HBox/CapturedContainer

@onready var bottom_player_card: PanelContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard
@onready var bottom_avatar_icon: TextureRect = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/AvatarIcon
@onready var bottom_name_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/NameLabel
@onready var bottom_badge_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/BadgeLabel
@onready var bottom_mate_badge: PanelContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/MateBadge
@onready var bottom_mate_label: Label = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/MateBadge/MateHBox/MateLabel
@onready var bottom_captured_container: HBoxContainer = $CenterContainer/MainLayout/GameLayout/BoardArea/BottomPlayerCard/HBox/CapturedContainer

@onready var elo_slider: EloSlider = $"CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabContainer/Engine & Assist/VBox/EloSlider"
@onready var move_history: MoveHistory = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabContainer/Moves/MoveHistory
@onready var game_controls: GameControls = $CenterContainer/MainLayout/GameLayout/SidePanel/GameControls
@onready var status_panel: PanelContainer = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel
@onready var status_label: Label = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel/StatusContent/StatusLabel
@onready var engine_status_row: HBoxContainer = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel/StatusContent/EngineStatusRow
@onready var engine_status_label: Label = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel/StatusContent/EngineStatusRow/EngineStatusLabel
@onready var engine_final_badge: Control = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel/StatusContent/EngineStatusRow/EngineFinalBadge
@onready var engine_progress_bar: ProgressBar = $CenterContainer/MainLayout/GameLayout/SidePanel/StatusPanel/StatusContent/EngineProgressBar
@onready var chess_painter: ChessPainter = $ChessPainterLayer/ChessPainter
@onready var chess_painter_layer: CanvasLayer = $ChessPainterLayer
@onready var btn_pause: Button = $CenterContainer/MainLayout/TopBar/BtnPause
@onready var pause_menu_layer: CanvasLayer = $PauseMenuLayer
@onready var pause_menu: PauseMenu = $PauseMenuLayer/PauseMenu
@onready var analysis_panel: AnalysisPanel = $"CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabContainer/Engine & Assist/VBox/AnalysisPanel"
@onready var confetti_layer: CanvasLayer = $ConfettiLayer
@onready var confetti_burst: ConfettiBurst = $ConfettiLayer/ConfettiBurst
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var game_over_dialog: GameOverDialog = $GameOverLayer/GameOverDialog
@onready var hud_tab_bar: HBoxContainer = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabBar
@onready var btn_tab_moves: Button = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabBar/BtnTabMoves
@onready var btn_tab_engine: Button = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabBar/BtnTabEngine
@onready var btn_tab_review: Button = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabBar/BtnTabReview
@onready var hud_tab_container: TabContainer = $CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabContainer
@onready var game_review_panel: GameReviewPanel = $"CenterContainer/MainLayout/GameLayout/SidePanel/HUDTabContainer/Review/GameReviewPanel"
@onready var review_settings_layer: CanvasLayer = $ReviewSettingsLayer
@onready var review_settings_dialog: ReviewSettingsDialog = $ReviewSettingsLayer/ReviewSettingsDialog

var current_is_mate: bool = false
var current_mate_in: int = 0
var last_reviewed_step_index: int = -1
var is_showing_best_move_active: bool = false

var board_state: ChessBoardState = null
var engine_service: EngineService = null
var game_mode: String = "vs_ai" # "vs_ai" | "local_2p"
var engine_arrows: Array[Dictionary] = []
var threat_arrows: Array[Dictionary] = []
var is_game_active: bool = true
var is_paused: bool = false
var state_history: Array[Dictionary] = []
var history_index: int = -1
var game_review_service: GameReviewService = null
var is_review_mode: bool = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if engine_service != null and engine_service.client != null:
			engine_service.client.stop()
		if game_review_service != null:
			game_review_service.stop()

var top_card_style: StyleBoxFlat = null
var bottom_card_style: StyleBoxFlat = null
var top_pulse_tween: Tween = null
var bottom_pulse_tween: Tween = null
var current_top_pulse_color: Color = Color.TRANSPARENT
var current_bottom_pulse_color: Color = Color.TRANSPARENT
var _top_card_base_border: Color = CardPalette.DARK_CARD_BORDER
var _bottom_card_base_border: Color = CardPalette.DARK_CARD_BORDER

const MATE_PULSE_GREEN = CardPalette.MATE_GREEN
const MATE_PULSE_RED = CardPalette.MATE_RED

func _ready() -> void:
	if top_player_card:
		var sb_top = top_player_card.get_theme_stylebox("panel")
		top_card_style = (sb_top.duplicate() if sb_top is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		top_player_card.add_theme_stylebox_override("panel", top_card_style)
	if bottom_player_card:
		var sb_bot = bottom_player_card.get_theme_stylebox("panel")
		bottom_card_style = (sb_bot.duplicate() if sb_bot is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		bottom_player_card.add_theme_stylebox_override("panel", bottom_card_style)

	chess_painter_layer.visible = false
	pause_menu_layer.visible = false
	if game_over_layer:
		game_over_layer.visible = false
	if review_settings_layer:
		review_settings_layer.visible = false

	# Inisialisasi Engine Service
	engine_service = EngineService.new()
	add_child(engine_service)
	engine_service.eval_updated.connect(_on_engine_eval_updated)
	engine_service.arrows_updated.connect(_on_engine_arrows_updated)
	engine_service.ai_move_ready.connect(_on_ai_move_ready)
	engine_service.analysis_progress_updated.connect(_on_analysis_progress_updated)
	GameSettings.engine_depth_changed.connect(_on_engine_depth_changed)

	# Inisialisasi Game Review Service
	game_review_service = GameReviewService.new()
	game_review_service.review_progress.connect(_on_review_analysis_progress)
	game_review_service.review_position_evaluated.connect(_on_review_position_evaluated)
	game_review_service.review_completed.connect(_on_review_completed)

	if game_review_panel:
		game_review_panel.move_selected.connect(_on_review_move_selected)
		game_review_panel.show_best_move_requested.connect(_on_review_show_best_move)
		game_review_panel.retry_mode_requested.connect(_on_review_retry_mode)
		game_review_panel.review_closed.connect(_on_review_closed)
		game_review_panel.settings_requested.connect(_on_review_settings_requested)

	if review_settings_dialog:
		review_settings_dialog.settings_applied.connect(_on_review_settings_applied)
		review_settings_dialog.dialog_closed.connect(_on_review_settings_closed)

	if btn_tab_moves:
		btn_tab_moves.pressed.connect(func(): select_hud_tab(0))
		_setup_tactile_tab_effect(btn_tab_moves)
	if btn_tab_engine:
		btn_tab_engine.pressed.connect(func(): select_hud_tab(1))
		_setup_tactile_tab_effect(btn_tab_engine)
	if btn_tab_review:
		btn_tab_review.pressed.connect(func(): select_hud_tab(2))
		_setup_tactile_tab_effect(btn_tab_review)

	_update_hud_tab_bar_styles(0)

	if hud_tab_container:
		hud_tab_container.tab_changed.connect(_on_hud_tab_changed)

	# Hubungkan sinyal dari ChessBoard
	chess_board.move_made.connect(_on_board_move_made)

	# Hubungkan sinyal dari GameControls
	game_controls.new_game_pressed.connect(_on_new_game_pressed)
	game_controls.resign_pressed.connect(_on_resign_pressed)
	game_controls.flip_board_pressed.connect(_on_flip_board_pressed)
	game_controls.undo_pressed.connect(undo_move)
	game_controls.redo_pressed.connect(redo_move)
	game_controls.open_painter_pressed.connect(_on_open_painter_pressed)

	btn_pause.pressed.connect(_on_pause_button_pressed)
	pause_menu.resume_pressed.connect(_on_pause_resume)
	pause_menu.restart_pressed.connect(_on_pause_restart)
	pause_menu.resign_pressed.connect(_on_pause_resign)
	pause_menu.main_menu_pressed.connect(_on_pause_main_menu)

	# Hubungkan sinyal dari ChessPainter
	chess_painter.play_position.connect(_on_painter_play_position)
	chess_painter.back_to_main_menu.connect(_on_painter_back)

	# Hubungkan sinyal dari GameOverDialog
	if game_over_dialog:
		game_over_dialog.rematch_pressed.connect(_on_game_over_rematch)
		game_over_dialog.review_pressed.connect(_on_game_over_review)
		game_over_dialog.main_menu_pressed.connect(_on_pause_main_menu)
		game_over_dialog.closed.connect(_on_game_over_closed)

	# Hubungkan sinyal pengaturan
	GameSettings.arrows_toggled.connect(func(): _update_threats())
	GameSettings.settings_changed.connect(_on_settings_changed)
	GameSettings.piece_set_changed.connect(func(_p): _on_settings_changed())

	start_new_game(ChessBoardState.DEFAULT_FEN, GameSettings.current_game_mode)
	if GameSettings.open_painter_on_launch:
		chess_painter_layer.visible = true

func start_new_game(fen: String = ChessBoardState.DEFAULT_FEN, mode: String = "vs_ai") -> void:
	game_mode = mode
	is_game_active = true
	is_paused = false
	engine_service.stop_analysis()
	engine_arrows.clear()
	threat_arrows.clear()
	if pause_menu_layer:
		pause_menu_layer.visible = false
	if game_over_layer:
		game_over_layer.visible = false
	if game_over_dialog:
		game_over_dialog.visible = false
	if review_settings_layer:
		review_settings_layer.visible = false
	if confetti_burst:
		confetti_burst.stop()
	is_review_mode = false
	if game_review_panel:
		game_review_panel.reset_view()
	if chess_board:
		chess_board.clear_review_badge()
	if game_controls:
		game_controls.visible = true
	if engine_status_row:
		engine_status_row.visible = true
	if engine_progress_bar:
		engine_progress_bar.visible = true
	if status_panel:
		status_panel.visible = true
		status_panel.custom_minimum_size = Vector2(0, 68)
	if hud_tab_container:
		hud_tab_container.current_tab = 0
	if hud_tab_bar:
		hud_tab_bar.visible = true
	_set_engine_tab_available(true)
	board_state = ChessBoardState.new(fen)

	if fen == ChessBoardState.DEFAULT_FEN:
		GameSettings.resolve_player_side()

	if analysis_panel:
		analysis_panel.set_game_mode(game_mode)

	chess_board.set_process_input(true)
	chess_board.setup_board(board_state, GameSettings.is_flipped)
	eval_bar.set_flipped(GameSettings.is_flipped)
	eval_bar.set_eval(0, false, 0)
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	_update_player_cards(false, 0)
	move_history.clear()
	if elo_slider:
		elo_slider.visible = (game_mode == "vs_ai")

	# Inisialisasi riwayat state untuk undo / redo
	state_history.clear()
	state_history.append({
		"fen": board_state.to_fen(),
		"from_sq": "",
		"to_sq": "",
		"san_history": [],
		"is_cap": false,
		"is_castle": false,
		"is_ep": false,
		"promo": ChessTypes.PieceType.NONE
	})
	history_index = 0
	_update_undo_redo_ui()

	var mode_text = "Play vs AI" if game_mode == "vs_ai" else "Local 2P"
	var turn_str = "White" if board_state.turn == ChessTypes.PieceColor.WHITE else "Black"
	_set_status("%s - %s to move" % [mode_text, turn_str])

	_update_threats()

	var player_c = GameSettings.player_color
	if game_mode == "vs_ai" and board_state.turn != player_c:
		chess_board.is_interactive = false
		_set_status("AI is thinking...")
		_set_ai_thinking_hud()
		_request_bot_move()
	else:
		chess_board.is_interactive = true
		engine_service.analyze_position(board_state.to_fen())

## Daftar langkah UCI dari posisi awal sampai `history_index`, dipakai untuk
## memberi Maia-3 konteks temporal (8 slot riwayat Chessformer).
func _uci_move_list() -> PackedStringArray:
	var moves := PackedStringArray()
	if state_history.is_empty():
		return moves
	var upto = clampi(history_index, 0, state_history.size() - 1)
	for i in range(1, upto + 1):
		var entry: Dictionary = state_history[i]
		var from_sq = str(entry.get("from_sq", entry.get("from", "")))
		var to_sq = str(entry.get("to_sq", entry.get("to", "")))
		if from_sq.is_empty() or to_sq.is_empty():
			continue
		var suffix = ""
		var promo = int(entry.get("promo", ChessTypes.PieceType.NONE))
		if promo != ChessTypes.PieceType.NONE:
			suffix = ChessTypes.piece_type_to_san_char(promo).to_lower()
		moves.append(from_sq + to_sq + suffix)
	return moves

## Satu-satunya jalur permintaan langkah bot. Riwayat hanya dikirim bila papan
## benar-benar sinkron dengan `state_history`; mode Retry Game Review memundurkan
## papan tanpa mengubah riwayat, dan di situ FEN tunggal yang aman.
func _request_bot_move() -> void:
	if board_state == null or engine_service == null:
		return
	var moves := PackedStringArray()
	var start_fen := ChessBoardState.DEFAULT_FEN
	if not state_history.is_empty():
		var idx = clampi(history_index, 0, state_history.size() - 1)
		if str(state_history[idx].get("fen", "")) == board_state.to_fen():
			start_fen = str(state_history[0].get("fen", ChessBoardState.DEFAULT_FEN))
			moves = _uci_move_list()
	engine_service.set_move_history(start_fen, moves)
	engine_service.request_ai_move(board_state.to_fen(), GameSettings.ai_elo)

func _on_board_move_made(move: Variant) -> void:
	if is_review_mode and game_review_panel and game_review_panel.is_retry_active:
		var from_sq_r = move.from_sq if move is ChessMove else move.get("from", "")
		var to_sq_r = move.to_sq if move is ChessMove else move.get("to", "")
		var promo_r = move.promotion if move is ChessMove else move.get("promotion", ChessTypes.PieceType.NONE)
		var played_uci = from_sq_r + to_sq_r
		if promo_r != ChessTypes.PieceType.NONE:
			played_uci += ChessTypes.piece_type_to_san_char(promo_r).to_lower()
		var success = game_review_panel.evaluate_retry_attempt(played_uci)
		if success:
			AudioService.play_victory()
			ChessMoveGenerator.apply_move_unchecked(board_state, move)
			chess_board.setup_board(board_state, GameSettings.is_flipped)
			chess_board.set_review_badge(to_sq_r, GameReviewService.Classification.BEST)
			chess_board.update_arrows([{ "from": from_sq_r, "to": to_sq_r, "color": Color(0.15, 0.85, 0.45, 0.9) }], [])
		else:
			AudioService.play_illegal()
			var step_data = game_review_panel.get_current_step_data()
			var prev_fen = step_data.get("prev_fen", ChessBoardState.DEFAULT_FEN)
			board_state = ChessBoardState.new(prev_fen)
			chess_board.setup_board(board_state, GameSettings.is_flipped)
			chess_board.is_interactive = true
		return

	if not is_game_active or is_paused or (move is Dictionary and move.is_empty()) or (move is ChessMove and move.is_empty()):
		return

	# Bersihkan panah posisi sebelumnya dan hentikan analisa lama saat langkah dilakukan
	engine_service.stop_analysis()
	engine_arrows.clear()
	threat_arrows.clear()
	if chess_board:
		chess_board.clear_selection()
		chess_board.update_arrows([], [])

	# Jika pengguna melangkah setelah undo, potong cabang riwayat redo
	if history_index < state_history.size() - 1:
		state_history = state_history.slice(0, history_index + 1)

	var from_sq = move.from_sq if move is ChessMove else move.get("from", "")
	var to_sq = move.to_sq if move is ChessMove else move.get("to", "")
	var is_castle = move.is_castling if move is ChessMove else move.get("is_castling", false)
	var promo = move.promotion if move is ChessMove else move.get("promotion", ChessTypes.PieceType.NONE)
	var is_ep = move.is_en_passant if move is ChessMove else move.get("is_en_passant", false)

	var san = ChessSAN.move_to_san(board_state, move)
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	var is_promo = promo != ChessTypes.PieceType.NONE

	ChessMoveGenerator.apply_move_unchecked(board_state, move)
	move_history.add_move(san)

	# Simpan state ke riwayat
	var previous_sans: Array = []
	if not state_history.is_empty() and history_index >= 0 and history_index < state_history.size():
		previous_sans = state_history[history_index]["san_history"].duplicate()
	previous_sans.append(san)

	state_history.append({
		"fen": board_state.to_fen(),
		"from": from_sq,
		"to": to_sq,
		"from_sq": from_sq,
		"to_sq": to_sq,
		"san": san,
		"san_history": previous_sans,
		"is_cap": is_cap,
		"is_castle": is_castle,
		"is_ep": is_ep,
		"promo": promo
	})
	history_index = state_history.size() - 1
	_update_undo_redo_ui()

	# Bunyikan efek suara yang sesuai tepat saat bidak mendarat di petak target
	var on_impact_sfx = func():
		_play_move_sfx(is_cap, is_castle, is_promo)

	chess_board.animate_move(move, board_state, is_cap, is_castle, is_ep, promo, func():
		_finalize_move_turn()
	, on_impact_sfx)

func _finalize_move_turn() -> void:
	if not is_game_active or is_paused or board_state == null:
		return

	# Periksa status akhir permainan
	if ChessMoveGenerator.is_checkmate(board_state):
		var winner = "Black" if board_state.turn == ChessTypes.PieceColor.WHITE else "White"
		var score = "0-1" if board_state.turn == ChessTypes.PieceColor.WHITE else "1-0"
		_handle_game_end("Checkmate! %s wins!" % winner, score, true)
		return
	elif ChessMoveGenerator.is_stalemate(board_state):
		_handle_game_end("Draw (Stalemate)", "1/2-1/2", false)
		return
	elif ChessMoveGenerator.is_threefold_repetition(board_state):
		_handle_game_end("Draw (Threefold Repetition)", "1/2-1/2", false)
		return
	elif ChessMoveGenerator.is_insufficient_material(board_state):
		_handle_game_end("Draw (Insufficient Material)", "1/2-1/2", false)
		return
	elif board_state.halfmove_clock >= 100:
		_handle_game_end("Draw (50-Move Rule)", "1/2-1/2", false)
		return

	# Update ancaman posisi baru
	_update_threats()
	_update_player_cards(false, 0)

	var turn_str = "White" if board_state.turn == ChessTypes.PieceColor.WHITE else "Black"
	_set_status("Turn: %s" % turn_str)

	# Jika giliran bot AI, minta langkah; jika giliran pemain, analisa posisi untuk panah
	var player_c = GameSettings.player_color
	if game_mode == "vs_ai" and board_state.turn != player_c:
		chess_board.is_interactive = false
		_set_status("AI is thinking...")
		_set_ai_thinking_hud()
		_request_bot_move()
	else:
		chess_board.is_interactive = true
		engine_service.analyze_position(board_state.to_fen())

func _handle_game_end(status_msg: String, score: String, is_checkmate: bool, is_resign: bool = false, resign_color: int = -1) -> void:
	is_game_active = false
	engine_service.stop_analysis()
	engine_arrows.clear()
	threat_arrows.clear()
	if chess_board:
		chess_board.clear_selection()
		chess_board.update_arrows([], [])
		chess_board.update_mate_popup(false, 0)
	_update_player_cards(false, 0)
	move_history.add_move(score)
	_set_status(status_msg)
	_update_undo_redo_ui()
	# Pertandingan selesai: tidak ada lagi posisi yang perlu dianalisis mesin,
	# jadi tab Engine & Assist tidak relevan dan disembunyikan sampai game baru.
	_set_engine_tab_available(false)

	var is_draw = (score == "1/2-1/2")
	var is_decisive = not is_draw
	var loser_color = -1
	var winner_color = -1

	if is_decisive:
		if is_resign:
			loser_color = resign_color
			winner_color = ChessTypes.PieceColor.BLACK if loser_color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
		else:
			loser_color = board_state.turn if board_state != null else ChessTypes.PieceColor.WHITE
			winner_color = ChessTypes.PieceColor.BLACK if loser_color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE

	var is_player_win = false
	if is_decisive:
		if game_mode == "vs_ai":
			is_player_win = (winner_color == GameSettings.player_color)
		else:
			is_player_win = true

	# Title & subtitle untuk game over dialog
	var dialog_title = ""
	var dialog_subtitle = ""
	if is_draw:
		dialog_title = "Draw"
		var sub = status_msg.trim_prefix("Draw").strip_edges().trim_prefix("(").trim_suffix(")")
		dialog_subtitle = "by " + sub if not sub.is_empty() else "by Agreement"
	elif game_mode == "vs_ai":
		if is_player_win:
			dialog_title = "You Won!"
		else:
			dialog_title = "You Lost"
		dialog_subtitle = "by Checkmate" if is_checkmate else "by Resignation"
	else:
		var win_name = "White" if winner_color == ChessTypes.PieceColor.WHITE else "Black"
		dialog_title = "%s Won!" % win_name
		dialog_subtitle = "by Checkmate" if is_checkmate else "by Resignation"

	# 1. Animasi topple raja yang kalah jika decisive
	if is_decisive and chess_board and loser_color != -1:
		chess_board.topple_king(loser_color)

	# 2. Audio & Efek Kemenangan
	if is_checkmate:
		AudioService.play_checkmate()
	elif is_resign:
		# Saat resign, mainkan audio penutup game_end yang tenang tanpa bertabrakan dengan fanfare
		AudioService.play("game_end")
	else:
		AudioService.play("game_end")

	if is_player_win and is_decisive and not is_resign:
		# Mainkan fanfare kemenangan dan letupkan konfeti HANYA jika bukan resign
		var win_timer = get_tree().create_timer(0.32)
		win_timer.timeout.connect(func():
			AudioService.play_victory()
			if confetti_burst:
				confetti_burst.burst()
		)

	# 3. Tampilkan GameOverDialog dengan jeda natural ala chess.com
	var popup_delay = 0.75 if is_decisive else 0.4
	var dlg_timer = get_tree().create_timer(popup_delay)
	dlg_timer.timeout.connect(func():
		if game_over_layer and game_over_dialog:
			game_over_layer.visible = true
			game_over_dialog.show_game_over(dialog_title, dialog_subtitle, score, is_player_win, is_draw)
	)

func _on_ai_move_ready(move_uci: String) -> void:
	if not is_game_active or is_paused or game_mode != "vs_ai":
		return

	if move_uci.is_empty():
		var legal_moves = ChessMoveGenerator.get_legal_moves(board_state)
		if legal_moves.is_empty():
			_finalize_move_turn()
		else:
			_on_board_move_made(legal_moves[0])
		return

	var move = ChessSAN.uci_to_move(board_state, move_uci)
	if not move.is_empty():
		_on_board_move_made(move)
	else:
		push_warning("main: Unparseable AI move '%s' on FEN '%s', executing legal fallback." % [move_uci, board_state.to_fen()])
		var legal_moves = ChessMoveGenerator.get_legal_moves(board_state)
		if legal_moves.is_empty():
			_finalize_move_turn()
		else:
			_on_board_move_made(legal_moves[0])

func _update_threats() -> void:
	if board_state == null:
		return
	if game_mode != "vs_ai":
		var new_threats: Array[Dictionary] = []
		if GameSettings.show_white_threat_arrows:
			new_threats.append_array(ThreatDetector.detect_threats(board_state, ChessTypes.PieceColor.WHITE))
		if GameSettings.show_black_threat_arrows:
			new_threats.append_array(ThreatDetector.detect_threats(board_state, ChessTypes.PieceColor.BLACK))
		threat_arrows = new_threats
		_refresh_arrows()
	else:
		_refresh_arrows()

func _refresh_arrows() -> void:
	if chess_board:
		var visible_engine_arrows: Array[Dictionary] = []
		var visible_threat_arrows: Array[Dictionary] = []
		
		if board_state != null:
			# Engine Arrows Logic
			var show_player_engine = false
			var show_opponent_engine = false
			
			if game_mode == "vs_ai":
				if board_state.turn == GameSettings.player_color:
					show_player_engine = GameSettings.get_player_engine_arrows()
				else:
					show_opponent_engine = GameSettings.get_opponent_engine_arrows()
			else:
				if board_state.turn == ChessTypes.PieceColor.WHITE:
					show_player_engine = GameSettings.show_white_engine_arrows
				else:
					show_opponent_engine = GameSettings.show_black_engine_arrows
			
			if show_player_engine or show_opponent_engine:
				for arr in engine_arrows:
					var from_sq = str(arr.get("from", ""))
					var p = board_state.get_piece(from_sq)
					if p != null and p["color"] == board_state.turn:
						visible_engine_arrows.append(arr)
			
			# Threat Arrows Logic
			if game_mode == "vs_ai":
				if GameSettings.get_player_threat_arrows():
					visible_threat_arrows.append_array(ThreatDetector.detect_threats(board_state, GameSettings.player_color))
				if GameSettings.get_opponent_threat_arrows():
					visible_threat_arrows.append_array(ThreatDetector.detect_threats(board_state, 1 - GameSettings.player_color))
			else:
				if GameSettings.show_white_threat_arrows:
					visible_threat_arrows.append_array(ThreatDetector.detect_threats(board_state, ChessTypes.PieceColor.WHITE))
				if GameSettings.show_black_threat_arrows:
					visible_threat_arrows.append_array(ThreatDetector.detect_threats(board_state, ChessTypes.PieceColor.BLACK))

		chess_board.update_arrows(visible_engine_arrows, visible_threat_arrows)

func _on_engine_eval_updated(score_cp: int, is_mate: bool, mate_in: int, depth: int) -> void:
	eval_bar.set_eval(score_cp, is_mate, mate_in, depth)
	_update_player_cards(is_mate, mate_in)

func _on_engine_arrows_updated(arrows: Array[Dictionary]) -> void:
	engine_arrows = arrows
	_refresh_arrows()

func _on_engine_depth_changed(_depth: int) -> void:
	if not is_paused and is_game_active and board_state != null:
		var player_c = GameSettings.player_color
		if game_mode != "vs_ai" or board_state.turn == player_c:
			engine_service.reanalyze()

var progress_tween: Tween = null

func _animate_progress_bar(target_value: float, is_final: bool) -> void:
	if engine_progress_bar == null:
		return
	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()
		progress_tween = null

	if target_value <= 0.001:
		engine_progress_bar.value = 0.0
		return

	progress_tween = create_tween()
	var duration = 0.12 if is_final else 0.16
	progress_tween.tween_property(engine_progress_bar, "value", target_value, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _set_ai_thinking_hud() -> void:
	if progress_tween and progress_tween.is_valid():
		progress_tween.kill()
		progress_tween = null
	if engine_progress_bar:
		engine_progress_bar.value = 0.0
	if engine_final_badge:
		engine_final_badge.visible = false
	if engine_status_label:
		engine_status_label.text = "AI Thinking (ELO %d)..." % GameSettings.ai_elo
		engine_status_label.add_theme_color_override("font_color", Color(0.74, 0.72, 0.69, 1))

func _on_analysis_progress_updated(cur_depth: int, target_depth: int, is_final: bool) -> void:
	if target_depth <= 0:
		return

	var target_pct: float = 1.0
	if is_final:
		target_pct = 1.0
		if engine_status_label:
			engine_status_label.text = "Analysis: Depth %d" % target_depth
			engine_status_label.add_theme_color_override("font_color", Color(0.3, 0.88, 0.55, 1))
		if engine_final_badge:
			engine_final_badge.visible = true
	elif cur_depth > 0:
		target_pct = engine_service.get_analysis_progress_ratio() if engine_service != null else clampf(float(cur_depth) / float(target_depth), 0.0, 0.95)
		if engine_status_label:
			if cur_depth >= target_depth:
				var mpv = engine_service.current_analysis_multipv if engine_service != null else 1
				engine_status_label.text = "Depth %d/%d (Finalizing Line %d/3...)" % [cur_depth, target_depth, mpv]
			else:
				engine_status_label.text = "Depth %d/%d (%d%%)" % [cur_depth, target_depth, int(target_pct * 100)]
			engine_status_label.add_theme_color_override("font_color", Color(0.3, 0.78, 1, 1))
		if engine_final_badge:
			engine_final_badge.visible = false
	else:
		target_pct = 0.0
		if engine_status_label:
			engine_status_label.text = "Analyzing..."
			engine_status_label.add_theme_color_override("font_color", Color(0.74, 0.72, 0.69, 1))
		if engine_final_badge:
			engine_final_badge.visible = false

	_animate_progress_bar(target_pct, is_final)

func _play_move_sfx(is_cap: bool, is_castle: bool, is_promo: bool) -> void:
	if ChessMoveGenerator.is_in_check(board_state, board_state.turn):
		AudioService.play_check()
	elif is_castle:
		AudioService.play_castle()
	elif is_promo:
		AudioService.play_promote()
	elif is_cap:
		AudioService.play_capture()
	else:
		AudioService.play_move()

func _on_new_game_pressed() -> void:
	start_new_game(ChessBoardState.DEFAULT_FEN, game_mode)

func _on_resign_pressed() -> void:
	if not is_game_active:
		return
	var res_color = GameSettings.player_color if game_mode == "vs_ai" else (board_state.turn if board_state != null else ChessTypes.PieceColor.WHITE)
	var score = "0-1" if res_color == ChessTypes.PieceColor.WHITE else "1-0"
	var winner_str = "Black" if res_color == ChessTypes.PieceColor.WHITE else "White"
	_handle_game_end("Resignation! %s wins!" % winner_str, score, false, true, res_color)

func _update_undo_redo_ui() -> void:
	if game_controls:
		var can_undo = not is_paused and history_index > 0
		var can_redo = not is_paused and history_index < state_history.size() - 1
		game_controls.update_undo_redo(can_undo, can_redo)

func undo_move() -> void:
	if is_paused or history_index <= 0:
		return

	var steps_to_undo = 1
	if game_mode == "vs_ai":
		var is_bot_thinking = engine_service.is_waiting_for_ai or engine_service.is_flushing_for_ai
		if is_bot_thinking:
			steps_to_undo = 1
		elif history_index >= 2:
			steps_to_undo = 2
		else:
			steps_to_undo = 1

	var target_index = clampi(history_index - steps_to_undo, 0, state_history.size() - 1)
	_animate_and_apply_undo(target_index, steps_to_undo)

func redo_move() -> void:
	if is_paused or history_index >= state_history.size() - 1:
		return

	var steps_to_redo = 1
	if game_mode == "vs_ai":
		if history_index + 2 <= state_history.size() - 1:
			steps_to_redo = 2
		else:
			steps_to_redo = 1

	var target_index = clampi(history_index + steps_to_redo, 0, state_history.size() - 1)
	_animate_and_apply_redo(target_index, steps_to_redo)

func _animate_and_apply_undo(target_index: int, steps: int) -> void:
	engine_service.stop_analysis()
	engine_arrows.clear()
	threat_arrows.clear()
	if chess_board:
		chess_board.update_arrows([], [])
	AudioService.play_move()

	if steps == 1:
		var move_info = state_history[history_index]
		history_index = target_index
		var target_state_data = state_history[history_index]
		board_state = ChessBoardState.new(target_state_data["fen"])
		chess_board.animate_undo_move(move_info, board_state, func():
			_finalize_history_transition(target_state_data)
		)
	elif steps >= 2:
		var bot_move_info = state_history[history_index]
		var intermediate_state_data = state_history[history_index - 1]
		var intermediate_board = ChessBoardState.new(intermediate_state_data["fen"])
		history_index = history_index - 1

		chess_board.animate_undo_move(bot_move_info, intermediate_board, func():
			var player_move_info = state_history[history_index]
			history_index = target_index
			var final_state_data = state_history[history_index]
			board_state = ChessBoardState.new(final_state_data["fen"])
			AudioService.play_move()
			chess_board.animate_undo_move(player_move_info, board_state, func():
				_finalize_history_transition(final_state_data)
			)
		)

func _animate_and_apply_redo(target_index: int, steps: int) -> void:
	engine_service.stop_analysis()
	engine_arrows.clear()
	threat_arrows.clear()
	if chess_board:
		chess_board.update_arrows([], [])
	AudioService.play_move()

	if steps == 1:
		history_index = target_index
		var move_info = state_history[history_index]
		board_state = ChessBoardState.new(move_info["fen"])
		var is_cap = move_info.get("is_cap", false)
		var is_castle = move_info.get("is_castle", false)
		var is_ep = move_info.get("is_ep", false)
		var promo = move_info.get("promo", ChessTypes.PieceType.NONE)

		var is_promo = promo != ChessTypes.PieceType.NONE
		chess_board.animate_move(move_info, board_state, is_cap, is_castle, is_ep, promo, func():
			_finalize_history_transition(move_info)
		, func(): _play_move_sfx(is_cap, is_castle, is_promo))
	elif steps >= 2:
		var step1_index = history_index + 1
		var move_info1 = state_history[step1_index]
		var board1 = ChessBoardState.new(move_info1["fen"])
		var is_cap1 = move_info1.get("is_cap", false)
		var is_castle1 = move_info1.get("is_castle", false)
		var is_ep1 = move_info1.get("is_ep", false)
		var promo1 = move_info1.get("promo", ChessTypes.PieceType.NONE)
		var is_promo1 = promo1 != ChessTypes.PieceType.NONE
		history_index = step1_index

		chess_board.animate_move(move_info1, board1, is_cap1, is_castle1, is_ep1, promo1, func():
			history_index = target_index
			var move_info2 = state_history[history_index]
			board_state = ChessBoardState.new(move_info2["fen"])
			var is_cap2 = move_info2.get("is_cap", false)
			var is_castle2 = move_info2.get("is_castle", false)
			var is_ep2 = move_info2.get("is_ep", false)
			var promo2 = move_info2.get("promo", ChessTypes.PieceType.NONE)
			var is_promo2 = promo2 != ChessTypes.PieceType.NONE

			chess_board.animate_move(move_info2, board_state, is_cap2, is_castle2, is_ep2, promo2, func():
				_finalize_history_transition(move_info2)
			, func(): _play_move_sfx(is_cap2, is_castle2, is_promo2))
		, func(): _play_move_sfx(is_cap1, is_castle1, is_promo1))

func _finalize_history_transition(state_data: Dictionary) -> void:
	if game_over_layer:
		game_over_layer.visible = false
	if game_over_dialog:
		game_over_dialog.visible = false
	if confetti_burst:
		confetti_burst.stop()

	is_game_active = true
	chess_board.set_process_input(true)
	chess_board.set_last_move(state_data["from_sq"], state_data["to_sq"])
	move_history.set_moves(state_data["san_history"])

	_update_threats()
	_update_undo_redo_ui()
	_update_player_cards(false, 0)

	var player_c = GameSettings.player_color
	var turn_str = "White" if board_state.turn == ChessTypes.PieceColor.WHITE else "Black"
	if game_mode == "vs_ai" and board_state.turn != player_c:
		chess_board.is_interactive = false
		_set_status("AI is thinking...")
		_set_ai_thinking_hud()
		_request_bot_move()
	else:
		chess_board.is_interactive = true
		_set_status("Turn: %s" % turn_str)
		engine_service.analyze_position(board_state.to_fen())

func _on_flip_board_pressed() -> void:
	GameSettings.set_flipped(not GameSettings.is_flipped)

func _on_settings_changed() -> void:
	CapturedPiecesView.clear_texture_cache()
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	var prev_last_move = chess_board.last_move.duplicate() if chess_board else {}
	chess_board.setup_board(board_state, GameSettings.is_flipped)
	if not prev_last_move.is_empty():
		chess_board.set_last_move(prev_last_move.get("from", ""), prev_last_move.get("to", ""))
	eval_bar.set_flipped(GameSettings.is_flipped)
	_update_threats()
	_update_player_cards(current_is_mate, current_mate_in)

var _last_top_captured_key: String = ""
var _last_bottom_captured_key: String = ""

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
	# Kontainer dari scene masih HBoxContainer; view digambar sendiri agar bidak
	# sejenis bisa saling menumpuk rapat seperti di Chess.com.
	var view := CapturedPiecesView.new()
	view.name = "CapturedPiecesView"
	container.add_child(view)
	view.custom_minimum_size = view.custom_minimum_size
	view.size = view.custom_minimum_size
	return view

func _render_captured_section(container: HBoxContainer, captured_pieces: Array, piece_color: int, point_advantage: int, is_top: bool, card_bg: Color) -> void:
	if container == null or not is_instance_valid(container):
		return

	var piece_set = GameSettings.piece_set if GameSettings else "cburnett"
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

func _update_player_cards(is_mate: bool = false, mate_in: int = 0) -> void:
	current_is_mate = is_mate
	current_mate_in = mate_in

	var robot_icon = preload("res://assets/ui/icons/icon_robot.svg")
	var person_icon = preload("res://assets/ui/icons/icon_person.svg")
	var people_icon = preload("res://assets/ui/icons/icon_people.svg")

	var is_flipped = GameSettings.is_flipped

	var white_name = "Player 1 (White)"
	var white_badge = "White"
	var white_avatar = person_icon

	var black_name = "Player 2 (Black)"
	var black_badge = "Black"
	var black_avatar = person_icon

	if game_mode == "vs_ai":
		var p_color = GameSettings.player_color
		var is_maia = (GameSettings.ai_engine_type == "maia3" and GameSettings.ai_elo < 2800)
		var bot_name = "Maia-3" if is_maia else "Stockfish 18"
		var bot_badge = "ELO %d" % GameSettings.ai_elo
		
		if p_color == ChessTypes.PieceColor.WHITE:
			white_name = "Player (You)"
			white_badge = "White"
			white_avatar = person_icon
			black_name = bot_name
			black_badge = bot_badge
			black_avatar = robot_icon
		else:
			black_name = "Player (You)"
			black_badge = "Black"
			black_avatar = person_icon
			white_name = bot_name
			white_badge = bot_badge
			white_avatar = robot_icon
	else:
		white_name = "Player 1 (White)"
		white_badge = "Local 2P"
		white_avatar = person_icon
		black_name = "Player 2 (Black)"
		black_badge = "Local 2P"
		black_avatar = people_icon

	# Top/Bottom determination based on board flip
	var top_is_white = is_flipped
	var bottom_is_white = not is_flipped

	if top_name_label:
		top_name_label.text = white_name if top_is_white else black_name
		top_badge_label.text = white_badge if top_is_white else black_badge
		top_avatar_icon.texture = white_avatar if top_is_white else black_avatar

	if bottom_name_label:
		bottom_name_label.text = white_name if bottom_is_white else black_name
		bottom_badge_label.text = white_badge if bottom_is_white else black_badge
		bottom_avatar_icon.texture = white_avatar if bottom_is_white else black_avatar

	# Setiap elemen latar depan diturunkan dari formula kontras WCAG, bukan
	# konstanta warna: kartu Putih berlatar terang, kartu Hitam berlatar gelap.
	_apply_card_palette(true, top_is_white)
	_apply_card_palette(false, bottom_is_white)

	_update_card_mate_state(true, top_mate_badge, top_mate_label, top_is_white, current_is_mate, current_mate_in)
	_update_card_mate_state(false, bottom_mate_badge, bottom_mate_label, bottom_is_white, current_is_mate, current_mate_in)

	# Update captured pieces dan material point advantage (gaya Chess.com)
	if board_state != null:
		var mat_data = ChessBoardState.calculate_material_and_captured(board_state)
		var white_adv = int(mat_data.get("white_advantage", 0))
		var black_cap = mat_data.get("black_captured", [])
		var white_cap = mat_data.get("white_captured", [])

		var top_container = top_captured_container
		var bottom_container = bottom_captured_container

		if top_is_white:
			_render_captured_section(top_container, black_cap, ChessTypes.PieceColor.BLACK, white_adv, true, CardPalette.card_bg(true))
			_render_captured_section(bottom_container, white_cap, ChessTypes.PieceColor.WHITE, -white_adv, false, CardPalette.card_bg(false))
		else:
			_render_captured_section(top_container, white_cap, ChessTypes.PieceColor.WHITE, -white_adv, true, CardPalette.card_bg(false))
			_render_captured_section(bottom_container, black_cap, ChessTypes.PieceColor.BLACK, white_adv, false, CardPalette.card_bg(true))
	else:
		_clear_captured_section(top_captured_container, true)
		_clear_captured_section(bottom_captured_container, false)

## Terapkan palet kartu pemain: latar terang untuk pemain Putih, gelap untuk
## Hitam, dan seluruh latar depan melewati formula kontras sehingga teks terang
## tidak pernah jatuh di atas latar terang.
func _apply_card_palette(is_top: bool, is_white_card: bool) -> void:
	var bg = CardPalette.card_bg(is_white_card)
	var border = CardPalette.card_border(bg)
	var style = top_card_style if is_top else bottom_card_style
	var pulse_color = current_top_pulse_color if is_top else current_bottom_pulse_color
	var is_pulsing = pulse_color != Color.TRANSPARENT

	if is_top:
		_top_card_base_border = border
	else:
		_bottom_card_base_border = border

	if style != null:
		style.bg_color = bg
		if not is_pulsing:
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

func _set_card_pulsing(is_top: bool, should_pulse: bool, pulse_color: Color = Color.WHITE) -> void:
	var style = top_card_style if is_top else bottom_card_style
	var active_tween = top_pulse_tween if is_top else bottom_pulse_tween
	var last_color = current_top_pulse_color if is_top else current_bottom_pulse_color

	if style == null:
		return

	if not should_pulse:
		if is_top:
			current_top_pulse_color = Color.TRANSPARENT
		else:
			current_bottom_pulse_color = Color.TRANSPARENT

		if active_tween and active_tween.is_valid():
			active_tween.kill()
		if is_top:
			top_pulse_tween = null
		else:
			bottom_pulse_tween = null

		style.border_width_left = 1
		style.border_width_top = 1
		style.border_width_right = 1
		style.border_width_bottom = 1
		style.border_color = _top_card_base_border if is_top else _bottom_card_base_border
		style.shadow_size = 0
		style.shadow_color = Color.TRANSPARENT
		return

	if active_tween and active_tween.is_valid() and last_color == pulse_color:
		return

	if is_top:
		current_top_pulse_color = pulse_color
	else:
		current_bottom_pulse_color = pulse_color

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2

	var col_peak = Color(pulse_color.r, pulse_color.g, pulse_color.b, 1.0)
	var col_low = Color(pulse_color.r, pulse_color.g, pulse_color.b, 0.2)
	style.shadow_color = Color(pulse_color.r, pulse_color.g, pulse_color.b, 0.45)

	var tw = create_tween().set_loops()
	tw.tween_property(style, "border_color", col_peak, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(style, "shadow_size", 8, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(style, "border_color", col_low, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(style, "shadow_size", 0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if is_top:
		top_pulse_tween = tw
	else:
		bottom_pulse_tween = tw

func _update_card_mate_state(is_top: bool, badge_node: PanelContainer, label_node: Label, is_white_card: bool, is_mate: bool, mate_in: int) -> void:
	var n = abs(mate_in)
	var is_valid_mate = is_game_active and is_mate and (n > 0)

	if not is_valid_mate:
		if badge_node:
			badge_node.visible = false
		_set_card_pulsing(is_top, false)
		return

	var white_has_mate = (mate_in > 0)
	var card_has_mate = (white_has_mate == is_white_card)

	if not card_has_mate:
		if badge_node:
			badge_node.visible = false
		_set_card_pulsing(is_top, false)
		return

	# Tentukan warna pulsating & badge
	var pulse_color: Color
	if game_mode == "vs_ai":
		var p_is_white = (GameSettings.player_color == ChessTypes.PieceColor.WHITE)
		var is_player_card = (is_white_card == p_is_white)
		if is_player_card:
			# Player checkmate in N moves -> Hijau
			pulse_color = MATE_PULSE_GREEN
		else:
			# Opponent mate in N (Player terancam checkmate) -> Merah
			pulse_color = MATE_PULSE_RED
	else:
		# Player vs Player -> Hijau
		pulse_color = MATE_PULSE_GREEN

	# Badge mate memakai palet kartu sebagai turunan formula: pada kartu terang
	# hijau/merah digelapkan sampai memenuhi ambang WCAG, pada kartu gelap
	# warnanya dipertahankan apa adanya.
	var card_bg = CardPalette.card_bg(is_white_card)
	var badge_bg = card_bg.lerp(pulse_color, 0.14)
	badge_bg.a = 0.95
	var badge_ink = CardPalette.accent(pulse_color, badge_bg, CardPalette.AA_TEXT)
	var badge_border = CardPalette.accent(pulse_color, card_bg, CardPalette.AA_LARGE)

	_set_card_pulsing(is_top, true, badge_border)

	if badge_node and label_node:
		var text_str = "Mate in 1!" if n == 1 else "Mate in %d!" % n
		label_node.text = text_str
		label_node.add_theme_color_override("font_color", badge_ink)

		var icon = badge_node.get_node_or_null("MateHBox/Icon")
		if icon:
			icon.modulate = badge_ink

		var sb = badge_node.get_theme_stylebox("panel")
		if sb is StyleBoxFlat:
			var dup = sb.duplicate() as StyleBoxFlat
			dup.border_color = Color(badge_border.r, badge_border.g, badge_border.b, 0.9)
			dup.bg_color = badge_bg
			badge_node.add_theme_stylebox_override("panel", dup)

		badge_node.visible = true

func _on_open_painter_pressed() -> void:
	chess_painter_layer.visible = true

func _on_painter_play_position(fen: String, mode: String) -> void:
	chess_painter_layer.visible = false
	start_new_game(fen, mode)

func _set_status(msg: String) -> void:
	if status_label:
		status_label.text = msg

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_command_or_control_pressed():
			if event.keycode == KEY_Z and not event.shift_pressed:
				undo_move()
				get_viewport().set_input_as_handled()
				return
			elif event.keycode == KEY_Y or (event.keycode == KEY_Z and event.shift_pressed):
				redo_move()
				get_viewport().set_input_as_handled()
				return

	var is_cancel = event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE)
	if is_cancel:
		if chess_painter_layer != null and chess_painter_layer.visible:
			_on_painter_back()
			get_viewport().set_input_as_handled()
		elif is_paused:
			resume_game()
			get_viewport().set_input_as_handled()
		else:
			pause_game()
			get_viewport().set_input_as_handled()

func pause_game() -> void:
	if is_paused:
		return
	is_paused = true
	chess_board.is_interactive = false
	chess_board.set_process_input(false)
	engine_service.stop_analysis()
	pause_menu_layer.visible = true
	pause_menu.show_pause(is_game_active)
	_update_undo_redo_ui()

func resume_game() -> void:
	if not is_paused:
		return
	is_paused = false
	pause_menu.hide_pause()
	pause_menu_layer.visible = false
	_update_undo_redo_ui()

	if not is_game_active or board_state == null:
		return

	chess_board.set_process_input(true)
	var player_c = GameSettings.player_color
	if game_mode == "vs_ai" and board_state.turn != player_c:
		chess_board.is_interactive = false
		_set_status("AI is thinking...")
		_set_ai_thinking_hud()
		_request_bot_move()
	else:
		chess_board.is_interactive = true
		engine_service.analyze_position(board_state.to_fen())

func _on_pause_button_pressed() -> void:
	if is_paused:
		resume_game()
	else:
		pause_game()

func _on_pause_resume() -> void:
	resume_game()

func _on_pause_restart() -> void:
	resume_game()
	start_new_game(ChessBoardState.DEFAULT_FEN, game_mode)

func _on_pause_resign() -> void:
	resume_game()
	_on_resign_pressed()

func _on_pause_main_menu() -> void:
	engine_service.stop_analysis()
	get_tree().change_scene_to_file("res://src/ui/menu/main_menu.tscn")

func _on_game_over_rematch() -> void:
	if game_over_layer:
		game_over_layer.visible = false
	start_new_game(ChessBoardState.DEFAULT_FEN, game_mode)

func _on_game_over_review() -> void:
	if game_over_layer:
		game_over_layer.visible = false
	start_game_review()

func _setup_tactile_tab_effect(btn: Button) -> void:
	if not btn:
		return
	var pressed_offset = 2.0
	btn.button_down.connect(func():
		btn.position.y += pressed_offset
	)
	var reset_fn = func():
		btn.position.y = 0.0
	btn.button_up.connect(reset_fn)
	btn.mouse_exited.connect(reset_fn)

## Tab Engine & Assist hanya berguna selama pertandingan berjalan. Setelah game
## berakhir tidak ada lagi posisi yang perlu dianalisis mesin, jadi tombolnya
## disembunyikan sampai game baru dimulai. Indeks TabContainer sengaja tidak
## diubah karena perpindahan tab dikendalikan HUDTabBar kustom.
func _set_engine_tab_available(available: bool) -> void:
	if btn_tab_engine:
		btn_tab_engine.visible = available
		btn_tab_engine.disabled = not available
	if available:
		return
	if hud_tab_container != null and hud_tab_container.current_tab == 1:
		hud_tab_container.current_tab = 0
		_update_hud_tab_bar_styles(0)

func _update_hud_tab_bar_styles(active_tab: int) -> void:
	if btn_tab_moves:
		TactileStyles.apply_tactile_button(btn_tab_moves, false, active_tab == 0)
	if btn_tab_engine:
		TactileStyles.apply_tactile_button(btn_tab_engine, false, active_tab == 1)
	if btn_tab_review:
		TactileStyles.apply_tactile_button(btn_tab_review, false, active_tab == 2)

func select_hud_tab(tab: int) -> void:
	if tab == 2:
		# Guard B1: Jangan matikan game aktif saat game masih berlangsung
		if is_game_active and board_state != null and not ChessMoveGenerator.is_game_over(board_state):
			_set_status("Game is currently active. Finish or resign to view Game Review.")
			_update_hud_tab_bar_styles(hud_tab_container.current_tab if hud_tab_container else 0)
			return

		if hud_tab_container:
			hud_tab_container.current_tab = 2
		if hud_tab_bar:
			hud_tab_bar.visible = false
		_update_hud_tab_bar_styles(2)

		if game_controls:
			game_controls.visible = false
		if engine_status_row:
			engine_status_row.visible = false
		if engine_progress_bar:
			engine_progress_bar.visible = false
		if status_panel:
			status_panel.visible = false

		if not is_review_mode:
			start_game_review()
	else:
		if hud_tab_container:
			hud_tab_container.current_tab = tab
		if hud_tab_bar:
			hud_tab_bar.visible = true
		_update_hud_tab_bar_styles(tab)

		if not is_review_mode:
			if game_controls:
				game_controls.visible = true
			if engine_status_row:
				engine_status_row.visible = true
			if engine_progress_bar:
				engine_progress_bar.visible = true
			if status_panel:
				status_panel.custom_minimum_size = Vector2(0, 68)

func _on_hud_tab_changed(tab: int) -> void:
	_update_hud_tab_bar_styles(tab)
	if tab == 2:
		if not is_review_mode and (not is_game_active or (board_state != null and ChessMoveGenerator.is_game_over(board_state))):
			start_game_review()

func _on_review_settings_requested() -> void:
	if review_settings_layer:
		review_settings_layer.visible = true
	if review_settings_dialog:
		review_settings_dialog.open_dialog()

func _on_review_settings_applied(should_reanalyze: bool) -> void:
	if review_settings_layer:
		review_settings_layer.visible = false
	if should_reanalyze and is_review_mode:
		start_game_review()

func _on_review_settings_closed() -> void:
	if review_settings_layer:
		review_settings_layer.visible = false

func start_game_review() -> void:
	is_review_mode = true
	is_game_active = false
	last_reviewed_step_index = -1
	engine_service.stop_analysis()
	if game_controls:
		game_controls.visible = false
	if engine_status_row:
		engine_status_row.visible = false
	if engine_progress_bar:
		engine_progress_bar.visible = false
	if status_panel:
		status_panel.visible = false
	if hud_tab_container:
		hud_tab_container.current_tab = 2
	if hud_tab_bar:
		hud_tab_bar.visible = false
	_update_hud_tab_bar_styles(2)
	_set_status("Game Review - Analyzing match with Stockfish...")
	if game_review_panel:
		game_review_panel.reset_view()
		game_review_panel.set_analysis_progress(0, state_history.size())
	if game_review_service:
		game_review_service.start_batch_analysis(state_history)

func _on_review_analysis_progress(current_step: int, total_steps: int) -> void:
	if game_review_panel:
		game_review_panel.set_analysis_progress(current_step, total_steps)

func _on_review_position_evaluated(ply: int, eval_white_cp: int, is_mate: bool, mate_in: int) -> void:
	if game_review_panel:
		game_review_panel.append_graph_point(ply, eval_white_cp, is_mate, mate_in)

func _on_review_completed(review_data: Dictionary) -> void:
	_set_status("Game Review - Analysis Ready")
	# Posisi awal game review: pastikan board berada di posisi awal game tanpa move apa pun
	var initial_fen = ChessBoardState.DEFAULT_FEN
	if not state_history.is_empty():
		initial_fen = state_history[0].get("fen", ChessBoardState.DEFAULT_FEN)
	board_state = ChessBoardState.new(initial_fen)
	chess_board.setup_board(board_state, GameSettings.is_flipped)
	chess_board.clear_review_badge()
	chess_board.update_arrows([], [])
	chess_board.is_interactive = false
	last_reviewed_step_index = -1
	is_showing_best_move_active = false
	eval_bar.set_eval(0, false, 0)

	if game_review_panel:
		game_review_panel.set_review_data(review_data)

func _play_review_move_sfx(state: ChessBoardState, is_cap: bool, is_castle: bool, is_promo: bool) -> void:
	if state != null:
		if ChessMoveGenerator.is_checkmate(state):
			AudioService.play_checkmate()
			return
		elif ChessMoveGenerator.is_in_check(state, state.turn):
			AudioService.play_check()
			return
	if is_castle:
		AudioService.play_castle()
	elif is_promo:
		AudioService.play_promote()
	elif is_cap:
		AudioService.play_capture()
	else:
		AudioService.play_move()

func _on_review_move_selected(step_index: int) -> void:
	if game_review_panel == null or chess_board == null:
		return
	var steps = game_review_panel.review_steps
	var prev_idx = last_reviewed_step_index
	last_reviewed_step_index = step_index

	# Skenario 1: Kembali ke Posisi Awal Permainan (Start Position, sebelum move apa pun)
	if step_index == -1:
		is_showing_best_move_active = false
		chess_board.clear_review_badge()
		chess_board.update_arrows([], [])
		eval_bar.set_eval(0, false, 0)
		_set_status("Game Review - Start Position")

		var initial_fen = ChessBoardState.DEFAULT_FEN
		if not state_history.is_empty():
			initial_fen = state_history[0].get("fen", ChessBoardState.DEFAULT_FEN)
		elif not steps.is_empty():
			initial_fen = steps[0].get("prev_fen", ChessBoardState.DEFAULT_FEN)

		# Jika mundur sekuensial 1 langkah dari step 0 ke -1: animasikan undo
		if prev_idx == 0 and not steps.is_empty():
			var step_0 = steps[0]
			var from_sq = step_0.get("from_sq", "")
			var to_sq = step_0.get("to_sq", "")
			var is_castle = (from_sq in ["e1", "e8"] and to_sq in ["c1", "g1", "c8", "g8"])
			board_state = ChessBoardState.new(initial_fen)
			chess_board.animate_undo_move({
				"from_sq": from_sq,
				"to_sq": to_sq,
				"is_castle": is_castle,
				"is_ep": step_0.get("is_ep", false),
				"promo": step_0.get("promo", ChessTypes.PieceType.NONE)
			}, board_state)
			AudioService.play_move()
		else:
			board_state = ChessBoardState.new(initial_fen)
			chess_board.setup_board(board_state, GameSettings.is_flipped)

		chess_board.is_interactive = false
		_update_player_cards(false, 0)
		return

	# Skenario 2: step_index >= 0 (langkah 0 .. steps.size() - 1)
	if step_index < 0 or step_index >= steps.size():
		return
	var step_data = steps[step_index]
	var fen_after = step_data.get("fen_after", "")
	var prev_fen = step_data.get("prev_fen", step_data.get("fen_before", ""))
	if prev_fen.is_empty():
		prev_fen = ChessBoardState.DEFAULT_FEN

	# CRITICAL BUG FIX: Reset bidak Show Best Move dari papan jika aktif sebelumnya!
	var was_showing_best = is_showing_best_move_active
	is_showing_best_move_active = false
	if was_showing_best:
		chess_board.setup_board(ChessBoardState.new(prev_fen), GameSettings.is_flipped)
		chess_board.update_arrows([], [])

	# Badge klasifikasi langkah tujuan dipasang SETELAH animasi selesai. Alasannya:
	# finalize_undo di ChessBoard selalu memanggil setup_board() sehingga memasang badge
	# secara sinkron membuat badge tampil sesaat lalu hilang saat menekan Previous Move.
	var final_to_sq = step_data.get("to_sq", "")
	var final_classification = step_data.get("classification", -1)
	var badge_deferred = false

	# Lepas badge langkah terdahulu agar tidak tertinggal di papan selama animasi transisi.
	chess_board.clear_review_badge()

	if not fen_after.is_empty():
		# Maju 1 langkah sekuensial (termasuk dari -1 ke 0, atau i ke i+1)
		if step_index == prev_idx + 1:
			var from_sq = step_data.get("from_sq", "")
			var to_sq = step_data.get("to_sq", "")
			var promo = step_data.get("promo", ChessTypes.PieceType.NONE)
			var is_ep = step_data.get("is_ep", false)
			var is_cap = is_ep
			if not prev_fen.is_empty():
				var prev_board = ChessBoardState.new(prev_fen)
				is_cap = is_cap or prev_board.get_piece(to_sq) != null
			var is_castle = (from_sq in ["e1", "e8"] and to_sq in ["c1", "g1", "c8", "g8"])
			board_state = ChessBoardState.new(fen_after)
			chess_board.animate_move(
				{"from": from_sq, "to": to_sq},
				board_state,
				is_cap,
				is_castle,
				is_ep,
				promo,
				func(): _apply_review_badge(final_to_sq, final_classification),
				func(): _play_review_move_sfx(board_state, is_cap, is_castle, promo != ChessTypes.PieceType.NONE)
			)
			badge_deferred = true
		# Mundur (undo) 1 langkah sekuensial
		elif step_index == prev_idx - 1 and prev_idx < steps.size():
			var prev_step_data = steps[prev_idx]
			var from_sq = prev_step_data.get("from_sq", "")
			var to_sq = prev_step_data.get("to_sq", "")
			var is_castle = (from_sq in ["e1", "e8"] and to_sq in ["c1", "g1", "c8", "g8"])
			board_state = ChessBoardState.new(fen_after)
			chess_board.animate_undo_move(
				{
					"from_sq": from_sq,
					"to_sq": to_sq,
					"is_castle": is_castle,
					"is_ep": prev_step_data.get("is_ep", false),
					# Promosi wajib diteruskan: tanpa ini perwira hasil promosi ikut mundur
					# sebagai perwira, bukan dirender ulang sebagai pion.
					"promo": prev_step_data.get("promo", ChessTypes.PieceType.NONE)
				},
				board_state,
				func(): _apply_review_badge(final_to_sq, final_classification)
			)
			AudioService.play_move()
			badge_deferred = true
		# Lompatan non-sekuensial -> Setup langsung
		else:
			board_state = ChessBoardState.new(fen_after)
			chess_board.setup_board(board_state, GameSettings.is_flipped)
			var jump_to_sq = step_data.get("to_sq", "")
			var jump_from_sq = step_data.get("from_sq", "")
			var jump_is_ep = step_data.get("is_ep", false)
			var jump_is_cap = jump_is_ep
			if not prev_fen.is_empty():
				jump_is_cap = jump_is_cap or ChessBoardState.new(prev_fen).get_piece(jump_to_sq) != null
			var jump_is_castle = (jump_from_sq in ["e1", "e8"] and jump_to_sq in ["c1", "g1", "c8", "g8"])
			var jump_promo = step_data.get("promo", ChessTypes.PieceType.NONE)
			_play_review_move_sfx(board_state, jump_is_cap, jump_is_castle, jump_promo != ChessTypes.PieceType.NONE)

		chess_board.is_interactive = false

	if not badge_deferred:
		_apply_review_badge(final_to_sq, final_classification)
	chess_board.update_arrows([], [])
	
	# B3 Fix: Evaluasi selalu dinilai dari perspektif White untuk bar
	var eval_white = step_data.get("eval_white_cp", step_data.get("eval_after", 0))
	var is_mate_after = step_data.get("is_mate_after", false)
	var mate_in_after = step_data.get("mate_in_after", 0)
	eval_bar.set_eval(eval_white, is_mate_after, mate_in_after)
	
	var full_notation = step_data.get("full_notation", "")
	if full_notation.is_empty():
		full_notation = step_data.get("san", "")
	_set_status("Review: %s (%s)" % [full_notation, GameReviewService.classification_to_string(final_classification)])
	_update_player_cards(is_mate_after, mate_in_after)

func _apply_review_badge(target_square: String, classification: int) -> void:
	if target_square.is_empty() or chess_board == null or not is_instance_valid(chess_board):
		return
	chess_board.set_review_badge(target_square, classification)

func _on_review_show_best_move(step_index: int, best_move_uci: String, is_showing: bool = true) -> void:
	if game_review_panel == null or chess_board == null:
		return
	var steps = game_review_panel.review_steps
	if step_index < 0 or step_index >= steps.size():
		return
	var step_data = steps[step_index]

	var prev_fen = step_data.get("prev_fen", step_data.get("fen_before", ""))
	if prev_fen.is_empty():
		prev_fen = ChessBoardState.DEFAULT_FEN
	var fen_after = step_data.get("fen_after", "")
	var played_from = step_data.get("from_sq", step_data.get("from", ""))
	var played_to = step_data.get("to_sq", step_data.get("to", ""))
	var played_is_castle = step_data.get("is_castle", false)
	var played_is_ep = step_data.get("is_ep", false)
	var played_promo = step_data.get("promo", ChessTypes.PieceType.NONE)
	var classification = step_data.get("classification", -1)

	if is_showing:
		is_showing_best_move_active = true
		if best_move_uci.length() < 4:
			return

		var best_from = best_move_uci.substr(0, 2)
		var best_to = best_move_uci.substr(2, 2)
		var best_promo_char = best_move_uci.substr(4, 1) if best_move_uci.length() > 4 else ""
		var promo_type = ChessTypes.san_char_to_piece_type(best_promo_char.to_upper()) if not best_promo_char.is_empty() else ChessTypes.PieceType.NONE

		# Bersihkan badge dan arrow terdahulu sebelum animasi mundur
		chess_board.clear_review_badge()
		chess_board.update_arrows([], [])

		var pre_board = ChessBoardState.new(prev_fen)

		# Langkah 1: Piece yang bukan best move memainkan animasi mundur terlebih dahulu ke petak sebelumnya
		var undo_info = {
			"from_sq": played_from,
			"to_sq": played_to,
			"is_castle": played_is_castle,
			"is_ep": played_is_ep,
			"promo": played_promo
		}

		chess_board.animate_undo_move(
			undo_info,
			pre_board,
			func():
				# Langkah 2: Setelah selesai mundur, best move melakukan animasi melangkah maju
				var is_cap = pre_board.get_piece(best_to) != null
				var is_castle = (best_from in ["e1", "e8"] and best_to in ["c1", "g1", "c8", "g8"] and pre_board.get_piece(best_from) != null and pre_board.get_piece(best_from)["type"] == ChessTypes.PieceType.KING)
				var best_move_obj = ChessMove.new(best_from, best_to, promo_type)
				var target_state = ChessBoardState.new(prev_fen)
				ChessMoveGenerator.apply_move_unchecked(target_state, best_move_obj)

				board_state = target_state
				chess_board.animate_move(
					{"from": best_from, "to": best_to},
					target_state,
					is_cap,
					is_castle,
					false,
					promo_type,
					Callable(),
					func(): _play_review_move_sfx(target_state, is_cap, is_castle, promo_type != ChessTypes.PieceType.NONE)
				)
				chess_board.update_arrows([{ "from": best_from, "to": best_to, "color": Color(0.15, 0.85, 0.45, 0.9) }], [])
				chess_board.set_review_badge(best_to, GameReviewService.Classification.BEST)
				_set_status("Best Move: %s -> %s" % [best_from, best_to])
		)
		AudioService.play_move()
	else:
		is_showing_best_move_active = false
		# Toggle kembali ke Played Move
		chess_board.clear_review_badge()
		chess_board.update_arrows([], [])

		if best_move_uci.length() >= 4 and not fen_after.is_empty() and not played_from.is_empty():
			var best_from = best_move_uci.substr(0, 2)
			var best_to = best_move_uci.substr(2, 2)
			var best_promo_char = best_move_uci.substr(4, 1) if best_move_uci.length() > 4 else ""
			var promo_type = ChessTypes.san_char_to_piece_type(best_promo_char.to_upper()) if not best_promo_char.is_empty() else ChessTypes.PieceType.NONE
			var pre_board = ChessBoardState.new(prev_fen)
			var is_best_castle = (best_from in ["e1", "e8"] and best_to in ["c1", "g1", "c8", "g8"] and pre_board.get_piece(best_from) != null and pre_board.get_piece(best_from)["type"] == ChessTypes.PieceType.KING)

			# Animasikan mundur best move ke petak asal
			chess_board.animate_undo_move(
				{
					"from_sq": best_from,
					"to_sq": best_to,
					"is_castle": is_best_castle,
					"promo": promo_type
				},
				pre_board,
				func():
					# Lalu animasikan maju played move
					var played_state = ChessBoardState.new(fen_after)
					var is_cap = pre_board.get_piece(played_to) != null
					board_state = played_state
					chess_board.animate_move(
						{"from": played_from, "to": played_to},
						played_state,
						is_cap,
						played_is_castle,
						played_is_ep,
						played_promo,
						Callable(),
						func(): _play_review_move_sfx(played_state, is_cap, played_is_castle, played_promo != ChessTypes.PieceType.NONE)
					)
					chess_board.set_review_badge(played_to, classification)
			)
			AudioService.play_move()
		else:
			if not fen_after.is_empty():
				board_state = ChessBoardState.new(fen_after)
				chess_board.setup_board(board_state, GameSettings.is_flipped)
			chess_board.set_review_badge(played_to, classification)

		var full_notation = step_data.get("full_notation", "")
		if full_notation.is_empty():
			full_notation = step_data.get("san", "")
		_set_status("Review: %s (%s)" % [full_notation, GameReviewService.classification_to_string(classification)])

func _on_review_retry_mode(step_index: int, prev_fen: String, best_move_uci: String) -> void:
	is_showing_best_move_active = false
	if chess_board:
		board_state = ChessBoardState.new(prev_fen)
		chess_board.setup_board(board_state, GameSettings.is_flipped)
		chess_board.clear_review_badge()
		chess_board.update_arrows([], [])
		chess_board.is_interactive = true
	AudioService.play_move()
	_set_status("Retry Mode - Find the Best Move on the board!")

func _on_review_closed() -> void:
	if review_settings_layer:
		review_settings_layer.visible = false
	is_review_mode = false
	is_showing_best_move_active = false
	last_reviewed_step_index = -1
	if status_panel:
		status_panel.visible = true
		status_panel.custom_minimum_size = Vector2(0, 68)
	if game_review_panel:
		game_review_panel.reset_view()
	if chess_board:
		chess_board.clear_review_badge()
		chess_board.update_arrows([], [])
		chess_board.is_interactive = false
		# B10 Fix: Kembalikan posisi papan ke posisi akhir permainan
		if not state_history.is_empty():
			var target_idx = clampi(history_index, 0, state_history.size() - 1)
			var last_item = state_history[target_idx]
			var end_fen = last_item.get("fen", ChessBoardState.DEFAULT_FEN)
			board_state = ChessBoardState.new(end_fen)
			chess_board.setup_board(board_state, GameSettings.is_flipped)
	if hud_tab_bar:
		hud_tab_bar.visible = true
	AudioService.play_move()
	select_hud_tab(0)
	_update_player_cards(false, 0)
	_set_status("Review Closed - Match Overview")

func _on_game_over_closed() -> void:
	if game_over_layer:
		game_over_layer.visible = false
	_set_status("Board View - Game Over")

func _on_painter_back() -> void:
	chess_painter_layer.visible = false
	if GameSettings.open_painter_on_launch:
		GameSettings.open_painter_on_launch = false
		get_tree().change_scene_to_file("res://src/ui/menu/main_menu.tscn")
