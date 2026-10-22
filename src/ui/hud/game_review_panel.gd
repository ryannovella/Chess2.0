class_name GameReviewPanel
extends PanelContainer

signal move_selected(step_index: int)
signal show_best_move_requested(step_index: int, best_move_uci: String, is_showing: bool)
signal retry_mode_requested(step_index: int, prev_fen: String, best_move_uci: String)
signal review_closed
signal settings_requested

const GameReviewService = preload("res://src/core/game_review_service.gd")
const CoachExplanationGenerator = preload("res://src/core/coach_explanation_generator.gd")
const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ReviewBadgeOverlay = preload("res://src/ui/board/review_badge_overlay.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const ReviewRules = preload("res://src/core/review_rules.gd")
const EvalGraph = preload("res://src/ui/hud/eval_graph.gd")

enum ReviewTab {
	SUMMARY,
	GRAPH,
	MOVES_LIST,
	MOVES
}

# UI References - Top Bar
@onready var header_bar: HBoxContainer = $Margin/VBox/HeaderBar
@onready var btn_tab_summary: Button = $Margin/VBox/HeaderBar/BtnTabSummary
@onready var btn_tab_graph: Button = $Margin/VBox/HeaderBar/BtnTabGraph
@onready var btn_tab_moves_list: Button = $Margin/VBox/HeaderBar/BtnTabMovesList
@onready var btn_tab_moves: Button = $Margin/VBox/HeaderBar/BtnTabMoves
@onready var btn_settings: Button = $Margin/VBox/HeaderBar/BtnSettings
@onready var btn_close_review: Button = $Margin/VBox/HeaderBar/BtnCloseReview

# UI References - Progress
@onready var progress_box: VBoxContainer = $Margin/VBox/ProgressBox
@onready var progress_bar: ProgressBar = $Margin/VBox/ProgressBox/ProgressBar
@onready var progress_label: Label = $Margin/VBox/ProgressBox/ProgressLabel

# UI References - Summary View
# Summary view dibungkus ScrollContainer supaya tinggi minimum panel tidak
# ditentukan konten (kalau ditentukan konten, SidePanel ikut memanjang dan
# seluruh layout bergeser saat berpindah tab).
@onready var summary_box: Control = $Margin/VBox/SummaryScroll
@onready var white_accuracy_label: Label = $Margin/VBox/SummaryScroll/SummaryBox/AccuracyLedger/LedgerVBox/AccuracyRow/WhiteCol/WhiteAccLabel
@onready var black_accuracy_label: Label = $Margin/VBox/SummaryScroll/SummaryBox/AccuracyLedger/LedgerVBox/AccuracyRow/BlackCol/BlackAccLabel
@onready var white_perf_label: Label = $Margin/VBox/SummaryScroll/SummaryBox/MoveClassTable/TableVBox/RatingRow/WhitePerfLabel
@onready var black_perf_label: Label = $Margin/VBox/SummaryScroll/SummaryBox/MoveClassTable/TableVBox/RatingRow/BlackPerfLabel
@onready var opening_label: Label = $Margin/VBox/SummaryScroll/SummaryBox/AccuracyLedger/LedgerVBox/OpeningLabel
@onready var counts_container: VBoxContainer = $Margin/VBox/SummaryScroll/SummaryBox/MoveClassTable/TableVBox/CountsContainer
# Aksi utama sengaja diletakkan di luar area scroll supaya tombolnya tidak
# pernah berada di bawah lipatan saat ringkasan perlu di-scroll.
@onready var btn_start_review: Button = $Margin/VBox/BtnStartReview

# UI References - Graph View
@onready var graph_box: VBoxContainer = $Margin/VBox/GraphBox
@onready var eval_graph: EvalGraph = $Margin/VBox/GraphBox/EvalGraph
@onready var graph_readout_label: Label = $Margin/VBox/GraphBox/ReadoutLabel

# UI References - Moves List View
@onready var moves_list_box: VBoxContainer = $Margin/VBox/MovesListBox
@onready var moves_scroll: ScrollContainer = $Margin/VBox/MovesListBox/MovesScroll
@onready var moves_container: VBoxContainer = $Margin/VBox/MovesListBox/MovesScroll/MovesContainer

# UI References - Move Review View
@onready var move_review_box: VBoxContainer = $Margin/VBox/MoveReviewBox
@onready var coach_card: PanelContainer = $Margin/VBox/MoveReviewBox/CoachCard
@onready var coach_avatar: TextureRect = $Margin/VBox/MoveReviewBox/CoachCard/VBox/HeaderRow/Avatar
@onready var coach_badge_icon: TextureRect = $Margin/VBox/MoveReviewBox/CoachCard/VBox/HeaderRow/BadgeIcon
@onready var coach_badge: Label = $Margin/VBox/MoveReviewBox/CoachCard/VBox/HeaderRow/BadgeLabel
@onready var coach_move_title: Label = $Margin/VBox/MoveReviewBox/CoachCard/VBox/HeaderRow/MoveTitleLabel
@onready var coach_text: Label = $Margin/VBox/MoveReviewBox/CoachCard/VBox/ExplanationLabel
@onready var eval_loss_label: Label = $Margin/VBox/MoveReviewBox/CoachCard/VBox/EvalLossLabel

@onready var btn_show_best: Button = $Margin/VBox/MoveReviewBox/ActionRow/BtnShowBest
@onready var btn_retry: Button = $Margin/VBox/MoveReviewBox/ActionRow/BtnRetry
@onready var btn_first: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnFirst
@onready var btn_prev_moment: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnPrevMoment
@onready var btn_prev_move: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnPrevMove
@onready var move_indicator_label: Label = $Margin/VBox/MoveReviewBox/NavRow/MoveIndicatorLabel
@onready var btn_next_move: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnNextMove
@onready var btn_next_moment: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnNextMoment
@onready var btn_last: Button = $Margin/VBox/MoveReviewBox/NavRow/BtnLast

var review_data: Dictionary = {}
var review_steps: Array = []
var current_step_index: int = -1
var is_retry_active: bool = false
var retry_target_move: String = ""
var is_showing_best_move: bool = false
var current_tab: int = ReviewTab.SUMMARY
var _move_list_buttons: Dictionary = {}

func _ready() -> void:
	_ensure_nodes()
	_apply_styles()
	_connect_signals()
	reset_view()

func _ensure_nodes() -> void:
	if header_bar == null:
		header_bar = get_node_or_null("Margin/VBox/HeaderBar")
	if btn_tab_summary == null and header_bar != null:
		btn_tab_summary = header_bar.get_node_or_null("BtnTabSummary")
	if btn_tab_graph == null and header_bar != null:
		btn_tab_graph = header_bar.get_node_or_null("BtnTabGraph")
	if btn_tab_moves_list == null and header_bar != null:
		btn_tab_moves_list = header_bar.get_node_or_null("BtnTabMovesList")
	if btn_tab_moves == null and header_bar != null:
		btn_tab_moves = header_bar.get_node_or_null("BtnTabMoves")
	if btn_settings == null and header_bar != null:
		btn_settings = header_bar.get_node_or_null("BtnSettings")
	if btn_close_review == null and header_bar != null:
		btn_close_review = header_bar.get_node_or_null("BtnCloseReview")

	if progress_box == null:
		progress_box = get_node_or_null("Margin/VBox/ProgressBox")
	if progress_bar == null and progress_box != null:
		progress_bar = progress_box.get_node_or_null("ProgressBar")
	if progress_label == null and progress_box != null:
		progress_label = progress_box.get_node_or_null("ProgressLabel")

	if summary_box == null:
		summary_box = get_node_or_null("Margin/VBox/SummaryScroll")
		if summary_box == null:
			summary_box = get_node_or_null("Margin/VBox/SummaryBox")
	var summary_root: Node = summary_box.get_node_or_null("SummaryBox") if summary_box != null else null
	if summary_root == null:
		summary_root = summary_box
	if white_accuracy_label == null and summary_root != null:
		white_accuracy_label = summary_root.get_node_or_null("AccuracyLedger/LedgerVBox/AccuracyRow/WhiteCol/WhiteAccLabel")
		if white_accuracy_label == null:
			white_accuracy_label = summary_root.get_node_or_null("AccuracyLedger/AccuracyRow/WhiteCol/WhiteAccLabel")
	if black_accuracy_label == null and summary_root != null:
		black_accuracy_label = summary_root.get_node_or_null("AccuracyLedger/LedgerVBox/AccuracyRow/BlackCol/BlackAccLabel")
		if black_accuracy_label == null:
			black_accuracy_label = summary_root.get_node_or_null("AccuracyLedger/AccuracyRow/BlackCol/BlackAccLabel")
	if white_perf_label == null and summary_root != null:
		white_perf_label = summary_root.get_node_or_null("MoveClassTable/TableVBox/RatingRow/WhitePerfLabel")
	if black_perf_label == null and summary_root != null:
		black_perf_label = summary_root.get_node_or_null("MoveClassTable/TableVBox/RatingRow/BlackPerfLabel")
	if opening_label == null and summary_root != null:
		opening_label = summary_root.get_node_or_null("AccuracyLedger/LedgerVBox/OpeningLabel")
	if counts_container == null and summary_root != null:
		counts_container = summary_root.get_node_or_null("MoveClassTable/TableVBox/CountsContainer")
	if btn_start_review == null:
		btn_start_review = get_node_or_null("Margin/VBox/BtnStartReview")
		if btn_start_review == null and summary_root != null:
			btn_start_review = summary_root.get_node_or_null("BtnStartReview")

	if graph_box == null:
		graph_box = get_node_or_null("Margin/VBox/GraphBox")
	if eval_graph == null and graph_box != null:
		eval_graph = graph_box.get_node_or_null("EvalGraph")
	if graph_readout_label == null and graph_box != null:
		graph_readout_label = graph_box.get_node_or_null("ReadoutLabel")

	if moves_list_box == null:
		moves_list_box = get_node_or_null("Margin/VBox/MovesListBox")
	if moves_scroll == null and moves_list_box != null:
		moves_scroll = moves_list_box.get_node_or_null("MovesScroll")
	if moves_container == null and moves_scroll != null:
		moves_container = moves_scroll.get_node_or_null("MovesContainer")
	elif moves_container == null and moves_list_box != null:
		moves_container = moves_list_box.get_node_or_null("MovesContainer")

	if move_review_box == null:
		move_review_box = get_node_or_null("Margin/VBox/MoveReviewBox")
	if coach_card == null and move_review_box != null:
		coach_card = move_review_box.get_node_or_null("CoachCard")
	elif coach_card == null:
		coach_card = get_node_or_null("Margin/VBox/CoachCard")

	if coach_card != null:
		if coach_avatar == null:
			coach_avatar = coach_card.get_node_or_null("VBox/HeaderRow/Avatar")
		if coach_badge_icon == null:
			coach_badge_icon = coach_card.get_node_or_null("VBox/HeaderRow/BadgeIcon")
		_apply_badge_icon_filter(coach_badge_icon)
		if coach_badge == null:
			coach_badge = coach_card.get_node_or_null("VBox/HeaderRow/BadgeLabel")
		if coach_move_title == null:
			coach_move_title = coach_card.get_node_or_null("VBox/HeaderRow/MoveTitleLabel")
		if coach_text == null:
			coach_text = coach_card.get_node_or_null("VBox/ExplanationLabel")
		if eval_loss_label == null:
			eval_loss_label = coach_card.get_node_or_null("VBox/EvalLossLabel")

	if move_review_box != null:
		if btn_show_best == null:
			btn_show_best = move_review_box.get_node_or_null("ActionRow/BtnShowBest")
		if btn_retry == null:
			btn_retry = move_review_box.get_node_or_null("ActionRow/BtnRetry")
		if btn_first == null:
			btn_first = move_review_box.get_node_or_null("NavRow/BtnFirst")
		if btn_prev_moment == null:
			btn_prev_moment = move_review_box.get_node_or_null("NavRow/BtnPrevMoment")
		if btn_prev_move == null:
			btn_prev_move = move_review_box.get_node_or_null("NavRow/BtnPrevMove")
		if move_indicator_label == null:
			move_indicator_label = move_review_box.get_node_or_null("NavRow/MoveIndicatorLabel")
		if btn_next_move == null:
			btn_next_move = move_review_box.get_node_or_null("NavRow/BtnNextMove")
		if btn_next_moment == null:
			btn_next_moment = move_review_box.get_node_or_null("NavRow/BtnNextMoment")
		if btn_last == null:
			btn_last = move_review_box.get_node_or_null("NavRow/BtnLast")

func _apply_styles() -> void:
	if btn_start_review:
		TactileStyles.apply_tactile_button(btn_start_review, true, false)
	if btn_show_best:
		TactileStyles.apply_tactile_button(btn_show_best, false, false)
	if btn_retry:
		TactileStyles.apply_tactile_button(btn_retry, false, false)
	if btn_first:
		TactileStyles.apply_tactile_button(btn_first, false, false, true)
	if btn_prev_moment:
		TactileStyles.apply_tactile_button(btn_prev_moment, false, false, true)
	if btn_prev_move:
		TactileStyles.apply_tactile_button(btn_prev_move, false, false, true)
	if btn_next_move:
		TactileStyles.apply_tactile_button(btn_next_move, false, false, true)
	if btn_next_moment:
		TactileStyles.apply_tactile_button(btn_next_moment, false, false, true)
	if btn_last:
		TactileStyles.apply_tactile_button(btn_last, false, false, true)
	if btn_tab_summary:
		TactileStyles.apply_tactile_button(btn_tab_summary, false, false)
	if btn_tab_graph:
		TactileStyles.apply_tactile_button(btn_tab_graph, false, false)
	if btn_tab_moves_list:
		TactileStyles.apply_tactile_button(btn_tab_moves_list, false, false)
	if btn_tab_moves:
		TactileStyles.apply_tactile_button(btn_tab_moves, false, false)
	if btn_settings:
		TactileStyles.apply_tactile_button(btn_settings, false, false, true)
	if btn_close_review:
		TactileStyles.apply_tactile_button(btn_close_review, false, false, true)

func _connect_signals() -> void:
	if btn_tab_summary and not btn_tab_summary.pressed.is_connected(_on_tab_summary_pressed):
		btn_tab_summary.pressed.connect(_on_tab_summary_pressed)
	if btn_tab_graph and not btn_tab_graph.pressed.is_connected(_on_tab_graph_pressed):
		btn_tab_graph.pressed.connect(_on_tab_graph_pressed)
	if btn_tab_moves_list and not btn_tab_moves_list.pressed.is_connected(_on_tab_moves_list_pressed):
		btn_tab_moves_list.pressed.connect(_on_tab_moves_list_pressed)
	if btn_tab_moves and not btn_tab_moves.pressed.is_connected(_on_tab_moves_pressed):
		btn_tab_moves.pressed.connect(_on_tab_moves_pressed)
	if btn_settings and not btn_settings.pressed.is_connected(_on_settings_pressed):
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_close_review and not btn_close_review.pressed.is_connected(_on_close_review_pressed):
		btn_close_review.pressed.connect(_on_close_review_pressed)
	if btn_start_review and not btn_start_review.pressed.is_connected(_on_start_review_pressed):
		btn_start_review.pressed.connect(_on_start_review_pressed)

	if btn_show_best and not btn_show_best.pressed.is_connected(_on_show_best_pressed):
		btn_show_best.pressed.connect(_on_show_best_pressed)
	if btn_retry and not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)
	if btn_first and not btn_first.pressed.is_connected(_on_first_pressed):
		btn_first.pressed.connect(_on_first_pressed)
	if btn_prev_move and not btn_prev_move.pressed.is_connected(_on_prev_move_pressed):
		btn_prev_move.pressed.connect(_on_prev_move_pressed)
	if btn_next_move and not btn_next_move.pressed.is_connected(_on_next_move_pressed):
		btn_next_move.pressed.connect(_on_next_move_pressed)
	if btn_prev_moment and not btn_prev_moment.pressed.is_connected(_on_prev_moment_pressed):
		btn_prev_moment.pressed.connect(_on_prev_moment_pressed)
	if btn_next_moment and not btn_next_moment.pressed.is_connected(_on_next_moment_pressed):
		btn_next_moment.pressed.connect(_on_next_moment_pressed)
	if btn_last and not btn_last.pressed.is_connected(_on_last_pressed):
		btn_last.pressed.connect(_on_last_pressed)

	if eval_graph and not eval_graph.ply_clicked.is_connected(_on_graph_ply_clicked):
		eval_graph.ply_clicked.connect(_on_graph_ply_clicked)
	if eval_graph and not eval_graph.hover_changed.is_connected(_on_graph_hover_changed):
		eval_graph.hover_changed.connect(_on_graph_hover_changed)

