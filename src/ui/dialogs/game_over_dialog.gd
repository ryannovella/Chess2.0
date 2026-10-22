class_name GameOverDialog
extends Control

signal rematch_pressed
signal review_pressed
signal main_menu_pressed
signal closed

@onready var backdrop: ColorRect = $DimBackdrop
@onready var card_panel: PanelContainer = $CenterContainer/CardPanel
@onready var header_icon: TextureRect = $CenterContainer/CardPanel/VBoxContainer/BannerRow/HeaderIcon
@onready var title_label: Label = $CenterContainer/CardPanel/VBoxContainer/BannerRow/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/CardPanel/VBoxContainer/SubtitleLabel
@onready var score_label: Label = $CenterContainer/CardPanel/VBoxContainer/ScoreBadge/ScoreLabel
@onready var btn_rematch: Button = $CenterContainer/CardPanel/VBoxContainer/BtnRematch
@onready var btn_review: Button = $CenterContainer/CardPanel/VBoxContainer/BtnReview
@onready var btn_main_menu: Button = $CenterContainer/CardPanel/VBoxContainer/BtnMainMenu
@onready var btn_close: Button = $CenterContainer/CardPanel/VBoxContainer/BtnClose

var icon_win = preload("res://assets/ui/icons/icon_checkmark.svg")
var icon_draw = preload("res://assets/ui/icons/icon_handshake.svg")
var icon_loss = preload("res://assets/ui/icons/icon_flag.svg")

var is_animating: bool = false

func _ensure_nodes() -> void:
	if title_label == null:
		backdrop = get_node_or_null("DimBackdrop")
		card_panel = get_node_or_null("CenterContainer/CardPanel")
		header_icon = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BannerRow/HeaderIcon")
		title_label = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BannerRow/TitleLabel")
		subtitle_label = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/SubtitleLabel")
		score_label = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/ScoreBadge/ScoreLabel")
		btn_rematch = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BtnRematch")
		btn_review = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BtnReview")
		btn_main_menu = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BtnMainMenu")
		btn_close = get_node_or_null("CenterContainer/CardPanel/VBoxContainer/BtnClose")

func _ready() -> void:
	_ensure_nodes()
	visible = false
	if btn_rematch and not btn_rematch.pressed.is_connected(_on_rematch_pressed):
		btn_rematch.pressed.connect(_on_rematch_pressed)
	if btn_review and not btn_review.pressed.is_connected(_on_review_pressed):
		btn_review.pressed.connect(_on_review_pressed)
	if btn_main_menu and not btn_main_menu.pressed.is_connected(_on_main_menu_pressed):
		btn_main_menu.pressed.connect(_on_main_menu_pressed)
	if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)

func show_game_over(title: String, subtitle: String, score: String, is_win: bool, is_draw: bool) -> void:
	_ensure_nodes()
	visible = true
	if title_label:
		title_label.text = title
	if subtitle_label:
		subtitle_label.text = subtitle
	if score_label:
		score_label.text = score

	if header_icon and title_label:
		if is_draw:
			header_icon.texture = icon_draw
			header_icon.modulate = Color(0.9, 0.82, 0.45) # Gold
			title_label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
		elif is_win:
			header_icon.texture = icon_win
			header_icon.modulate = Color(0.3, 0.9, 0.5) # Emerald Green
			title_label.add_theme_color_override("font_color", Color(0.4, 0.95, 0.6))
		else:
			header_icon.texture = icon_loss
			header_icon.modulate = Color(0.95, 0.45, 0.45) # Crimson / Slate Red
			title_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.55))

	if card_panel and backdrop and is_inside_tree():
		# Animasi Tween popup halus (scale in & fade in)
		var p_size = card_panel.size
		if p_size.x <= 0.0 or p_size.y <= 0.0:
			p_size = card_panel.custom_minimum_size
		if p_size.x <= 0.0:
			p_size = Vector2(520, 400)
		card_panel.pivot_offset = p_size * 0.5
		card_panel.scale = Vector2(0.8, 0.8)
		card_panel.modulate.a = 0.0
		backdrop.modulate.a = 0.0

		var tween = create_tween().set_parallel(true)
		tween.tween_property(backdrop, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_panel, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(card_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if btn_rematch and is_inside_tree():
		btn_rematch.grab_focus()

func hide_dialog(on_complete: Callable = Callable()) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(backdrop, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(card_panel, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(card_panel, "scale", Vector2(0.85, 0.85), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().finished.connect(func():
		visible = false
		if on_complete.is_valid():
			on_complete.call()
	)

func _on_rematch_pressed() -> void:
	hide_dialog(func(): rematch_pressed.emit())

func _on_review_pressed() -> void:
	hide_dialog(func(): review_pressed.emit())

func _on_main_menu_pressed() -> void:
	hide_dialog(func(): main_menu_pressed.emit())

func _on_close_pressed() -> void:
	hide_dialog(func(): closed.emit())
