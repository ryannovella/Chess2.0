class_name GameReviewService
extends RefCounted

const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessMove = preload("res://src/core/chess_move.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const UCIClient = preload("res://src/engine/uci_client.gd")
const CoachExplanationGenerator = preload("res://src/core/coach_explanation_generator.gd")
const ReviewRules = preload("res://src/core/review_rules.gd")
const OpeningBook = preload("res://src/core/opening_book.gd")
const ReviewEngineSession = preload("res://src/engine/review_engine_session.gd")

signal review_progress(current_step: int, total_steps: int)
signal review_completed(review_result: Dictionary)
# Titik evaluasi progresif: dipancarkan tiap posisi selesai dinilai, sebelum
# klasifikasi langkah dibangun. Dipakai grafik evaluasi agar kurva tumbuh bertahap.
# Nilai eval_white_cp selalu dari perspektif Putih.
signal review_position_evaluated(ply: int, eval_white_cp: int, is_mate: bool, mate_in: int)

# Alias to ReviewRules.Classification for backward compatibility
enum Classification {
	BOOK,
	BRILLIANT,
	GREAT,
	BEST,
	EXCELLENT,
	GOOD,
	INACCURACY,
	MISTAKE,
	MISS,
	BLUNDER
}

static func classification_to_string(c: Classification) -> String:
	return ReviewRules.classification_to_string(c as ReviewRules.Classification)

static func classification_to_badge_symbol(c: Classification) -> String:
	return ReviewRules.classification_to_symbol(c as ReviewRules.Classification)

static func classification_to_color(c: Classification) -> Color:
	return ReviewRules.classification_to_color(c as ReviewRules.Classification)

static func calculate_win_probability(score_cp: int) -> float:
	return ReviewRules.win_probability_chess_com(score_cp)

static func calculate_move_accuracy(win_prob_before: float, win_prob_after: float) -> float:
	return ReviewRules.accuracy_chess_com(win_prob_before, win_prob_after)

static func is_move_sacrifice(board_before: ChessBoardState, move: ChessMove, eval_after: int) -> bool:
	return ReviewRules.is_move_sacrifice(board_before, move, eval_after)

static func classify_move_static(
	eval_before_cp: int,
	eval_after_cp: int,
	move_uci: String,
	best_move_uci: String,
	is_sacrifice: bool = false,
	is_mate_before: bool = false,
	mate_in_before: int = 0,
	is_mate_after: bool = false,
	mate_in_after: int = 0
) -> Classification:
	var res = ReviewRules.classify_chess_com(
		eval_before_cp,
		eval_after_cp,
		move_uci,
		best_move_uci,
		is_sacrifice,
		false, # is_book
		false, # is_only_move
		is_mate_before,
		mate_in_before,
		is_mate_after,
		mate_in_after
	)
	return res as Classification

static func compute_game_accuracy(moves_data: Array, white_elo: int = 1200, black_elo: int = 1200) -> Dictionary:
	var white_acc_sum = 0.0
	var white_count = 0
	var black_acc_sum = 0.0
	var black_count = 0

	var white_counts: Dictionary = {}
	var black_counts: Dictionary = {}
	for c_idx in Classification.values():
		white_counts[c_idx] = 0
		black_counts[c_idx] = 0

	for item in moves_data:
		var color = item.get("color", ChessTypes.PieceColor.WHITE)
		var acc = float(item.get("accuracy", 100.0))
		var cls = item.get("classification", Classification.BEST)

		if color == ChessTypes.PieceColor.WHITE:
			white_acc_sum += acc
			white_count += 1
			white_counts[cls] = white_counts.get(cls, 0) + 1
		else:
			black_acc_sum += acc
			black_count += 1
			black_counts[cls] = black_counts.get(cls, 0) + 1

	var white_final_acc = (white_acc_sum / float(maxi(1, white_count))) if white_count > 0 else 100.0
	var black_final_acc = (black_acc_sum / float(maxi(1, black_count))) if black_count > 0 else 100.0

	var white_perf = ReviewRules.estimate_performance_rating(white_final_acc, black_elo)
	var black_perf = ReviewRules.estimate_performance_rating(black_final_acc, white_elo)

	return {
		"white_accuracy": snappedf(white_final_acc, 0.1),
		"black_accuracy": snappedf(black_final_acc, 0.1),
		"white_performance": white_perf,
		"black_performance": black_perf,
		"white_counts": white_counts,
		"black_counts": black_counts,
		"total_moves": moves_data.size()
	}

# --- Asynchronous Batch Analysis Engine ---
var _session: ReviewEngineSession = null
var _history_items: Array[Dictionary] = []
var _is_running_batch: bool = false

func start_batch_analysis(
	history: Array[Dictionary],
	analysis_depth: int = -1,
	max_time_ms: int = -1,
	multipv: int = -1,
	threads: int = -1,
	hash_mb: int = -1
) -> void:
	if history.is_empty():
		review_completed.emit({"moves": [], "steps": [], "summary": compute_game_accuracy([])})
		return

	_history_items = history.duplicate()
	_is_running_batch = true

	# Ambil setting dari GameSettings jika tidak di-override
	var target_depth = analysis_depth
	var target_time = max_time_ms
	var target_mpv = multipv
	var target_threads = threads
	var target_hash = hash_mb

	var main_loop = Engine.get_main_loop()
	var gs = main_loop.root.get_node_or_null("/root/GameSettings") if (main_loop is SceneTree and main_loop.root != null) else null
	if gs != null:
		if target_depth <= 0:
			target_depth = gs.review_depth
		if target_time <= 0:
			target_time = gs.review_max_time_ms
		if target_mpv <= 0:
			target_mpv = gs.review_multipv
		if target_threads <= 0:
			target_threads = gs.review_threads
		if target_hash <= 0:
			target_hash = gs.review_hash_mb
	else:
		if target_depth <= 0: target_depth = 14
		if target_time <= 0: target_time = 800
		if target_mpv <= 0: target_mpv = 2
		if target_threads <= 0: target_threads = 1
		if target_hash <= 0: target_hash = 64

	# Siapkan daftar posisi dengan pendeteksian terminal checkmate (B4 fix)
	var queue_positions: Array[Dictionary] = []
	for i in range(_history_items.size()):
		var item = _history_items[i]
		var fen = item.get("fen", ChessBoardState.DEFAULT_FEN)
		var board = ChessBoardState.new(fen)
		var is_terminal = false
		var terminal_eval = 0

		# Cek apakah posisi ini checkmate atau stalemate
		var legal_moves = ChessMoveGenerator.get_legal_moves(board)
		if legal_moves.is_empty():
			var in_check = ChessMoveGenerator.is_in_check(board, board.turn)
			is_terminal = true
			if in_check:
				# Pemain yang giliran melangkah kena skakmat: skor sangat buruk untuknya
				terminal_eval = -99999 if board.turn == ChessTypes.PieceColor.WHITE else 99999
			else:
				# Stalemate -> 0
				terminal_eval = 0

		queue_positions.append({
			"fen": fen,
			"ply": i,
			"turn": board.turn,
			"is_terminal": is_terminal,
			"terminal_eval": terminal_eval
		})

	if _session == null:
		_session = ReviewEngineSession.new()
		_session.progress_updated.connect(_on_session_progress)
		_session.position_evaluated.connect(_on_session_position_evaluated)
		_session.session_completed.connect(_on_session_completed)

	_session.start_analysis(queue_positions, target_depth, target_time, target_mpv, target_threads, target_hash)

func stop() -> void:
	_is_running_batch = false
	if _session != null:
		_session.stop_analysis()

func dispose() -> void:
	stop()
	if _session != null:
		_session.dispose()
		_session = null

func _on_session_progress(completed: int, total: int) -> void:
	if not _is_running_batch:
		return
	review_progress.emit(completed, total)

func _on_session_position_evaluated(_fen: String, result: Dictionary) -> void:
	if not _is_running_batch:
		return
	review_position_evaluated.emit(
		int(result.get("ply", -1)),
		int(result.get("score_cp", 0)),
		bool(result.get("is_mate", false)),
		int(result.get("mate_in", 0))
	)

func _on_session_completed(evaluated_positions: Array[Dictionary]) -> void:
	if not _is_running_batch:
		return
	_is_running_batch = false
	_build_and_emit_review_result(evaluated_positions)

func _build_and_emit_review_result(evaluated_positions: Array[Dictionary]) -> void:
	var moves_analysis: Array[Dictionary] = []
	var detected_opening_name = "Standard Chess"
	var detected_opening_eco = "A00"

	# Deteksi rating pemain & AI bot untuk kalibrasi Performance Rating
	var white_elo = 1200
	var black_elo = 1200
	var main_loop = Engine.get_main_loop()
	var gs = main_loop.root.get_node_or_null("/root/GameSettings") if (main_loop is SceneTree and main_loop.root != null) else null
	if gs != null:
		if gs.current_game_mode == "vs_ai":
			if gs.player_color == ChessTypes.PieceColor.WHITE:
				white_elo = 1200
				black_elo = gs.ai_elo
			else:
				black_elo = 1200
				white_elo = gs.ai_elo

	# Pre-kalkulasi indeks last book move
	var last_book_ply = -1
	for j in range(1, _history_items.size()):
		var step_fen = _history_items[j].get("fen", "")
		if OpeningBook.is_book_move(step_fen, j):
			last_book_ply = j

	# history_items index 0 adalah posisi awal
	# history_items index 1..N adalah langkah yang dimainkan
	for i in range(1, _history_items.size()):
		var prev_eval = evaluated_positions[i - 1] if i - 1 < evaluated_positions.size() else {}
		var curr_eval = evaluated_positions[i] if i < evaluated_positions.size() else {}
		var step_data = _history_items[i]
		var prev_step_data = _history_items[i - 1]

		var prev_fen = prev_step_data.get("fen", ChessBoardState.DEFAULT_FEN)
		var curr_fen = step_data.get("fen", ChessBoardState.DEFAULT_FEN)
		var from_sq = step_data.get("from_sq", "")
		var to_sq = step_data.get("to_sq", "")
		var promo = step_data.get("promo", ChessTypes.PieceType.NONE)
		var played_uci = from_sq + to_sq
		if promo != ChessTypes.PieceType.NONE:
			played_uci += ChessTypes.piece_type_to_san_char(promo).to_lower()

		var best_uci = prev_eval.get("best_move", "")
		var pv = prev_eval.get("pv", [])

		var prev_board = ChessBoardState.new(prev_fen)
		var turn = prev_board.turn

		# B13: Flag taktis langkah (promosi, en-passant, castling) WAJIB ikut dialirkan ke
		# step_dict agar papan review dapat merender bidak dengan benar saat navigasi per ply.
		# Tanpa ini, animasi maju menyisakan pion yang tidak berubah menjadi perwira promosi.
		var is_castle = step_data.get("is_castle", false)
		var is_ep = step_data.get("is_ep", false)
		var mover_piece = prev_board.get_piece(from_sq)
		if not from_sq.is_empty() and not to_sq.is_empty():
			if promo == ChessTypes.PieceType.NONE and mover_piece != null and mover_piece["type"] == ChessTypes.PieceType.PAWN:
				var promo_rank = 7 if mover_piece["color"] == ChessTypes.PieceColor.WHITE else 0
				if ChessTypes.square_to_coord(to_sq).y == promo_rank:
					promo = ChessTypes.PieceType.QUEEN
			if not is_castle and from_sq in ["e1", "e8"] and to_sq in ["c1", "g1", "c8", "g8"]:
				if mover_piece != null and mover_piece["type"] == ChessTypes.PieceType.KING:
					is_castle = true
			if not is_ep and mover_piece != null and mover_piece["type"] == ChessTypes.PieceType.PAWN:
				if from_sq.substr(0, 1) != to_sq.substr(0, 1) and prev_board.get_piece(to_sq) == null:
					is_ep = true

		# Evaluasi mentah dari UCI Client selalu dinormalisasi ke White (+ untuk White, - untuk Black)
		var white_eval_before = prev_eval.get("score_cp", 0)
		var white_eval_after = curr_eval.get("score_cp", 0)
		var is_mate_before = prev_eval.get("is_mate", false)
		var mate_in_before = prev_eval.get("mate_in", 0)
		var is_mate_after = curr_eval.get("is_mate", false)
		var mate_in_after = curr_eval.get("mate_in", 0)

		# Normalisasi skor dari perspektif pemain yang melangkah (mover)
		var player_eval_before = white_eval_before if turn == ChessTypes.PieceColor.WHITE else -white_eval_before
		var player_eval_after = white_eval_after if turn == ChessTypes.PieceColor.WHITE else -white_eval_after

		var win_prob_before = ReviewRules.win_probability_chess_com(player_eval_before)
		var win_prob_after = ReviewRules.win_probability_chess_com(player_eval_after)
		var accuracy = ReviewRules.accuracy_chess_com(win_prob_before, win_prob_after)

		var test_move = ChessMove.new(from_sq, to_sq, promo)
		var is_sac = ReviewRules.is_move_sacrifice(prev_board, test_move, player_eval_after)
		var is_book = OpeningBook.is_book_move(curr_fen, i)

		if is_book:
			var op_info = OpeningBook.lookup_position(curr_fen)
			if op_info.get("found", false):
				detected_opening_name = op_info.get("name", detected_opening_name)
				detected_opening_eco = op_info.get("eco", detected_opening_eco)

		# Cek Only Move (Candidate rank 2 jauh lebih buruk, misal gap >= 150 cp)
		var second_score = prev_eval.get("second_best_score_cp", player_eval_before)
		var player_second_score = second_score if turn == ChessTypes.PieceColor.WHITE else -second_score
		var is_only_move = (player_eval_before - player_second_score >= 150)

		# Cek apakah langkah sebelumnya dari lawan adalah kesalahan (Inaccuracy/Mistake/Miss/Blunder)
		var prev_move_was_mistake = false
		if not moves_analysis.is_empty():
			var last_step = moves_analysis[-1]
			var last_cls = last_step.get("classification", -1)
			if last_cls in [
				Classification.INACCURACY,
				Classification.MISTAKE,
				Classification.MISS,
				Classification.BLUNDER
			]:
				prev_move_was_mistake = true

		var classification_enum = ReviewRules.classify_chess_com(
			player_eval_before,
			player_eval_after,
			played_uci,
			best_uci,
			is_sac,
			is_book,
			is_only_move,
			is_mate_before,
			mate_in_before,
			is_mate_after,
			mate_in_after,
			player_second_score,
			prev_move_was_mistake
		)
		var classification = classification_enum as Classification

		# Perhitungan SAN & Move Notation yang akurat
		var san_list = step_data.get("san_history", [])
		var san_move = san_list[-1] if not san_list.is_empty() else step_data.get("san", played_uci)
		var move_number = ((i - 1) / 2) + 1
		var move_prefix = "%d." % move_number if turn == ChessTypes.PieceColor.WHITE else "%d..." % move_number
		var full_notation = "%s %s" % [move_prefix, san_move]

		var step_dict = {
			"ply_index": i,
			"ply": i,
			"move_number": move_number,
			"color": turn,
			"played_uci": played_uci,
			"san": san_move,
			"move_prefix": move_prefix,
			"full_notation": full_notation,
			"from_sq": from_sq,
			"to_sq": to_sq,
			"is_castle": is_castle,
			"is_ep": is_ep,
			"promo": promo,
			"prev_fen": prev_fen,
			"best_move": best_uci,
			"best_uci": best_uci,
			"pv": pv,
			# Nilai perspektif Mover (untuk akurasi & klasifikasi)
			"eval_before": player_eval_before,
			"eval_after": player_eval_after,
			"eval_loss_cp": maxi(0, player_eval_before - player_eval_after),
			# Nilai perspektif White (B3 fix: untuk meter/bar evaluasi agar tidak terbalik)
			"eval_white_cp": white_eval_after,
			"win_prob_before": win_prob_before,
			"win_prob_after": win_prob_after,
			"accuracy": accuracy,
			"classification": classification,
			"classification_str": ReviewRules.classification_to_string(classification_enum),
			"classification_symbol": ReviewRules.classification_to_symbol(classification_enum),
			"classification_desc": ReviewRules.classification_to_description(classification_enum),
			"fen_before": prev_fen,
			"fen_after": curr_fen,
			"is_mate_before": is_mate_before,
			"mate_in_before": mate_in_before,
			"is_mate_after": is_mate_after,
			"mate_in_after": mate_in_after,
			"is_last_book": (is_book and i == last_book_ply),
			"opening_name": detected_opening_name,
			"opening_eco": detected_opening_eco
		}

		var explanation = CoachExplanationGenerator.generate_explanation(step_dict)
		step_dict["explanation"] = explanation
		moves_analysis.append(step_dict)

	var summary = compute_game_accuracy(moves_analysis, white_elo, black_elo)
	summary["opening_name"] = detected_opening_name
	summary["opening_eco"] = detected_opening_eco

	var final_result = {
		"moves": moves_analysis,
		"steps": moves_analysis,
		"summary": summary,
		"opening_name": detected_opening_name,
		"opening_eco": detected_opening_eco,
		"white_accuracy": summary.get("white_accuracy", 0.0),
		"black_accuracy": summary.get("black_accuracy", 0.0),
		"white_performance": summary.get("white_performance", 1200),
		"black_performance": summary.get("black_performance", 1200),
		"white_counts": summary.get("white_counts", {}),
		"black_counts": summary.get("black_counts", {})
	}
	review_completed.emit(final_result)
