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
const CapturedPiecesView = preload("res://src/ui/hud/captured_pieces_view.gd")
const GameSettings = preload("res://src/config/game_settings.gd")

const MAIN_MENU_SCENE = "res://src/ui/menu/main_menu.tscn"
const ICON_ROBOT = preload("res://assets/ui/icons/icon_robot.svg")
const ICON_PERSON = preload("res://assets/ui/icons/icon_person.svg")
const ICON_TARGET = preload("res://assets/ui/icons/icon_target.svg")
const ICON_CHECKMARK = preload("res://assets/ui/icons/icon_checkmark.svg")

# UI Nodes
@onready var btn_back: Button = $CenterContainer/MainLayout/TopBar/BtnBack
@onready var opt_repertoire: OptionButton = $CenterContainer/MainLayout/TopBar/OptRepertoire
@onready var header_card: PanelContainer = $CenterContainer/MainLayout/HeaderCard
@onready var repertoire_title_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/RepertoireTitleLabel
@onready var repertoire_meta_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/RepertoireMetaLabel
@onready var mastery_progress_bar: ProgressBar = $CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryProgressBar
@onready var mastery_percent_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryPercentLabel
@onready var mode_chip: PanelContainer = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/ModeChip
@onready var mode_badge_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/ModeChip/ModeBadgeLabel
@onready var due_chip: PanelContainer = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/DueChip
@onready var due_badge_label: Label = $CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/DueChip/DueBadgeLabel

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

@onready var btn_hint: Button = $CenterContainer/MainLayout/ControlsBar/BtnHint
@onready var btn_retry: Button = $CenterContainer/MainLayout/ControlsBar/BtnRetry
@onready var btn_prev_line: Button = $CenterContainer/MainLayout/ControlsBar/BtnPrevLine
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
var top_card_style: StyleBoxFlat = null
var bottom_card_style: StyleBoxFlat = null
var coach_card_style: StyleBoxFlat = null
var mode_chip_style: StyleBoxFlat = null
var _last_top_captured_key: String = ""
var _last_bottom_captured_key: String = ""

func _ready() -> void:
	_ensure_nodes()
	_init_card_styles()
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
		repertoire_title_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/RepertoireTitleLabel")
	if repertoire_title_label == null:
		repertoire_title_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/RepertoireTitleLabel")
	if repertoire_meta_label == null:
		repertoire_meta_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/TitleCol/RepertoireMetaLabel")
	if repertoire_meta_label == null:
		repertoire_meta_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/RepertoireMetaLabel")
	if mastery_progress_bar == null:
		mastery_progress_bar = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryProgressBar")
	if mastery_percent_label == null:
		mastery_percent_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/ProgressHBox/MasteryPercentLabel")
	if mode_chip == null:
		mode_chip = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/ModeChip")
	if mode_badge_label == null:
		mode_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/ModeChip/ModeBadgeLabel")
	if mode_badge_label == null:
		mode_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/ModeBadgeLabel")
	if due_chip == null:
		due_chip = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/DueChip")
	if due_badge_label == null:
		due_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/TopRow/MetaRow/DueChip/DueBadgeLabel")
	if due_badge_label == null:
		due_badge_label = get_node_or_null("CenterContainer/MainLayout/HeaderCard/VBox/MetaRow/DueBadgeLabel")

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
	if chess_board == null:
		chess_board = get_node_or_null("CenterContainer/MainLayout/BoardCenter/ChessBoard")

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
	if status_label == null:
		status_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusLabel")
	if step_badge_label == null:
		step_badge_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/StatusRow/StepBadgeLabel")
	if blurb_label == null:
		blurb_label = get_node_or_null("CenterContainer/MainLayout/CoachCard/VBox/BlurbLabel")

	if btn_hint == null:
		btn_hint = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnHint")
	if btn_hint == null:
		btn_hint = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnHint")
	if btn_retry == null:
		btn_retry = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnRetry")
	if btn_retry == null:
		btn_retry = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnRetry")
	if btn_prev_line == null:
		btn_prev_line = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnPrevLine")
	if btn_prev_line == null:
		btn_prev_line = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnPrevLine")
	if btn_next_line == null:
		btn_next_line = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnNextLine")
	if btn_next_line == null:
		btn_next_line = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnNextLine")
	if btn_mode_toggle == null:
		btn_mode_toggle = get_node_or_null("CenterContainer/MainLayout/ControlsBar/BtnModeToggle")
	if btn_mode_toggle == null:
		btn_mode_toggle = get_node_or_null("CenterContainer/MainLayout/ControlsCard/ControlsBar/BtnModeToggle")

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
	if mode_chip:
		var sb_mode = mode_chip.get_theme_stylebox("panel")
		mode_chip_style = (sb_mode.duplicate() if sb_mode is StyleBoxFlat else StyleBoxFlat.new()) as StyleBoxFlat
		mode_chip.add_theme_stylebox_override("panel", mode_chip_style)

	for icon_node in [top_avatar_icon, bottom_avatar_icon, coach_avatar]:
		if icon_node != null:
			icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _apply_tactile_styles() -> void:
	if btn_back:
		TactileStyles.apply_tactile_button(btn_back, false, false, true)
	if btn_hint:
		TactileStyles.apply_tactile_button(btn_hint, false, hint_used_on_step, false)
		btn_hint.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.65))
	if btn_retry:
		TactileStyles.apply_tactile_button(btn_retry, false, false, false)
		btn_retry.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.65))
	if btn_prev_line:
		TactileStyles.apply_tactile_button(btn_prev_line, false, false, false)
		btn_prev_line.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.65))
	if btn_next_line:
		TactileStyles.apply_tactile_button(btn_next_line, true, false, false)
		btn_next_line.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.65))
	if btn_mode_toggle:
		TactileStyles.apply_tactile_button(btn_mode_toggle, false, is_drill_mode, false)
		btn_mode_toggle.add_theme_color_override("font_disabled_color", Color(0.72, 0.70, 0.67, 0.65))

