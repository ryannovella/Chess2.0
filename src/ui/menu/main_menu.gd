class_name MainMenu
extends Control

# Mode Cards
@onready var card_play_bots: Button = $CenterContainer/MainLayout/RightCard/VBox/ModeCards/CardPlayBots
@onready var card_play_friend: Button = $CenterContainer/MainLayout/RightCard/VBox/ModeCards/CardPlayFriend
@onready var card_trainer: Button = $CenterContainer/MainLayout/RightCard/VBox/ModeCards/CardTrainer
@onready var card_variants: Button = $CenterContainer/MainLayout/RightCard/VBox/ModeCards/CardVariants

# Left Card Player Details
@onready var opponent_badge: Label = $CenterContainer/MainLayout/LeftCard/VBox/Info/OpponentBadge
@onready var opponent_name: Label = $CenterContainer/MainLayout/LeftCard/VBox/Info/OpponentRow/OpponentName
@onready var side_indicator: Label = $CenterContainer/MainLayout/LeftCard/VBox/Info/SideIndicator
@onready var mini_board: MiniBoardPreview = $CenterContainer/MainLayout/LeftCard/VBox/BoardCenter/MiniBoard

# Setup Controls (Difficulty, Engine Best Move, Play As)
@onready var difficulty_card: PanelContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard
@onready var difficulty_header: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/Header
@onready var elo_label: Label = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/Header/EloLabel
@onready var elo_slider: HSlider = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/EloSlider
@onready var preset_row: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow
@onready var difficulty_separator: HSeparator = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/HSeparator
@onready var delay_row: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/DelayRow
@onready var delay_slider: HSlider = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/DelayRow/DelaySlider
@onready var delay_value_label: Label = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/DelayRow/DelayValueLabel

@onready var btn_preset_400: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset400
@onready var btn_preset_1000: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset1000
@onready var btn_preset_1500: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset1500
@onready var btn_preset_2000: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset2000
@onready var btn_preset_2800: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset2800

@onready var engine_assist_card: PanelContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard
@onready var engine_assist_header: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/Header
@onready var player_arrows_row: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/PlayerArrowsRow
@onready var opponent_arrows_row: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/OpponentArrowsRow
@onready var depth_row: HBoxContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/DepthRow
@onready var chk_best_move: CheckBox = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/PlayerArrowsRow/ChkBestMove
@onready var chk_player_threats: CheckBox = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/PlayerArrowsRow/ChkPlayerThreats
@onready var chk_opponent_best_move: CheckBox = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/OpponentArrowsRow/ChkOpponentBestMove
@onready var chk_opponent_threats: CheckBox = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/OpponentArrowsRow/ChkOpponentThreats
@onready var depth_slider: HSlider = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/DepthRow/DepthSlider
@onready var depth_value_label: Label = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard/VBox/DepthRow/DepthValueLabel

@onready var play_as_row: HBoxContainer = $CenterContainer/MainLayout/LeftCard/VBox/Info/PlayAsRow
@onready var btn_side_white: Button = $CenterContainer/MainLayout/LeftCard/VBox/Info/PlayAsRow/BtnSideWhite
@onready var btn_side_random: Button = $CenterContainer/MainLayout/LeftCard/VBox/Info/PlayAsRow/BtnSideRandom
@onready var btn_side_black: Button = $CenterContainer/MainLayout/LeftCard/VBox/Info/PlayAsRow/BtnSideBlack

@onready var btn_play: Button = $CenterContainer/MainLayout/RightCard/VBox/BtnPlay
@onready var version_label: Label = $CenterContainer/MainLayout/RightCard/VBox/HeaderRow/VersionLabel

# Footer Links
@onready var btn_settings: Button = $CenterContainer/MainLayout/RightCard/VBox/FooterLinks/BtnSettings
@onready var btn_update: Button = $CenterContainer/MainLayout/RightCard/VBox/FooterLinks/BtnUpdate
@onready var btn_exit: Button = $CenterContainer/MainLayout/RightCard/VBox/FooterLinks/BtnExit

# Update Modal
@onready var update_modal: Control = $UpdateModal
@onready var local_version_label: Label = $UpdateModal/CenterContainer/UpdateCard/VBox/VersionRow/LocalVersionLabel
@onready var remote_version_label: Label = $UpdateModal/CenterContainer/UpdateCard/VBox/VersionRow/RemoteVersionLabel
@onready var status_label: Label = $UpdateModal/CenterContainer/UpdateCard/VBox/StatusBox/StatusLabel
@onready var btn_close_update: Button = $UpdateModal/CenterContainer/UpdateCard/VBox/ActionButtons/BtnCloseUpdate
@onready var btn_check_update: Button = $UpdateModal/CenterContainer/UpdateCard/VBox/ActionButtons/BtnCheckUpdate
@onready var btn_install_update: Button = $UpdateModal/CenterContainer/UpdateCard/VBox/ActionButtons/BtnInstallUpdate

# Trainer Hub Modal
@onready var trainer_modal: Control = $TrainerModal
@onready var trainer_modal_title: Label = $TrainerModal/CenterContainer/TrainerCard/VBox/Header/Title
@onready var btn_tab_openings: Button = $TrainerModal/CenterContainer/TrainerCard/VBox/TabBar/BtnTabOpenings
@onready var btn_tab_checkmate: Button = $TrainerModal/CenterContainer/TrainerCard/VBox/TabBar/BtnTabCheckmate
@onready var btn_tab_queen: Button = $TrainerModal/CenterContainer/TrainerCard/VBox/TabBar/BtnTabQueen
@onready var trainer_cards_container: VBoxContainer = $TrainerModal/CenterContainer/TrainerCard/VBox/Scroll/CardsContainer
@onready var btn_close_trainer: Button = $TrainerModal/CenterContainer/TrainerCard/VBox/ActionButtons/BtnCloseTrainer

# Settings Modal
@onready var settings_modal: Control = $SettingsModal
@onready var banner_board: MiniBoardPreview = $SettingsModal/CenterContainer/SettingsCard/VBox/BannerCenter/BannerBoard
@onready var opt_piece_set: OptionButton = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/PieceRow/OptPieceSet
@onready var opt_board_theme: OptionButton = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/BoardRow/OptBoardTheme
@onready var chk_white_engine: CheckBox = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/WhiteArrowsRow/ChkWhiteEngine
@onready var chk_white_threats: CheckBox = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/WhiteArrowsRow/ChkWhiteThreats
@onready var chk_black_engine: CheckBox = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/BlackArrowsRow/ChkBlackEngine
@onready var chk_black_threats: CheckBox = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/BlackArrowsRow/ChkBlackThreats
@onready var chk_sound: CheckBox = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/SoundRow/ChkSound
@onready var opt_button_sound: OptionButton = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/ButtonSoundRow/OptButtonSound
@onready var settings_delay_slider: HSlider = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/DelayRow/SettingsDelaySlider
@onready var settings_delay_value: Label = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/DelayRow/SettingsDelayValue
@onready var btn_cancel_settings: Button = $SettingsModal/CenterContainer/SettingsCard/VBox/ModalButtons/BtnCancelSettings
@onready var btn_save_settings: Button = $SettingsModal/CenterContainer/SettingsCard/VBox/ModalButtons/BtnSaveSettings

