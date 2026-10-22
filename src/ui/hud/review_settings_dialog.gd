class_name ReviewSettingsDialog
extends Control

signal settings_applied(should_reanalyze: bool)
signal dialog_closed

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

@onready var panel_container: PanelContainer = $Center/Panel
@onready var backdrop: Panel = $Backdrop
@onready var opt_strength: OptionButton = $Center/Panel/Margin/VBox/Grid/OptStrength
@onready var spin_depth: SpinBox = $Center/Panel/Margin/VBox/Grid/SpinDepth
@onready var spin_time: SpinBox = $Center/Panel/Margin/VBox/Grid/SpinTime
@onready var spin_multipv: SpinBox = $Center/Panel/Margin/VBox/Grid/SpinMultiPV
@onready var spin_threads: SpinBox = $Center/Panel/Margin/VBox/Grid/SpinThreads
@onready var spin_hash: SpinBox = $Center/Panel/Margin/VBox/Grid/SpinHash
@onready var btn_apply: Button = $Center/Panel/Margin/VBox/ButtonRow/BtnApply
@onready var btn_close: Button = $Center/Panel/Margin/VBox/ButtonRow/BtnClose

func _ready() -> void:
	visible = false
	_setup_options()
	_apply_styles()
	_connect_signals()

func _setup_options() -> void:
	if opt_strength:
		opt_strength.clear()
		opt_strength.add_item("Fast (Depth 14, 800ms)", 0)
		opt_strength.add_item("Standard (Depth 18, 1500ms)", 1)
		opt_strength.add_item("Deep (Depth 22, 3000ms)", 2)
		opt_strength.add_item("Max (Depth 26, 6000ms)", 3)

func _apply_styles() -> void:
	if btn_apply:
		TactileStyles.apply_tactile_button(btn_apply, true, false)
	if btn_close:
		TactileStyles.apply_tactile_button(btn_close, false, false)

func _connect_signals() -> void:
	if backdrop and not backdrop.gui_input.is_connected(_on_backdrop_gui_input):
		backdrop.gui_input.connect(_on_backdrop_gui_input)
	if opt_strength and not opt_strength.item_selected.is_connected(_on_strength_selected):
		opt_strength.item_selected.connect(_on_strength_selected)
	if btn_apply and not btn_apply.pressed.is_connected(_on_apply_pressed):
		btn_apply.pressed.connect(_on_apply_pressed)
	if btn_close and not btn_close.pressed.is_connected(_on_close_pressed):
		btn_close.pressed.connect(_on_close_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_dialog()
		get_viewport().set_input_as_handled()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_dialog()

func open_dialog() -> void:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameSettings")
	if gs != null:
		match gs.review_strength:
			"fast": opt_strength.selected = 0
			"standard": opt_strength.selected = 1
			"deep": opt_strength.selected = 2
			"max": opt_strength.selected = 3
			_: opt_strength.selected = 0
		
		spin_depth.value = gs.review_depth
		spin_time.value = gs.review_max_time_ms
		spin_multipv.value = gs.review_multipv
		spin_threads.value = gs.review_threads
		spin_hash.value = gs.review_hash_mb
	
	visible = true

func close_dialog() -> void:
	visible = false
	dialog_closed.emit()

func _on_strength_selected(index: int) -> void:
	match index:
		0:
			spin_depth.value = 14
			spin_time.value = 800
			spin_multipv.value = 2
		1:
			spin_depth.value = 18
			spin_time.value = 1500
			spin_multipv.value = 3
		2:
			spin_depth.value = 22
			spin_time.value = 3000
			spin_multipv.value = 3
		3:
			spin_depth.value = 26
			spin_time.value = 6000
			spin_multipv.value = 4

func _on_apply_pressed() -> void:
	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameSettings")
	if gs != null:
		var strength_keys = ["fast", "standard", "deep", "max"]
		var s_idx = clampi(opt_strength.selected, 0, 3)
		gs.review_strength = strength_keys[s_idx]
		gs.set_review_depth(int(spin_depth.value))
		gs.set_review_max_time_ms(int(spin_time.value))
		gs.set_review_multipv(int(spin_multipv.value))
		gs.set_review_threads(int(spin_threads.value))
		gs.set_review_hash_mb(int(spin_hash.value))
		gs.save_settings()

	visible = false
	settings_applied.emit(true)

func _on_close_pressed() -> void:
	close_dialog()
