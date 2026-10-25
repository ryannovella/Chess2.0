class_name CoachExplanationGenerator
extends RefCounted

const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessMove = preload("res://src/core/chess_move.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const ThreatDetector = preload("res://src/core/threat_detector.gd")
const GameReviewService = preload("res://src/core/game_review_service.gd")

# Emosi Avatar Coach
enum CoachEmotion {
	PROUD,      # Brilliant / Spectacular mate
	HAPPY,      # Best / Great / Win material
	THOUGHTFUL, # Good / Inaccuracy / Positional moment
	WORRIED,    # Mistake / Missed opportunity
	SHOCKED     # Blunder / Hanging piece / Mated
}
const Emotion = CoachEmotion

static func generate_explanation(review_step: Dictionary) -> Dictionary:
	var classification = review_step.get("classification", GameReviewService.Classification.GOOD)
	var fen_before = review_step.get("fen_before", ChessBoardState.DEFAULT_FEN)
	var fen_after = review_step.get("fen_after", ChessBoardState.DEFAULT_FEN)
	var played_uci = review_step.get("played_uci", "")
	var best_uci = review_step.get("best_uci", "")
	var san = review_step.get("san", "")
	var is_mate_before = review_step.get("is_mate_before", false)
	var mate_in_before = review_step.get("mate_in_before", 0)
	var is_mate_after = review_step.get("is_mate_after", false)
	var mate_in_after = review_step.get("mate_in_after", 0)
	var eval_before = review_step.get("eval_before", 0)
	var eval_after = review_step.get("eval_after", 0)

	var board_before = ChessBoardState.new(fen_before)
	var board_after = ChessBoardState.new(fen_after)
	var player_color = board_before.turn

	var best_move = _uci_to_move(best_uci)
	var played_move = _uci_to_move(played_uci)

	var best_san = ""
	if best_move != null:
		best_san = ChessSAN.move_to_san(board_before, best_move)

	# Analisis Motif Taktis
	var motif_data = _analyze_motifs(board_before, board_after, played_move, best_move, review_step)

	var motif = motif_data["motif"]
	var coach_text = ""
	var emotion = CoachEmotion.HAPPY
	var title = GameReviewService.classification_to_string(classification)

	var best_ref = best_san if not best_san.is_empty() else best_uci

	match classification:
		GameReviewService.Classification.BRILLIANT:
			emotion = CoachEmotion.PROUD
			title = "Brilian / Brilliant (!!)"
			coach_text = "Brilliant sacrifice! %s" % motif_data["success_detail"]

		GameReviewService.Classification.GREAT:
			emotion = CoachEmotion.PROUD
			title = "Great Move (!)"
			coach_text = "Great find! Langkah terbaik di posisi ini. %s" % motif_data["success_detail"]

		GameReviewService.Classification.BEST:
			emotion = CoachEmotion.HAPPY
			title = "Best Move (★)"
			coach_text = "Best move. Menjaga inisiatif dan dominasi posisi. %s" % motif_data["success_detail"]

		GameReviewService.Classification.EXCELLENT:
			emotion = CoachEmotion.HAPPY
			title = "Excellent Move (✓)"
			coach_text = "Excellent move. Posisi solid dan mempertahankan kendali."

		GameReviewService.Classification.GOOD:
			emotion = CoachEmotion.THOUGHTFUL
			title = "Good Move (✓)"
			coach_text = "Good move. Posisi tetap seimbang dan terarah."

		GameReviewService.Classification.INACCURACY:
			emotion = CoachEmotion.THOUGHTFUL
			title = "Inaccuracy (?!)"
			coach_text = "Inaccuracy. %s Best move: %s (%s)." % [
				motif_data["flaw_detail"],
				best_ref,
				motif_data["best_benefit"]
			]

		GameReviewService.Classification.MISTAKE:
			emotion = CoachEmotion.WORRIED
			title = "Mistake (?)"
			coach_text = "Mistake. %s Best move: %s (%s)." % [
				motif_data["flaw_detail"],
				best_ref,
				motif_data["best_benefit"]
			]

		GameReviewService.Classification.MISS:
			emotion = CoachEmotion.WORRIED
			title = "Miss (✕)"
			coach_text = "Missed chance! %s Best move: %s (%s)." % [
				motif_data["flaw_detail"],
				best_ref,
				motif_data["best_benefit"]
			]

		GameReviewService.Classification.BLUNDER:
			emotion = CoachEmotion.SHOCKED
			title = "Blunder (??)"
			coach_text = "Blunder! %s Best move: %s (%s)." % [
				motif_data["flaw_detail"],
				best_ref,
				motif_data["best_benefit"]
			]

		GameReviewService.Classification.BOOK:
			emotion = CoachEmotion.HAPPY
			var is_last_book = review_step.get("is_last_book", false)
			var op_name = review_step.get("opening_name", "")
			if is_last_book:
				title = "Last Book Move"
				if not op_name.is_empty() and op_name != "Standard Chess":
					coach_text = "Last book move (%s). Teori opening selesai, permainan memasuki fase mandiri." % op_name
				else:
					coach_text = "Last book move. Teori opening selesai, permainan memasuki fase mandiri."
			else:
				title = "Book Move"
				if not op_name.is_empty() and op_name != "Standard Chess":
					coach_text = "Opening book move (%s)." % op_name
				else:
					coach_text = "Opening book move."

	return {
		"title": title,
		"explanation": coach_text,
		"narrative": coach_text,
		"motif": motif,
		"emotion": emotion,
		"best_san": best_san,
		"best_uci": best_uci,
		"played_san": san,
		"classification": classification,
		"eval_str": _format_eval(eval_after, is_mate_after, mate_in_after)
	}

static func _analyze_motifs(
	board_before: ChessBoardState,
	board_after: ChessBoardState,
	played_move: ChessMove,
	best_move: ChessMove,
	step: Dictionary
) -> Dictionary:
	var motif = "general"
	var success_detail = "Memperkuat kontrol posisi."
	var flaw_detail = "Melepas inisiatif posisi."
	var best_benefit = "mempertahankan inisiatif"

	var is_mate_after = step.get("is_mate_after", false)
	var mate_in_after = step.get("mate_in_after", 0)
	var is_mate_before = step.get("is_mate_before", false)
	var mate_in_before = step.get("mate_in_before", 0)

	# 1. Motif Checkmate / Mating Net
	if ChessMoveGenerator.is_checkmate(board_after):
		motif = "checkmate"
		success_detail = "Checkmate! King lawan tidak memiliki petak lari."
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	if is_mate_after and mate_in_after > 0:
		motif = "forced_mate"
		success_detail = "Forced mate dalam %d langkah." % mate_in_after
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	if is_mate_before and mate_in_before > 0:
		motif = "missed_mate"
		flaw_detail = "Melewatkan forced mate."
		best_benefit = "menyelesaikan forced mate langsung"
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# 2. Motif Menyerang / Menangkap Queen
	if best_move != null:
		var target_piece = board_before.get_piece(best_move.to_sq)
		if target_piece != null and target_piece["type"] == ChessTypes.PieceType.QUEEN:
			best_benefit = "menangkap Queen lawan"
			if played_move != null and played_move.to_sq == best_move.to_sq:
				motif = "winning_queen"
				success_detail = "Memenangkan Queen lawan."
				return _pack_motif(motif, success_detail, flaw_detail, best_benefit)
			else:
				flaw_detail = "Melewatkan kesempatan menangkap Queen lawan."

	# Cek apakah langkah pemain membuat Queen hanging
	if played_move != null:
		var played_p = board_before.get_piece(played_move.from_sq)
		if played_p != null and played_p["type"] == ChessTypes.PieceType.QUEEN:
			var threats = ThreatDetector.detect_threats(board_after, board_before.turn)
			for thr in threats:
				if thr["to"] == played_move.to_sq and thr["type"] == "threat-hanging":
					motif = "hanging_queen"
					flaw_detail = "Hanging Queen! Queen tidak terjaga dan dapat dimakan."
					best_benefit = "mengamankan Queen ke petak aman"
					return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# 3. Motif Fork
	if played_move != null and _is_fork_move(board_before, board_after, played_move):
		motif = "fork"
		success_detail = "Fork taktis menyerang dua sasaran sekaligus."
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)
	elif best_move != null and _is_fork_move(board_before, _simulate_move(board_before, best_move), best_move):
		best_benefit = "melancarkan taktik Fork"
		flaw_detail = "Melewatkan Fork yang menyerang dua sasaran."

	# 4. Motif Pin & Skewer
	if played_move != null and _is_pin_or_skewer(board_after, board_before.turn):
		motif = "pin"
		success_detail = "Pin taktis menekan piece lawan."
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)
	elif best_move != null and _is_pin_or_skewer(_simulate_move(board_before, best_move), board_before.turn):
		best_benefit = "melancarkan taktik Pin"
		flaw_detail = "Melewatkan Pin taktis terhadap piece lawan."

	# 5. Motif Hanging Piece & Win Material
	if played_move != null:
		var cap_piece = board_before.get_piece(played_move.to_sq)
		if cap_piece != null:
			motif = "winning_material"
			success_detail = "Memenangkan material piece lawan."
			return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# Cek piece gantung pasca langkah
	var threats_after = ThreatDetector.detect_threats(board_after, board_before.turn)
	for thr in threats_after:
		if thr["type"] == "threat-hanging":
			var hanging_p = board_after.get_piece(thr["to"])
			if hanging_p != null and hanging_p["type"] != ChessTypes.PieceType.PAWN:
				motif = "hanging_piece"
				flaw_detail = "Hanging piece di %s tanpa perlindungan." % thr["to"]
				best_benefit = "mengamankan piece dari ancaman"
				return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# 6. Motif Winning Tempo & Inisiatif (Check)
	if played_move != null:
		var gives_check = ChessMoveGenerator.is_in_check(board_after, board_after.turn)
		if gives_check:
			motif = "winning_tempo"
			success_detail = "Check menguntungkan dan merebut tempo."
			return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# 7. Motif Castling & King Safety
	if played_move != null and _is_castling_move(board_before, played_move):
		motif = "king_safety"
		success_detail = "Castling mengamankan King dan mengaktifkan Rook."
		return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	# 8. Motif Passed Pawn
	if played_move != null:
		var mover = board_before.get_piece(played_move.from_sq)
		if mover != null and mover["type"] == ChessTypes.PieceType.PAWN:
			var to_rank = ChessTypes.square_to_coord(played_move.to_sq).y
			if (mover["color"] == ChessTypes.PieceColor.WHITE and to_rank >= 5) or (mover["color"] == ChessTypes.PieceColor.BLACK and to_rank <= 2):
				motif = "passed_pawn"
				success_detail = "Passed pawn maju mengancam promosi."
				return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

	return _pack_motif(motif, success_detail, flaw_detail, best_benefit)