func switch_tab(tab: int) -> void:
	_ensure_nodes()
	current_tab = tab
	if btn_tab_summary:
		TactileStyles.apply_tactile_button(btn_tab_summary, false, tab == ReviewTab.SUMMARY)
	if btn_tab_graph:
		TactileStyles.apply_tactile_button(btn_tab_graph, false, tab == ReviewTab.GRAPH)
	if btn_tab_moves_list:
		TactileStyles.apply_tactile_button(btn_tab_moves_list, false, tab == ReviewTab.MOVES_LIST)
	if btn_tab_moves:
		TactileStyles.apply_tactile_button(btn_tab_moves, false, tab == ReviewTab.MOVES)

	if summary_box:
		summary_box.visible = (tab == ReviewTab.SUMMARY)
	if graph_box:
		graph_box.visible = (tab == ReviewTab.GRAPH)
	if moves_list_box:
		moves_list_box.visible = (tab == ReviewTab.MOVES_LIST)
	# Tombol aksi utama ikut tampil hanya di view Summary, karena ia hidup di luar
	# area scroll (lihat deklarasi btn_start_review).
	if btn_start_review:
		btn_start_review.visible = (tab == ReviewTab.SUMMARY)
	if move_review_box:
		move_review_box.visible = (tab == ReviewTab.MOVES)