func _connect_signals() -> void:
	if btn_back and not btn_back.pressed.is_connected(_on_back_pressed):
		btn_back.pressed.connect(_on_back_pressed)
	if opt_repertoire and not opt_repertoire.item_selected.is_connected(_on_repertoire_selected):
		opt_repertoire.item_selected.connect(_on_repertoire_selected)
	if btn_hint and not btn_hint.pressed.is_connected(_on_hint_pressed):
		btn_hint.pressed.connect(_on_hint_pressed)
	if btn_retry and not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)
	if btn_prev_line and not btn_prev_line.pressed.is_connected(_on_prev_line_pressed):
		btn_prev_line.pressed.connect(_on_prev_line_pressed)
	if btn_next_line and not btn_next_line.pressed.is_connected(_on_next_line_pressed):
		btn_next_line.pressed.connect(_on_next_line_pressed)
	if btn_mode_toggle and not btn_mode_toggle.pressed.is_connected(_on_mode_toggle_pressed):
		btn_mode_toggle.pressed.connect(_on_mode_toggle_pressed)
	if chess_board and not chess_board.move_made.is_connected(_on_board_move_made):
		chess_board.move_made.connect(_on_board_move_made)
	if is_inside_tree():
		var gs = get_node_or_null("/root/GameSettings")
		if gs:
			if gs.has_signal("settings_changed") and not gs.settings_changed.is_connected(_on_settings_changed):
				gs.settings_changed.connect(_on_settings_changed)
			if gs.has_signal("piece_set_changed") and not gs.piece_set_changed.is_connected(_on_piece_set_changed):
				gs.piece_set_changed.connect(_on_piece_set_changed)

func _on_piece_set_changed(_p: String) -> void:
	_on_settings_changed()

func _on_settings_changed() -> void:
	CapturedPiecesView.clear_texture_cache()
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	if chess_board and board_state:
		var prev_last_move = chess_board.last_move.duplicate()
		chess_board.setup_board(board_state, is_flipped)
		if not prev_last_move.is_empty():
			chess_board.set_last_move(prev_last_move.get("from", ""), prev_last_move.get("to", ""))
	_update_player_cards()

func _get_active_piece_set() -> String:
	if is_inside_tree():
		var gs = get_node_or_null("/root/GameSettings")
		if gs and not str(gs.piece_set).is_empty():
			return str(gs.piece_set)
	return "cburnett"

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