static func _pack_motif(m: String, s: String, f: String, b: String) -> Dictionary:
	return {
		"motif": m,
		"success_detail": s,
		"flaw_detail": f,
		"best_benefit": b
	}

static func _is_fork_move(_board_before: ChessBoardState, board_after: ChessBoardState, move: ChessMove) -> bool:
	var piece = board_after.get_piece(move.to_sq)
	if piece == null:
		return false
	var opp_color = ChessTypes.PieceColor.BLACK if piece["color"] == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	
	var high_value_attacked = 0
	var attacks = ChessMoveGenerator.get_legal_moves(board_after)
	for m in attacks:
		if m.from_sq == move.to_sq:
			var target = board_after.get_piece(m.to_sq)
			if target != null and target["color"] == opp_color:
				if target["type"] in [ChessTypes.PieceType.QUEEN, ChessTypes.PieceType.ROOK, ChessTypes.PieceType.KING]:
					high_value_attacked += 1
				elif target["type"] in [ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT] and piece["type"] in [ChessTypes.PieceType.PAWN, ChessTypes.PieceType.KNIGHT]:
					high_value_attacked += 1

	return high_value_attacked >= 2

static func _is_pin_or_skewer(board_after: ChessBoardState, player_color: int) -> bool:
	var opp_color = ChessTypes.PieceColor.BLACK if player_color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	var opp_state = board_after.clone()
	opp_state.turn = opp_color
	var legal_m = ChessMoveGenerator.get_legal_moves(opp_state)
	return legal_m.size() < 12 and not ChessMoveGenerator.is_in_check(board_after, opp_color)

