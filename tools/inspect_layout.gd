extends SceneTree

var frame_count = 0
var panel: Control
var container: PanelContainer

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
			"explanation": { "narrative": "Blunder fatal. Melepas kontrol secara drastis. Membuka diagonal raja ke arah g8.", "emotion": 4 }
		}
	]
}

func _init() -> void:
	var gs_script = load("res://src/config/game_settings.gd")
	if gs_script:
		var gs_node = Node.new()
		gs_node.set_script(gs_script)
		gs_node.name = "GameSettings"
		root.add_child(gs_node)

	container = PanelContainer.new()
	container.custom_minimum_size = Vector2(708, 240)
	container.size = Vector2(708, 240)
	root.add_child(container)

	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	panel = review_scene.instantiate()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_child(panel)

func _process(delta: float) -> bool:
	frame_count += 1
	if frame_count == 2:
		panel.set_review_data(mock)
		print("=== STATE 1: SUMMARY TAB ===")
		_dump_sizes()
		panel.switch_tab(1) # MOVES
		panel.select_step(-1) # Start position
	elif frame_count == 4:
		print("\n=== STATE 2: MOVES TAB (STEP -1: START) ===")
		_dump_sizes()
		panel.select_step(0) # Step 0 (Best move)
	elif frame_count == 6:
		print("\n=== STATE 3: MOVES TAB (STEP 0: BEST MOVE) ===")
		_dump_sizes()
		panel.select_step(1) # Step 1 (Blunder)
	elif frame_count == 8:
		print("\n=== STATE 4: MOVES TAB (STEP 1: BLUNDER) ===")
		_dump_sizes()
		panel._on_show_best_pressed() # Toggle Show Best Move
	elif frame_count == 10:
		print("\n=== STATE 5: MOVES TAB (STEP 1: SHOW PLAYED MOVE TOGGLED) ===")
		_dump_sizes()
		quit(0)
		return true
	return false

func _dump_sizes() -> void:
	print("Panel size:", panel.size, " min:", panel.get_combined_minimum_size())
	if panel.summary_box.visible:
		print("SummaryBox size:", panel.summary_box.size, " min:", panel.summary_box.get_combined_minimum_size())
	if panel.move_review_box.visible:
		print("MoveReviewBox size:", panel.move_review_box.size, " min:", panel.move_review_box.get_combined_minimum_size())
		print("CoachCard size:", panel.coach_card.size, " pos:", panel.coach_card.position)
		print("  BadgeIcon visible:", panel.coach_badge_icon.visible, " pos:", panel.coach_badge_icon.position, " size:", panel.coach_badge_icon.size)
		print("  BadgeLabel pos:", panel.coach_badge.position, " size:", panel.coach_badge.size, " text:", panel.coach_badge.text)
		print("  MoveTitleLabel pos:", panel.coach_move_title.position, " size:", panel.coach_move_title.size, " text:", panel.coach_move_title.text)
		print("  ExplanationLabel pos:", panel.coach_text.position, " size:", panel.coach_text.size, " min:", panel.coach_text.get_combined_minimum_size())
		print("  EvalLossLabel visible:", panel.eval_loss_label.visible, " pos:", panel.eval_loss_label.position, " size:", panel.eval_loss_label.size)
		print("ActionRow size:", panel.btn_show_best.get_parent().size, " pos:", panel.btn_show_best.get_parent().position)
		print("  BtnShowBest pos:", panel.btn_show_best.position, " size:", panel.btn_show_best.size, " text:", panel.btn_show_best.text, " dis:", panel.btn_show_best.disabled)
		print("  BtnRetry pos:", panel.btn_retry.position, " size:", panel.btn_retry.size, " text:", panel.btn_retry.text, " dis:", panel.btn_retry.disabled)
		print("NavRow size:", panel.btn_first.get_parent().size, " pos:", panel.btn_first.get_parent().position)
		print("  BtnFirst:", panel.btn_first.size.x, " PrevM:", panel.btn_prev_moment.size.x, " Prev:", panel.btn_prev_move.size.x,
			" Ind:", panel.move_indicator_label.size.x, " Next:", panel.btn_next_move.size.x, " NextM:", panel.btn_next_moment.size.x, " Last:", panel.btn_last.size.x)
