extends SceneTree

## Diagnostik layout Game Review (berbasis frame, jadi angka minimum size segar).
##
## Mereplikasi rangkaian nyata di src/main.tscn:
##   HUDTabContainer (TabContainer, lantai 148 px, tabs_visible = false)
##   └─ Review (MarginContainer, margin 4)
##      └─ GameReviewPanel
## StyleBox panel TabContainer di main.tscn memberi content margin 8 atas/bawah,
## sehingga lantai 148 px hanya mengikat bila minimum panel <= 124 px.

const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")
const TAB_PANEL_VERTICAL_CHROME := 16.0
const REVIEW_MARGIN_CHROME := 8.0
const FLOOR := 148.0

func _build_mock() -> Dictionary:
	var steps: Array = []
	var classes: Array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
	for i in range(40):
		steps.append({
			"ply": i + 1,
			"san": "Nf%d" % (i + 1),
			"full_notation": "%d. Nf%d" % [(i / 2) + 1, i + 1],
			"color": i % 2,
			"classification": classes[i % classes.size()],
			"eval_white_cp": (i % 11) * 45 - 220,
			"is_mate_after": false,
			"mate_in_after": 0,
			"win_prob_before": 0.5,
			"best_move": "g1f3",
			"played_uci": "g1f3",
			"explanation": {"narrative": "Sample narrative.", "emotion": 1}
		})
	var white_counts: Dictionary = {}
	var black_counts: Dictionary = {}
	for i in range(steps.size()):
		var classification: int = int(steps[i]["classification"])
		if i % 2 == 0:
			white_counts[classification] = int(white_counts.get(classification, 0)) + 1
		else:
			black_counts[classification] = int(black_counts.get(classification, 0)) + 1
	return {
		"white_accuracy": 49.5,
		"black_accuracy": 51.3,
		"white_performance": 100,
		"black_performance": 100,
		"white_counts": white_counts,
		"black_counts": black_counts,
		"steps": steps
	}

func _init() -> void:
	_run()

func _run() -> void:
	var holder := Control.new()
	holder.size = Vector2(708, 420)
	root.add_child(holder)

	var tab := TabContainer.new()
	tab.custom_minimum_size = Vector2(0, FLOOR)
	tab.tabs_visible = false
	tab.clip_tabs = true
	var tab_panel_style := StyleBoxFlat.new()
	tab_panel_style.content_margin_top = 8.0
	tab_panel_style.content_margin_bottom = 8.0
	tab.add_theme_stylebox_override("panel", tab_panel_style)
	holder.add_child(tab)

	var review_margin := MarginContainer.new()
	review_margin.name = "Review"
	review_margin.add_theme_constant_override("margin_left", 4)
	review_margin.add_theme_constant_override("margin_top", 4)
	review_margin.add_theme_constant_override("margin_right", 4)
	review_margin.add_theme_constant_override("margin_bottom", 4)
	tab.add_child(review_margin)

	var panel: GameReviewPanel = load("res://src/ui/hud/game_review_panel.tscn").instantiate()
	review_margin.add_child(panel)
	panel.set_review_data(_build_mock())

	await process_frame
	await process_frame

	print("Anggaran: lantai %d px - chrome %d px = minimum panel yang diizinkan %.0f px" % [
		int(FLOOR), int(TAB_PANEL_VERTICAL_CHROME + REVIEW_MARGIN_CHROME),
		FLOOR - TAB_PANEL_VERTICAL_CHROME - REVIEW_MARGIN_CHROME
	])
	print("")

	var segments := {
		"SUMMARY": GameReviewPanel.ReviewTab.SUMMARY,
		"GRAPH": GameReviewPanel.ReviewTab.GRAPH,
		"MOVES_LIST": GameReviewPanel.ReviewTab.MOVES_LIST,
		"MOVES": GameReviewPanel.ReviewTab.MOVES
	}
	var results: Array = []
	for label in segments.keys():
		panel.switch_tab(segments[label])
		await process_frame
		await process_frame
		var panel_min: Vector2 = panel.get_combined_minimum_size()
		var tab_min: Vector2 = tab.get_combined_minimum_size()
		var needed: float = panel_min.y + TAB_PANEL_VERTICAL_CHROME + REVIEW_MARGIN_CHROME
		results.append({
			"label": label,
			"panel_min": panel_min,
			"tab_min": tab_min,
			"needed": needed,
			"within_floor": needed <= FLOOR
		})
		print("%-8s panel_min=(%.1f, %.1f)  tab_min=(%.1f, %.1f)  dipakai=%.1f px  lantai_148_terjaga=%s" % [
			label, panel_min.x, panel_min.y, tab_min.x, tab_min.y, needed, str(needed <= FLOOR)
		])

	var identical: bool = true
	for result in results:
		if not is_equal_approx(float(result["panel_min"].y), float(results[0]["panel_min"].y)):
			identical = false
	print("")
	print("Tinggi minimum panel identik di ketiga segmen (tanpa layout shift): ", identical)
	print("Semua segmen di dalam lantai 148 px: ", results.all(func(r): return bool(r["within_floor"])))

	holder.free()
	quit(0)