const MAIN_SCENE_PATH = "res://src/main.tscn"
const OPENING_TRAINER_PATH = "res://src/ui/trainer/opening_trainer.tscn"
const TACTICS_TRAINER_PATH = "res://src/ui/trainer/tactics_trainer.tscn"
const RepertoireService = preload("res://src/core/repertoire/repertoire_service.gd")
const TacticsService = preload("res://src/core/tactics/tactics_service.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const ChevronIndicator = preload("res://src/ui/menu/chevron_indicator.gd")
const EngineBootstrap = preload("res://src/engine/engine_bootstrap.gd")

var selected_mode: String = "vs_ai" # "vs_ai", "local_2p", "painter"
var current_trainer_tab: String = "openings" # "openings" | "checkmate" | "queen_tactics"

var is_difficulty_expanded: bool = true
var is_engine_assist_expanded: bool = false
var difficulty_chevron: ChevronIndicator = null
var engine_assist_chevron: ChevronIndicator = null
var _engine_bootstrap: EngineBootstrap = null
var _engine_setup_modal: ColorRect = null
var _engine_setup_status: Label = null
var _engine_setup_bar: ProgressBar = null
var _engine_setup_btn_retry: Button = null
var _engine_setup_btn_skip: Button = null
var _engine_setup_tween: Tween = null

var card_active_style: StyleBox
var card_active_hover_style: StyleBox
var card_active_pressed_style: StyleBox
var card_normal_style: StyleBox
var card_normal_hover_style: StyleBox
var card_normal_pressed_style: StyleBox
var side_selected_style: StyleBox
var side_selected_hover_style: StyleBox
var side_selected_pressed_style: StyleBox
var side_unselected_style: StyleBox
var side_hover_style: StyleBox
var side_pressed_style: StyleBox
var preset_normal_style: StyleBox
var preset_hover_style: StyleBox
var preset_active_style: StyleBox
var preset_active_hover_style: StyleBox

var preset_buttons: Array[Button] = []
var preset_values: Array[int] = [400, 1000, 1500, 2000, 2800]

func _ready() -> void:
	settings_modal.visible = false
	if update_modal:
		update_modal.visible = false

	# Cache stylebox presets
	card_active_style = card_play_bots.get_theme_stylebox("normal")
	card_active_hover_style = card_play_bots.get_theme_stylebox("hover")
	card_active_pressed_style = card_play_bots.get_theme_stylebox("pressed")
	card_normal_style = card_play_friend.get_theme_stylebox("normal")
	card_normal_hover_style = card_play_friend.get_theme_stylebox("hover")
	card_normal_pressed_style = card_play_friend.get_theme_stylebox("pressed")
	side_selected_style = btn_side_white.get_theme_stylebox("normal")
	side_selected_hover_style = btn_side_white.get_theme_stylebox("hover")
	side_selected_pressed_style = btn_side_white.get_theme_stylebox("pressed")
	side_unselected_style = btn_side_random.get_theme_stylebox("normal")
	side_hover_style = btn_side_random.get_theme_stylebox("hover")
	side_pressed_style = btn_side_random.get_theme_stylebox("pressed")

	preset_normal_style = btn_preset_400.get_theme_stylebox("normal")
	preset_hover_style = btn_preset_400.get_theme_stylebox("hover")

	if preset_normal_style is StyleBoxFlat:
		preset_active_style = preset_normal_style.duplicate()
		(preset_active_style as StyleBoxFlat).bg_color = Color(0.20, 0.25, 0.18, 1.0)
		(preset_active_style as StyleBoxFlat).border_width_left = 1
		(preset_active_style as StyleBoxFlat).border_width_top = 1
		(preset_active_style as StyleBoxFlat).border_width_right = 1
		(preset_active_style as StyleBoxFlat).border_width_bottom = 3
		(preset_active_style as StyleBoxFlat).border_color = Color(0.506, 0.714, 0.298, 1.0)
		preset_active_hover_style = (preset_active_style as StyleBoxFlat).duplicate()
		(preset_active_hover_style as StyleBoxFlat).bg_color = Color(0.24, 0.30, 0.21, 1.0)
		(preset_active_hover_style as StyleBoxFlat).border_color = Color(0.584, 0.784, 0.353, 1.0)
	else:
		preset_active_style = side_selected_style
		preset_active_hover_style = side_selected_style

	# Setup Mode Card Clicks
	card_play_bots.pressed.connect(func(): _select_mode("vs_ai"))
	card_play_friend.pressed.connect(func(): _select_mode("local_2p"))
	card_trainer.pressed.connect(func():
		_select_mode("trainer")
		_open_trainer_menu()
	)
	card_variants.pressed.connect(func(): _select_mode("painter"))

	# Setup Side Selector Buttons
	btn_side_white.pressed.connect(func(): _set_player_side("white"))
	btn_side_random.pressed.connect(func(): _set_player_side("random"))
	btn_side_black.pressed.connect(func(): _set_player_side("black"))

	# Setup ELO Slider & Presets
	preset_buttons = [btn_preset_400, btn_preset_1000, btn_preset_1500, btn_preset_2000, btn_preset_2800]
	for i in range(preset_buttons.size()):
		var btn = preset_buttons[i]
		var val = preset_values[i]
		btn.pressed.connect(func(): _set_elo(val))

	elo_slider.value = GameSettings.ai_elo
	_update_elo_label(GameSettings.ai_elo)
	elo_slider.value_changed.connect(_on_elo_slider_changed)

	# Setup Engine Best Move & Threat Controls
	_sync_engine_assist_ui()
	chk_best_move.toggled.connect(_on_best_move_toggled)
	chk_player_threats.toggled.connect(_on_player_threats_toggled)
	chk_opponent_best_move.toggled.connect(_on_opponent_best_move_toggled)
	chk_opponent_threats.toggled.connect(_on_opponent_threats_toggled)
	depth_slider.value_changed.connect(_on_depth_slider_changed)

	# Setup Play Button
	btn_play.pressed.connect(_on_play_pressed)

	# Footer Links
	btn_settings.pressed.connect(_on_settings_pressed)
	if btn_update:
		btn_update.pressed.connect(_on_update_pressed)
	btn_exit.pressed.connect(func(): get_tree().quit())

	# Trainer Modal Handlers
	if btn_close_trainer:
		btn_close_trainer.pressed.connect(func(): trainer_modal.visible = false)
	if btn_tab_openings:
		btn_tab_openings.pressed.connect(func(): _select_trainer_tab("openings"))
	if btn_tab_checkmate:
		btn_tab_checkmate.pressed.connect(func(): _select_trainer_tab("checkmate"))
	if btn_tab_queen:
		btn_tab_queen.pressed.connect(func(): _select_trainer_tab("queen_tactics"))

	# Settings Modal Handlers
	btn_cancel_settings.pressed.connect(func(): settings_modal.visible = false)
	btn_save_settings.pressed.connect(_on_save_settings_pressed)

	# Update Modal Handlers
	if btn_close_update:
		btn_close_update.pressed.connect(func(): update_modal.visible = false)
	if btn_check_update:
		btn_check_update.pressed.connect(check_for_updates)
	if btn_install_update:
		btn_install_update.pressed.connect(install_update)

	_refresh_version_display()
	if version_label:
		version_label.mouse_filter = Control.MOUSE_FILTER_STOP
		version_label.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		version_label.tooltip_text = "Click to check for updates"
		version_label.gui_input.connect(_on_version_label_gui_input)

	_update_side_icons()
	_update_side_ui()
	_select_mode("vs_ai")
	_setup_card_delay()
	_setup_settings_form()
	_setup_tactile_card_effects()
	_setup_collapsible_headers()
	GameSettings.ai_delay_changed.connect(func(_m, _c): _sync_delay_ui())
	_check_engine_bootstrap()

func _select_mode(mode: String) -> void:
	selected_mode = mode
	card_play_bots.add_theme_stylebox_override("normal", card_active_style if mode == "vs_ai" else card_normal_style)
	card_play_bots.add_theme_stylebox_override("hover", card_active_hover_style if mode == "vs_ai" else card_normal_hover_style)
	card_play_bots.add_theme_stylebox_override("pressed", card_active_pressed_style if mode == "vs_ai" else card_normal_pressed_style)

	card_play_friend.add_theme_stylebox_override("normal", card_active_style if mode == "local_2p" else card_normal_style)
	card_play_friend.add_theme_stylebox_override("hover", card_active_hover_style if mode == "local_2p" else card_normal_hover_style)
	card_play_friend.add_theme_stylebox_override("pressed", card_active_pressed_style if mode == "local_2p" else card_normal_pressed_style)

	card_trainer.add_theme_stylebox_override("normal", card_active_style if mode == "trainer" else card_normal_style)
	card_trainer.add_theme_stylebox_override("hover", card_active_hover_style if mode == "trainer" else card_normal_hover_style)
	card_trainer.add_theme_stylebox_override("pressed", card_active_pressed_style if mode == "trainer" else card_normal_pressed_style)

	card_variants.add_theme_stylebox_override("normal", card_active_style if mode == "painter" else card_normal_style)
	card_variants.add_theme_stylebox_override("hover", card_active_hover_style if mode == "painter" else card_normal_hover_style)
	card_variants.add_theme_stylebox_override("pressed", card_active_pressed_style if mode == "painter" else card_normal_pressed_style)

	# Tampilkan / sembunyikan pengaturan bot ELO, Best Move, dan Side selector
	difficulty_card.visible = (mode == "vs_ai")
	engine_assist_card.visible = (mode != "painter" and mode != "trainer")
	play_as_row.visible = (mode != "painter" and mode != "trainer")

	if mode == "vs_ai":
		opponent_name.text = "Stockfish 18 (AI)"
		opponent_badge.text = "ELO %d" % GameSettings.ai_elo
		btn_play.text = "Play"
	elif mode == "local_2p":
		opponent_name.text = "Player 2 (Opponent)"
		opponent_badge.text = "Local 2P"
		btn_play.text = "Play"
	elif mode == "trainer":
		opponent_name.text = "Training Hub"
		opponent_badge.text = "Openings & Tactics"
		btn_play.text = "Open Training Hub"
	elif mode == "painter":
		opponent_name.text = "Custom Position Setup"
		opponent_badge.text = "Sandbox"
		btn_play.text = "Open Editor"

	_sync_engine_assist_ui()
	_sync_settings_form_arrows()

func _setup_tactile_card_effects() -> void:
	var cards: Array[Button] = [card_play_bots, card_play_friend, card_trainer, card_variants]
	for card in cards:
		var hbox = card.get_node_or_null("HBox") as Control
		if not hbox:
			continue
		var initial_top = hbox.offset_top
		var initial_bottom = hbox.offset_bottom
		var pressed_offset = 3.0

		card.button_down.connect(func():
			hbox.offset_top = initial_top + pressed_offset
			hbox.offset_bottom = initial_bottom + pressed_offset
		)
		var reset_pos = func():
			hbox.offset_top = initial_top
			hbox.offset_bottom = initial_bottom
		card.button_up.connect(reset_pos)
		card.mouse_exited.connect(reset_pos)

func _setup_collapsible_headers() -> void:
	if difficulty_header:
		difficulty_header.mouse_filter = Control.MOUSE_FILTER_STOP
		difficulty_header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		difficulty_header.tooltip_text = "Click to toggle Bot Difficulty"
		for child in difficulty_header.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		difficulty_chevron = ChevronIndicator.new()
		difficulty_chevron.is_expanded = is_difficulty_expanded
		difficulty_header.add_child(difficulty_chevron)
		
		difficulty_header.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				toggle_difficulty()
		)
		difficulty_header.mouse_entered.connect(func():
			if difficulty_chevron:
				difficulty_chevron.chevron_color = Color(1.0, 1.0, 1.0, 1.0)
		)
		difficulty_header.mouse_exited.connect(func():
			if difficulty_chevron:
				difficulty_chevron.chevron_color = Color(0.75, 0.75, 0.75, 0.85)
		)

	if engine_assist_header:
		engine_assist_header.mouse_filter = Control.MOUSE_FILTER_STOP
		engine_assist_header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		engine_assist_header.tooltip_text = "Click to toggle Engine Assist"
		for child in engine_assist_header.get_children():
			if child is Control:
				(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		engine_assist_chevron = ChevronIndicator.new()
		engine_assist_chevron.is_expanded = is_engine_assist_expanded
		engine_assist_header.add_child(engine_assist_chevron)
		
		engine_assist_header.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				toggle_engine_assist()
		)
		engine_assist_header.mouse_entered.connect(func():
			if engine_assist_chevron:
				engine_assist_chevron.chevron_color = Color(1.0, 1.0, 1.0, 1.0)
		)
		engine_assist_header.mouse_exited.connect(func():
			if engine_assist_chevron:
				engine_assist_chevron.chevron_color = Color(0.75, 0.75, 0.75, 0.85)
		)

	set_difficulty_expanded(true)
	set_engine_assist_expanded(false)