func _on_tab_summary_pressed() -> void:
	switch_tab(ReviewTab.SUMMARY)

func _on_tab_graph_pressed() -> void:
	switch_tab(ReviewTab.GRAPH)

func _on_tab_moves_list_pressed() -> void:
	switch_tab(ReviewTab.MOVES_LIST)

func _on_tab_moves_pressed() -> void:
	switch_tab(ReviewTab.MOVES)

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_start_review_pressed() -> void:
	switch_tab(ReviewTab.MOVES)
	if current_step_index < 0 and not review_steps.is_empty():
		select_step(0)

func _on_close_review_pressed() -> void:
	review_closed.emit()

func reset_view() -> void:
	_ensure_nodes()
	if header_bar:
		header_bar.visible = false
	if progress_box:
		progress_box.visible = false
	if summary_box:
		summary_box.visible = false
	if graph_box:
		graph_box.visible = false
	if moves_list_box:
		moves_list_box.visible = false
	if moves_container:
		for child in moves_container.get_children():
			moves_container.remove_child(child)
			child.queue_free()
	_move_list_buttons.clear()
	if eval_graph:
		eval_graph.clear()
	if graph_readout_label:
		graph_readout_label.text = "Select a move to inspect"
	if btn_start_review:
		btn_start_review.visible = false
	if move_review_box:
		move_review_box.visible = false
	_set_tab_buttons_enabled(true)
	if coach_card:
		coach_card.visible = false
	if btn_show_best:
		btn_show_best.text = "Show Best Move"
		btn_show_best.disabled = true
	if btn_retry:
		btn_retry.disabled = true
	if move_indicator_label:
		move_indicator_label.text = "- / -"

	review_data.clear()
	review_steps.clear()
	current_step_index = -1
	is_retry_active = false
	is_showing_best_move = false
	retry_target_move = ""
	current_tab = ReviewTab.SUMMARY

