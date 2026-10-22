class_name RepertoireService
extends RefCounted

const RepertoireTree = preload("res://src/core/repertoire/repertoire_tree.gd")
const SRSEngine = preload("res://src/core/repertoire/srs_engine.gd")

const REPERTOIRE_DIR = "res://assets/data/repertoire/"

static var _srs_engine: SRSEngine = null
static var _loaded_trees: Dictionary = {}

static func get_srs_engine() -> SRSEngine:
	if _srs_engine == null:
		_srs_engine = SRSEngine.new()
	return _srs_engine

static func get_available_repertoires() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dir = DirAccess.open(REPERTOIRE_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				var full_path = REPERTOIRE_DIR + file_name
				var meta = _read_repertoire_meta(full_path)
				if not meta.is_empty():
					result.append(meta)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result

static func _read_repertoire_meta(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	var data: Dictionary = json.data
	var rep_id = data.get("id", "")
	var rep_color = data.get("color", "white")
	
	# Compute quick stats
	var tree = load_repertoire(rep_id, path)
	var total_moves = 0
	var mastery_percent: float = 0.0
	var due_count = 0
	
	if tree:
		total_moves = tree.get_total_player_moves()
		var player_ids: Array[String] = []
		for p in tree.all_player_nodes:
			player_ids.append(p.id)
		var srs = get_srs_engine()
		mastery_percent = srs.get_mastery_percentage(player_ids)
		due_count = srs.get_due_items(player_ids).size()
		
	return {
		"id": rep_id,
		"name": data.get("name", "Unknown Opening"),
		"eco": data.get("eco", ""),
		"color": rep_color,
		"description": data.get("description", ""),
		"total_moves": total_moves,
		"mastery_percent": mastery_percent,
		"due_count": due_count,
		"path": path
	}

static func load_repertoire(repertoire_id: String, custom_path: String = "") -> RepertoireTree:
	if _loaded_trees.has(repertoire_id):
		return _loaded_trees[repertoire_id]
		
	var path = custom_path
	if path.is_empty():
		path = REPERTOIRE_DIR + repertoire_id + ".json"
		
	if not FileAccess.file_exists(path):
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return null
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return null
		
	var tree = RepertoireTree.new()
	if tree.load_from_dict(json.data):
		_loaded_trees[repertoire_id] = tree
		return tree
	return null

static func get_repertoire_stats(repertoire_id: String) -> Dictionary:
	var tree = load_repertoire(repertoire_id)
	if not tree:
		return {"total_moves": 0, "due_count": 0, "mastery_percent": 0.0}
	var player_ids: Array[String] = []
	for p in tree.all_player_nodes:
		player_ids.append(p.id)
	var srs = get_srs_engine()
	return {
		"total_moves": player_ids.size(),
		"due_count": srs.get_due_items(player_ids).size(),
		"mastery_percent": srs.get_mastery_percentage(player_ids)
	}
