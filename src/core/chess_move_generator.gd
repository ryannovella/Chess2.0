class_name ChessMoveGenerator
extends RefCounted

const KNIGHT_OFFSETS = [
	Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, -1), Vector2i(1, -2),
	Vector2i(-1, -2), Vector2i(-2, -1), Vector2i(-2, 1), Vector2i(-1, 2)
]

const BISHOP_DIRS = [
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

const ROOK_DIRS = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
]

const KING_DIRS = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)
]

# Create move instance
static func create_move(from_sq: String, to_sq: String, promo: int = ChessTypes.PieceType.NONE, is_castle: bool = false, is_ep: bool = false) -> ChessMove:
	return ChessMove.new(from_sq, to_sq, promo, is_castle, is_ep)

# Find king index
static func find_king(state: ChessBoardState, color: int) -> int:
	for i in range(64):
		var p = state.squares[i]
		if p != null and p["color"] == color and p["type"] == ChessTypes.PieceType.KING:
			return i
	return -1

# Check if a square is attacked by opponent
static func is_square_attacked(state: ChessBoardState, sq_idx: int, by_color: int) -> bool:
	if sq_idx < 0 or sq_idx >= 64:
		return false
	var target_f = sq_idx % 8
	var target_r = sq_idx / 8

	# 1. Attacked by Pawns
	var pawn_dir = 1 if by_color == ChessTypes.PieceColor.WHITE else -1
	# If white attacks, attacking pawns are at rank - 1
	var pawn_r = target_r - pawn_dir
	if pawn_r >= 0 and pawn_r <= 7:
		for df in [-1, 1]:
			var pf = target_f + df
			if pf >= 0 and pf <= 7:
				var p = state.squares[pawn_r * 8 + pf]
				if p != null and p["color"] == by_color and p["type"] == ChessTypes.PieceType.PAWN:
					return true

	# 2. Attacked by Knights
	for off in KNIGHT_OFFSETS:
		var nf = target_f + off.x
		var nr = target_r + off.y
		if nf >= 0 and nf <= 7 and nr >= 0 and nr <= 7:
			var p = state.squares[nr * 8 + nf]
			if p != null and p["color"] == by_color and p["type"] == ChessTypes.PieceType.KNIGHT:
				return true

	# 3. Attacked by Bishops / Queens (diagonals)
	for dir in BISHOP_DIRS:
		var cur_f = target_f + dir.x
		var cur_r = target_r + dir.y
		while cur_f >= 0 and cur_f <= 7 and cur_r >= 0 and cur_r <= 7:
			var p = state.squares[cur_r * 8 + cur_f]
			if p != null:
				if p["color"] == by_color and (p["type"] == ChessTypes.PieceType.BISHOP or p["type"] == ChessTypes.PieceType.QUEEN):
					return true
				break
			cur_f += dir.x
			cur_r += dir.y

	# 4. Attacked by Rooks / Queens (orthogonals)
	for dir in ROOK_DIRS:
		var cur_f = target_f + dir.x
		var cur_r = target_r + dir.y
		while cur_f >= 0 and cur_f <= 7 and cur_r >= 0 and cur_r <= 7:
			var p = state.squares[cur_r * 8 + cur_f]
			if p != null:
				if p["color"] == by_color and (p["type"] == ChessTypes.PieceType.ROOK or p["type"] == ChessTypes.PieceType.QUEEN):
					return true
				break
			cur_f += dir.x
			cur_r += dir.y

	# 5. Attacked by King
	for dir in KING_DIRS:
		var kf = target_f + dir.x
		var kr = target_r + dir.y
		if kf >= 0 and kf <= 7 and kr >= 0 and kr <= 7:
			var p = state.squares[kr * 8 + kf]
			if p != null and p["color"] == by_color and p["type"] == ChessTypes.PieceType.KING:
				return true

	return false