func set_analysis_progress(current: int, total: int) -> void:
	_ensure_nodes()
	# Segmen Graph sengaja tetap tampil selama analisis supaya kurva tumbuh progresif
	# seiring tiap posisi selesai dievaluasi (bukan layar kosong + progress bar saja).
	if header_bar:
		header_bar.visible = true
	if progress_box:
		progress_box.visible = true
	if summary_box:
		summary_box.visible = false
	if graph_box:
		graph_box.visible = true
	if moves_list_box:
		moves_list_box.visible = false
	if btn_start_review:
		btn_start_review.visible = false
	if move_review_box:
		move_review_box.visible = false
	if coach_card:
		coach_card.visible = false
	# Segmen Graph tetap aktif selama analisis, jadi segmen lain dinonaktifkan
	# supaya tombol Graph tidak tampil sebagai tombol mati.
	_set_tab_buttons_enabled(false)
	if btn_tab_graph:
		btn_tab_graph.disabled = false
	current_tab = ReviewTab.GRAPH
	if btn_tab_summary:
		TactileStyles.apply_tactile_button(btn_tab_summary, false, false)
	if btn_tab_graph:
		TactileStyles.apply_tactile_button(btn_tab_graph, false, true)
	if btn_tab_moves_list:
		TactileStyles.apply_tactile_button(btn_tab_moves_list, false, false)
	if btn_tab_moves:
		TactileStyles.apply_tactile_button(btn_tab_moves, false, false)
	if eval_graph:
		eval_graph.set_analysis_pending(true)
		# total posisi = jumlah ply + 1 (posisi awal), jadi ply maksimum = total - 1.
		eval_graph.set_axis_max_ply(maxi(1, total - 1))
	if graph_readout_label:
		graph_readout_label.text = " "
	if progress_bar:
		progress_bar.max_value = max(1, total)
		progress_bar.value = current
	if progress_label:
		progress_label.text = "Analyzing move %d of %d..." % [current, total]

func _set_tab_buttons_enabled(enabled: bool) -> void:
	if btn_tab_summary:
		btn_tab_summary.disabled = not enabled
	if btn_tab_graph:
		btn_tab_graph.disabled = not enabled
	if btn_tab_moves_list:
		btn_tab_moves_list.disabled = not enabled
	if btn_tab_moves:
		btn_tab_moves.disabled = not enabled

# -----------------------------------------------------------------------------
# Eval Graph
# -----------------------------------------------------------------------------

## Titik progresif dari ReviewEngineSession (score_cp selalu perspektif Putih).
func append_graph_point(ply: int, eval_white_cp: int, is_mate: bool, mate_in: int) -> void:
	_ensure_nodes()
	if eval_graph == null or ply < 0:
		return
	eval_graph.append_point(_graph_point_from_eval(ply, eval_white_cp, is_mate, mate_in, -1))

func set_graph_points(from_steps: Array) -> void:
	_ensure_nodes()
	if eval_graph == null:
		return
	eval_graph.set_points(_build_graph_points(from_steps))

func _build_graph_points(from_steps: Array) -> Array:
	var points: Array = []
	if from_steps.is_empty():
		return points

	# Titik pembuka pada ply 0 = posisi awal, memakai peluang menang sebelum langkah
	# pertama (dikonversi ke perspektif Putih bila langkah pertama bukan Putih).
	var first: Dictionary = from_steps[0]
	var start_win_prob: float = float(first.get("win_prob_before", 0.5))
	if int(first.get("color", ChessTypes.PieceColor.WHITE)) != ChessTypes.PieceColor.WHITE:
		start_win_prob = 1.0 - start_win_prob
	points.append(_graph_point_from_wp(0, start_win_prob, -1))

	for i in range(from_steps.size()):
		var step: Dictionary = from_steps[i]
		var ply: int = int(step.get("ply", i + 1))
		var classification: int = int(step.get("classification", -1))
		var point: Dictionary = _graph_point_from_eval(
			ply,
			int(step.get("eval_white_cp", 0)),
			bool(step.get("is_mate_after", false)),
			int(step.get("mate_in_after", 0)),
			classification
		)
		points.append(point)
	return points

func _graph_point_from_eval(ply: int, eval_white_cp: int, is_mate: bool, mate_in: int, classification: int) -> Dictionary:
	if is_mate:
		# Posisi skakmat / mate: bila eval_white_cp > 0 atau mate_in > 0, Putih yang menang.
		# Pada terminal checkmate mate_in bernilai 0 dan eval_white_cp = 99999, jadi
		# pengecekan mate_in > 0 semata salah menghasilkan 0.0 (curam hitam ke bawah).
		var is_white_win: bool = (eval_white_cp > 0) or (mate_in > 0)
		var mate_wp: float = 1.0 if is_white_win else 0.0
		return _graph_point_from_wp(ply, mate_wp, classification)
	# Satu model peluang menang dengan perhitungan akurasi, supaya kurva dan angka
	# akurasi tidak mungkin saling bertentangan.
	return _graph_point_from_wp(ply, ReviewRules.win_probability_chess_com(eval_white_cp), classification)

func _graph_point_from_wp(ply: int, win_prob: float, classification: int) -> Dictionary:
	return {
		"ply": ply,
		"wp": clampf(win_prob, 0.0, 1.0),
		"classification": classification
	}

