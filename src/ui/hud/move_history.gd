class_name MoveHistory
extends PanelContainer

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var list_container: GridContainer = $VBoxContainer/ScrollContainer/ListContainer
@onready var count_label: Label = $VBoxContainer/Header/CountLabel

var moves: Array[String] = []

func _ready() -> void:
	clear()

func clear() -> void:
	moves.clear()
	for child in list_container.get_children():
		list_container.remove_child(child)
		child.queue_free()
	count_label.text = "0 moves"

func set_moves(new_moves: Array) -> void:
	clear()
	for s in new_moves:
		add_move(str(s))

func add_move(san: String) -> void:
	moves.append(san)
	var move_num = (moves.size() + 1) / 2
	var is_white = (moves.size() % 2 == 1)

	if is_white:
		# Baris baru: "1. e4"
		var row = HBoxContainer.new()
		row.name = "Row_%d" % move_num
		row.add_theme_constant_override("separation", 6)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var num_lbl = Label.new()
		num_lbl.custom_minimum_size = Vector2(34, 30)
		num_lbl.text = "%d." % move_num
		num_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		num_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(num_lbl)

		var white_lbl = Label.new()
		white_lbl.name = "White"
		white_lbl.custom_minimum_size = Vector2(68, 30)
		white_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		white_lbl.text = san
		white_lbl.add_theme_color_override("font_color", Color(0.96, 0.95, 0.93))
		white_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(white_lbl)

		var black_lbl = Label.new()
		black_lbl.name = "Black"
		black_lbl.custom_minimum_size = Vector2(68, 30)
		black_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		black_lbl.text = ""
		black_lbl.add_theme_color_override("font_color", Color(0.86, 0.85, 0.83))
		black_lbl.add_theme_font_size_override("font_size", 18)
		row.add_child(black_lbl)

		list_container.add_child(row)
	else:
		# Tambahkan langkah hitam pada baris terakhir
		var last_row = list_container.get_child(list_container.get_child_count() - 1)
		if last_row:
			var black_lbl = last_row.get_node_or_null("Black")
			if black_lbl is Label:
				black_lbl.text = san

	count_label.text = "%d moves" % moves.size()

	# Auto-scroll ke bawah
	await get_tree().process_frame
	if scroll_container:
		scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)