static func _is_castling_move(board_before: ChessBoardState, move: ChessMove) -> bool:
	var piece = board_before.get_piece(move.from_sq)
	if piece == null or piece["type"] != ChessTypes.PieceType.KING:
		return false
	var from_c = ChessTypes.square_to_coord(move.from_sq)
	var to_c = ChessTypes.square_to_coord(move.to_sq)
	return abs(to_c.x - from_c.x) == 2

static func _simulate_move(board: ChessBoardState, move: ChessMove) -> ChessBoardState:
	var clone_st = board.clone()
	ChessMoveGenerator.apply_move_unchecked(clone_st, move)
	return clone_st

static func _uci_to_move(uci: String) -> ChessMove:
	var clean = uci.strip_edges()
	if clean.length() < 4:
		return null
	var from_sq = clean.substr(0, 2)
	var to_sq = clean.substr(2, 2)
	var promo = ChessTypes.PieceType.NONE
	if clean.length() >= 5:
		promo = ChessTypes.san_char_to_piece_type(clean.substr(4, 1))
	return ChessMove.new(from_sq, to_sq, promo)

static func _format_eval(cp: int, is_mate: bool, mate_in: int) -> String:
	if is_mate:
		return "M%d" % mate_in if mate_in > 0 else "-M%d" % abs(mate_in)
	var val = float(cp) / 100.0
	return ("+%.1f" % val) if val >= 0 else ("%.1f" % val)
