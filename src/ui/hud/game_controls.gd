class_name GameControls
extends PanelContainer

signal new_game_pressed
signal resign_pressed
signal flip_board_pressed
signal open_painter_pressed
signal undo_pressed
signal redo_pressed

@onready var btn_undo: Button = $Margin/Toolbar/BtnUndo
@onready var btn_redo: Button = $Margin/Toolbar/BtnRedo
@onready var btn_flip: Button = $Margin/Toolbar/BtnFlip
@onready var btn_new_game: Button = $Margin/Toolbar/BtnNewGame
@onready var btn_painter: Button = $Margin/Toolbar/BtnPainter
@onready var btn_resign: Button = $Margin/Toolbar/BtnResign

func _ready() -> void:
	btn_undo.pressed.connect(func(): undo_pressed.emit())
	btn_redo.pressed.connect(func(): redo_pressed.emit())
	btn_flip.pressed.connect(func(): flip_board_pressed.emit())

	btn_new_game.pressed.connect(func(): new_game_pressed.emit())
	btn_resign.pressed.connect(func(): resign_pressed.emit())
	btn_painter.pressed.connect(func(): open_painter_pressed.emit())

func update_undo_redo(can_undo: bool, can_redo: bool) -> void:
	if btn_undo:
		btn_undo.disabled = not can_undo
	if btn_redo:
		btn_redo.disabled = not can_redo