func _step_index_for_ply(ply: int) -> int:
	if ply <= 0:
		return -1
	for i in range(review_steps.size()):
		if int(review_steps[i].get("ply", i + 1)) == ply:
			return i
	var fallback: int = ply - 1
	return fallback if fallback >= 0 and fallback < review_steps.size() else -1

func _on_graph_ply_clicked(ply: int) -> void:
	var step_index: int = _step_index_for_ply(ply)
	switch_tab(ReviewTab.MOVES)
	select_step(step_index)

func _on_graph_hover_changed(ply: int) -> void:
	_update_graph_readout(ply)

func _update_graph_readout(ply: int) -> void:
	if graph_readout_label == null:
		return
	if ply < 0:
		ply = eval_graph.get_active_ply() if eval_graph != null else -1
	if ply <= 0 and review_steps.is_empty():
		graph_readout_label.text = "Select a move to inspect"
		return
	graph_readout_label.text = _format_readout(ply)

func _format_readout(ply: int) -> String:
	var step_index: int = _step_index_for_ply(ply)
	if step_index < 0:
		return "Start position    0.00"
	var step: Dictionary = review_steps[step_index]
	var notation: String = step.get("full_notation", "")
	if notation.is_empty():
		notation = step.get("san", "-")
	var classification: int = int(step.get("classification", GameReviewService.Classification.BOOK))
	return "%s    %s    %s" % [notation, _format_eval_white(step), GameReviewService.classification_to_string(classification)]

func _format_eval_white(step: Dictionary) -> String:
	if bool(step.get("is_mate_after", false)):
		var mate_in: int = int(step.get("mate_in_after", 0))
		var eval_cp: int = int(step.get("eval_white_cp", 0))
		var is_white_win: bool = (eval_cp > 0) or (mate_in > 0)
		var prefix: String = "+" if is_white_win else "-"
		if mate_in == 0:
			return "%s#" % prefix
		return "%sM%d" % [prefix, absi(mate_in)]
	var pawns: float = float(step.get("eval_white_cp", 0)) / 100.0
	if absf(pawns) < 0.05:
		return "0.00"
	return "%+.2f" % pawns

func set_review_data(data: Dictionary) -> void:
	_ensure_nodes()
	review_data = data
	review_steps = data.get("steps", [])

	if header_bar:
		header_bar.visible = true
	if progress_box:
		progress_box.visible = false

	# Accuracy display
	var white_acc: float = data.get("white_accuracy", 0.0)
	var black_acc: float = data.get("black_accuracy", 0.0)
	if white_accuracy_label:
		white_accuracy_label.text = "%.1f%%" % white_acc
	if black_accuracy_label:
		black_accuracy_label.text = "%.1f%%" % black_acc

	# Estimated Performance (baris "Game Rating" pada tabel ringkasan)
	var white_perf: int = data.get("white_performance", 1200)
	var black_perf: int = data.get("black_performance", 1200)
	if white_perf_label:
		white_perf_label.text = "%d" % white_perf
	if black_perf_label:
		black_perf_label.text = "%d" % black_perf

	# Opening Theory Info
	if opening_label:
		var op_name = data.get("opening_name", "Standard Chess")
		var op_eco = data.get("opening_eco", "A00")
		opening_label.text = "Opening: %s (%s)" % [op_name, op_eco]

	_populate_counts(data.get("white_counts", {}), data.get("black_counts", {}))
	_populate_moves_list()

	# Kurva evaluasi dibangun dari langkah yang sudah teranalisis, jadi segmen Graph
	# tidak memerlukan analisis tambahan maupun data engine baru.
	set_graph_points(review_steps)
	if eval_graph:
		eval_graph.set_axis_max_ply(maxi(1, review_steps.size()))
		eval_graph.set_analysis_pending(false)
	_set_tab_buttons_enabled(true)

	# Tampilkan Summary tab secara default
	switch_tab(ReviewTab.SUMMARY)

	if not review_steps.is_empty():
		select_step(-1)
	else:
		reset_view()

func _populate_counts(white_counts: Dictionary, black_counts: Dictionary) -> void:
	if counts_container == null:
		return
	for child in counts_container.get_children():
		counts_container.remove_child(child)
		child.queue_free()

	# Urutan mengikuti ringkasan Chess.com: Book di atas Best, dan tanpa field
	# simbol teks apa pun — lambang class disediakan ikon SVG (ReviewBadgeOverlay).
	var classifications = [
		{"type": GameReviewService.Classification.BRILLIANT, "name": "Brilliant"},
		{"type": GameReviewService.Classification.GREAT, "name": "Great"},
		{"type": GameReviewService.Classification.BOOK, "name": "Book"},
		{"type": GameReviewService.Classification.BEST, "name": "Best"},
		{"type": GameReviewService.Classification.EXCELLENT, "name": "Excellent"},
		{"type": GameReviewService.Classification.GOOD, "name": "Good"},
		{"type": GameReviewService.Classification.INACCURACY, "name": "Inaccuracy"},
		{"type": GameReviewService.Classification.MISTAKE, "name": "Mistake"},
		{"type": GameReviewService.Classification.MISS, "name": "Miss"},
		{"type": GameReviewService.Classification.BLUNDER, "name": "Blunder"},
	]

	for c in classifications:
		var c_type: int = c["type"]
		var w_cnt: int = white_counts.get(c_type, 0)
		var b_cnt: int = black_counts.get(c_type, 0)
		if w_cnt == 0 and b_cnt == 0:
			continue
		counts_container.add_child(_build_classification_row(c_type, c["name"], w_cnt, b_cnt))

