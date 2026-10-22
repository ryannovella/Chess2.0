class_name PauseMenu
extends Control

signal resume_pressed
signal restart_pressed
signal resign_pressed
signal main_menu_pressed

@onready var btn_resume: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnResume
@onready var btn_restart: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnRestart
@onready var btn_resign: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnResign
@onready var btn_main_menu: Button = $CenterContainer/PanelContainer/VBoxContainer/BtnMainMenu

func _ready() -> void:
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)
	btn_resign.pressed.connect(_on_resign_pressed)
	btn_main_menu.pressed.connect(_on_main_menu_pressed)

func show_pause(can_resume: bool = true) -> void:
	visible = true
	btn_resume.visible = can_resume
	btn_resign.visible = can_resume
	if can_resume:
		btn_resume.grab_focus()
	else:
		btn_restart.grab_focus()

func hide_pause() -> void:
	visible = false

func _on_resume_pressed() -> void:
	hide_pause()
	resume_pressed.emit()

func _on_restart_pressed() -> void:
	hide_pause()
	restart_pressed.emit()

func _on_resign_pressed() -> void:
	hide_pause()
	resign_pressed.emit()

func _on_main_menu_pressed() -> void:
	hide_pause()
	main_menu_pressed.emit()
