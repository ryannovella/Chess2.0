class_name ReviewRules
extends RefCounted

# ==============================================================================
# CHESS.COM GAME REVIEW & EXPECTED POINTS MODEL (CLASSIFICATION V2)
# Sumber spesifikasi resmi:
# https://support.chess.com/en/articles/8572705-how-are-moves-classified-what-is-a-blunder-or-brilliant-etc
# https://support.chess.com/en/articles/8708970-how-is-accuracy-in-analysis-determined
# https://support.chess.com/en/articles/8584089-how-does-game-review-work
# ==============================================================================

const OpeningBook = preload("res://src/core/opening_book.gd")

enum Classification {
	BOOK = 0,
	BRILLIANT = 1,
	GREAT = 2,
	BEST = 3,
	EXCELLENT = 4,
	GOOD = 5,
	INACCURACY = 6,
	MISTAKE = 7,
	MISS = 8,
	BLUNDER = 9
}

# Ambang batas penurunan Expected Points resmi Chess.com (Win Probability Loss):
# - Best: Top engine move atau 0.00 loss
# - Excellent: <= 2% loss (0.02)
# - Good: <= 5% loss (0.05)
# - Inaccuracy: <= 10% loss (0.10)
# - Mistake: <= 20% loss (0.20)
# - Blunder: > 20% loss (> 0.20)
const EP_CUTOFF_BEST = 0.00
const EP_CUTOFF_EXCELLENT = 0.02
const EP_CUTOFF_GOOD = 0.05
const EP_CUTOFF_INACCURACY = 0.10
const EP_CUTOFF_MISTAKE = 0.20

# ------------------------------------------------------------------------------
# 1. EXPECTED POINTS (EP) & ACCURACY CALCULATION
# ------------------------------------------------------------------------------

# Hitung probabilitas menang (0.0 s/d 1.0) dari sudut pandang pemain yang melangkah
static func calculate_win_probability(score_cp: int, _rating: int = 1200) -> float:
	if score_cp >= 90000:
		return 1.0
	elif score_cp <= -90000:
		return 0.0
	
	# Formula logistik terkalibrasi:
	# 0 cp -> 50%
	# +400 cp (+4 pion) -> ~90.9%
	# -400 cp (-4 pion) -> ~9.1%
	var exponent = -float(score_cp) / 400.0
	return 1.0 / (1.0 + pow(10.0, exponent))

# Hitung akurasi langkah individual berdasarkan penurunan peluang menang
static func calculate_move_accuracy(win_prob_before: float, win_prob_after: float) -> float:
	var loss = maxf(0.0, win_prob_before - win_prob_after)
	var raw_acc = 100.0 * exp(-2.5 * loss)
	return clampf(raw_acc, 0.0, 100.0)

# Deteksi Pengorbanan Perwira (Material Sacrifice)
static func is_move_sacrifice(board_before, move, eval_after: int) -> bool:
	if board_before == null or move == null:
		return false
	var moving_p = board_before.get_piece(move.from_sq)
	if moving_p == null:
		return false
	
	var piece_type = moving_p["type"]
	# Pion dan Raja bukan perwira yang dihitung sebagai piece sacrifice untuk Brilliant
	if piece_type == 1 or piece_type == 6: # PAWN or KING
		return false

	var piece_val = _get_piece_value(piece_type)
	var target_p = board_before.get_piece(move.to_sq)
	var target_val = _get_piece_value(target_p["type"]) if target_p != null else 0

	# Jika menangkap perwira yang nilainya lebih tinggi atau sama, bukan sacrifice
	if target_val >= piece_val:
		return false

	var test_state = board_before.clone()
	var ChessMoveGeneratorRef = load("res://src/core/chess_move_generator.gd")
	ChessMoveGeneratorRef.apply_move_unchecked(test_state, move)
	
	var opp_replies = ChessMoveGeneratorRef.get_legal_moves(test_state)
	var can_be_captured = false
	for opp_m in opp_replies:
		if opp_m.to_sq == move.to_sq:
			can_be_captured = true
			break

	# Bidak bisa dimakan lawan, dan evaluasi setelahnya tetap solid/unggul
	return can_be_captured and (eval_after >= -50 or eval_after >= 90000)

static func _get_piece_value(ptype: int) -> int:
	match ptype:
		1: return 100   # PAWN
		2: return 320   # KNIGHT
		3: return 330   # BISHOP
		4: return 500   # ROOK
		5: return 900   # QUEEN
		6: return 10000 # KING
		_: return 0