static func is_in_check(state: ChessBoardState, color: int) -> bool:
	var king_idx = find_king(state, color)
	if king_idx == -1:
		return false
	var opp_color = ChessTypes.PieceColor.BLACK if color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	return is_square_attacked(state, king_idx, opp_color)

# Generate pseudo-legal moves for a specific square or all squares of current turn
static func generate_pseudo_moves(state: ChessBoardState, from_sq: String = "") -> Array[ChessMove]:
	var moves: Array[ChessMove] = []
	var start_idx = 0
	var end_idx = 64
	if not from_sq.is_empty():
		start_idx = ChessTypes.square_to_index(from_sq)
		end_idx = start_idx + 1

	var turn = state.turn
	var opp_color = ChessTypes.PieceColor.BLACK if turn == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE

	for idx in range(start_idx, end_idx):
		var p = state.squares[idx]
		if p == null or p["color"] != turn:
			continue

		var f = idx % 8
		var r = idx / 8
		var src_sq = ChessTypes.coord_to_square(f, r)

		match p["type"]:
			ChessTypes.PieceType.PAWN:
				var forward = 1 if turn == ChessTypes.PieceColor.WHITE else -1
				var start_rank = 1 if turn == ChessTypes.PieceColor.WHITE else 6
				var promo_rank = 7 if turn == ChessTypes.PieceColor.WHITE else 0

				# Single step forward
				var step_r = r + forward
				if step_r >= 0 and step_r <= 7:
					var step_idx = step_r * 8 + f
					if state.squares[step_idx] == null:
						var dest_sq = ChessTypes.coord_to_square(f, step_r)
						if step_r == promo_rank:
							for promo in [ChessTypes.PieceType.QUEEN, ChessTypes.PieceType.ROOK, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT]:
								moves.append(create_move(src_sq, dest_sq, promo))
						else:
							moves.append(create_move(src_sq, dest_sq))

						# Double step forward from initial rank
						if r == start_rank:
							var double_r = r + forward * 2
							var double_idx = double_r * 8 + f
							if state.squares[double_idx] == null:
								moves.append(create_move(src_sq, ChessTypes.coord_to_square(f, double_r)))

				# Captures (left and right diagonal)
				for df in [-1, 1]:
					var cap_f = f + df
					var cap_r = r + forward
					if cap_f >= 0 and cap_f <= 7 and cap_r >= 0 and cap_r <= 7:
						var cap_idx = cap_r * 8 + cap_f
						var target_sq = ChessTypes.coord_to_square(cap_f, cap_r)
						var target_piece = state.squares[cap_idx]
						if target_piece != null and target_piece["color"] == opp_color:
							if cap_r == promo_rank:
								for promo in [ChessTypes.PieceType.QUEEN, ChessTypes.PieceType.ROOK, ChessTypes.PieceType.BISHOP, ChessTypes.PieceType.KNIGHT]:
									moves.append(create_move(src_sq, target_sq, promo))
							else:
								moves.append(create_move(src_sq, target_sq))
						elif state.ep_square == target_sq:
							# En passant capture
							moves.append(create_move(src_sq, target_sq, ChessTypes.PieceType.NONE, false, true))

			ChessTypes.PieceType.KNIGHT:
				for off in KNIGHT_OFFSETS:
					var tf = f + off.x
					var tr = r + off.y
					if tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var target_piece = state.squares[tr * 8 + tf]
						if target_piece == null or target_piece["color"] == opp_color:
							moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))

			ChessTypes.PieceType.BISHOP:
				for dir in BISHOP_DIRS:
					var tf = f + dir.x
					var tr = r + dir.y
					while tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var target_piece = state.squares[tr * 8 + tf]
						if target_piece == null:
							moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
						else:
							if target_piece["color"] == opp_color:
								moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
							break
						tf += dir.x
						tr += dir.y

			ChessTypes.PieceType.ROOK:
				for dir in ROOK_DIRS:
					var tf = f + dir.x
					var tr = r + dir.y
					while tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var target_piece = state.squares[tr * 8 + tf]
						if target_piece == null:
							moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
						else:
							if target_piece["color"] == opp_color:
								moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
							break
						tf += dir.x
						tr += dir.y

			ChessTypes.PieceType.QUEEN:
				for dir in KING_DIRS:
					var tf = f + dir.x
					var tr = r + dir.y
					while tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var target_piece = state.squares[tr * 8 + tf]
						if target_piece == null:
							moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
						else:
							if target_piece["color"] == opp_color:
								moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))
							break
						tf += dir.x
						tr += dir.y

			ChessTypes.PieceType.KING:
				# Normal moves
				for dir in KING_DIRS:
					var tf = f + dir.x
					var tr = r + dir.y
					if tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var target_piece = state.squares[tr * 8 + tf]
						if target_piece == null or target_piece["color"] == opp_color:
							moves.append(create_move(src_sq, ChessTypes.coord_to_square(tf, tr)))

				# Castling
				if turn == ChessTypes.PieceColor.WHITE and r == 0 and f == 4:
					# White Kingside (e1-g1)
					if state.castling.get("wK", false):
						if state.squares[0 * 8 + 5] == null and state.squares[0 * 8 + 6] == null:
							if not is_square_attacked(state, 4, opp_color) and not is_square_attacked(state, 5, opp_color) and not is_square_attacked(state, 6, opp_color):
								var rook = state.squares[0 * 8 + 7]
								if rook != null and rook["type"] == ChessTypes.PieceType.ROOK and rook["color"] == ChessTypes.PieceColor.WHITE:
									moves.append(create_move("e1", "g1", ChessTypes.PieceType.NONE, true))
					# White Queenside (e1-c1)
					if state.castling.get("wQ", false):
						if state.squares[1] == null and state.squares[2] == null and state.squares[3] == null:
							if not is_square_attacked(state, 4, opp_color) and not is_square_attacked(state, 3, opp_color) and not is_square_attacked(state, 2, opp_color):
								var rook = state.squares[0]
								if rook != null and rook["type"] == ChessTypes.PieceType.ROOK and rook["color"] == ChessTypes.PieceColor.WHITE:
									moves.append(create_move("e1", "c1", ChessTypes.PieceType.NONE, true))

				elif turn == ChessTypes.PieceColor.BLACK and r == 7 and f == 4:
					# Black Kingside (e8-g8)
					if state.castling.get("bK", false):
						if state.squares[7 * 8 + 5] == null and state.squares[7 * 8 + 6] == null:
							if not is_square_attacked(state, 7 * 8 + 4, opp_color) and not is_square_attacked(state, 7 * 8 + 5, opp_color) and not is_square_attacked(state, 7 * 8 + 6, opp_color):
								var rook = state.squares[7 * 8 + 7]
								if rook != null and rook["type"] == ChessTypes.PieceType.ROOK and rook["color"] == ChessTypes.PieceColor.BLACK:
									moves.append(create_move("e8", "g8", ChessTypes.PieceType.NONE, true))
					# Black Queenside (e8-c8)
					if state.castling.get("bQ", false):
						if state.squares[7 * 8 + 1] == null and state.squares[7 * 8 + 2] == null and state.squares[7 * 8 + 3] == null:
							if not is_square_attacked(state, 7 * 8 + 4, opp_color) and not is_square_attacked(state, 7 * 8 + 3, opp_color) and not is_square_attacked(state, 7 * 8 + 2, opp_color):
								var rook = state.squares[7 * 8 + 0]
								if rook != null and rook["type"] == ChessTypes.PieceType.ROOK and rook["color"] == ChessTypes.PieceColor.BLACK:
									moves.append(create_move("e8", "c8", ChessTypes.PieceType.NONE, true))

	return moves

