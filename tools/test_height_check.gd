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
	
	panel.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	panel.eval_loss_label.visible = true
	panel.eval_loss_label.text = "Eval Loss: -1.25 pawn"
	var moves_min = panel.get_combined_minimum_size()
	print("Moves min size with compact nav buttons & eval loss visible:", moves_min)
	print("moves_min.y <= 240.0?", moves_min.y <= 240.0)
	
	panel.switch_tab(GameReviewPanel.ReviewTab.SUMMARY)
	var summary_min = panel.get_combined_minimum_size()
	print("Summary min size:", summary_min)
	print("summary_min.y <= 240.0?", summary_min.y <= 240.0)
	
	panel.free()
	quit(0)
