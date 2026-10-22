extends SceneTree

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

func _init() -> void:
	var hbox = HBoxContainer.new()
	hbox.size = Vector2(500, 40)
	
	var b1 = Button.new()
	b1.text = "<<"
	b1.custom_minimum_size = Vector2(36, 34)
	TactileStyles.apply_tactile_button(b1, false, false)
	hbox.add_child(b1)
	
	var b2 = Button.new()
	b2.text = "<"
	b2.custom_minimum_size = Vector2(36, 34)
	TactileStyles.apply_tactile_button(b2, false, false)
	hbox.add_child(b2)
	
	root.add_child(hbox)
	
	print("b1 (<<) min size:", b1.get_combined_minimum_size())
	print("b2 (<) min size:", b2.get_combined_minimum_size())
	
	b1.clip_text = true
	b2.clip_text = true
	print("With clip_text=true:")
	print("b1 (<<) min size:", b1.get_combined_minimum_size())
	print("b2 (<) min size:", b2.get_combined_minimum_size())

	# Now test with custom compact stylebox margins:
	var sb = TactileStyles.create_gray_style("normal")
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	b1.add_theme_stylebox_override("normal", sb)
	print("With margin 6 and text '<<': min size:", b1.get_combined_minimum_size())

	hbox.free()
	quit(0)
