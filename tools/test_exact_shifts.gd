extends SceneTree

const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")

func _init() -> void:
	var root_ctrl = Control.new()
	root_ctrl.size = Vector2(708, 240)
	root.add_child(root_ctrl)
	
	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	var panel = review_scene.instantiate()
	root_ctrl.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var mock = {
		"white_accuracy": 92.5,
		"black_accuracy": 67.8,
		"white_counts": { 2: 3, 1: 1 },
		"black_counts": { 9: 2, 7: 1 },
		"steps": [
			{
				"ply": 1,
				"san": "e4",
				"classification": 2, # BEST
				"best_move": "e2e4",
				"explanation": { "narrative": "Akurat! Mengontrol pusat papan.", "emotion": 1 }
			},
			{
				"ply": 2,
				"san": "f6",
				"classification": 9, # BLUNDER
				"best_move": "e7e5",
				"eval_loss_cp": 350.0,
				"explanation": { "narrative": "Blunder fatal. Melepas kontrol secara drastis.", "emotion": 4 }
			}
		]
	}
	panel.set_review_data(mock)
	
	# Force layout pass
	root_ctrl.force_update_transform()
	
	print("--- TEST STEP -1 (START) ---")
	panel.switch_tab(1)
	panel.select_step(-1)
	print("CoachCard size:", panel.coach_card.size, " pos:", panel.coach_card.position)
	print("ActionRow size:", panel.btn_show_best.get_parent().size, " pos:", panel.btn_show_best.get_parent().position)
	print("NavRow size:", panel.btn_first.get_parent().size, " pos:", panel.btn_first.get_parent().position)
	print("  BadgeIcon visible:", panel.coach_badge_icon.visible, " modulate.a:", panel.coach_badge_icon.modulate.a)
	print("  BadgeLabel text:", panel.coach_badge.text, " pos:", panel.coach_badge.position)
	print("  MoveTitle text:", panel.coach_move_title.text, " pos:", panel.coach_move_title.position)
	print("  BtnFirst:", panel.btn_first.size, " PrevM:", panel.btn_prev_moment.size, " Prev:", panel.btn_prev_move.size,
		" Ind:", panel.move_indicator_label.size, " Next:", panel.btn_next_move.size, " NextM:", panel.btn_next_moment.size, " Last:", panel.btn_last.size)
	
	print("\n--- TEST STEP 0 (BEST) ---")
	panel.select_step(0)
	print("CoachCard size:", panel.coach_card.size, " pos:", panel.coach_card.position)
	print("ActionRow size:", panel.btn_show_best.get_parent().size, " pos:", panel.btn_show_best.get_parent().position)
	print("NavRow size:", panel.btn_first.get_parent().size, " pos:", panel.btn_first.get_parent().position)
	print("  BadgeIcon visible:", panel.coach_badge_icon.visible, " modulate.a:", panel.coach_badge_icon.modulate.a)
	print("  BadgeLabel text:", panel.coach_badge.text, " pos:", panel.coach_badge.position)
	print("  MoveTitle text:", panel.coach_move_title.text, " pos:", panel.coach_move_title.position)
	print("  BtnFirst:", panel.btn_first.size, " PrevM:", panel.btn_prev_moment.size, " Prev:", panel.btn_prev_move.size,
		" Ind:", panel.move_indicator_label.size, " Next:", panel.btn_next_move.size, " NextM:", panel.btn_next_moment.size, " Last:", panel.btn_last.size)
	
	print("\n--- TEST STEP 1 (BLUNDER) ---")
	panel.select_step(1)
	print("CoachCard size:", panel.coach_card.size, " pos:", panel.coach_card.position)
	print("ActionRow size:", panel.btn_show_best.get_parent().size, " pos:", panel.btn_show_best.get_parent().position)
	print("NavRow size:", panel.btn_first.get_parent().size, " pos:", panel.btn_first.get_parent().position)
	print("  EvalLossLabel visible:", panel.eval_loss_label.visible, " text:", panel.eval_loss_label.text)
	
	print("\n--- TEST SHOW BEST MOVE TOGGLE ---")
	panel._on_show_best_pressed()
	print("BtnShowBest text:", panel.btn_show_best.text, " size:", panel.btn_show_best.size)
	print("BtnRetry text:", panel.btn_retry.text, " size:", panel.btn_retry.size)
	print("CoachCard size:", panel.coach_card.size, " pos:", panel.coach_card.position)
	
	root_ctrl.free()
	quit(0)
