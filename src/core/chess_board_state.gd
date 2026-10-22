class_name ChessBoardState
extends RefCounted

const DEFAULT_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

var squares: Array = [] # 64 items: null or {"color": int, "type": int}
var turn: int = ChessTypes.PieceColor.WHITE
var castling: Dictionary = {
	"wK": true,
	"wQ": true,
	"bK": true,
	"bQ": true
}
var ep_square: String = "-"
var halfmove_clock: int = 0
var fullmove_number: int = 1
var position_history: Array[String] = []

func _init(fen_str: String = DEFAULT_FEN):
	squares.resize(64)
	squares.fill(null)
	load_fen(fen_str)

func clone() -> ChessBoardState:
	var copy = ChessBoardState.new("")
	for i in range(64):
		var p = squares[i]
		if p != null:
			copy.squares[i] = {"color": p["color"], "type": p["type"]}
		else:
			copy.squares[i] = null
	copy.turn = turn
	copy.castling = castling.duplicate()
	copy.ep_square = ep_square
	copy.halfmove_clock = halfmove_clock
	copy.fullmove_number = fullmove_number
	copy.position_history = position_history.duplicate()
	return copy

func get_piece(sq: String) -> Variant:
	var idx = ChessTypes.square_to_index(sq)
	if idx < 0 or idx >= 64:
		return null
	return squares[idx]

func set_piece(sq: String, piece: Variant) -> void:
	var idx = ChessTypes.square_to_index(sq)
	if idx >= 0 and idx < 64:
		squares[idx] = piece

func get_piece_at_idx(idx: int) -> Variant:
	if idx < 0 or idx >= 64:
		return null
	return squares[idx]

func set_piece_at_idx(idx: int, piece: Variant) -> void:
	if idx >= 0 and idx < 64:
		squares[idx] = piece

func load_fen(fen_str: String) -> bool:
	if fen_str.strip_edges().is_empty():
		fen_str = DEFAULT_FEN
	var parts = fen_str.strip_edges().split(" ")
	if parts.size() < 1:
		return false

	# Reset
	squares.fill(null)
	castling = {"wK": false, "wQ": false, "bK": false, "bQ": false}
	ep_square = "-"
	halfmove_clock = 0
	fullmove_number = 1
	position_history.clear()

	# 1. Piece placement (from rank 8 down to rank 1)
	var ranks = parts[0].split("/")
	if ranks.size() != 8:
		return false

	for r in range(8):
		var rank_str = ranks[r]
		var rank_idx = 7 - r # rank 8 is index 7, rank 1 is index 0
		var file_idx = 0
		for i in range(rank_str.length()):
			var ch = rank_str[i]
			if ch.is_valid_int():
				file_idx += ch.to_int()
			else:
				var piece = ChessTypes.char_to_piece(ch)
				if not piece.is_empty() and file_idx < 8:
					var sq_idx = rank_idx * 8 + file_idx
					squares[sq_idx] = piece
					file_idx += 1

	# 2. Active turn
	if parts.size() > 1:
		turn = ChessTypes.PieceColor.BLACK if parts[1] == "b" else ChessTypes.PieceColor.WHITE
	else:
		turn = ChessTypes.PieceColor.WHITE

	# 3. Castling rights
	if parts.size() > 2:
		var cast = parts[2]
		castling["wK"] = cast.contains("K")
		castling["wQ"] = cast.contains("Q")
		castling["bK"] = cast.contains("k")
		castling["bQ"] = cast.contains("q")

	# 4. En passant target
	if parts.size() > 3:
		ep_square = parts[3]
		if ep_square != "-" and ep_square.length() != 2:
			ep_square = "-"

	# 5. Halfmove clock
	if parts.size() > 4 and parts[4].is_valid_int():
		halfmove_clock = parts[4].to_int()

	# 6. Fullmove number
	if parts.size() > 5 and parts[5].is_valid_int():
		fullmove_number = parts[5].to_int()

	record_current_position()
	return true

func get_position_key() -> String:
	var rows: Array[String] = []
	for r in range(7, -1, -1):
		var row_str = ""
		var empty_count = 0
		for f in range(8):
			var idx = r * 8 + f
			var p = squares[idx]
			if p == null:
				empty_count += 1
			else:
				if empty_count > 0:
					row_str += str(empty_count)
					empty_count = 0
				row_str += ChessTypes.piece_to_char(p)
		if empty_count > 0:
			row_str += str(empty_count)
		rows.append(row_str)

	var board_part = "/".join(rows)
	var turn_part = "w" if turn == ChessTypes.PieceColor.WHITE else "b"

	var cast_str = ""
	if castling.get("wK", false): cast_str += "K"
	if castling.get("wQ", false): cast_str += "Q"
	if castling.get("bK", false): cast_str += "k"
	if castling.get("bQ", false): cast_str += "q"
	if cast_str.is_empty(): cast_str = "-"

	var ep_part = ep_square if ep_square != "" else "-"
	return "%s %s %s %s" % [board_part, turn_part, cast_str, ep_part]