# Alias helper
static func win_probability_chess_com(score_cp: int) -> float:
	return calculate_win_probability(score_cp)

static func accuracy_chess_com(p_before: float, p_after: float) -> float:
	return calculate_move_accuracy(p_before, p_after)

static func classification_to_symbol(c: Classification) -> String:
	return classification_to_badge_symbol(c)

# ------------------------------------------------------------------------------
# 2. MOVE CLASSIFICATION ENGINE (1:1 CHESS.COM V2)
# ------------------------------------------------------------------------------

static func classify_move(
	eval_before_cp: int,
	eval_after_cp: int,
	move_uci: String,
	best_move_uci: String,
	is_sacrifice: bool = false,
	is_mate_before: bool = false,
	mate_in_before: int = 0,
	is_mate_after: bool = false,
	mate_in_after: int = 0,
	is_book: bool = false,
	alt_best_eval_cp: int = -999999, # MultiPV rank 2 eval if available
	prev_move_was_mistake: bool = false,
	is_only_move: bool = false
) -> Classification:
	var clean_move = move_uci.to_lower().strip_edges()
	var clean_best = best_move_uci.to_lower().strip_edges()
	var is_top_engine = (clean_move == clean_best) or (not clean_best.is_empty() and clean_best.begins_with(clean_move))

	var win_prob_before = calculate_win_probability(eval_before_cp)
	var win_prob_after = calculate_win_probability(eval_after_cp)
	var ep_loss = maxf(0.0, win_prob_before - win_prob_after)

	# 1. BOOK MOVE
	# Conventional opening move dari teori resmi
	if is_book and (is_top_engine or ep_loss <= EP_CUTOFF_EXCELLENT):
		return Classification.BOOK

	# 2. BRILLIANT MOVE
	# Pengorbanan perwira yang bagus, posisi akhir tidak buruk, sebelum langkah belum menang mutlak
	if (is_top_engine or ep_loss <= EP_CUTOFF_EXCELLENT) and is_sacrifice:
		var position_not_bad = (eval_after_cp >= -50 or win_prob_after >= 0.45)
		var not_already_won = (win_prob_before <= 0.95 or eval_before_cp <= 600)
		if position_not_bad and not_already_won:
			return Classification.BRILLIANT

	# 3. GREAT MOVE
	# Langkah penting/kritis yang mengubah jalannya pertandingan atau satu-satunya langkah bagus
	if (is_top_engine or ep_loss <= 0.01):
		# Kriteria A: Only good move (is_only_move eksplisit atau MultiPV rank 2 jauh lebih buruk)
		if is_only_move:
			return Classification.GREAT
		if alt_best_eval_cp != -999999:
			var alt_win_prob = calculate_win_probability(alt_best_eval_cp)
			if (win_prob_after - alt_win_prob) >= 0.15:
				return Classification.GREAT
		# Kriteria B: Mengubah posisi dari kalah ke imbang, atau imbang ke menang
		if win_prob_before < 0.35 and win_prob_after >= 0.48:
			return Classification.GREAT
		elif win_prob_before <= 0.52 and win_prob_after >= 0.75:
			return Classification.GREAT

	# 4. BEST MOVE
	# Top choice engine
	if is_top_engine or ep_loss <= EP_CUTOFF_BEST:
		return Classification.BEST

	# 5. MISS
	# Melewatkan peluang mematikan lawan atau menghukum kesalahan/blunder lawan
	if is_mate_before and mate_in_before > 0:
		if not is_mate_after or mate_in_after <= 0:
			return Classification.MISS

	if prev_move_was_mistake and ep_loss >= EP_CUTOFF_GOOD and win_prob_after < 0.65:
		return Classification.MISS

	# 6. STANDAR EXPECTED POINTS CUTOFFS TABLE (CHESS.COM V2)
	if ep_loss <= EP_CUTOFF_EXCELLENT:
		return Classification.EXCELLENT
	elif ep_loss <= EP_CUTOFF_GOOD:
		return Classification.GOOD
	elif ep_loss <= EP_CUTOFF_INACCURACY:
		return Classification.INACCURACY
	elif ep_loss <= EP_CUTOFF_MISTAKE:
		return Classification.MISTAKE
	else:
		return Classification.BLUNDER

