extends SceneTree

func _init() -> void:
	var label = Label.new()
	label.theme = load("res://src/theme/theme_modern.tres")
	label.add_theme_font_size_override("font_size", 14)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "Blunder fatal. Melepas kontrol secara drastis. Membuka diagonal raja ke arah g8. Posisi ini memberikan inisiatif taktis penuh kepada lawan untuk melakukan kombinasi skakmat atau memenangkan menteri."
	label.custom_minimum_size = Vector2(300, 0)
	
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(300, 0)
	vbox.add_child(label)
	root.add_child(vbox)
	
	print("No max_lines: label size:", label.get_combined_minimum_size(), " vbox:", vbox.get_combined_minimum_size())
	
	label.max_lines_visible = 2
	print("max_lines=2: label size:", label.get_combined_minimum_size(), " vbox:", vbox.get_combined_minimum_size())
	
	label.max_lines_visible = 3
	print("max_lines=3: label size:", label.get_combined_minimum_size(), " vbox:", vbox.get_combined_minimum_size())

	vbox.free()
	quit(0)
