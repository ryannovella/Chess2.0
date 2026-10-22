class_name ChessMove
extends RefCounted

var from_sq: String = ""
var to_sq: String = ""
var from_idx: int = -1
var to_idx: int = -1
var promotion: int = ChessTypes.PieceType.NONE
var is_castling: bool = false
var is_en_passant: bool = false
var san: String = ""

func _init(p_from: String = "", p_to: String = "", p_promo: int = ChessTypes.PieceType.NONE, p_castle: bool = false, p_ep: bool = false) -> void:
	from_sq = p_from
	to_sq = p_to
	promotion = p_promo
	is_castling = p_castle
	is_en_passant = p_ep
	from_idx = ChessTypes.square_to_index(p_from) if not p_from.is_empty() else -1
	to_idx = ChessTypes.square_to_index(p_to) if not p_to.is_empty() else -1

func to_uci() -> String:
	var uci = from_sq + to_sq
	if promotion != ChessTypes.PieceType.NONE:
		var p_char = "q"
		match promotion:
			ChessTypes.PieceType.ROOK: p_char = "r"
			ChessTypes.PieceType.BISHOP: p_char = "b"
			ChessTypes.PieceType.KNIGHT: p_char = "n"
			_: p_char = "q"
		uci += p_char
	return uci

func to_dict() -> Dictionary:
	return {
		"from": from_sq,
		"to": to_sq,
		"promotion": promotion,
		"is_castling": is_castling,
		"is_en_passant": is_en_passant,
		"san": san
	}

static func from_dict(d: Dictionary) -> ChessMove:
	var mv = ChessMove.new(
		d.get("from", ""),
		d.get("to", ""),
		d.get("promotion", ChessTypes.PieceType.NONE),
		d.get("is_castling", false),
		d.get("is_en_passant", false)
	)
	mv.san = d.get("san", "")
	return mv

static func create(p_from: String, p_to: String, p_promo: int = ChessTypes.PieceType.NONE, p_castle: bool = false, p_ep: bool = false) -> ChessMove:
	return ChessMove.new(p_from, p_to, p_promo, p_castle, p_ep)

func equals(other: Variant) -> bool:
	if other is ChessMove:
		return from_sq == other.from_sq and to_sq == other.to_sq and promotion == other.promotion
	elif other is Dictionary:
		return from_sq == other.get("from", "") and to_sq == other.get("to", "") and promotion == other.get("promotion", ChessTypes.PieceType.NONE)
	return false

func clone() -> ChessMove:
	var c = ChessMove.new(from_sq, to_sq, promotion, is_castling, is_en_passant)
	c.san = san
	return c

func duplicate(_sub_resources: bool = false) -> ChessMove:
	return clone()

# Kompatibilitas indeks Dictionary: move["from"], move["to"], move["promotion"], dsb.
func _get(property: StringName) -> Variant:
	match property:
		&"from": return from_sq
		&"to": return to_sq
		&"promotion": return promotion
		&"is_castling": return is_castling
		&"is_en_passant": return is_en_passant
		&"san": return san
	return null

func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"from":
			from_sq = str(value)
			from_idx = ChessTypes.square_to_index(from_sq)
			return true
		&"to":
			to_sq = str(value)
			to_idx = ChessTypes.square_to_index(to_sq)
			return true
		&"promotion":
			promotion = int(value)
			return true
		&"is_castling":
			is_castling = bool(value)
			return true
		&"is_en_passant":
			is_en_passant = bool(value)
			return true
		&"san":
			san = str(value)
			return true
	return false


func is_empty() -> bool:
	return from_sq.is_empty() or to_sq.is_empty()

func _to_string() -> String:
	var res = "%s->%s" % [from_sq, to_sq]
	if promotion != ChessTypes.PieceType.NONE:
		res += "(promo:%d)" % promotion
	if is_castling:
		res += "(castle)"
	if is_en_passant:
		res += "(ep)"
	return res
