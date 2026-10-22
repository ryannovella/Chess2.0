class_name RepertoireNode
extends RefCounted

var id: String = ""
var ply: int = 1
var move_uci: String = ""
var san: String = ""
var fen_before: String = ""
var fen_after: String = ""
var epd_after: String = ""
var blurb: String = ""
var is_player_move: bool = true
var human_freq: float = 1.0
var is_blunder: bool = false
var annotation: String = ""
var children: Array = []
var parent_ref: WeakRef = null

func _init(p_uci: String = "", p_san: String = "", p_blurb: String = "", p_is_player: bool = true) -> void:
	move_uci = p_uci
	san = p_san
	blurb = p_blurb
	is_player_move = p_is_player

func add_child(child: RefCounted) -> void:
	child.parent_ref = weakref(self)
	child.ply = ply + 1
	children.append(child)

func get_parent() -> RefCounted:
	if parent_ref != null:
		return parent_ref.get_ref() as RefCounted
	return null

func find_child_by_uci(uci: String) -> RefCounted:
	for c in children:
		if c.move_uci == uci:
			return c
	return null

func find_child_by_san(san_str: String) -> RefCounted:
	for c in children:
		if c.san == san_str:
			return c
	return null

func to_dict() -> Dictionary:
	var c_list: Array = []
	for c in children:
		c_list.append(c.to_dict())
	return {
		"id": id,
		"ply": ply,
		"move_uci": move_uci,
		"san": san,
		"fen_before": fen_before,
		"fen_after": fen_after,
		"epd_after": epd_after,
		"blurb": blurb,
		"is_player_move": is_player_move,
		"human_freq": human_freq,
		"is_blunder": is_blunder,
		"annotation": annotation,
		"children": c_list
	}

static func from_dict(data: Dictionary) -> RefCounted:
	var script = load("res://src/core/repertoire/repertoire_node.gd") as GDScript
	var node = script.new(
		data.get("move_uci", data.get("move", "")),
		data.get("san", ""),
		data.get("blurb", ""),
		data.get("is_player_move", true)
	)
	node.id = data.get("id", "")
	node.ply = data.get("ply", 1)
	node.fen_before = data.get("fen_before", "")
	node.fen_after = data.get("fen_after", "")
	node.epd_after = data.get("epd_after", "")
	node.human_freq = float(data.get("human_freq", 1.0))
	node.is_blunder = data.get("is_blunder", false)
	node.annotation = data.get("annotation", "")
	
	var raw_children = data.get("children", [])
	if raw_children is Array:
		for c_data in raw_children:
			if c_data is Dictionary:
				var c_node = from_dict(c_data)
				node.add_child(c_node)
	return node