func set_difficulty_expanded(expanded: bool) -> void:
	is_difficulty_expanded = expanded
	if elo_slider:
		elo_slider.visible = expanded
	if preset_row:
		preset_row.visible = expanded
	if difficulty_separator:
		difficulty_separator.visible = expanded
	if delay_row:
		delay_row.visible = expanded
	if difficulty_chevron:
		difficulty_chevron.is_expanded = expanded

func set_engine_assist_expanded(expanded: bool) -> void:
	is_engine_assist_expanded = expanded
	if player_arrows_row:
		player_arrows_row.visible = expanded
	if opponent_arrows_row:
		opponent_arrows_row.visible = expanded
	if depth_row:
		depth_row.visible = expanded
	if engine_assist_chevron:
		engine_assist_chevron.is_expanded = expanded

func toggle_difficulty() -> void:
	set_difficulty_expanded(!is_difficulty_expanded)
	_play_header_click_sfx()

func toggle_engine_assist() -> void:
	set_engine_assist_expanded(!is_engine_assist_expanded)
	_play_header_click_sfx()

func _play_header_click_sfx() -> void:
	var audio = get_tree().root.get_node_or_null("AudioService")
	if audio:
		audio.play_button_down()
		audio.play_button_up()

func _set_player_side(side: String) -> void:
	# Simpan preferensi role (Player vs Opponent) sebelum sisi berganti
	var p_eng = GameSettings.get_player_engine_arrows()
	var o_eng = GameSettings.get_opponent_engine_arrows()
	var p_thr = GameSettings.get_player_threat_arrows()
	var o_thr = GameSettings.get_opponent_threat_arrows()
	
	GameSettings.set_chosen_side(side)
	
	# Sinkronkan kembali preferensi role ke warna baru
	GameSettings.set_player_engine_arrows(p_eng)
	GameSettings.set_opponent_engine_arrows(o_eng)
	GameSettings.set_player_threat_arrows(p_thr)
	GameSettings.set_opponent_threat_arrows(o_thr)
	GameSettings.save_settings()

	_update_side_ui()
	_sync_engine_assist_ui()
	_sync_settings_form_arrows()
	if mini_board:
		mini_board.queue_redraw()

func _update_side_icons() -> void:
	var piece_set = GameSettings.piece_set
	var wk_path = "res://assets/pieces/%s/wK.png" % piece_set
	if not ResourceLoader.exists(wk_path):
		wk_path = "res://assets/pieces/%s/wK.svg" % piece_set
	if ResourceLoader.exists(wk_path):
		btn_side_white.icon = load(wk_path)

	var rand_path = "res://assets/pieces/%s/randK.png" % piece_set
	if not ResourceLoader.exists(rand_path):
		rand_path = "res://assets/pieces/%s/randK.svg" % piece_set
	if ResourceLoader.exists(rand_path):
		btn_side_random.icon = load(rand_path)
	elif ResourceLoader.exists("res://assets/ui/random_side.svg"):
		btn_side_random.icon = load("res://assets/ui/random_side.svg")

	var bk_path = "res://assets/pieces/%s/bK.png" % piece_set
	if not ResourceLoader.exists(bk_path):
		bk_path = "res://assets/pieces/%s/bK.svg" % piece_set
	if ResourceLoader.exists(bk_path):
		btn_side_black.icon = load(bk_path)