static func classify_chess_com(
	eval_before_cp: int,
	eval_after_cp: int,
	move_uci: String,
	best_move_uci: String,
	is_sacrifice: bool = false,
	is_book: bool = false,
	is_only_move: bool = false,
	is_mate_before: bool = false,
	mate_in_before: int = 0,
	is_mate_after: bool = false,
	mate_in_after: int = 0,
	alt_best_eval_cp: int = -999999,
	prev_move_was_mistake: bool = false
) -> Classification:
	return classify_move(
		eval_before_cp,
		eval_after_cp,
		move_uci,
		best_move_uci,
		is_sacrifice,
		is_mate_before,
		mate_in_before,
		is_mate_after,
		mate_in_after,
		is_book,
		alt_best_eval_cp,
		prev_move_was_mistake,
		is_only_move
	)

# ------------------------------------------------------------------------------
# 3. STRINGS, COLORS & GLYPHS (CHESS.COM EXACT STANDARDS)
# ------------------------------------------------------------------------------

static func classification_to_string(c: Classification) -> String:
	match c:
		Classification.BOOK: return "Book"
		Classification.BRILLIANT: return "Brilliant"
		Classification.GREAT: return "Great"
		Classification.BEST: return "Best"
		Classification.EXCELLENT: return "Excellent"
		Classification.GOOD: return "Good"
		Classification.INACCURACY: return "Inaccuracy"
		Classification.MISTAKE: return "Mistake"
		Classification.MISS: return "Miss"
		Classification.BLUNDER: return "Blunder"
		_: return "Good"

static func classification_to_badge_symbol(c: Classification) -> String:
	match c:
		Classification.BOOK: return "Bk"
		Classification.BRILLIANT: return "!!"
		Classification.GREAT: return "!"
		Classification.BEST: return "★"
		Classification.EXCELLENT: return "✓"
		Classification.GOOD: return "✓"
		Classification.INACCURACY: return "?!"
		Classification.MISTAKE: return "?"
		Classification.MISS: return "✕"
		Classification.BLUNDER: return "??"
		_: return ""

# Warna resmi move classification chess.com, diambil langsung dari artwork PNG di
# assets/ui/icons/review/. Nilai hex ini adalah SATU-SATUNYA sumber warna badge:
# dipakai oleh ReviewBadgeOverlay, legend Game Review, dan teks coach. Jangan
# menduplikasi daftar warna ini di tempat lain.
static func classification_to_color(c: Classification) -> Color:
	match c:
		Classification.BOOK: return Color("a88865")       # Book Brown
		Classification.BRILLIANT: return Color("1bada6")   # Brilliant Teal
		Classification.GREAT: return Color("1bada6")       # Great Teal (chess.com)
		Classification.BEST: return Color("96bc4b")        # Best Green
		Classification.EXCELLENT: return Color("96bc4b")   # Excellent Green
		Classification.GOOD: return Color("96af8b")        # Good Sage
		Classification.INACCURACY: return Color("f7c045")  # Inaccuracy Yellow
		Classification.MISTAKE: return Color("e58f2a")     # Mistake Orange
		Classification.MISS: return Color("ca3431")        # Miss Red
		Classification.BLUNDER: return Color("ca3431")     # Blunder Red
		_: return Color(0.6, 0.6, 0.6)

static func classification_to_description(c: Classification) -> String:
	match c:
		Classification.BOOK: return "A conventional opening move"
		Classification.BRILLIANT: return "The best move - and tricky to find too!"
		Classification.GREAT: return "A move that altered the course of the game!"
		Classification.BEST: return "The chess engine's top choice"
		Classification.EXCELLENT: return "Almost as good as the Best move"
		Classification.GOOD: return "A decent move, but not the best"
		Classification.INACCURACY: return "A weak move"
		Classification.MISTAKE: return "A bad move that immediately worsens your position"
		Classification.MISS: return "A move that missed a tactical opportunity"
		Classification.BLUNDER: return "A very bad move that also loses material or the game"
		_: return ""

# ------------------------------------------------------------------------------
# 4. GAME PERFORMANCE RATING ESTIMATE (EST.)
# ------------------------------------------------------------------------------

# Estimasi performance rating permainan berdasarkan rata-rata akurasi & baseline
static func estimate_performance_rating(accuracy: float, opponent_elo: int = 1200) -> int:
	# Akurasi ~50 -> rating ~ 400-600
	# Akurasi ~75 -> rating ~ 1200
	# Akurasi ~85 -> rating ~ 1600
	# Akurasi ~95 -> rating ~ 2200
	# Akurasi ~99 -> rating ~ 2700+
	var base_perf = 400.0 + (accuracy / 100.0) * 2300.0
	var weighted = (base_perf * 0.7) + (float(opponent_elo) * 0.3)
	return clampi(int(snappedf(weighted, 10.0)), 200, 3200)