# Apply move directly to state (without validation)
static func apply_move_unchecked(state: ChessBoardState, move: Variant) -> void:
	var from_sq: String = ""
	var to_sq: String = ""
	var promo: int = ChessTypes.PieceType.NONE
	var is_castle: bool = false
	var is_ep: bool = false

	if move is ChessMove:
		from_sq = move.from_sq
		to_sq = move.to_sq
		promo = move.promotion
		is_castle = move.is_castling
		is_ep = move.is_en_passant
	elif move is Dictionary:
		from_sq = move.get("from", "")
		to_sq = move.get("to", "")
		promo = move.get("promotion", ChessTypes.PieceType.NONE)
		is_castle = move.get("is_castling", false)
		is_ep = move.get("is_en_passant", false)
	else:
		return

	var from_idx = ChessTypes.square_to_index(from_sq)
	var to_idx = ChessTypes.square_to_index(to_sq)
	if from_idx < 0 or to_idx < 0:
		return

	var piece = state.squares[from_idx]
	if piece == null:
		return

	var is_capture = state.squares[to_idx] != null
	var is_pawn = piece["type"] == ChessTypes.PieceType.PAWN

	# Reset en passant target
	state.ep_square = "-"

	# Handle En Passant capture removal
	if is_ep:
		is_capture = true
		var ep_coord = ChessTypes.square_to_coord(to_sq)
		var captured_pawn_r = 4 if piece["color"] == ChessTypes.PieceColor.WHITE else 3
		var captured_idx = captured_pawn_r * 8 + ep_coord.x
		state.squares[captured_idx] = null

	# Handle Double Pawn Push (set en-passant square)
	if is_pawn and abs(to_idx / 8 - from_idx / 8) == 2:
		var ep_r = (from_idx / 8 + to_idx / 8) / 2
		state.ep_square = ChessTypes.coord_to_square(from_idx % 8, ep_r)

	# Handle Castling Rook move
	if is_castle:
		if to_sq == "g1": # White kingside
			state.squares[5] = state.squares[7]
			state.squares[7] = null
		elif to_sq == "c1": # White queenside
			state.squares[3] = state.squares[0]
			state.squares[0] = null
		elif to_sq == "g8": # Black kingside
			state.squares[7 * 8 + 5] = state.squares[7 * 8 + 7]
			state.squares[7 * 8 + 7] = null
		elif to_sq == "c8": # Black queenside
			state.squares[7 * 8 + 3] = state.squares[7 * 8 + 0]
			state.squares[7 * 8 + 0] = null

	# Move piece
	if promo != ChessTypes.PieceType.NONE:
		state.squares[to_idx] = {"color": piece["color"], "type": promo}
	else:
		state.squares[to_idx] = piece
	state.squares[from_idx] = null

	# Revoke castling rights if King or Rook moved or was captured
	if piece["type"] == ChessTypes.PieceType.KING:
		if piece["color"] == ChessTypes.PieceColor.WHITE:
			state.castling["wK"] = false
			state.castling["wQ"] = false
		else:
			state.castling["bK"] = false
			state.castling["bQ"] = false
	elif piece["type"] == ChessTypes.PieceType.ROOK:
		if from_idx == 0: state.castling["wQ"] = false
		elif from_idx == 7: state.castling["wK"] = false
		elif from_idx == 56: state.castling["bQ"] = false
		elif from_idx == 63: state.castling["bK"] = false

	# If rook was captured on original square
	if to_idx == 0: state.castling["wQ"] = false
	elif to_idx == 7: state.castling["wK"] = false
	elif to_idx == 56: state.castling["bQ"] = false
	elif to_idx == 63: state.castling["bK"] = false

	# Update clocks
	if is_pawn or is_capture:
		state.halfmove_clock = 0
	else:
		state.halfmove_clock += 1

	if state.turn == ChessTypes.PieceColor.BLACK:
		state.fullmove_number += 1
		state.turn = ChessTypes.PieceColor.WHITE
	else:
		state.turn = ChessTypes.PieceColor.BLACK

	# Catat riwayat posisi baru
	state.record_current_position()

