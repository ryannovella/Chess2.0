class_name TacticsService
extends RefCounted

const TACTICS_DIR = "res://assets/data/tactics/"
const PROGRESS_SAVE_PATH = "user://tactics_progress.json"

static var _loaded_sets: Dictionary = {}
static var _progress: Dictionary = {}
static var _is_progress_loaded: bool = false

# ==============================================================================
# SET & PUZZLE LOADING
# ==============================================================================

static func get_available_sets() -> Array[Dictionary]:
	_ensure_progress_loaded()
	var result: Array[Dictionary] = []
	var known_files = ["checkmate_patterns.json", "queen_captures.json"]
	
	for filename in known_files:
		var full_path = TACTICS_DIR + filename
		if FileAccess.file_exists(full_path):
			var set_data = _load_set_file(full_path)
			if not set_data.is_empty():
				var set_id: String = set_data.get("id", "")
				var stats = get_set_stats(set_id)
				result.append({
					"id": set_id,
					"title": set_data.get("title", ""),
					"description": set_data.get("description", ""),
					"category": set_data.get("category", ""),
					"total_puzzles": set_data.get("total_puzzles", 0),
					"solved_count": stats.get("solved_count", 0),
					"total_stars": stats.get("total_stars", 0),
					"mastery_percent": stats.get("mastery_percent", 0.0),
					"path": full_path
				})
	return result

static func load_set(set_id: String) -> Dictionary:
	if _loaded_sets.has(set_id):
		return _loaded_sets[set_id]
	
	var path = TACTICS_DIR + set_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	
	var data = _load_set_file(path)
	if not data.is_empty():
		_loaded_sets[set_id] = data
	return data

static func _load_set_file(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	if json.parse(text) != OK or not (json.data is Dictionary):
		return {}
	return json.data

static func get_puzzles(set_id: String, side_filter: String = "", theme_filter: String = "") -> Array[Dictionary]:
	var set_data = load_set(set_id)
	var raw_puzzles: Array = set_data.get("puzzles", [])
	var filtered: Array[Dictionary] = []
	
	var norm_side = side_filter.strip_edges().to_lower()
	var norm_theme = theme_filter.strip_edges().to_lower()
	
	for p in raw_puzzles:
		if not (p is Dictionary):
			continue
		var p_dict = p as Dictionary
		if not norm_side.is_empty() and p_dict.get("side", "").to_lower() != norm_side:
			continue
		if not norm_theme.is_empty() and p_dict.get("theme", "").to_lower() != norm_theme:
			continue
		filtered.append(p_dict)
		
	return filtered

static func get_puzzle_by_id(set_id: String, puzzle_id: String) -> Dictionary:
	var set_data = load_set(set_id)
	var raw_puzzles: Array = set_data.get("puzzles", [])
	for p in raw_puzzles:
		if p is Dictionary and p.get("id", "") == puzzle_id:
			return p as Dictionary
	return {}

# ==============================================================================
# PUZZLE STEP VALIDATION
# ==============================================================================

static func validate_player_move(puzzle: Dictionary, step_index: int, played_uci: String) -> Dictionary:
	var moves: Array = puzzle.get("moves", [])
	if step_index < 0 or step_index >= moves.size():
		return {
			"is_correct": false,
			"expected_uci": "",
			"is_final_step": false,
			"next_opponent_uci": ""
		}
	
	var expected_uci: String = str(moves[step_index]).strip_edges().to_lower()
	var is_correct: bool = (played_uci.strip_edges().to_lower() == expected_uci)
	
	var is_final_step: bool = is_correct and (step_index + 1 >= moves.size())
	var next_opponent_uci: String = ""
	if is_correct and not is_final_step:
		# If the next move is opponent's forced response
		if step_index + 1 < moves.size():
			next_opponent_uci = str(moves[step_index + 1]).strip_edges().to_lower()
	
	return {
		"is_correct": is_correct,
		"expected_uci": expected_uci,
		"is_final_step": is_final_step,
		"next_opponent_uci": next_opponent_uci
	}

static func get_hint(puzzle: Dictionary, step_index: int) -> Dictionary:
	var moves: Array = puzzle.get("moves", [])
	if step_index < 0 or step_index >= moves.size():
		return {"from": "", "to": "", "uci": ""}
	var uci = str(moves[step_index]).strip_edges().to_lower()
	if uci.length() >= 4:
		return {
			"from": uci.substr(0, 2),
			"to": uci.substr(2, 2),
			"uci": uci
		}
	return {"from": "", "to": "", "uci": ""}

# ==============================================================================
# PROGRESS & PERSISTENCE
# ==============================================================================

static func _ensure_progress_loaded() -> void:
	if _is_progress_loaded:
		return
	_progress.clear()
	_is_progress_loaded = true
	if not FileAccess.file_exists(PROGRESS_SAVE_PATH):
		return
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK and json.data is Dictionary:
			_progress = json.data

static func _save_progress() -> bool:
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(_progress, "\t"))
	file.close()
	return true

static func get_puzzle_progress(puzzle_id: String) -> Dictionary:
	_ensure_progress_loaded()
	if _progress.has(puzzle_id):
		return _progress[puzzle_id]
	return {
		"solved": false,
		"attempts": 0,
		"mistakes": 0,
		"hints_used": 0,
		"stars": 0,
		"last_played": 0
	}

static func record_puzzle_completion(puzzle_id: String, mistakes: int, hints: int) -> int:
	_ensure_progress_loaded()
	var cur = get_puzzle_progress(puzzle_id)
	
	# Determine stars (1 to 3):
	# 3 stars: solved cleanly with 0 mistakes and 0 hints
	# 2 stars: 1 mistake OR 1 hint (total flaws == 1)
	# 1 star: solved with multiple mistakes and/or hints (total flaws >= 2)
	var total_flaws = mistakes + hints
	var stars = 3
	if total_flaws >= 2:
		stars = 1
	elif total_flaws == 1:
		stars = 2
	
	# Keep highest stars earned
	var existing_stars = int(cur.get("stars", 0))
	var final_stars = maxi(existing_stars, stars)
	
	var updated = {
		"solved": true,
		"attempts": int(cur.get("attempts", 0)) + 1,
		"mistakes": mistakes,
		"hints_used": hints,
		"stars": final_stars,
		"last_played": int(Time.get_unix_time_from_system())
	}
	_progress[puzzle_id] = updated
	_save_progress()
	return final_stars

static func get_set_stats(set_id: String) -> Dictionary:
	_ensure_progress_loaded()
	var set_data = load_set(set_id)
	var raw_puzzles: Array = set_data.get("puzzles", [])
	var total = raw_puzzles.size()
	if total == 0:
		return {
			"total": 0,
			"solved_count": 0,
			"total_stars": 0,
			"max_stars": 0,
			"mastery_percent": 0.0
		}
	
	var solved_count = 0
	var total_stars = 0
	
	for p in raw_puzzles:
		if p is Dictionary:
			var pid = p.get("id", "")
			var prog = get_puzzle_progress(pid)
			if prog.get("solved", false):
				solved_count += 1
			total_stars += int(prog.get("stars", 0))
	
	var max_stars = total * 3
	var mastery_pct = (float(total_stars) / float(max_stars)) * 100.0 if max_stars > 0 else 0.0
	
	return {
		"total": total,
		"solved_count": solved_count,
		"total_stars": total_stars,
		"max_stars": max_stars,
		"mastery_percent": mastery_pct
	}

static func clear_all_progress() -> void:
	_ensure_progress_loaded()
	_progress.clear()
	_save_progress()