func _update_side_ui() -> void:
	var side = GameSettings.chosen_side
	var is_white = (side == "white")
	var is_rand = (side == "random")
	var is_black = (side == "black")

	btn_side_white.add_theme_stylebox_override("normal", side_selected_style if is_white else side_unselected_style)
	btn_side_white.add_theme_stylebox_override("hover", side_selected_hover_style if is_white else side_hover_style)
	btn_side_white.add_theme_stylebox_override("pressed", side_selected_pressed_style if is_white else side_pressed_style)

	btn_side_random.add_theme_stylebox_override("normal", side_selected_style if is_rand else side_unselected_style)
	btn_side_random.add_theme_stylebox_override("hover", side_selected_hover_style if is_rand else side_hover_style)
	btn_side_random.add_theme_stylebox_override("pressed", side_selected_pressed_style if is_rand else side_pressed_style)

	btn_side_black.add_theme_stylebox_override("normal", side_selected_style if is_black else side_unselected_style)
	btn_side_black.add_theme_stylebox_override("hover", side_selected_hover_style if is_black else side_hover_style)
	btn_side_black.add_theme_stylebox_override("pressed", side_selected_pressed_style if is_black else side_pressed_style)

	if side == "white":
		side_indicator.text = "Side: White"
		side_indicator.add_theme_color_override("font_color", Color(0.506, 0.714, 0.298))
	elif side == "black":
		side_indicator.text = "Side: Black"
		side_indicator.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	else:
		side_indicator.text = "Side: Random (50/50)"
		side_indicator.add_theme_color_override("font_color", Color(0.35, 0.75, 1))

func _set_elo(target_elo: int) -> void:
	elo_slider.value = target_elo

func _on_elo_slider_changed(val: float) -> void:
	var elo = int(val)
	GameSettings.set_elo(elo)
	_update_elo_label(elo)
	if opponent_badge and selected_mode == "vs_ai":
		opponent_badge.text = "ELO %d" % elo

func _update_elo_label(elo: int) -> void:
	var tier = "Novice"
	if elo < 400: tier = "Beginner"
	elif elo < 800: tier = "Novice"
	elif elo < 1200: tier = "Casual"
	elif elo < 1600: tier = "Intermediate"
	elif elo < 2000: tier = "Advanced"
	elif elo < 2400: tier = "Master"
	elif elo < 2800: tier = "Grandmaster"
	else: tier = "Superhuman"
	elo_label.text = "%d ELO (%s)" % [elo, tier]

	# Update highlight preset buttons
	for i in range(preset_buttons.size()):
		var btn = preset_buttons[i]
		var val = preset_values[i]
		if abs(val - elo) <= 60:
			btn.add_theme_stylebox_override("normal", preset_active_style)
			btn.add_theme_stylebox_override("hover", preset_active_hover_style)
			btn.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		else:
			btn.add_theme_stylebox_override("normal", preset_normal_style)
			btn.add_theme_stylebox_override("hover", preset_hover_style)
			btn.add_theme_color_override("font_color", Color(0.7, 0.68, 0.65, 1))

func _sync_engine_assist_ui() -> void:
	if chk_best_move == null:
		return
	if selected_mode == "vs_ai":
		chk_best_move.text = "Player Best"
		chk_player_threats.text = "Player Threats"
		chk_opponent_best_move.text = "Bot Best"
		chk_opponent_threats.text = "Bot Threats"

		chk_best_move.set_pressed_no_signal(GameSettings.get_player_engine_arrows())
		chk_player_threats.set_pressed_no_signal(GameSettings.get_player_threat_arrows())
		chk_opponent_best_move.set_pressed_no_signal(GameSettings.get_opponent_engine_arrows())
		chk_opponent_threats.set_pressed_no_signal(GameSettings.get_opponent_threat_arrows())
	else:
		chk_best_move.text = "White Best"
		chk_player_threats.text = "White Threats"
		chk_opponent_best_move.text = "Black Best"
		chk_opponent_threats.text = "Black Threats"

		chk_best_move.set_pressed_no_signal(GameSettings.show_white_engine_arrows)
		chk_player_threats.set_pressed_no_signal(GameSettings.show_white_threat_arrows)
		chk_opponent_best_move.set_pressed_no_signal(GameSettings.show_black_engine_arrows)
		chk_opponent_threats.set_pressed_no_signal(GameSettings.show_black_threat_arrows)

	_update_depth_slider_editable()
	depth_slider.value = GameSettings.engine_depth
	_update_depth_label(GameSettings.engine_depth)

func _update_depth_slider_editable() -> void:
	var any_engine = false
	if selected_mode == "vs_ai":
		any_engine = GameSettings.get_player_engine_arrows() or GameSettings.get_opponent_engine_arrows()
	else:
		any_engine = GameSettings.show_white_engine_arrows or GameSettings.show_black_engine_arrows
	depth_slider.editable = any_engine

func _on_best_move_toggled(pressed: bool) -> void:
	if selected_mode == "vs_ai":
		GameSettings.set_player_engine_arrows(pressed)
	else:
		GameSettings.show_white_engine_arrows = pressed
	GameSettings.save_settings()
	_update_depth_slider_editable()

func _on_player_threats_toggled(pressed: bool) -> void:
	if selected_mode == "vs_ai":
		GameSettings.set_player_threat_arrows(pressed)
	else:
		GameSettings.show_white_threat_arrows = pressed
	GameSettings.save_settings()

func _on_opponent_best_move_toggled(pressed: bool) -> void:
	if selected_mode == "vs_ai":
		GameSettings.set_opponent_engine_arrows(pressed)
	else:
		GameSettings.show_black_engine_arrows = pressed
	GameSettings.save_settings()
	_update_depth_slider_editable()

func _on_opponent_threats_toggled(pressed: bool) -> void:
	if selected_mode == "vs_ai":
		GameSettings.set_opponent_threat_arrows(pressed)
	else:
		GameSettings.show_black_threat_arrows = pressed
	GameSettings.save_settings()

func _on_depth_slider_changed(val: float) -> void:
	var depth = int(val)
	GameSettings.set_engine_depth(depth)
	_update_depth_label(depth)

func _update_depth_label(depth: int) -> void:
	var desc = "Fast"
	if depth >= 20: desc = "Deep"
	elif depth >= 16: desc = "Optimal"
	elif depth >= 12: desc = "Standard"
	depth_value_label.text = "Depth %d (%s)" % [depth, desc]

func _on_play_pressed() -> void:
	if selected_mode == "vs_ai":
		GameSettings.current_game_mode = "vs_ai"
		GameSettings.open_painter_on_launch = false
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	elif selected_mode == "local_2p":
		GameSettings.current_game_mode = "local_2p"
		GameSettings.open_painter_on_launch = false
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)
	elif selected_mode == "trainer":
		_open_trainer_menu()
	elif selected_mode == "painter":
		GameSettings.current_game_mode = "vs_ai"
		GameSettings.open_painter_on_launch = true
		get_tree().change_scene_to_file(MAIN_SCENE_PATH)

func _on_settings_pressed() -> void:
	_sync_settings_form_dropdowns()
	_sync_settings_form_arrows()
	settings_modal.visible = true
	if banner_board:
		banner_board.queue_redraw()

func _sync_settings_form_dropdowns() -> void:
	if opt_piece_set:
		for i in range(opt_piece_set.item_count):
			if str(opt_piece_set.get_item_metadata(i)) == GameSettings.piece_set:
				opt_piece_set.select(i)
				break
	if opt_board_theme:
		for i in range(opt_board_theme.item_count):
			if str(opt_board_theme.get_item_metadata(i)) == GameSettings.board_theme:
				opt_board_theme.select(i)
				break
	if opt_button_sound:
		for i in range(opt_button_sound.item_count):
			if str(opt_button_sound.get_item_metadata(i)) == GameSettings.button_sound_theme:
				opt_button_sound.select(i)
				break

