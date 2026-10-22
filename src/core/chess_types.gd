class_name ChessTypes
extends RefCounted

enum PieceColor {
	WHITE = 0,
	BLACK = 1,
	NONE = -1
}

enum PieceType {
	NONE = 0,
	PAWN = 1,
	KNIGHT = 2,
	BISHOP = 3,
	ROOK = 4,
	QUEEN = 5,
	KING = 6
}

const FILES: Array[String] = ["a", "b", "c", "d", "e", "f", "g", "h"]
const RANKS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]

static func square_to_index(sq: String) -> int:
	if sq.length() != 2:
		return -1
	var f = FILES.find(sq[0])
	var r = RANKS.find(sq[1])
	if f == -1 or r == -1:
		return -1
	return r * 8 + f

static func index_to_square(idx: int) -> String:
	if idx < 0 or idx >= 64:
		return ""
	var f = idx % 8
	var r = int(idx / 8.0)
	return FILES[f] + RANKS[r]

static func coord_to_square(file_idx: int, rank_idx: int) -> String:
	if file_idx < 0 or file_idx > 7 or rank_idx < 0 or rank_idx > 7:
		return ""
	return FILES[file_idx] + RANKS[rank_idx]

static func square_to_coord(sq: String) -> Vector2i:
	if sq.length() != 2:
		return Vector2i(-1, -1)
	var f = FILES.find(sq[0])
	var r = RANKS.find(sq[1])
	return Vector2i(f, r)

static func char_to_piece(ch: String) -> Dictionary:
	var is_white = ch == ch.to_upper()
	var color = PieceColor.WHITE if is_white else PieceColor.BLACK
	var lower = ch.to_lower()
	var type = PieceType.NONE
	match lower:
		"p": type = PieceType.PAWN
		"n": type = PieceType.KNIGHT
		"b": type = PieceType.BISHOP
		"r": type = PieceType.ROOK
		"q": type = PieceType.QUEEN
		"k": type = PieceType.KING
	if type == PieceType.NONE:
		return {}
	return {"color": color, "type": type}

static func piece_to_char(piece: Dictionary) -> String:
	if piece.is_empty() or piece.get("type", PieceType.NONE) == PieceType.NONE:
		return ""
	var ch = ""
	match piece.get("type"):
		PieceType.PAWN: ch = "p"
		PieceType.KNIGHT: ch = "n"
		PieceType.BISHOP: ch = "b"
		PieceType.ROOK: ch = "r"
		PieceType.QUEEN: ch = "q"
		PieceType.KING: ch = "k"
	if piece.get("color") == PieceColor.WHITE:
		return ch.to_upper()
	return ch

static func piece_type_to_san_char(type: int) -> String:
	match type:
		PieceType.KNIGHT: return "N"
		PieceType.BISHOP: return "B"
		PieceType.ROOK: return "R"
		PieceType.QUEEN: return "Q"
		PieceType.KING: return "K"
		_: return ""

static func san_char_to_piece_type(ch: String) -> int:
	match ch.to_upper():
		"N": return PieceType.KNIGHT
		"B": return PieceType.BISHOP
		"R": return PieceType.ROOK
		"Q": return PieceType.QUEEN
		"K": return PieceType.KING
		"P": return PieceType.PAWN
		_: return PieceType.NONE
