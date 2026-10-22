extends SceneTree

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

func _init() -> void:
	var buttons = ["|<", "<<", "<", ">", ">>", ">|"]
	var theme = load("res://src/theme/theme_modern.tres")
	
	var normal_sb = TactileStyles.create_gray_style("normal")
	normal_sb.content_margin_left = 6.0
	normal_sb.content_margin_right = 6.0
	
	var disabled_sb = TactileStyles.create_gray_style("normal").duplicate()
	disabled_sb.content_margin_left = 6.0
	disabled_sb.content_margin_right = 6.0
	disabled_sb.modulate_color = Color(0.5, 0.5, 0.5, 0.5)

	var hbox = HBoxContainer.new()
	hbox.size = Vector2(700, 40)
	root.add_child(hbox)
	
	for t in buttons:
		var btn = Button.new()
		btn.theme = theme
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = t
		btn.custom_minimum_size = Vector2(38, 34)
		btn.add_theme_stylebox_override("normal", normal_sb)
		btn.add_theme_stylebox_override("disabled", disabled_sb)
		hbox.add_child(btn)
		print("Btn '", t, "' enabled: ", btn.get_combined_minimum_size(), " disabled: ", (func(): btn.disabled = true; return btn.get_combined_minimum_size()).call())

	hbox.free()
	quit(0)
