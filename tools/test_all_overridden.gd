extends SceneTree

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

func _init() -> void:
	var buttons = ["|<", "<<", "<", ">", ">>", ">|"]
	var theme = load("res://src/theme/theme_modern.tres")
	
	var sb = StyleBoxFlat.new()
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 4.0

	var hbox = HBoxContainer.new()
	hbox.size = Vector2(700, 40)
	root.add_child(hbox)
	
	for t in buttons:
		var btn = Button.new()
		btn.theme = theme
		btn.add_theme_font_size_override("font_size", 14)
		btn.text = t
		btn.custom_minimum_size = Vector2(38, 34)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)
		btn.add_theme_stylebox_override("disabled", sb)
		hbox.add_child(btn)
		print("Btn '", t, "' min size: ", btn.get_combined_minimum_size())

	hbox.free()
	quit(0)
