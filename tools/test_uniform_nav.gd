extends SceneTree

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

func _init() -> void:
	var buttons_text = ["|<", "<<", "<", ">", ">>", ">|"]
	var hbox = HBoxContainer.new()
	hbox.size = Vector2(708, 40)
	root.add_child(hbox)
	
	print("--- TEST COMPACT = TRUE WITH CUSTOM_MIN_SIZE ---")
	for target_w in [36, 38, 40, 42, 44]:
		print("\nTarget width:", target_w)
		for t in buttons_text:
			var btn = Button.new()
			btn.theme = load("res://src/theme/theme_modern.tres")
			btn.add_theme_font_size_override("font_size", 14)
			btn.text = t
			btn.clip_text = true
			btn.custom_minimum_size = Vector2(target_w, 34)
			TactileStyles.apply_tactile_button(btn, false, false, true)
			hbox.add_child(btn)
			var sz = btn.get_combined_minimum_size()
			print("  Btn '", t, "' min:", sz)
			btn.free()

	hbox.free()
	quit(0)