func _sync_settings_form_arrows() -> void:
	if not chk_white_engine or not chk_black_engine:
		return
	if selected_mode == "vs_ai":
		chk_white_engine.text = "Player Best"
		chk_white_threats.text = "Player Threats"
		chk_black_engine.text = "Bot Best"
		chk_black_threats.text = "Bot Threats"
		chk_white_engine.button_pressed = GameSettings.get_player_engine_arrows()
		chk_white_threats.button_pressed = GameSettings.get_player_threat_arrows()
		chk_black_engine.button_pressed = GameSettings.get_opponent_engine_arrows()
		chk_black_threats.button_pressed = GameSettings.get_opponent_threat_arrows()
	else:
		chk_white_engine.text = "White Best"
		chk_white_threats.text = "White Threats"
		chk_black_engine.text = "Black Best"
		chk_black_threats.text = "Black Threats"
		chk_white_engine.button_pressed = GameSettings.show_white_engine_arrows
		chk_white_threats.button_pressed = GameSettings.show_white_threat_arrows
		chk_black_engine.button_pressed = GameSettings.show_black_engine_arrows
		chk_black_threats.button_pressed = GameSettings.show_black_threat_arrows

func _setup_settings_form() -> void:
	opt_piece_set.clear()
	var sets = [
		{"id": "neo", "name": "Neo"},
		{"id": "cburnett", "name": "Classic"},
		{"id": "staunty", "name": "Staunty"},
		{"id": "horsey", "name": "Horsey"}
	]
	var sel_set = 0
	for i in range(sets.size()):
		var s = sets[i]
		opt_piece_set.add_item(s["name"], i)
		opt_piece_set.set_item_metadata(i, s["id"])
		if s["id"] == GameSettings.piece_set:
			sel_set = i
	opt_piece_set.select(sel_set)

	opt_board_theme.clear()
	var themes = [
		{"id": "emerald", "name": "Emerald Green"},
		{"id": "slate", "name": "Slate"},
		{"id": "wood", "name": "Wood"},
		{"id": "ocean", "name": "Ocean"},
		{"id": "midnight", "name": "Midnight"}
	]
	var sel_theme = 0
	for i in range(themes.size()):
		var t = themes[i]
		opt_board_theme.add_item(t["name"], i)
		opt_board_theme.set_item_metadata(i, t["id"])
		if t["id"] == GameSettings.board_theme:
			sel_theme = i
	opt_board_theme.select(sel_theme)

	_sync_settings_form_arrows()
	chk_sound.button_pressed = GameSettings.sound_enabled
	_setup_settings_delay()

	if opt_button_sound:
		opt_button_sound.clear()
		var button_sounds = [
			{"id": "mechanical", "name": "Mechanical"},
			{"id": "modern", "name": "Modern"},
			{"id": "soft", "name": "Soft Tick"},
			{"id": "mouse", "name": "Classic Mouse"},
			{"id": "off", "name": "Muted"}
		]
		var sel_btn_sound = 0
		for i in range(button_sounds.size()):
			var bs = button_sounds[i]
			opt_button_sound.add_item(bs["name"], i)
			opt_button_sound.set_item_metadata(i, bs["id"])
			if bs["id"] == GameSettings.button_sound_theme:
				sel_btn_sound = i
		opt_button_sound.select(sel_btn_sound)
		if not opt_button_sound.item_selected.is_connected(_on_opt_button_sound_selected):
			opt_button_sound.item_selected.connect(_on_opt_button_sound_selected)

	# Live preview saat dropdown berubah
	if not opt_piece_set.item_selected.is_connected(_on_opt_piece_set_selected):
		opt_piece_set.item_selected.connect(_on_opt_piece_set_selected)
	if not opt_board_theme.item_selected.is_connected(_on_opt_board_theme_selected):
		opt_board_theme.item_selected.connect(_on_opt_board_theme_selected)

func _on_opt_piece_set_selected(idx: int) -> void:
	var meta = opt_piece_set.get_item_metadata(idx)
	if meta != null and str(meta) != "":
		GameSettings.set_piece_set(str(meta))
		_update_side_icons()
		if banner_board: banner_board.queue_redraw()

func _on_opt_board_theme_selected(idx: int) -> void:
	var meta = opt_board_theme.get_item_metadata(idx)
	if meta != null and str(meta) != "":
		GameSettings.set_board_theme(str(meta))
		if banner_board: banner_board.queue_redraw()

func _on_opt_button_sound_selected(idx: int) -> void:
	if not opt_button_sound:
		return
	var meta = opt_button_sound.get_item_metadata(idx)
	if meta != null and str(meta) != "":
		GameSettings.set_button_sound_theme(str(meta))
		var audio = get_tree().root.get_node_or_null("AudioService")
		if audio and audio.has_method("preview_button_sound"):
			audio.preview_button_sound(str(meta))

func _format_delay_label(val: float) -> String:
	if is_zero_approx(val):
		return "0.0s (Instant)"
	elif val <= 0.6:
		return "%.1fs (Fast)" % val
	elif val <= 1.8:
		return "%.1fs (Natural)" % val
	elif val <= 3.0:
		return "%.1fs (Relaxed)" % val
	else:
		return "%.1fs (Slow)" % val

func _get_current_delay_value() -> float:
	if GameSettings.ai_delay_mode == "instant":
		return 0.0
	elif GameSettings.ai_delay_mode == "fast":
		return 0.5
	elif GameSettings.ai_delay_mode == "natural":
		return 1.2
	elif GameSettings.ai_delay_mode == "relaxed":
		return 3.0
	else:
		return GameSettings.ai_custom_delay

func _setup_card_delay() -> void:
	var cur_val = _get_current_delay_value()
	delay_slider.value = cur_val
	delay_value_label.text = _format_delay_label(cur_val)

	delay_slider.value_changed.connect(func(val: float):
		delay_value_label.text = _format_delay_label(val)
		if is_zero_approx(val):
			GameSettings.set_ai_delay_mode("instant")
			GameSettings.set_ai_custom_delay(0.0)
		else:
			GameSettings.set_ai_delay_mode("custom")
			GameSettings.set_ai_custom_delay(val)
	)

func _setup_settings_delay() -> void:
	var cur_val = _get_current_delay_value()
	settings_delay_slider.value = cur_val
	settings_delay_value.text = _format_delay_label(cur_val)

	settings_delay_slider.value_changed.connect(func(val: float):
		settings_delay_value.text = _format_delay_label(val)
	)

func _sync_delay_ui() -> void:
	var cur_val = _get_current_delay_value()
	if delay_slider:
		delay_slider.value = cur_val
		delay_value_label.text = _format_delay_label(cur_val)
	if settings_delay_slider:
		settings_delay_slider.value = cur_val
		settings_delay_value.text = _format_delay_label(cur_val)