func record_current_position() -> void:
	position_history.append(get_position_key())

func to_fen() -> String:
	var rows: Array[String] = []
	for r in range(7, -1, -1):
		var row_str = ""
		var empty_count = 0
		for f in range(8):
			var idx = r * 8 + f
			var p = squares[idx]
			if p == null:
				empty_count += 1
			else:
				if empty_count > 0:
					row_str += str(empty_count)
					empty_count = 0
				row_str += ChessTypes.piece_to_char(p)
		if empty_count > 0:
			row_str += str(empty_count)
		rows.append(row_str)

	var board_part = "/".join(rows)
	var turn_part = "w" if turn == ChessTypes.PieceColor.WHITE else "b"

	var cast_str = ""
	if castling.get("wK", false): cast_str += "K"
	if castling.get("wQ", false): cast_str += "Q"
	if castling.get("bK", false): cast_str += "k"
	if castling.get("bQ", false): cast_str += "q"
	if cast_str.is_empty(): cast_str = "-"

	var ep_part = ep_square if ep_square != "" else "-"
	return "%s %s %s %s %d %d" % [board_part, turn_part, cast_str, ep_part, halfmove_clock, fullmove_number]

const PIECE_VALUES = {
	ChessTypes.PieceType.PAWN: 1,
	ChessTypes.PieceType.KNIGHT: 3,
	ChessTypes.PieceType.BISHOP: 3,
	ChessTypes.PieceType.ROOK: 5,
	ChessTypes.PieceType.QUEEN: 9,
}

const INITIAL_PIECE_COUNTS = {
	ChessTypes.PieceType.PAWN: 8,
	ChessTypes.PieceType.KNIGHT: 2,
	ChessTypes.PieceType.BISHOP: 2,
	ChessTypes.PieceType.ROOK: 2,
	ChessTypes.PieceType.QUEEN: 1,
}

static func calculate_material_and_captured(state: ChessBoardState) -> Dictionary:
	var white_counts: Dictionary = {
		ChessTypes.PieceType.PAWN: 0,
		ChessTypes.PieceType.KNIGHT: 0,
		ChessTypes.PieceType.BISHOP: 0,
		ChessTypes.PieceType.ROOK: 0,
		ChessTypes.PieceType.QUEEN: 0,
	}
	var black_counts: Dictionary = {
		ChessTypes.PieceType.PAWN: 0,
		ChessTypes.PieceType.KNIGHT: 0,
		ChessTypes.PieceType.BISHOP: 0,
		ChessTypes.PieceType.ROOK: 0,
		ChessTypes.PieceType.QUEEN: 0,
	}

	if state != null and state.squares != null:
		for sq in state.squares:
			if sq != null and sq is Dictionary:
				var t = sq.get("type", ChessTypes.PieceType.NONE)
				var c = sq.get("color", ChessTypes.PieceColor.NONE)
				if t != ChessTypes.PieceType.KING and t != ChessTypes.PieceType.NONE:
					if c == ChessTypes.PieceColor.WHITE:
						white_counts[t] = white_counts.get(t, 0) + 1
					elif c == ChessTypes.PieceColor.BLACK:
						black_counts[t] = black_counts.get(t, 0) + 1

	var white_val: int = (
		white_counts[ChessTypes.PieceType.PAWN] * 1 +
		white_counts[ChessTypes.PieceType.KNIGHT] * 3 +
		white_counts[ChessTypes.PieceType.BISHOP] * 3 +
		white_counts[ChessTypes.PieceType.ROOK] * 5 +
		white_counts[ChessTypes.PieceType.QUEEN] * 9
	)
	var black_val: int = (
		black_counts[ChessTypes.PieceType.PAWN] * 1 +
		black_counts[ChessTypes.PieceType.KNIGHT] * 3 +
		black_counts[ChessTypes.PieceType.BISHOP] * 3 +
		black_counts[ChessTypes.PieceType.ROOK] * 5 +
		black_counts[ChessTypes.PieceType.QUEEN] * 9
	)

	var black_captured: Array[int] = []
	var white_captured: Array[int] = []

	var order = [
		ChessTypes.PieceType.PAWN,
		ChessTypes.PieceType.KNIGHT,
		ChessTypes.PieceType.BISHOP,
		ChessTypes.PieceType.ROOK,
		ChessTypes.PieceType.QUEEN
	]

	for p_type in order:
		var init_c = INITIAL_PIECE_COUNTS[p_type]
		var missing_b = maxi(0, init_c - black_counts[p_type])
		for _i in range(missing_b):
			black_captured.append(p_type)

		var missing_w = maxi(0, init_c - white_counts[p_type])
		for _j in range(missing_w):
			white_captured.append(p_type)

	return {
		"white_material": white_val,
		"black_material": black_val,
		"white_advantage": white_val - black_val,
		"black_captured": black_captured,
		"white_captured": white_captured
	}

