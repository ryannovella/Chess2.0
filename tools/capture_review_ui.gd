extends SceneTree

## Menangkap tangkapan layar segmen Game Review untuk verifikasi visual.
## Dijalankan TANPA --headless (butuh renderer nyata), lalu keluar sendiri.
##   & "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . -s res://tools/capture_review_ui.gd

const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")
const OUT_DIR := "res://zzdiag/"
const PANEL_SCENE := "res://src/ui/hud/game_review_panel.tscn"

func _init() -> void:
	_run()

func _mock() -> Dictionary:
	var steps: Array = []
	var classes: Array = [3, 3, 5, 0, 3, 4, 6, 7, 8, 9, 2, 1]
	var evals: Array = [18, 25, 40, 12, -20, -35, -12, 30, 55, 90, 140, 210, 180, 240, 300, 260, 320, 480, 540, 620]
	for i in range(40):
		var classification: int = classes[i % classes.size()]
		var move_number: int = (i / 2) + 1
		steps.append({
			"ply": i + 1,
			"san": "Nf%d" % (i + 1),
			"full_notation": ("%d. Nf%d" % [move_number, i + 1]) if i % 2 == 0 else ("%d... Nf%d" % [move_number, i + 1]),
			"color": i % 2,
			"classification": classification,
			"eval_white_cp": int(evals[i % evals.size()]),
			"eval_loss_cp": 0,
			"is_mate_after": false,
			"mate_in_after": 0,
			"win_prob_before": 0.5,
			"best_move": "g1f3",
			"played_uci": "g1f3",
			"prev_fen": "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
			"explanation": {"narrative": "Sample narrative for capture.", "emotion": 1}
		})
	steps[31]["classification"] = 7
	steps[31]["eval_white_cp"] = -420
	steps[31]["eval_loss_cp"] = 380
	steps[31]["explanation"] = {
		"narrative": "Knight mundur ke pinggir papan dan melepas tekanan di pusat. Stockfish menyarankan pertukaran di d5.",
		"emotion": 3
	}
	steps[35]["classification"] = 9
	steps[35]["eval_white_cp"] = -780
	steps[37]["classification"] = 6
	steps[37]["eval_white_cp"] = -210
	steps[39]["classification"] = 3
	steps[39]["eval_white_cp"] = 99999
	steps[39]["is_mate_after"] = true
	steps[39]["mate_in_after"] = 0

	var white_counts: Dictionary = {}
	var black_counts: Dictionary = {}
	for i in range(steps.size()):
		var classification: int = int(steps[i]["classification"])
		if i % 2 == 0:
			white_counts[classification] = int(white_counts.get(classification, 0)) + 1
		else:
			black_counts[classification] = int(black_counts.get(classification, 0)) + 1
	return {
		"white_accuracy": 61.4,
		"black_accuracy": 48.9,
		"white_performance": 1240,
		"black_performance": 880,
		"opening_name": "Italian Game",
		"opening_eco": "C50",
		"white_counts": white_counts,
		"black_counts": black_counts,
		"steps": steps
	}

func _make_panel(height: float, y: float) -> GameReviewPanel:
	var tab := TabContainer.new()
	tab.custom_minimum_size = Vector2(708, height)
	tab.size = Vector2(708, height)
	tab.position = Vector2(6, y)
	tab.tabs_visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.125, 0.118, 0.11, 0.95)
	style.content_margin_left = 6
	style.content_margin_top = 8
	style.content_margin_right = 6
	style.content_margin_bottom = 8
	style.set_corner_radius_all(8)
	tab.add_theme_stylebox_override("panel", style)
	root.add_child(tab)

	var margin := MarginContainer.new()
	margin.name = "Review"
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	tab.add_child(margin)

	var panel: GameReviewPanel = load(PANEL_SCENE).instantiate()
	margin.add_child(panel)
	return panel

func _capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image != null:
		image.save_png(path)
		print("saved: ", path, " ", image.get_size())

func _run() -> void:
	# Folder ini murni scratch untuk tangkapan layar verifikasi dan tidak disimpan di
	# repo, jadi dibuat ulang di sini supaya skrip tetap bisa dijalankan kapan saja.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var background := ColorRect.new()
	background.color = Color(0.086, 0.086, 0.094)
	background.size = Vector2(720, 1280)
	root.add_child(background)

	# 1. Segmen Graph (eval White checkmate win di puncak, tidak curam ke bawah).
	var panel_graph := _make_panel(232.0, 16.0)
	# 2. Segmen Moves yang baru (berjejer dengan Summary, Graph, Move Review).
	var panel_moves_list := _make_panel(360.0, 264.0)
	# 3. Segmen Move Review (langkah aktif move 1, kartu Start Position placeholder hilang).
	var panel_moves := _make_panel(232.0, 640.0)

	# _ready() baru berjalan pada frame pertama (root belum siap saat _init),
	# jadi seluruh pengisian data dilakukan setelah dua frame.
	await process_frame
	await process_frame

	panel_graph.set_review_data(_mock())
	panel_graph.switch_tab(GameReviewPanel.ReviewTab.GRAPH)
	panel_graph.select_step(39)

	panel_moves_list.set_review_data(_mock())
	panel_moves_list.switch_tab(GameReviewPanel.ReviewTab.MOVES_LIST)

	panel_moves.set_review_data(_mock())
	panel_moves.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	panel_moves.select_step(0)

	for i in range(6):
		await process_frame
	await _capture(OUT_DIR + "review_segments.png")

	# Keadaan analisis progresif: titik netral bertambah, ekor kanan diredupkan,
	# dan perpindahan segmen dinonaktifkan sampai analisis selesai.
	panel_moves_list.reset_view()
	panel_moves_list.set_analysis_progress(8, 41)
	for i in range(1, 9):
		panel_moves_list.append_graph_point(i, int(90.0 * sin(float(i) * 0.5)) - (i * 6), false, 0)
	for i in range(6):
		await process_frame
	await _capture(OUT_DIR + "review_progressive.png")

	quit(0)