func _update_player_cards() -> void:
	var top_is_white = is_flipped
	var bottom_is_white = not is_flipped

	var eco_str = current_tree.eco if current_tree != null else ""
	var opp_side_badge = "White" if top_is_white else "Black"
	if not eco_str.is_empty():
		opp_side_badge = "%s (%s)" % [opp_side_badge, eco_str]
	var player_side_badge = "White" if bottom_is_white else "Black"

	if top_name_label:
		top_name_label.text = "Trainer Bot"
	if top_badge_label:
		top_badge_label.text = opp_side_badge
	if top_avatar_icon:
		top_avatar_icon.texture = ICON_ROBOT

	if bottom_name_label:
		bottom_name_label.text = "Player (You)"
	if bottom_badge_label:
		bottom_badge_label.text = player_side_badge
	if bottom_avatar_icon:
		bottom_avatar_icon.texture = ICON_PERSON

	_apply_card_palette(true, top_is_white)
	_apply_card_palette(false, bottom_is_white)

	if board_state != null:
		var mat_data = ChessBoardState.calculate_material_and_captured(board_state)
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
		repertoire_meta_label.text = "%s  |  Playing as %s  |  %d Variations  |  %d Key Positions" % [
			current_tree.eco,
			side_name,
			current_tree.get_total_lines(),
			current_tree.get_total_player_moves()
		]
	if mode_badge_label:
		mode_badge_label.text = "MODE: DRILL" if is_drill_mode else "MODE: LEARN"
		var mode_col = Color(0.95, 0.80, 0.40, 1) if is_drill_mode else Color(0.55, 0.82, 0.36, 1)
		mode_badge_label.add_theme_color_override("font_color", mode_col)
	if mode_chip_style:
		mode_chip_style.bg_color = Color(0.22, 0.18, 0.11, 0.95) if is_drill_mode else Color(0.16, 0.21, 0.14, 0.95)
		mode_chip_style.border_color = Color(0.88, 0.72, 0.32, 0.75) if is_drill_mode else Color(0.506, 0.714, 0.298, 0.75)
	if btn_mode_toggle:
		btn_mode_toggle.text = "Learn Mode" if is_drill_mode else "Drill Mode"
		TactileStyles.apply_tactile_button(btn_mode_toggle, false, is_drill_mode, false)

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

func _update_step_badge() -> void:
	if step_badge_label == null or current_tree == null:
		return
	var total_lines = maxi(1, current_tree.flattened_lines.size())
	var line_num = clampi(active_line_index + 1, 1, total_lines)
	var total_player_moves = 0
	var current_player_move = 0
	for i in range(active_line.size()):
		if active_line[i].is_player_move:
			total_player_moves += 1
			if i <= current_node_index:
				current_player_move += 1
	total_player_moves = maxi(1, total_player_moves)
	current_player_move = clampi(maxi(1, current_player_move), 1, total_player_moves)
	if is_line_completed:
		step_badge_label.text = "Line %d/%d  |  Done" % [line_num, total_lines]
	else:
		step_badge_label.text = "Line %d/%d  |  Move %d/%d" % [line_num, total_lines, current_player_move, total_player_moves]

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
	_last_top_captured_key = ""
	_last_bottom_captured_key = ""
	if chess_board:
		chess_board.setup_board(board_state, is_flipped)
		chess_board.clear_last_move()
		chess_board.clear_review_badge()
		_clear_arrows()

	_update_player_cards()

	if btn_prev_line:
		btn_prev_line.disabled = (current_tree.flattened_lines.size() <= 1)
	if btn_next_line:
		btn_next_line.disabled = (current_tree.flattened_lines.size() <= 1)
		TactileStyles.apply_tactile_button(btn_next_line, true, false, false)
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
	_update_step_badge()

	if node.is_player_move:
		_setup_player_turn(node)
	else:
		_setup_opponent_turn(node)

func _setup_player_turn(node: Variant) -> void:
	is_waiting_opponent = false
	if is_line_completed:
		if chess_board:
			chess_board.is_interactive = false
		return

	if chess_board:
		chess_board.is_interactive = true

	var side_str = "White" if current_tree.color == "white" else "Black"
	_set_coach_card_accent("neutral")

	if status_label:
		if is_drill_mode:
			status_label.text = "Giliran Anda (%s): Mainkan move opening terbaik" % side_str
		else:
			status_label.text = "Mainkan %s (%s to move)" % [node.san, side_str]
		status_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1))

	if blurb_label:
		if is_drill_mode:
			blurb_label.text = "Ingat move opening yang tepat untuk posisi ini. Tekan Hint jika butuh bantuan."
		else:
			blurb_label.text = node.blurb if not node.blurb.is_empty() else "Mainkan %s untuk mengikuti repertoire." % node.san

	if btn_hint:
		btn_hint.disabled = false
	if btn_retry:
		btn_retry.disabled = (current_node_index == 0 and mistakes_on_step == 0)

	if not is_drill_mode and chess_board:
		_show_hint_arrows(node.move_uci)

