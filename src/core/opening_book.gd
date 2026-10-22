class_name OpeningBook
extends RefCounted

const OPENINGS_DATA_PATH = "res://assets/data/openings.json"

static var _db: Dictionary = {}
static var _is_loaded: bool = false

static func _ensure_loaded() -> void:
	if _is_loaded:
		return
	_is_loaded = true
	if not FileAccess.file_exists(OPENINGS_DATA_PATH):
		return
	var file = FileAccess.open(OPENINGS_DATA_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_err = json.parse(json_str)
		if parse_err == OK and json.data is Dictionary:
			_db = json.data

static func fen_to_epd(fen: String) -> String:
	var parts = fen.strip_edges().split(" ")
	if parts.size() >= 3:
		return "%s %s %s" % [parts[0], parts[1], parts[2]]
	return fen.strip_edges()


static func lookup_position(fen: String) -> Dictionary:
	_ensure_loaded()
	var epd = fen_to_epd(fen)
	if _db.has(epd):
		var entry: Dictionary = _db[epd]
		return {
			"found": true,
			"name": entry.get("name", "Unknown Opening"),
			"eco": entry.get("eco", ""),
			"ply": entry.get("ply", 0)
		}
	return {
		"found": false,
		"name": "",
		"eco": "",
		"ply": 0
	}

static func is_book_move(curr_fen: String, ply: int) -> bool:
	_ensure_loaded()
	if ply > 24: # Opening phase cap
		return false
	var info = lookup_position(curr_fen)
	return info.get("found", false)
