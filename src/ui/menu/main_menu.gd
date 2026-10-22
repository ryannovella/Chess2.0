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
@onready var elo_label: Label = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/Header/EloLabel
@onready var elo_slider: HSlider = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/EloSlider
@onready var delay_slider: HSlider = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/DelayRow/DelaySlider
@onready var delay_value_label: Label = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/DelayRow/DelayValueLabel

@onready var btn_preset_400: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset400
@onready var btn_preset_1000: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset1000
@onready var btn_preset_1500: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset1500
@onready var btn_preset_2000: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset2000
@onready var btn_preset_2800: Button = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/DifficultyCard/VBox/PresetRow/BtnPreset2800

@onready var engine_assist_card: PanelContainer = $CenterContainer/MainLayout/RightCard/VBox/SetupScroll/SetupSection/EngineAssistCard
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
@onready var settings_delay_slider: HSlider = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/DelayRow/SettingsDelaySlider
@onready var settings_delay_value: Label = $SettingsModal/CenterContainer/SettingsCard/VBox/Form/DelayRow/SettingsDelayValue
@onready var btn_cancel_settings: Button = $SettingsModal/CenterContainer/SettingsCard/VBox/ModalButtons/BtnCancelSettings
@onready var btn_save_settings: Button = $SettingsModal/CenterContainer/SettingsCard/VBox/ModalButtons/BtnSaveSettings

const MAIN_SCENE_PATH = "res://src/main.tscn"

var selected_mode: String = "vs_ai" # "vs_ai", "local_2p", "painter"

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
	card_trainer.pressed.connect(func(): _select_mode("trainer"))
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

	_update_side_icons()
	_update_side_ui()
	_select_mode("vs_ai")
	_setup_card_delay()
	_setup_settings_form()
	_setup_tactile_card_effects()
	GameSettings.ai_delay_changed.connect(func(_m, _c): _sync_delay_ui())

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
		opponent_name.text = "Opening Trainer"
		opponent_badge.text = "SRS Reps"
		btn_play.text = "Train Openings"
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
		get_tree().change_scene_to_file("res://src/ui/trainer/opening_trainer.tscn")
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
		if update_modal and update_modal.visible:
			update_modal.visible = false
			get_viewport().set_input_as_handled()
			return
		if settings_modal.visible:
			settings_modal.visible = false
			get_viewport().set_input_as_handled()

func _on_update_pressed() -> void:
	if update_modal:
		update_modal.visible = true
		if local_version_label:
			var branch_info = _get_git_branch_info()
			local_version_label.text = "Local: %s" % branch_info
		check_for_updates()

func check_for_updates() -> void:
	if not status_label:
		return
	status_label.text = "Checking remote repository for changes..."
	if btn_check_update:
		btn_check_update.disabled = true
	if btn_install_update:
		btn_install_update.disabled = true

	var output: Array = []
	var exit_code = OS.execute("git", ["fetch", "origin", "main"], output, true)
	if exit_code != 0:
		# Fallback to master if main doesn't exist
		exit_code = OS.execute("git", ["fetch", "origin", "master"], output, true)

	if exit_code != 0:
		status_label.text = "Failed to connect to remote repo. Please check internet connection or git remote."
		if btn_check_update:
			btn_check_update.disabled = false
		return

	var status_output: Array = []
	var rev_exit = OS.execute("git", ["rev-list", "--count", "HEAD..@{u}"], status_output, true)
	var commits_behind = 0
	if rev_exit == 0 and not status_output.is_empty():
		commits_behind = int(str(status_output[0]).strip_edges())

	var remote_log: Array = []
	OS.execute("git", ["log", "-n", "1", "@{u}", "--format=%h - %s"], remote_log, true)
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

	var pull_out: Array = []
	var exit_code = OS.execute("git", ["pull", "--ff-only"], pull_out, true)
	var pull_str = str(pull_out[0]) if not pull_out.is_empty() else ""

	if exit_code == 0:
		status_label.text = "Update installed successfully!\nPlease restart the game to apply changes.\n" + pull_str.strip_edges()
		if local_version_label:
			local_version_label.text = "Local: %s" % _get_git_branch_info()
		if btn_install_update:
			btn_install_update.disabled = true
	else:
		status_label.text = "Failed to pull updates automatically.\nOutput: " + pull_str.strip_edges()
		if btn_install_update:
			btn_install_update.disabled = false

	if btn_check_update:
		btn_check_update.disabled = false

func _get_git_branch_info() -> String:
	var out: Array = []
	var code = OS.execute("git", ["log", "-n", "1", "--format=%h (%cd)", "--date=short"], out, true)
	if code == 0 and not out.is_empty():
		return str(out[0]).strip_edges()
	return "Git Version"
