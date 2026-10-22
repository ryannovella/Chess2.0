class_name ChessSAN
extends RefCounted

# Convert a legal move into Standard Algebraic Notation (SAN)
static func move_to_san(state: ChessBoardState, move: Variant) -> String:
	var from_sq = move.from_sq if move is ChessMove else move.get("from", "")
	var to_sq = move.to_sq if move is ChessMove else move.get("to", "")
	var is_castle = move.is_castling if move is ChessMove else move.get("is_castling", false)
	var promo = move.promotion if move is ChessMove else move.get("promotion", ChessTypes.PieceType.NONE)
	var is_ep = move.is_en_passant if move is ChessMove else move.get("is_en_passant", false)

	if is_castle:
		var san_castle = "O-O" if to_sq[0] == "g" else "O-O-O"
		var test_state = state.clone()
		ChessMoveGenerator.apply_move_unchecked(test_state, move)
		if ChessMoveGenerator.is_checkmate(test_state):
			san_castle += "#"
		elif ChessMoveGenerator.is_in_check(test_state, test_state.turn):
			san_castle += "+"
		return san_castle

	var from_idx = ChessTypes.square_to_index(from_sq)
	var to_idx = ChessTypes.square_to_index(to_sq)
	var piece = state.squares[from_idx]
	if piece == null:
		return from_sq + to_sq

	var is_capture = state.squares[to_idx] != null or is_ep
	var san = ""

	if piece["type"] == ChessTypes.PieceType.PAWN:
		if is_capture:
			san += from_sq[0] + "x" + to_sq
		else:
			san += to_sq
		if promo != ChessTypes.PieceType.NONE:
			san += "=" + ChessTypes.piece_type_to_san_char(promo)
	else:
		san += ChessTypes.piece_type_to_san_char(piece["type"])

		# Disambiguation: check if another piece of same type and color can reach destination
		var legal_moves = ChessMoveGenerator.get_legal_moves(state)
		var ambiguous_moves: Array[ChessMove] = []
		for m in legal_moves:
			if m.to_sq == to_sq and m.from_sq != from_sq:
				var p_other = state.squares[ChessTypes.square_to_index(m.from_sq)]
				if p_other != null and p_other["type"] == piece["type"] and p_other["color"] == piece["color"]:
					ambiguous_moves.append(m)

		if not ambiguous_moves.is_empty():
			var same_file = false
			var same_rank = false
			for am in ambiguous_moves:
				if am.from_sq[0] == from_sq[0]:
					same_file = true
				if am.from_sq[1] == from_sq[1]:
					same_rank = true
			if not same_file:
				san += from_sq[0] # File is enough
			elif not same_rank:
				san += from_sq[1] # Rank is enough
			else:
				san += from_sq # Both required

		if is_capture:
			san += "x"
		san += to_sq

	# Check and Checkmate indicator
	var sim_state = state.clone()
	ChessMoveGenerator.apply_move_unchecked(sim_state, move)
	if ChessMoveGenerator.is_checkmate(sim_state):
		san += "#"
	elif ChessMoveGenerator.is_in_check(sim_state, sim_state.turn):
		san += "+"

	return san

# Convert UCI move string (e.g. "e2e4", "e7e8q") to a ChessMove
static func uci_to_move(state: ChessBoardState, uci: String) -> ChessMove:
	if uci.length() < 4:
		return ChessMove.new()
	var from_sq = uci.substr(0, 2)
	var to_sq = uci.substr(2, 2)
	var promo_char = uci.substr(4, 1) if uci.length() >= 5 else ""
	var promo = ChessTypes.san_char_to_piece_type(promo_char)

	var legal_moves = ChessMoveGenerator.get_legal_moves(state, from_sq)
	for m in legal_moves:
		if m.to_sq == to_sq:
			if promo != ChessTypes.PieceType.NONE:
				if m.promotion == promo:
					return m
			else:
				return m
	return ChessMove.new()

# Convert move to UCI string (e.g. "e2e4", "e7e8q")
static func move_to_uci(move: Variant) -> String:
	if move is ChessMove:
		return move.to_uci()
	var uci = move.get("from", "") + move.get("to", "")
	var promo = move.get("promotion", ChessTypes.PieceType.NONE)
	if promo != ChessTypes.PieceType.NONE:
		match promo:
			ChessTypes.PieceType.QUEEN: uci += "q"
			ChessTypes.PieceType.ROOK: uci += "r"
			ChessTypes.PieceType.BISHOP: uci += "b"
			ChessTypes.PieceType.KNIGHT: uci += "n"
	return uci
