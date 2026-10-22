extends SceneTree

const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")

func _init() -> void:
	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	var panel = review_scene.instantiate()
	root.add_child(panel)
	
	panel.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	print("Initial MoveReviewBox min_size.y:", panel.get_combined_minimum_size().y)
	
	# Long narrative simulation
	var data = {
		"steps": [
			{
				"ply": 1,
				"san": "e4",
				"classification": 9, # BLUNDER
				"best_move": "d2d4",
				"eval_loss_cp": 400.0,
				"explanation": {
					"narrative": "A terrible blunder that completely loses the game. The king is exposed to direct check and the queen is trapped without any defensive squares remaining on the queenside.",
					"emotion": 4
				}
			}
		]
	}
	panel.set_review_data(data)
	panel.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	panel.select_step(0)
	
	print("With long narrative, MoveReviewBox min_size.y:", panel.get_combined_minimum_size().y)
	panel.free()
	quit(0)