func _on_save_settings_pressed() -> void:
	if opt_piece_set and opt_piece_set.selected >= 0:
		var p_id = opt_piece_set.get_item_metadata(opt_piece_set.selected)
		if p_id != null and str(p_id) != "":
			GameSettings.set_piece_set(str(p_id))
	if opt_board_theme and opt_board_theme.selected >= 0:
		var t_id = opt_board_theme.get_item_metadata(opt_board_theme.selected)
		if t_id != null and str(t_id) != "":
			GameSettings.set_board_theme(str(t_id))
	if opt_button_sound and opt_button_sound.selected >= 0:
		var b_id = opt_button_sound.get_item_metadata(opt_button_sound.selected)
		if b_id != null and str(b_id) != "":
			GameSettings.set_button_sound_theme(str(b_id))
	if settings_delay_slider:
		var s_val = settings_delay_slider.value
		if is_zero_approx(s_val):
			GameSettings.set_ai_delay_mode("instant")
			GameSettings.set_ai_custom_delay(0.0)
		else:
			GameSettings.set_ai_delay_mode("custom")
			GameSettings.set_ai_custom_delay(s_val)

	if selected_mode == "vs_ai":
		GameSettings.set_player_engine_arrows(chk_white_engine.button_pressed)
		GameSettings.set_player_threat_arrows(chk_white_threats.button_pressed)
		GameSettings.set_opponent_engine_arrows(chk_black_engine.button_pressed)
		GameSettings.set_opponent_threat_arrows(chk_black_threats.button_pressed)
	else:
		GameSettings.show_white_engine_arrows = chk_white_engine.button_pressed
		GameSettings.show_white_threat_arrows = chk_white_threats.button_pressed
		GameSettings.show_black_engine_arrows = chk_black_engine.button_pressed
		GameSettings.show_black_threat_arrows = chk_black_threats.button_pressed
	GameSettings.sound_enabled = chk_sound.button_pressed
	GameSettings.save_settings()

	_update_side_icons()
	_sync_engine_assist_ui()
	_sync_delay_ui()
	if mini_board:
		mini_board.queue_redraw()
	settings_modal.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		if trainer_modal and trainer_modal.visible:
			trainer_modal.visible = false
			get_viewport().set_input_as_handled()
			return
		if update_modal and update_modal.visible:
			update_modal.visible = false
			get_viewport().set_input_as_handled()
			return
		if settings_modal.visible:
			settings_modal.visible = false
			get_viewport().set_input_as_handled()

func _on_version_label_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_update_pressed()

func _refresh_version_display() -> void:
	var ver = _get_active_build_version()
	if version_label:
		version_label.text = ver
	if local_version_label:
		local_version_label.text = "Local: %s" % _get_git_branch_info()

func _get_active_build_version() -> String:
	var hash_str = _get_git_short_hash()
	var rev_count = _get_git_commit_count()
	if rev_count > 0:
		return "v1.0.%d (%s)" % [rev_count, hash_str]
	if hash_str != "main" and not hash_str.is_empty():
		return "v1.0.0 (%s)" % hash_str
	return "v1.0.0"

func _get_git_commit_count() -> int:
	var out: Array = []
	var git_exe = _get_git_executable()
	var project_dir = ProjectSettings.globalize_path("res://")
	var code = OS.execute(git_exe, ["-C", project_dir, "rev-list", "--count", "HEAD"], out, true)
	if code == 0 and not out.is_empty():
		return int(str(out[0]).strip_edges())
	return 0

func _on_update_pressed() -> void:
	if update_modal:
		update_modal.visible = true
		_refresh_version_display()
		check_for_updates()

func _open_trainer_menu() -> void:
	if trainer_modal == null:
		get_tree().change_scene_to_file(OPENING_TRAINER_PATH)
		return
	_update_trainer_tab_buttons()
	_populate_trainer_cards()
	trainer_modal.visible = true

func _update_trainer_tab_buttons() -> void:
	if btn_tab_openings:
		TactileStyles.apply_tactile_button(btn_tab_openings, false, current_trainer_tab == "openings", false)
	if btn_tab_checkmate:
		TactileStyles.apply_tactile_button(btn_tab_checkmate, false, current_trainer_tab == "checkmate", false)
	if btn_tab_queen:
		TactileStyles.apply_tactile_button(btn_tab_queen, false, current_trainer_tab == "queen_tactics", false)
	
	if trainer_modal_title:
		match current_trainer_tab:
			"openings":
				trainer_modal_title.text = "Pilih Latihan Pembukaan"
			"checkmate":
				trainer_modal_title.text = "Checkmate Trainer"
			"queen_tactics":
				trainer_modal_title.text = "Queen Tactics & Captures"

func _select_trainer_tab(tab: String) -> void:
	current_trainer_tab = tab
	_update_trainer_tab_buttons()
	_populate_trainer_cards()

func _populate_trainer_cards() -> void:
	if trainer_cards_container == null:
		return
	for child in trainer_cards_container.get_children():
		trainer_cards_container.remove_child(child)
		child.queue_free()

	match current_trainer_tab:
		"openings":
			_populate_opening_cards()
		"checkmate":
			_populate_tactics_cards("checkmate_patterns")
		"queen_tactics":
			_populate_tactics_cards("queen_captures")

func _populate_opening_cards() -> void:
	var reps: Array[Dictionary] = RepertoireService.get_available_repertoires()
	for meta in reps:
		var rep_id: String = meta.get("id", "")
		var rep_name: String = meta.get("name", "Unknown Opening")
		var rep_eco: String = meta.get("eco", "")
		var rep_color: String = meta.get("color", "white")
		var rep_desc: String = meta.get("description", "")
		var total_moves: int = int(meta.get("total_moves", 0))
		var mastery_pct: float = float(meta.get("mastery_percent", 0.0))

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 108)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		TactileStyles.apply_tactile_button(btn, false, false, false)

		var margin: MarginContainer = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		btn.add_child(margin)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_theme_constant_override("separation", 6)
		margin.add_child(card_vbox)

		# Row 1: Title + Side/ECO Badge
		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(top_row)

		var title_lbl: Label = Label.new()
		title_lbl.theme_type_variation = &"LabelBold"
		title_lbl.text = rep_name
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 19)
		title_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
		top_row.add_child(title_lbl)

		var meta_chip: PanelContainer = PanelContainer.new()
		meta_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip_sb: StyleBoxFlat = StyleBoxFlat.new()
		chip_sb.set_corner_radius_all(6)
		chip_sb.content_margin_left = 8
		chip_sb.content_margin_right = 8
		chip_sb.content_margin_top = 2
		chip_sb.content_margin_bottom = 2
		var is_white_side: bool = (rep_color.to_lower() == "white")
		chip_sb.bg_color = Color(0.20, 0.25, 0.18, 0.95) if is_white_side else Color(0.25, 0.20, 0.16, 0.95)
		chip_sb.border_width_left = 1
		chip_sb.border_width_top = 1
		chip_sb.border_width_right = 1
		chip_sb.border_width_bottom = 1
		chip_sb.border_color = Color(0.506, 0.714, 0.298, 0.7) if is_white_side else Color(0.9, 0.65, 0.35, 0.7)
		meta_chip.add_theme_stylebox_override("panel", chip_sb)

		var meta_lbl: Label = Label.new()
		meta_lbl.theme_type_variation = &"LabelBold"
		meta_lbl.add_theme_font_size_override("font_size", 13)
		var side_str: String = "White" if is_white_side else "Black"
		meta_lbl.text = "%s  •  %s" % [rep_eco, side_str]
		meta_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.8, 1.0) if is_white_side else Color(1.0, 0.88, 0.7, 1.0))
		meta_chip.add_child(meta_lbl)
		top_row.add_child(meta_chip)

		# Row 2: Ringkasan gambit / pembukaan (Indonesian)
		var desc_lbl: Label = Label.new()
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.text = rep_desc
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.76, 0.74, 1.0))
		card_vbox.add_child(desc_lbl)

		# Row 3: Info ringkas moves & penguasaan
		var stats_row: HBoxContainer = HBoxContainer.new()
		stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_row.add_theme_constant_override("separation", 14)
		card_vbox.add_child(stats_row)

		var stats_lbl: Label = Label.new()
		stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_lbl.add_theme_font_size_override("font_size", 13)
		stats_lbl.text = "%d moves  •  Penguasaan: %.0f%%" % [total_moves, mastery_pct]
		stats_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.68, 1.0))
		stats_row.add_child(stats_lbl)

		btn.pressed.connect(func(): _start_training_repertoire(rep_id))
		trainer_cards_container.add_child(btn)