## Satu baris tabel: ikon + nama class (kolom kiri) dan jumlah langkah Putih/Hitam
## pada kolom kanan dengan lebar tetap, sehingga angka sejajar antar baris.
## Baris memakai Button agar hover/pressed dan navigasi ke kategori tetap konsisten;
## isi baris diletakkan sebagai anak dengan mouse_filter IGNORE agar tidak menelan klik.
func _build_classification_row(c_type: int, class_name_text: String, white_count: int, black_count: int) -> Button:
	var accent: Color = GameReviewService.classification_to_color(c_type)

	var row_btn := Button.new()
	row_btn.custom_minimum_size = Vector2(0, 26)
	row_btn.size_flags_horizontal = SIZE_EXPAND_FILL
	row_btn.focus_mode = Control.FOCUS_NONE
	row_btn.tooltip_text = "Jump to %s moves" % class_name_text

	var row_normal := StyleBoxFlat.new()
	row_normal.bg_color = Color(0.16, 0.15, 0.14, 0.95)
	row_normal.border_width_left = 3
	row_normal.border_color = accent
	row_normal.corner_radius_top_left = 4
	row_normal.corner_radius_top_right = 4
	row_normal.corner_radius_bottom_right = 4
	row_normal.corner_radius_bottom_left = 4
	row_normal.content_margin_left = 10
	row_normal.content_margin_right = 10
	row_normal.content_margin_top = 3
	row_normal.content_margin_bottom = 3

	var row_hover := row_normal.duplicate() as StyleBoxFlat
	row_hover.bg_color = Color(0.22, 0.21, 0.19, 0.98)

	row_btn.add_theme_stylebox_override("normal", row_normal)
	row_btn.add_theme_stylebox_override("hover", row_hover)
	row_btn.add_theme_stylebox_override("pressed", row_hover)
	row_btn.add_theme_stylebox_override("focus", row_normal)

	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	row_btn.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_badge_icon_filter(icon)
	var icon_path: String = ReviewBadgeOverlay.get_icon_path(c_type)
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	content.add_child(icon)

	var name_label := Label.new()
	name_label.text = class_name_text
	name_label.size_flags_horizontal = SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	name_label.add_theme_font_size_override("font_size", 14)
	content.add_child(name_label)

	content.add_child(_build_count_label(white_count, Color(0.94, 0.94, 0.94)))
	content.add_child(_build_count_label(black_count, Color(0.90, 0.90, 0.90)))

	row_btn.pressed.connect(func():
		_jump_to_first_classification(c_type)
	)
	return row_btn

## Ikon klasifikasi adalah artwork PNG 256x256 yang selalu tampil jauh lebih kecil
## (16-24 px). Filter linear + mipmap dipasang eksplisit agar tepinya halus dan tidak
## bergerigi walaupun ada container induk yang memakai filter Nearest.
func _apply_badge_icon_filter(tex_rect: TextureRect) -> void:
	if tex_rect != null:
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _build_count_label(count: int, color: Color) -> Label:
	var label := Label.new()
	label.text = "%d" % count
	label.custom_minimum_size = Vector2(52, 0)
	label.size_flags_horizontal = SIZE_SHRINK_END
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	return label

func _jump_to_first_classification(target_class: int) -> void:
	for i in range(review_steps.size()):
		if review_steps[i].get("classification", -1) == target_class:
			switch_tab(ReviewTab.MOVES)
			select_step(i)
			return
	switch_tab(ReviewTab.MOVES)

## Membangun daftar langkah (tabel notasi berpasangan White & Black dengan badge klasifikasi)
## untuk segmen Moves yang kini berjejer di dalam GameReviewPanel.
func _populate_moves_list() -> void:
	if moves_container == null:
		return
	for child in moves_container.get_children():
		moves_container.remove_child(child)
		child.queue_free()
	_move_list_buttons.clear()

	if review_steps.is_empty():
		return

	var total_steps: int = review_steps.size()
	var step_idx: int = 0
	while step_idx < total_steps:
		var white_step: Dictionary = review_steps[step_idx]
		var black_step: Dictionary = review_steps[step_idx + 1] if step_idx + 1 < total_steps else {}

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 6)

		var move_num: int = int(white_step.get("move_number", (step_idx / 2) + 1))
		var num_lbl := Label.new()
		num_lbl.custom_minimum_size = Vector2(34, 28)
		num_lbl.text = "%d." % move_num
		num_lbl.add_theme_color_override("font_color", Color(0.65, 0.63, 0.60))
		num_lbl.add_theme_font_size_override("font_size", 14)
		num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(num_lbl)

		var w_idx: int = step_idx
		var w_btn := _build_move_list_button(white_step, w_idx)
		row.add_child(w_btn)
		_move_list_buttons[w_idx] = w_btn

		if not black_step.is_empty():
			var b_idx: int = step_idx + 1
			var b_btn := _build_move_list_button(black_step, b_idx)
			row.add_child(b_btn)
			_move_list_buttons[b_idx] = b_btn
		else:
			var spacer := Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(spacer)

		moves_container.add_child(row)
		step_idx += 2

func _build_move_list_button(step: Dictionary, step_idx: int) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 28)
	btn.focus_mode = Control.FOCUS_NONE

	var san: String = str(step.get("san", "-"))
	var cls: int = int(step.get("classification", -1))
	var icon_path: String = ReviewBadgeOverlay.get_icon_path(cls) if cls >= 0 else ""

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 6)
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.add_child(hbox)

	var icon_rect := TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(16, 16)
	icon_rect.size = Vector2(16, 16)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_badge_icon_filter(icon_rect)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	hbox.add_child(icon_rect)

	var san_lbl := Label.new()
	san_lbl.text = san
	san_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	san_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	san_lbl.add_theme_font_size_override("font_size", 14)
	san_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	san_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(san_lbl)

	TactileStyles.apply_tactile_button(btn, false, false, true)

	btn.pressed.connect(func():
		select_step(step_idx)
	)
	return btn

func _sync_move_list_highlight(active_idx: int) -> void:
	for step_k in _move_list_buttons.keys():
		var b = _move_list_buttons[step_k]
		if is_instance_valid(b):
			TactileStyles.apply_tactile_button(b, false, step_k == active_idx, true)
	if active_idx >= 0 and moves_scroll != null and _move_list_buttons.has(active_idx):
		var target_btn: Control = _move_list_buttons[active_idx]
		if is_instance_valid(target_btn):
			moves_scroll.ensure_control_visible(target_btn)

