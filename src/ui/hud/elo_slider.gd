class_name EloSlider
extends PanelContainer

@onready var elo_value_label: Label = $VBoxContainer/Header/EloValueLabel
@onready var rank_label: Label = $VBoxContainer/RankLabel
@onready var hslider: HSlider = $VBoxContainer/HSlider

func _ready() -> void:
	hslider.min_value = 200
	hslider.max_value = 3000
	hslider.step = 25
	hslider.value = GameSettings.ai_elo
	_update_display(int(hslider.value))

	hslider.value_changed.connect(_on_slider_value_changed)
	GameSettings.elo_changed.connect(_on_settings_elo_changed)

func _on_slider_value_changed(value: float) -> void:
	var elo = int(value)
	GameSettings.set_elo(elo)
	_update_display(elo)

func _on_settings_elo_changed(elo: int) -> void:
	if int(hslider.value) != elo:
		hslider.value = elo
	_update_display(elo)

func _update_display(elo: int) -> void:
	elo_value_label.text = "%d" % elo

	var title = "Novice"
	var col = Color(0.4, 0.8, 0.4) # Greenish
	if elo < 400:
		title = "Beginner"
		col = Color(0.3, 0.9, 0.5)
	elif elo < 800:
		title = "Novice"
		col = Color(0.35, 0.8, 0.7)
	elif elo < 1200:
		title = "Casual"
		col = Color(0.4, 0.75, 0.9)
	elif elo < 1600:
		title = "Intermediate"
		col = Color(0.95, 0.8, 0.3)
	elif elo < 2000:
		title = "Advanced"
		col = Color(0.98, 0.6, 0.2)
	elif elo < 2400:
		title = "Master"
		col = Color(0.95, 0.35, 0.35)
	elif elo < 2800:
		title = "Grandmaster"
		col = Color(0.85, 0.3, 0.85)
	else:
		title = "Superhuman"
		col = Color(0.7, 0.5, 1.0)

	rank_label.text = title
	rank_label.add_theme_color_override("font_color", col)