func _populate_tactics_cards(set_id: String) -> void:
	var set_data: Dictionary = TacticsService.load_set(set_id)
	var puzzles: Array = set_data.get("puzzles", [])
	
	for i in range(puzzles.size()):
		var p: Dictionary = puzzles[i] if puzzles[i] is Dictionary else {}
		var pid: String = p.get("id", "")
		var p_title: String = p.get("title", "Puzzle")
		var p_side: String = p.get("side", "white")
		var p_theme: String = p.get("theme", "").replace("_", " ").capitalize()
		var p_blurb: String = p.get("blurb", "")
		var p_diff: int = int(p.get("difficulty", 1))

		var prog = TacticsService.get_puzzle_progress(pid)
		var stars = int(prog.get("stars", 0))

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 108)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		TactileStyles.apply_tactile_button(btn, false, false, false)

		var margin: MarginContainer = MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		btn.add_child(margin)

		var card_vbox: VBoxContainer = VBoxContainer.new()
		card_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_theme_constant_override("separation", 6)
		margin.add_child(card_vbox)

		# Row 1: Title + Side/Theme Badge
		var top_row: HBoxContainer = HBoxContainer.new()
		top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(top_row)

		var title_lbl: Label = Label.new()
		title_lbl.theme_type_variation = &"LabelBold"
		title_lbl.text = "%d. %s" % [i + 1, p_title]
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 19)
		title_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
		top_row.add_child(title_lbl)

		var meta_chip: PanelContainer = PanelContainer.new()
		meta_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var chip_sb: StyleBoxFlat = StyleBoxFlat.new()
		chip_sb.set_corner_radius_all(6)
		chip_sb.content_margin_left = 8
		chip_sb.content_margin_right = 8
		chip_sb.content_margin_top = 2
		chip_sb.content_margin_bottom = 2
		var is_white_side: bool = (p_side.to_lower() == "white")
		chip_sb.bg_color = Color(0.20, 0.25, 0.18, 0.95) if is_white_side else Color(0.25, 0.20, 0.16, 0.95)
		chip_sb.border_width_left = 1
		chip_sb.border_width_top = 1
		chip_sb.border_width_right = 1
		chip_sb.border_width_bottom = 1
		chip_sb.border_color = Color(0.506, 0.714, 0.298, 0.7) if is_white_side else Color(0.9, 0.65, 0.35, 0.7)
		meta_chip.add_theme_stylebox_override("panel", chip_sb)

		var meta_lbl: Label = Label.new()
		meta_lbl.theme_type_variation = &"LabelBold"
		meta_lbl.add_theme_font_size_override("font_size", 13)
		var side_str: String = "White" if is_white_side else "Black"
		meta_lbl.text = "%s  •  %s" % [side_str, p_theme]
		meta_lbl.add_theme_color_override("font_color", Color(0.85, 0.95, 0.8, 1.0) if is_white_side else Color(1.0, 0.88, 0.7, 1.0))
		meta_chip.add_child(meta_lbl)
		top_row.add_child(meta_chip)

		# Row 2: Blurb deskripsi
		var desc_lbl: Label = Label.new()
		desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.text = p_blurb
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.76, 0.74, 1.0))
		card_vbox.add_child(desc_lbl)

		# Row 3: Info difficulty & status
		var stats_row: HBoxContainer = HBoxContainer.new()
		stats_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats_row.add_theme_constant_override("separation", 14)
		card_vbox.add_child(stats_row)

		var stats_lbl: Label = Label.new()
		stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stats_lbl.add_theme_font_size_override("font_size", 13)
		var stars_text = "New"
		if stars == 3:
			stars_text = "[***] Solved"
		elif stars == 2:
			stars_text = "[** ] Solved"
		elif stars == 1:
			stars_text = "[*  ] Solved"
		stats_lbl.text = "Difficulty %d  •  Status: %s" % [p_diff, stars_text]
		stats_lbl.add_theme_color_override("font_color", Color(0.60, 0.65, 0.68, 1.0))
		stats_row.add_child(stats_lbl)

		btn.pressed.connect(func(): _start_training_tactics(set_id, pid))
		trainer_cards_container.add_child(btn)

func _start_training_repertoire(rep_id: String) -> void:
	if trainer_modal:
		trainer_modal.visible = false
	var gs = get_node_or_null("/root/GameSettings")
	if gs and "selected_repertoire_id" in gs:
		gs.selected_repertoire_id = rep_id
	get_tree().change_scene_to_file(OPENING_TRAINER_PATH)

func _start_training_tactics(set_id: String, puzzle_id: String = "") -> void:
	if trainer_modal:
		trainer_modal.visible = false
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameSettings")
		if gs:
			if "selected_tactics_set_id" in gs:
				gs.selected_tactics_set_id = set_id
			if "selected_tactics_puzzle_id" in gs:
				gs.selected_tactics_puzzle_id = puzzle_id
	get_tree().change_scene_to_file(TACTICS_TRAINER_PATH)

func check_for_updates() -> void:
	if not status_label:
		return
	status_label.text = "Checking remote repository for changes..."
	if btn_check_update:
		btn_check_update.disabled = true
	if btn_install_update:
		btn_install_update.disabled = true

	var git_exe = _get_git_executable()
	var project_dir = ProjectSettings.globalize_path("res://")
	var output: Array = []
	var exit_code = OS.execute(git_exe, ["-C", project_dir, "fetch", "origin", "main"], output, true)
	if exit_code != 0:
		# Fallback to current branch or master
		exit_code = OS.execute(git_exe, ["-C", project_dir, "fetch", "origin"], output, true)

	if exit_code != 0:
		status_label.text = "Failed to connect to remote repo. Please check internet connection or git remote."
		if btn_check_update:
			btn_check_update.disabled = false
		return

	var status_output: Array = []
	var rev_exit = OS.execute(git_exe, ["-C", project_dir, "rev-list", "--count", "HEAD..@{u}"], status_output, true)
	var commits_behind = 0
	if rev_exit == 0 and not status_output.is_empty():
		commits_behind = int(str(status_output[0]).strip_edges())

	var remote_log: Array = []
	OS.execute(git_exe, ["-C", project_dir, "log", "-n", "1", "@{u}", "--format=%h - %s"], remote_log, true)
	var latest_msg = str(remote_log[0]).strip_edges() if not remote_log.is_empty() else "Up to date"

	if remote_version_label:
		remote_version_label.text = "Latest: %s" % (latest_msg.substr(0, 24) + "..." if latest_msg.length() > 24 else latest_msg)

	if commits_behind > 0:
		status_label.text = "Update available! (%d commits behind origin).\nLatest: %s" % [commits_behind, latest_msg]
		if btn_install_update:
			btn_install_update.disabled = false
	else:
		status_label.text = "Chess 2.0 is up to date with origin!\nHead: %s" % latest_msg
		if btn_install_update:
			btn_install_update.disabled = true

	if btn_check_update:
		btn_check_update.disabled = false

func install_update() -> void:
	if not status_label:
		return
	status_label.text = "Pulling updates from GitHub..."
	if btn_install_update:
		btn_install_update.disabled = true
	if btn_check_update:
		btn_check_update.disabled = true

	var git_exe = _get_git_executable()
	var project_dir = ProjectSettings.globalize_path("res://")
	var pull_out: Array = []
	var exit_code = OS.execute(git_exe, ["-C", project_dir, "pull", "--ff-only"], pull_out, true)
	var pull_str = str(pull_out[0]) if not pull_out.is_empty() else ""

	for _retry in range(2):
		if exit_code == 0:
			break
		if not _resolve_godot_pull_conflicts(git_exe, project_dir, pull_str):
			break
		pull_out = []
		exit_code = OS.execute(git_exe, ["-C", project_dir, "pull", "--ff-only"], pull_out, true)
		pull_str = str(pull_out[0]) if not pull_out.is_empty() else ""

	if exit_code == 0:
		status_label.text = "Update installed successfully!\nPlease restart the game to apply changes.\n" + pull_str.strip_edges()
		_refresh_version_display()
		if btn_install_update:
			btn_install_update.disabled = true
	else:
		status_label.text = "Failed to pull updates automatically.\nOutput: " + pull_str.strip_edges()
		if btn_install_update:
			btn_install_update.disabled = false

	if btn_check_update:
		btn_check_update.disabled = false