func select_step(idx: int) -> void:
	if review_steps.is_empty():
		return
	_ensure_nodes()

	# Kartu coach adalah badan utama segmen Move Review; pada posisi awal permainan
	# (Start Position, idx < 0) kartu disembunyikan agar tidak ada card placeholder
	# kosong "Game Review - Start of Game".
	if coach_card:
		coach_card.visible = (idx >= 0)

	# Selalu reset state Show Best Move saat berpindah langkah
	is_showing_best_move = false
	if btn_show_best:
		btn_show_best.text = "Show Best Move"

	# Penanganan Posisi Awal Permainan (Start of Game, sebelum langkah 1)
	if idx < 0:
		current_step_index = -1
		is_retry_active = false
		retry_target_move = ""

		if move_indicator_label:
			move_indicator_label.text = "Start"
		if btn_first:
			btn_first.disabled = true
		if btn_prev_move:
			btn_prev_move.disabled = true
		if btn_next_move:
			btn_next_move.disabled = false
		if btn_last:
			btn_last.disabled = false
		if btn_prev_moment:
			btn_prev_moment.disabled = true
		if btn_next_moment:
			btn_next_moment.disabled = (_find_next_key_moment(-1) == -1)

		if btn_show_best:
			btn_show_best.disabled = true
		if btn_retry:
			btn_retry.disabled = true

		if coach_badge:
			coach_badge.text = ""
		if coach_badge_icon:
			coach_badge_icon.texture = null
			coach_badge_icon.modulate.a = 0.0
		if coach_move_title:
			coach_move_title.text = ""
		if coach_text:
			coach_text.text = ""
		if eval_loss_label:
			eval_loss_label.text = " "
			eval_loss_label.modulate.a = 0.0
		if coach_avatar:
			coach_avatar.modulate = Color.WHITE

		# Kursor graph berada di titik pembuka (ply 0), bukan hilang.
		_sync_graph_cursor(0)
		_sync_move_list_highlight(-1)
		move_selected.emit(-1)
		return

	current_step_index = clampi(idx, 0, review_steps.size() - 1)
	is_retry_active = false

	var step_data: Dictionary = review_steps[current_step_index]
	var classification: int = step_data.get("classification", GameReviewService.Classification.BOOK)
	var explanation: Dictionary = step_data.get("explanation", {})
	var narrative: String = explanation.get("narrative", "")
	var emotion: int = explanation.get("emotion", CoachExplanationGenerator.Emotion.HAPPY)
	var best_move: String = step_data.get("best_move", "")

	retry_target_move = best_move

	# Update Coach Avatar & Card styling
	_update_coach_display(classification, narrative, emotion, step_data)

	# Update Nav buttons
	if move_indicator_label:
		move_indicator_label.text = "%d / %d" % [current_step_index + 1, review_steps.size()]
	if btn_first:
		btn_first.disabled = false
	if btn_prev_move:
		btn_prev_move.disabled = false
	if btn_next_move:
		btn_next_move.disabled = (current_step_index == review_steps.size() - 1)
	if btn_last:
		btn_last.disabled = (current_step_index == review_steps.size() - 1)
	if btn_prev_moment:
		btn_prev_moment.disabled = (_find_prev_key_moment(current_step_index) == -1)
	if btn_next_moment:
		btn_next_moment.disabled = (_find_next_key_moment(current_step_index) == -1)

	# Actions
	if btn_show_best:
		btn_show_best.text = "Show Best Move"
		var played_uci: String = step_data.get("played_uci", "")
		if played_uci.is_empty():
			played_uci = step_data.get("from_sq", "") + step_data.get("to_sq", "")
		var is_already_best: bool = false
		if classification in [
			GameReviewService.Classification.BEST,
			GameReviewService.Classification.BOOK,
			GameReviewService.Classification.BRILLIANT
		]:
			is_already_best = true
		elif not played_uci.is_empty() and not best_move.is_empty() and played_uci == best_move:
			is_already_best = true
		btn_show_best.disabled = best_move.is_empty() or is_already_best
	if btn_retry:
		var can_retry = classification in [
			GameReviewService.Classification.INACCURACY,
			GameReviewService.Classification.MISTAKE,
			GameReviewService.Classification.MISS,
			GameReviewService.Classification.BLUNDER
		]
		btn_retry.disabled = not can_retry

	_sync_graph_cursor(int(step_data.get("ply", current_step_index + 1)))
	_sync_move_list_highlight(current_step_index)
	move_selected.emit(current_step_index)

## Menyelaraskan kursor graph dengan langkah yang sedang dibuka, termasuk saat
## pengguna bernavigasi lewat tombol Next/Prev atau klik kategori move.
func _sync_graph_cursor(ply: int) -> void:
	if eval_graph == null:
		return
	if eval_graph.get_point_count() == 0:
		return
	eval_graph.set_active_ply(ply)
	if eval_graph.has_ply(ply):
		_update_graph_readout(ply)

func _update_coach_display(classification: int, narrative: String, emotion: int, step_data: Dictionary) -> void:
	# Label badge sengaja ASCII murni: lambang class (!!, !, ★, ✓, ?!, ?, ✕, ??)
	# sudah dibawa ikon SVG di sebelahnya, sehingga tidak ada ketergantungan pada
	# glyph font yang bisa muncul sebagai karakter rusak.
	var badge_map = {
		GameReviewService.Classification.BOOK: "Book Move",
		GameReviewService.Classification.BRILLIANT: "Brilliant",
		GameReviewService.Classification.GREAT: "Great Move",
		GameReviewService.Classification.BEST: "Best Move",
		GameReviewService.Classification.EXCELLENT: "Excellent",
		GameReviewService.Classification.GOOD: "Good Move",
		GameReviewService.Classification.INACCURACY: "Inaccuracy",
		GameReviewService.Classification.MISTAKE: "Mistake",
		GameReviewService.Classification.MISS: "Miss",
		GameReviewService.Classification.BLUNDER: "Blunder",
	}

	# Satu sumber warna: ReviewRules.classification_to_color()
	var cls_color: Color = GameReviewService.classification_to_color(classification)
	var badge_title: String = badge_map.get(classification, "")

	if coach_badge:
		coach_badge.text = badge_title
		coach_badge.add_theme_color_override("font_color", cls_color)

	if coach_badge_icon:
		var icon_path = ReviewBadgeOverlay.get_icon_path(classification)
		if ResourceLoader.exists(icon_path):
			coach_badge_icon.texture = load(icon_path)
			coach_badge_icon.modulate.a = 1.0
		else:
			coach_badge_icon.texture = null
			coach_badge_icon.modulate.a = 0.0

	# B2 Fix: Gunakan field color atau move_prefix yang akurat
	var full_notation = step_data.get("full_notation", "")
	if full_notation.is_empty():
		var san = step_data.get("san", "")
		var ply = step_data.get("ply", 0)
		var color = step_data.get("color", ChessTypes.PieceColor.WHITE)
		var move_num = ((ply - 1) / 2) + 1 if ply > 0 else 1
		full_notation = "%d. %s" % [move_num, san] if color == ChessTypes.PieceColor.WHITE else "%d... %s" % [move_num, san]

	if coach_move_title:
		coach_move_title.text = full_notation

	if coach_text:
		coach_text.text = narrative

	if eval_loss_label:
		var loss_cp = step_data.get("eval_loss_cp", 0.0)
		if abs(loss_cp) > 10.0:
			eval_loss_label.text = "Eval Loss: -%.2f pawn" % (loss_cp / 100.0)
			eval_loss_label.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
			eval_loss_label.modulate.a = 1.0
		else:
			eval_loss_label.text = " "
			eval_loss_label.modulate.a = 0.0

	if coach_avatar:
		match emotion:
			CoachExplanationGenerator.Emotion.PROUD:
				coach_avatar.modulate = Color(0.12, 0.85, 0.75)
			CoachExplanationGenerator.Emotion.HAPPY:
				coach_avatar.modulate = Color(0.40, 0.85, 0.40)
			CoachExplanationGenerator.Emotion.THOUGHTFUL:
				coach_avatar.modulate = Color(0.36, 0.65, 0.95)
			CoachExplanationGenerator.Emotion.WORRIED:
				coach_avatar.modulate = Color(0.95, 0.60, 0.20)
			CoachExplanationGenerator.Emotion.SHOCKED:
				coach_avatar.modulate = Color(0.95, 0.20, 0.20)
			_:
				coach_avatar.modulate = Color.WHITE

