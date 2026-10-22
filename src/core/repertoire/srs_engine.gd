class_name SRSEngine
extends RefCounted

const PROGRESS_SAVE_PATH = "user://reps_progress.json"
const DEFAULT_EASE_FACTOR: float = 2.5
const MIN_EASE_FACTOR: float = 1.3
const SECONDS_PER_DAY: int = 86400

# Dictionary mapping item_id (String) -> Dictionary of SRS progress
# {
#   "reps": int,
#   "interval_days": float,
#   "ease_factor": float,
#   "last_reviewed": int,
#   "due_date": int,
#   "history": Array[int] # quality scores
# }
var _progress: Dictionary = {}
var _is_loaded: bool = false

func _init() -> void:
	load_progress()

func load_progress() -> void:
	_progress.clear()
	_is_loaded = true
	if not FileAccess.file_exists(PROGRESS_SAVE_PATH):
		return
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		file.close()
		var json = JSON.new()
		var err = json.parse(content)
		if err == OK and json.data is Dictionary:
			_progress = json.data

func save_progress() -> bool:
	var file = FileAccess.open(PROGRESS_SAVE_PATH, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(_progress, "\\t"))
	file.close()
	return true

func get_item_data(item_id: String) -> Dictionary:
	if _progress.has(item_id):
		return _progress[item_id]
	return {
		"reps": 0,
		"interval_days": 0.0,
		"ease_factor": DEFAULT_EASE_FACTOR,
		"last_reviewed": 0,
		"due_date": 0,
		"history": []
	}

func record_attempt(item_id: String, quality: int, current_timestamp: int = -1) -> Dictionary:
	if current_timestamp <= 0:
		current_timestamp = int(Time.get_unix_time_from_system())
		
	var item = get_item_data(item_id)
	var reps: int = item.get("reps", 0)
	var interval_days: float = float(item.get("interval_days", 0.0))
	var ease_factor: float = float(item.get("ease_factor", DEFAULT_EASE_FACTOR))
	var history: Array = item.get("history", [])
	
	# Clamp quality to 0..5
	quality = clampi(quality, 0, 5)
	history.append(quality)
	
	# SM-2 calculation
	if quality >= 3:
		if reps == 0:
			interval_days = 1.0
		elif reps == 1:
			interval_days = 6.0
		else:
			interval_days = interval_days * ease_factor
		reps += 1
	else:
		reps = 0
		interval_days = 1.0
		
	# Update Ease Factor: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
	ease_factor = ease_factor + (0.1 - (5.0 - quality) * (0.08 + (5.0 - quality) * 0.02))
	ease_factor = maxf(MIN_EASE_FACTOR, ease_factor)
	
	var due_date: int = current_timestamp + int(interval_days * SECONDS_PER_DAY)
	
	var updated_data = {
		"reps": reps,
		"interval_days": interval_days,
		"ease_factor": ease_factor,
		"last_reviewed": current_timestamp,
		"due_date": due_date,
		"history": history
	}
	
	_progress[item_id] = updated_data
	save_progress()
	return updated_data

func is_due(item_id: String, current_timestamp: int = -1) -> bool:
	if current_timestamp <= 0:
		current_timestamp = int(Time.get_unix_time_from_system())
	if not _progress.has(item_id):
		return true # Unseen items are immediately due
	var item = _progress[item_id]
	var due_date: int = item.get("due_date", 0)
	return current_timestamp >= due_date

func get_due_items(item_ids: Array[String], current_timestamp: int = -1) -> Array[String]:
	if current_timestamp <= 0:
		current_timestamp = int(Time.get_unix_time_from_system())
	var due_list: Array[String] = []
	for id in item_ids:
		if is_due(id, current_timestamp):
			due_list.append(id)
	return due_list

func get_mastery_level(item_id: String) -> int:
	if not _progress.has(item_id):
		return 0 # 0: New
	var reps: int = _progress[item_id].get("reps", 0)
	if reps <= 0:
		return 0
	elif reps <= 2:
		return 1 # 1: Learning
	elif reps <= 4:
		return 2 # 2: Reviewing
	else:
		return 3 # 3: Mastered

func get_mastery_percentage(item_ids: Array[String]) -> float:
	if item_ids.is_empty():
		return 0.0
	var total_score: float = 0.0
	for id in item_ids:
		var level = get_mastery_level(id)
		total_score += (float(level) / 3.0) # 0.0 to 1.0
	return clampf((total_score / float(item_ids.size())) * 100.0, 0.0, 100.0)

func reset_item(item_id: String) -> void:
	if _progress.has(item_id):
		_progress.erase(item_id)
		save_progress()

func clear_all() -> void:
	_progress.clear()
	save_progress()
