extends SceneTree

func _init() -> void:
	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	var panel = review_scene.instantiate()
	root.add_child(panel)
	var btn = panel.get_node("Margin/VBox/MoveReviewBox/NavRow/BtnPrevMove")
	print("btn_prev_move in tscn:")
	print("  custom_minimum_size:", btn.custom_minimum_size)
	print("  min_size:", btn.get_combined_minimum_size())
	print("  theme overrides:", btn.get_theme_stylebox("normal"))
	var sb = btn.get_theme_stylebox("normal")
	if sb:
		print("  sb class:", sb.get_class())
		print("  content_margins:", sb.content_margin_top, sb.content_margin_bottom)
	panel.free()
	quit(0)