static func _is_godot_generated_metadata_file(rel_path: String) -> bool:
	var clean := rel_path.strip_edges().replace("\\", "/")
	if clean.is_empty() or clean.begins_with("/") or clean.contains(":") or clean.contains(".."):
		return false
	return clean.ends_with(".uid") or clean.ends_with(".import")

static func _extract_merge_conflict_files(pull_output: String) -> Dictionary:
	var untracked: Array[String] = []
	var tracked: Array[String] = []
	var mode := ""
	for raw_line in pull_output.replace("\r\n", "\n").split("\n"):
		if raw_line.contains("untracked working tree files would be overwritten by merge:"):
			mode = "untracked"
			continue
		if raw_line.contains("local changes to the following files would be overwritten by merge:"):
			mode = "tracked"
			continue
		if mode.is_empty():
			continue
		var trimmed := raw_line.strip_edges()
		if trimmed.is_empty() or trimmed.begins_with("Please ") or trimmed.begins_with("Aborting") or trimmed.begins_with("Updating ") or trimmed.begins_with("error:") or trimmed.begins_with("fatal:"):
			mode = ""
			continue
		if mode == "untracked":
			untracked.append(trimmed)
		elif mode == "tracked":
			tracked.append(trimmed)
	return {"untracked": untracked, "tracked": tracked}

func _resolve_godot_pull_conflicts(git_exe: String, project_dir: String, pull_output: String) -> bool:
	var conflicts := _extract_merge_conflict_files(pull_output)
	var untracked: Array = conflicts["untracked"]
	var tracked: Array = conflicts["tracked"]
	if untracked.is_empty() and tracked.is_empty():
		return false
	for p in untracked:
		if not _is_godot_generated_metadata_file(str(p)):
			return false
	for p in tracked:
		if not _is_godot_generated_metadata_file(str(p)):
			return false
	for p in untracked:
		var abs_path := project_dir.path_join(str(p))
		if FileAccess.file_exists(abs_path):
			if DirAccess.remove_absolute(abs_path) != OK:
				return false
	if not tracked.is_empty():
		var args: Array[String] = ["-C", project_dir, "checkout", "--"]
		for p in tracked:
			args.append(str(p))
		var co_out: Array = []
		if OS.execute(git_exe, args, co_out, true) != 0:
			return false
	return true

func _get_git_branch_info() -> String:
	var out: Array = []
	var git_exe = _get_git_executable()
	var project_dir = ProjectSettings.globalize_path("res://")
	var code = OS.execute(git_exe, ["-C", project_dir, "log", "-n", "1", "--format=%h (%cd)", "--date=short"], out, true)
	if code == 0 and not out.is_empty():
		return str(out[0]).strip_edges()
	return "Git Version"

func _get_git_short_hash() -> String:
	var out: Array = []
	var git_exe = _get_git_executable()
	var project_dir = ProjectSettings.globalize_path("res://")
	var code = OS.execute(git_exe, ["-C", project_dir, "log", "-n", "1", "--format=%h"], out, true)
	if code == 0 and not out.is_empty():
		return str(out[0]).strip_edges()
	return "main"

func _get_git_executable() -> String:
	var standard_paths: Array[String] = [
		"git",
		"C:/Program Files/Git/bin/git.exe",
		"C:/Program Files/Git/cmd/git.exe",
	]
	var local_app_data := OS.get_environment("LOCALAPPDATA")
	if not local_app_data.is_empty():
		standard_paths.append(local_app_data.path_join("Programs/Git/cmd/git.exe"))
	for p in standard_paths:
		if p == "git" or FileAccess.file_exists(p):
			return p
	return "git"

func _check_engine_bootstrap() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if EngineBootstrap.is_stockfish_ready():
		return
	_show_engine_setup_modal()

func _show_engine_setup_modal() -> void:
	if _engine_setup_modal != null:
		_engine_setup_modal.visible = true
		return

	_engine_setup_modal = ColorRect.new()
	_engine_setup_modal.name = "EngineSetupModal"
	_engine_setup_modal.color = Color(0.05, 0.06, 0.08, 0.82)
	_engine_setup_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_engine_setup_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_engine_setup_modal)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_engine_setup_modal.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(460, 210)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.145, 0.141, 0.133, 1.0)
	card_style.border_color = Color(0.32, 0.31, 0.29, 1.0)
	card_style.set_border_width_all(2)
	card_style.set_corner_radius_all(12)
	card_style.set_content_margin_all(24)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	card.add_child(vbox)

	var title := Label.new()
	title.text = "First-Time Engine Setup"
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = "Stockfish 18 engine binary is missing after clone. Downloading automatically so bot moves and engine arrows work."
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.78, 0.77, 0.75, 1.0))
	vbox.add_child(desc)

	_engine_setup_bar = ProgressBar.new()
	_engine_setup_bar.custom_minimum_size = Vector2(0, 22)
	_engine_setup_bar.min_value = 0.0
	_engine_setup_bar.max_value = 100.0
	_engine_setup_bar.value = 0.0
	vbox.add_child(_engine_setup_bar)

	_engine_setup_status = Label.new()
	_engine_setup_status.text = "Preparing download..."
	_engine_setup_status.add_theme_font_size_override("font_size", 13)
	_engine_setup_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_engine_setup_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_engine_setup_status)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	vbox.add_child(actions)

	_engine_setup_btn_retry = Button.new()
	_engine_setup_btn_retry.text = "Retry Download"
	_engine_setup_btn_retry.custom_minimum_size = Vector2(150, 38)
	_engine_setup_btn_retry.visible = false
	_engine_setup_btn_retry.pressed.connect(_on_engine_setup_retry)
	actions.add_child(_engine_setup_btn_retry)

	_engine_setup_btn_skip = Button.new()
	_engine_setup_btn_skip.text = "Skip"
	_engine_setup_btn_skip.custom_minimum_size = Vector2(110, 38)
	_engine_setup_btn_skip.visible = false
	_engine_setup_btn_skip.pressed.connect(func():
		if _engine_setup_modal != null:
			_engine_setup_modal.visible = false
	)
	actions.add_child(_engine_setup_btn_skip)

	_engine_bootstrap = EngineBootstrap.new()
	add_child(_engine_bootstrap)
	_engine_bootstrap.download_progress.connect(_on_engine_setup_progress)
	_engine_bootstrap.download_completed.connect(_on_engine_setup_completed)
	_engine_bootstrap.start_stockfish_download()

func _on_engine_setup_retry() -> void:
	if _engine_setup_btn_retry:
		_engine_setup_btn_retry.visible = false
	if _engine_setup_btn_skip:
		_engine_setup_btn_skip.visible = false
	if _engine_setup_bar:
		_engine_setup_bar.value = 0.0
	if _engine_bootstrap:
		_engine_bootstrap.start_stockfish_download()

func _on_engine_setup_progress(_downloaded: int, _total: int, percent: float, status_text: String) -> void:
	if _engine_setup_status:
		_engine_setup_status.text = status_text
	if _engine_setup_bar:
		if _engine_setup_tween != null and _engine_setup_tween.is_valid():
			_engine_setup_tween.kill()
		_engine_setup_tween = create_tween()
		_engine_setup_tween.tween_property(_engine_setup_bar, "value", percent, 0.14)

func _on_engine_setup_completed(success: bool, message: String) -> void:
	if _engine_setup_status:
		_engine_setup_status.text = message
	if success:
		if _engine_setup_bar:
			_engine_setup_bar.value = 100.0
		var tree := get_tree()
		if tree != null:
			await tree.create_timer(0.8).timeout
		if _engine_setup_modal != null:
			_engine_setup_modal.visible = false
	else:
		if _engine_setup_btn_retry:
			_engine_setup_btn_retry.visible = true
		if _engine_setup_btn_skip:
			_engine_setup_btn_skip.visible = true
