extends SceneTree

const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")

func _init() -> void:
	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	var panel = review_scene.instantiate()
	root.add_child(panel)
	panel._ensure_nodes()
	
	var nav_buttons = [
		panel.btn_first, panel.btn_prev_moment, panel.btn_prev_move,
		panel.btn_next_move, panel.btn_next_moment, panel.btn_last
	]
	
	for btn in nav_buttons:
		btn.custom_minimum_size = Vector2(40, 34)
		btn.clip_text = true
		TactileStyles.apply_tactile_button(btn, false, false, true)
	
	print("Nav buttons with compact=true and custom_min=(40, 34):")
	for btn in nav_buttons:
		print("  Btn '", btn.text, "' min:", btn.get_combined_minimum_size(), " disabled:", (func(): btn.disabled = true; return btn.get_combined_minimum_size()).call())
	
	panel.free()
	quit(0)
