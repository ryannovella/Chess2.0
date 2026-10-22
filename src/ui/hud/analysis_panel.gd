class_name AnalysisPanel
extends PanelContainer

@onready var depth_slider: HSlider = $Margin/VBox/DepthRow/DepthSlider
@onready var depth_value_label: Label = $Margin/VBox/DepthRow/DepthValueLabel

@onready var chk_white_engine: CheckBox = $Margin/VBox/WhiteArrowsRow/ChkWhiteEngine
@onready var chk_white_threats: CheckBox = $Margin/VBox/WhiteArrowsRow/ChkWhiteThreats
@onready var black_arrows_row: HBoxContainer = $Margin/VBox/BlackArrowsRow
@onready var chk_black_engine: CheckBox = $Margin/VBox/BlackArrowsRow/ChkBlackEngine
@onready var chk_black_threats: CheckBox = $Margin/VBox/BlackArrowsRow/ChkBlackThreats

var current_mode: String = "vs_ai"

func _ready() -> void:
	# 1. Depth Slider
	depth_slider.value = GameSettings.engine_depth
	depth_value_label.text = "D%d" % GameSettings.engine_depth
	depth_slider.value_changed.connect(_on_depth_slider_changed)
	GameSettings.engine_depth_changed.connect(_on_settings_depth_changed)

	# 2. Arrows Checkboxes
	_sync_arrow_ui()
	GameSettings.arrows_toggled.connect(_sync_arrow_ui)
	GameSettings.settings_changed.connect(_sync_arrow_ui)

	chk_white_engine.toggled.connect(func(_val):
		if current_mode == "vs_ai":
			GameSettings.toggle_player_engine_arrows()
		else:
			GameSettings.toggle_white_engine_arrows()
	)
	chk_white_threats.toggled.connect(func(_val):
		if current_mode == "vs_ai":
			GameSettings.toggle_player_threat_arrows()
		else:
			GameSettings.toggle_white_threat_arrows()
	)
	chk_black_engine.toggled.connect(func(_val):
		if current_mode == "vs_ai":
			GameSettings.toggle_opponent_engine_arrows()
		else:
			GameSettings.toggle_black_engine_arrows()
	)
	chk_black_threats.toggled.connect(func(_val):
		if current_mode == "vs_ai":
			GameSettings.toggle_opponent_threat_arrows()
		else:
			GameSettings.toggle_black_threat_arrows()
	)

func set_game_mode(mode: String) -> void:
	current_mode = mode
	if black_arrows_row:
		black_arrows_row.visible = true
	_sync_arrow_ui()

func _sync_arrow_ui() -> void:
	if current_mode == "vs_ai":
		if chk_white_engine:
			chk_white_engine.text = "Player Best"
			chk_white_engine.set_pressed_no_signal(GameSettings.get_player_engine_arrows())
		if chk_white_threats:
			chk_white_threats.text = "Player Threats"
			chk_white_threats.set_pressed_no_signal(GameSettings.get_player_threat_arrows())
		if chk_black_engine:
			chk_black_engine.text = "Bot Best"
			chk_black_engine.set_pressed_no_signal(GameSettings.get_opponent_engine_arrows())
		if chk_black_threats:
			chk_black_threats.text = "Bot Threats"
			chk_black_threats.set_pressed_no_signal(GameSettings.get_opponent_threat_arrows())
	else:
		if chk_white_engine:
			chk_white_engine.text = "White Best"
			chk_white_engine.set_pressed_no_signal(GameSettings.show_white_engine_arrows)
		if chk_white_threats:
			chk_white_threats.text = "White Threats"
			chk_white_threats.set_pressed_no_signal(GameSettings.show_white_threat_arrows)
		if chk_black_engine:
			chk_black_engine.text = "Black Best"
			chk_black_engine.set_pressed_no_signal(GameSettings.show_black_engine_arrows)
		if chk_black_threats:
			chk_black_threats.text = "Black Threats"
			chk_black_threats.set_pressed_no_signal(GameSettings.show_black_threat_arrows)

func _on_depth_slider_changed(val: float) -> void:
	var d = int(val)
	depth_value_label.text = "D%d" % d
	GameSettings.set_engine_depth(d)

func _on_settings_depth_changed(d: int) -> void:
	if int(depth_slider.value) != d:
		depth_slider.value = d
	depth_value_label.text = "D%d" % d
