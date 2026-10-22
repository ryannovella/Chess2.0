class_name RepertoireTree
extends RefCounted

const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const OpeningBook = preload("res://src/core/opening_book.gd")
const RepertoireNode = preload("res://src/core/repertoire/repertoire_node.gd")

var id: String = ""
var name: String = ""
var color: String = "white" # "white" or "black"
var eco: String = ""
var description: String = ""
var root_nodes: Array = []
var epd_to_nodes: Dictionary = {} # epd -> Array
var all_player_nodes: Array = []
var flattened_lines: Array = [] # Array of Arrays

func load_from_dict(data: Dictionary) -> bool:
	id = data.get("id", "")
	name = data.get("name", "")
	color = data.get("color", "white").to_lower()
	eco = data.get("eco", "")
	description = data.get("description", "")
	
	root_nodes.clear()
	epd_to_nodes.clear()
	all_player_nodes.clear()
	flattened_lines.clear()
	
	var raw_root = data.get("root", null)
	if raw_root is Dictionary:
		var node = RepertoireNode.from_dict(raw_root)
		root_nodes.append(node)
	elif data.get("roots", null) is Array:
		for r in data["roots"]:
			if r is Dictionary:
				root_nodes.append(RepertoireNode.from_dict(r))
				
	_build_and_validate_tree()
	_generate_flattened_lines()
	return root_nodes.size() > 0

func _build_and_validate_tree() -> void:
	epd_to_nodes.clear()
	all_player_nodes.clear()
	
	var is_player_white = (color == "white")
	var initial_state = ChessBoardState.new()
	var initial_epd = OpeningBook.fen_to_epd(initial_state.to_fen())
	
	for root in root_nodes:
		_process_node_recursive(root, initial_state.clone(), initial_epd, 1, is_player_white)

func _process_node_recursive(node: RefCounted, state: ChessBoardState, epd_before: String, current_ply: int, is_player_white: bool) -> void:
	node.ply = current_ply
	node.fen_before = state.to_fen()
	
	# Determine if this move belongs to the player
	var is_white_turn = (state.turn == 0) # PieceColor.WHITE is 0
	node.is_player_move = (is_white_turn == is_player_white)
	
	if node.is_player_move:
		if node.id.is_empty():
			node.id = "%s_p%d_%s" % [id, node.ply, node.move_uci]
		all_player_nodes.append(node)
	else:
		if node.id.is_empty():
			node.id = "%s_o%d_%s" % [id, node.ply, node.move_uci]
			
	# Convert UCI to Move and execute
	if not node.move_uci.is_empty():
		var move = ChessSAN.uci_to_move(state, node.move_uci)
		if move:
			if node.san.is_empty():
				node.san = ChessSAN.move_to_san(state, move)
			ChessMoveGenerator.apply_move_unchecked(state, move)
			
	node.fen_after = state.to_fen()
	node.epd_after = OpeningBook.fen_to_epd(node.fen_after)
	
	if not epd_to_nodes.has(node.epd_after):
		epd_to_nodes[node.epd_after] = []
	(epd_to_nodes[node.epd_after] as Array).append(node)
	
	for child in node.children:
		_process_node_recursive(child, state.clone(), node.epd_after, current_ply + 1, is_player_white)

func _generate_flattened_lines() -> void:
	flattened_lines.clear()
	for root in root_nodes:
		_traverse_line(root, [])

func _traverse_line(node: RefCounted, current_path: Array) -> void:
	var path = current_path.duplicate()
	path.append(node)
	
	if node.children.is_empty():
		flattened_lines.append(path)
	else:
		for child in node.children:
			_traverse_line(child, path)

func get_expected_player_move_from_fen(fen: String) -> RefCounted:
	var epd = OpeningBook.fen_to_epd(fen)
	# Check if this position is in the tree and has children that are player moves
	# or if the initial state has root player moves
	var initial_epd = OpeningBook.fen_to_epd(ChessBoardState.DEFAULT_FEN)
	if epd == initial_epd and color == "white" and not root_nodes.is_empty():
		return root_nodes[0]
		
	if epd_to_nodes.has(epd):
		var nodes: Array = epd_to_nodes[epd]
		for n in nodes:
			var node = n
			for child in node.children:
				if child.is_player_move:
					return child
	return null

func get_opponent_replies_from_fen(fen: String) -> Array:
	var epd = OpeningBook.fen_to_epd(fen)
	var replies: Array = []
	
	var initial_epd = OpeningBook.fen_to_epd(ChessBoardState.DEFAULT_FEN)
	if epd == initial_epd and color == "black" and not root_nodes.is_empty():
		for r in root_nodes:
			replies.append(r)
		return replies
		
	if epd_to_nodes.has(epd):
		var nodes: Array = epd_to_nodes[epd]
		for n in nodes:
			var node = n
			for child in node.children:
				if not child.is_player_move:
					replies.append(child)
	return replies

func pick_opponent_reply(fen: String) -> RefCounted:
	var replies = get_opponent_replies_from_fen(fen)
	if replies.is_empty():
		return null
	if replies.size() == 1:
		return replies[0]
		
	# Weighted random choice based on human_freq
	var total_weight: float = 0.0
	for r in replies:
		total_weight += maxf(0.01, r.human_freq)
		
	var roll = randf() * total_weight
	var accum: float = 0.0
	for r in replies:
		accum += maxf(0.01, r.human_freq)
		if roll <= accum:
			return r
	return replies[0]

func get_total_player_moves() -> int:
	return all_player_nodes.size()

func get_total_lines() -> int:
	return flattened_lines.size()