# Get strictly legal moves (filtered for check)
static func get_legal_moves(state: ChessBoardState, from_sq: String = "") -> Array[ChessMove]:
	var pseudo_moves = generate_pseudo_moves(state, from_sq)
	var legal_moves: Array[ChessMove] = []
	var player_color = state.turn

	for m in pseudo_moves:
		var sim_state = state.clone()
		apply_move_unchecked(sim_state, m)
		# After move, is the moving player's king in check?
		if not is_in_check(sim_state, player_color):
			legal_moves.append(m)

	return legal_moves

static func is_checkmate(state: ChessBoardState) -> bool:
	if not is_in_check(state, state.turn):
		return false
	return get_legal_moves(state).is_empty()

static func is_stalemate(state: ChessBoardState) -> bool:
	if is_in_check(state, state.turn):
		return false
	return get_legal_moves(state).is_empty()

# Deteksi Threefold Repetition (Remis jika posisi yang sama terjadi 3 kali)
static func is_threefold_repetition(state: ChessBoardState) -> bool:
	if state.position_history.is_empty():
		return false
	var cur_key = state.get_position_key()
	var count = 0
	for key in state.position_history:
		if key == cur_key:
			count += 1
			if count >= 3:
				return true
	return false

# Deteksi Insufficient Material (Remis jika sisa materi tidak memungkinkan skakmat)
static func is_insufficient_material(state: ChessBoardState) -> bool:
	var white_pieces: Array[Dictionary] = []
	var black_pieces: Array[Dictionary] = []

	for i in range(64):
		var p = state.squares[i]
		if p == null:
			continue
		if p["type"] == ChessTypes.PieceType.KING:
			continue
		# Adanya pion, benteng, atau ratu memungkinkan skakmat
		if p["type"] == ChessTypes.PieceType.PAWN or p["type"] == ChessTypes.PieceType.ROOK or p["type"] == ChessTypes.PieceType.QUEEN:
			return false
		if p["color"] == ChessTypes.PieceColor.WHITE:
			white_pieces.append({"type": p["type"], "idx": i})
		else:
			black_pieces.append({"type": p["type"], "idx": i})

	# King vs King
	if white_pieces.is_empty() and black_pieces.is_empty():
		return true

	# King + Minor vs King
	if white_pieces.size() == 1 and black_pieces.is_empty():
		return true
	if black_pieces.size() == 1 and white_pieces.is_empty():
		return true

	# King + Bishop vs King + Bishop (petak sewarna)
	if white_pieces.size() == 1 and black_pieces.size() == 1:
		var wp = white_pieces[0]
		var bp = black_pieces[0]
		if wp["type"] == ChessTypes.PieceType.BISHOP and bp["type"] == ChessTypes.PieceType.BISHOP:
			var w_sq_color = ((wp["idx"] % 8) + (wp["idx"] / 8)) % 2
			var b_sq_color = ((bp["idx"] % 8) + (bp["idx"] / 8)) % 2
			if w_sq_color == b_sq_color:
				return true

	return false

static func is_game_over(state: ChessBoardState) -> bool:
	if is_checkmate(state) or is_stalemate(state):
		return true
	if state.halfmove_clock >= 100:
		return true
	if is_threefold_repetition(state):
		return true
	if is_insufficient_material(state):
		return true
	return false

# Perft (Performance Test) untuk menguji keakuratan move generator secara rekursif
static func perft(state: ChessBoardState, depth: int) -> int:
	if depth <= 0:
		return 1
	var moves = get_legal_moves(state)
	if depth == 1:
		return moves.size()

	var nodes = 0
	for m in moves:
		var sim = state.clone()
		apply_move_unchecked(sim, m)
		nodes += perft(sim, depth - 1)
	return nodes