func _setup_opponent_turn(node: Variant) -> void:
	is_waiting_opponent = true
	if chess_board:
		chess_board.is_interactive = false
	var opp_side = "Black" if current_tree.color == "white" else "White"
	_set_coach_card_accent("neutral")

	if status_label:
		status_label.text = "Lawan (%s) sedang berpikir..." % opp_side
		status_label.add_theme_color_override("font_color", Color(0.74, 0.72, 0.69, 1))

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
	var is_promo = promo != ChessTypes.PieceType.NONE
	ChessMoveGenerator.apply_move_unchecked(next_state, move)
	board_state = next_state
	_update_player_cards()

	if chess_board:
		chess_board.animate_move(
			move,
			next_state,
			is_cap,
			is_castle,
			is_ep,
			promo,
			Callable(self, "_on_opponent_move_animation_done").bind(node, next_state),
			func(): _play_move_sfx(next_state, is_cap, is_castle, is_promo)
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

func _on_opponent_move_animation_done(node: Variant, next_state: ChessBoardState) -> void:
	board_state = next_state
	_update_player_cards()
	if chess_board:
		chess_board.set_last_move(node.move_uci.substr(0, 2), node.move_uci.substr(2, 2))
		chess_board.is_interactive = true

	if blurb_label and not node.blurb.is_empty():
		blurb_label.text = node.blurb
	elif node.is_blunder and blurb_label:
		blurb_label.text = "Lawan memainkan %s?! Blunder umum tingkat klub yang harus dihukum." % node.san

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
	var is_promo = promo != ChessTypes.PieceType.NONE

	var next_state = board_state.clone()
	var is_cap = (board_state.get_piece(to_sq) != null) or is_ep
	ChessMoveGenerator.apply_move_unchecked(next_state, move)
	board_state = next_state
	_update_player_cards()

	# Compute quality for SRS: 5=perfect, 4=one mistake, 3=hint used, etc.
	var quality = 5
	if hint_used_on_step:
		quality = 3
	elif mistakes_on_step > 0:
		quality = 4

	RepertoireService.get_srs_engine().record_attempt(expected_node.id, quality)
	_refresh_stats()
	_set_coach_card_accent("correct")

	if status_label:
		status_label.text = "Benar! %s" % expected_node.san
		status_label.add_theme_color_override("font_color", Color(0.51, 0.78, 0.32, 1))

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
			Callable(self, "_on_player_move_animation_done").bind(next_state),
			func(): _play_move_sfx(next_state, is_cap, is_castle, is_promo)
		)
	else:
		_on_player_move_animation_done(next_state)

func _on_player_move_animation_done(next_state: ChessBoardState) -> void:
	board_state = next_state
	_update_player_cards()
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
	_set_coach_card_accent("incorrect")

	_play_sfx("play_illegal")

	if status_label:
		if is_drill_mode:
			status_label.text = "Langkah salah (Incorrect). Coba lagi, atau tekan Hint."
		else:
			status_label.text = "Langkah salah (Incorrect). Mainkan %s untuk lanjut." % expected_node.san
		status_label.add_theme_color_override("font_color", Color(0.92, 0.38, 0.34, 1))

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
		blurb_label.text = "Hint: Mainkan %s. %s" % [node.san, node.blurb]

func _show_hint_arrows(uci: String) -> void:
	if chess_board == null or uci.length() < 4:
		return
	var from_sq = uci.substr(0, 2)
	var to_sq = uci.substr(2, 2)
	var arrows: Array[Dictionary] = [{"from": from_sq, "to": to_sq, "type": "best"}]
	var threats: Array[Dictionary] = []
	chess_board.update_arrows(arrows, threats)

func _on_retry_pressed() -> void:
	if is_line_completed or (mistakes_on_step == 0 and current_node_index > 0):
		_load_line(active_line_index)
		return
	if current_node_index >= active_line.size():
		return
	if chess_board and board_state:
		chess_board.setup_board(board_state, is_flipped)
		_clear_arrows()
	_set_coach_card_accent("neutral")
	if status_label:
		var side_str = "White" if current_tree.color == "white" else "Black"
		status_label.text = "Your Turn (%s): Play the best repertoire move" % side_str
		status_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1))
	if not is_drill_mode and current_node_index < active_line.size():
		_show_hint_arrows(active_line[current_node_index].move_uci)

func _on_line_completed() -> void:
	is_line_completed = true
	if chess_board:
		chess_board.is_interactive = false
		chess_board.clear_selection()
		_clear_arrows()

	_update_step_badge()
	_set_coach_card_accent("correct")
	if status_label:
		status_label.text = "Variasi Selesai! Akurasi 100%"
		status_label.add_theme_color_override("font_color", Color(0.55, 0.82, 0.36, 1))
	if blurb_label:
		blurb_label.text = "Reps sempurna! Anda telah menguasai variasi cabang ini. Tekan Next Line untuk melanjutkan."
	if btn_next_line:
		btn_next_line.disabled = false
		TactileStyles.apply_tactile_button(btn_next_line, true, false, false)
	if btn_hint:
		btn_hint.disabled = true
	if btn_retry:
		btn_retry.disabled = false

	_play_sfx("play_victory")

func _on_prev_line_pressed() -> void:
	_load_line(active_line_index - 1)

func _on_next_line_pressed() -> void:
	_load_line(active_line_index + 1)

func _on_mode_toggle_pressed() -> void:
	is_drill_mode = not is_drill_mode
	_update_header_ui()
	if current_node_index < active_line.size():
		var node = active_line[current_node_index]
		if node.is_player_move:
			if is_drill_mode:
				_clear_arrows()
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