func _get_last_book_move_index() -> int:
	var last_book = -1
	for i in range(review_steps.size()):
		if review_steps[i].get("classification", -1) == GameReviewService.Classification.BOOK:
			last_book = i
	return last_book

func _find_first_key_moment() -> int:
	return _find_next_key_moment(-1)

func _find_prev_key_moment(from_idx: int) -> int:
	var last_book = _get_last_book_move_index()
	var interesting = [
		GameReviewService.Classification.BRILLIANT,
		GameReviewService.Classification.GREAT,
		GameReviewService.Classification.MISS,
		GameReviewService.Classification.MISTAKE,
		GameReviewService.Classification.BLUNDER
	]
	var start = from_idx - 1 if from_idx >= 0 else -1
	for i in range(start, -1, -1):
		if review_steps[i].get("classification", -1) in interesting:
			return i
		if i == last_book and last_book != -1:
			return last_book
	return -1

func _find_next_key_moment(from_idx: int) -> int:
	var last_book = _get_last_book_move_index()
	# Aturan Chess.com: Key Move pertama adalah Last Book Move
	if last_book != -1 and from_idx < last_book:
		return last_book

	var interesting = [
		GameReviewService.Classification.BRILLIANT,
		GameReviewService.Classification.GREAT,
		GameReviewService.Classification.MISS,
		GameReviewService.Classification.MISTAKE,
		GameReviewService.Classification.BLUNDER
	]
	var start = from_idx + 1 if from_idx >= 0 else 0
	for i in range(start, review_steps.size()):
		if review_steps[i].get("classification", -1) in interesting:
			return i
	return -1

func _on_first_pressed() -> void:
	select_step(-1)

func _on_last_pressed() -> void:
	if not review_steps.is_empty():
		select_step(review_steps.size() - 1)

func _on_prev_move_pressed() -> void:
	if current_step_index > 0:
		select_step(current_step_index - 1)
	elif current_step_index == 0:
		select_step(-1)

func _on_next_move_pressed() -> void:
	if current_step_index < 0:
		select_step(0)
	elif current_step_index < review_steps.size() - 1:
		select_step(current_step_index + 1)

func _on_prev_moment_pressed() -> void:
	var idx = _find_prev_key_moment(current_step_index)
	if idx != -1:
		select_step(idx)

func _on_next_moment_pressed() -> void:
	var idx = _find_next_key_moment(current_step_index)
	if idx != -1:
		select_step(idx)

func _on_show_best_pressed() -> void:
	if current_step_index < 0 or current_step_index >= review_steps.size():
		return
	var step_data = review_steps[current_step_index]
	var best_move = step_data.get("best_move", "")
	if best_move.is_empty():
		return

	is_showing_best_move = not is_showing_best_move
	if is_showing_best_move:
		if btn_show_best:
			btn_show_best.text = "Show Played Move"
		if coach_badge:
			coach_badge.text = "Best Move: " + best_move
			coach_badge.add_theme_color_override("font_color", Color(0.15, 0.85, 0.45))
		if coach_text:
			coach_text.text = "Stockfish recommends %s as the best move in this position." % best_move
	else:
		if btn_show_best:
			btn_show_best.text = "Show Best Move"
		var classification = step_data.get("classification", GameReviewService.Classification.BOOK)
		var explanation = step_data.get("explanation", {})
		var narrative = explanation.get("narrative", "")
		var emotion = explanation.get("emotion", CoachExplanationGenerator.Emotion.HAPPY)
		_update_coach_display(classification, narrative, emotion, step_data)

	show_best_move_requested.emit(current_step_index, best_move, is_showing_best_move)

func _on_retry_pressed() -> void:
	if current_step_index < 0 or current_step_index >= review_steps.size():
		return
	is_showing_best_move = false
	if btn_show_best:
		btn_show_best.text = "Show Best Move"
	var step_data = review_steps[current_step_index]
	var prev_fen = step_data.get("prev_fen", ChessBoardState.DEFAULT_FEN)
	var best_move = step_data.get("best_move", "")
	is_retry_active = true
	retry_target_move = best_move

	if coach_text:
		coach_text.text = "Your turn! Find the Best Move on the board."
	if coach_avatar:
		coach_avatar.modulate = Color(0.9, 0.8, 0.3)

	retry_mode_requested.emit(current_step_index, prev_fen, best_move)

func evaluate_retry_attempt(played_uci: String) -> bool:
	if not is_retry_active:
		return false
	if played_uci == retry_target_move:
		is_retry_active = false
		if coach_text:
			coach_text.text = "Best Move found! Excellent tactical intuition."
		if coach_avatar:
			coach_avatar.modulate = Color(0.2, 0.9, 0.4)
		if coach_badge:
			coach_badge.text = "Best Move found"
			coach_badge.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
		return true
	else:
		if coach_text:
			coach_text.text = "Not that move. Review the threats and try again."
		if coach_avatar:
			coach_avatar.modulate = Color(0.9, 0.3, 0.3)
		return false

func get_current_step_data() -> Dictionary:
	if current_step_index >= 0 and current_step_index < review_steps.size():
		return review_steps[current_step_index]
	return {}
