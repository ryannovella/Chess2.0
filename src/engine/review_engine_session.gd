class_name ReviewEngineSession
extends RefCounted

const UCIClient = preload("res://src/engine/uci_client.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")

signal position_evaluated(fen: String, result: Dictionary)
signal progress_updated(completed: int, total: int)
signal session_completed(results: Array[Dictionary])

var _client: UCIClient = null
var _is_running: bool = false
var _queue: Array[Dictionary] = [] # [{ "fen": String, "ply": int, "turn": int, "is_terminal": bool, "terminal_eval": int }]
var _results: Array[Dictionary] = []
var _current_idx: int = 0
var _current_req_id: int = 0
var _multipv_data: Dictionary = {} # multipv rank -> eval dict
var _target_depth: int = 18
var _max_time_ms: int = 1500
var _multipv_count: int = 3
var _timer_guard: SceneTreeTimer = null
var _is_engine_ready: bool = false

func _init() -> void:
	pass

func start_analysis(positions: Array[Dictionary], depth: int = 14, max_time_ms: int = 800, multipv: int = 2, threads: int = 1, hash_mb: int = 64) -> void:
	stop_analysis()
	_queue = positions.duplicate()
	_results.clear()
	_current_idx = 0
	_is_running = true
	_target_depth = depth
	_max_time_ms = max_time_ms
	_multipv_count = multipv

	if _client == null:
		_is_engine_ready = false
		_client = UCIClient.new()
		_client.engine_ready.connect(_on_engine_ready)
		_client.evaluation_updated.connect(_on_eval_updated)
		_client.best_move_received.connect(_on_best_move_received)
		_client.start()
		_client.send_command("setoption name Threads value %d" % clampi(threads, 1, 8))
		_client.send_command("setoption name Hash value %d" % clampi(hash_mb, 16, 512))
		_client.send_command("setoption name MultiPV value %d" % clampi(multipv, 1, 5))
	else:
		_client.send_command("setoption name Threads value %d" % clampi(threads, 1, 8))
		_client.send_command("setoption name Hash value %d" % clampi(hash_mb, 16, 512))
		_client.send_command("setoption name MultiPV value %d" % clampi(multipv, 1, 5))
		if _is_engine_ready:
			_step_next()

func stop_analysis() -> void:
	_is_running = false
	_current_req_id += 1
	if _client != null:
		_client.send_command("stop")
		_client.send_command("isready")

func dispose() -> void:
	_is_running = false
	if _client != null:
		_client.stop()
		_client = null

func _on_engine_ready() -> void:
	if not _is_engine_ready:
		_is_engine_ready = true
		if _is_running:
			_step_next()

func _on_eval_updated(eval_dict: Dictionary) -> void:
	if not _is_running:
		return
	var mpv = eval_dict.get("multipv", 1)
	_multipv_data[mpv] = eval_dict.duplicate()

func _on_best_move_received(best_move_uci: String) -> void:
	if not _is_running:
		return
	_record_current_and_continue(best_move_uci)

func _record_current_and_continue(best_move_uci: String) -> void:
	if _current_idx >= _queue.size():
		return

	var item = _queue[_current_idx]
	var fen = item.get("fen", "")
	var turn = item.get("turn", 0)

	var line1 = _multipv_data.get(1, {})
	var line2 = _multipv_data.get(2, {})
	var line3 = _multipv_data.get(3, {})

	var eval_score_cp = line1.get("score_cp", 0)
	var is_mate = line1.get("is_mate", false)
	var mate_in = line1.get("mate_in", 0)
	var pv = line1.get("pv", [])
	var actual_best = best_move_uci if not best_move_uci.is_empty() else line1.get("best_move", "")

	# Jika posisi terminal yang sudah ditentukan sebelumnya (checkmate / stalemate)
	if item.get("is_terminal", false):
		eval_score_cp = item.get("terminal_eval", 0)
		is_mate = abs(eval_score_cp) >= 90000
		mate_in = 0
		actual_best = ""
		pv = []

	var eval_dict = {
		"fen": fen,
		"ply": int(item.get("ply", -1)),
		"score_cp": eval_score_cp,
		"is_mate": is_mate,
		"mate_in": mate_in,
		"best_move": actual_best,
		"pv": pv,
		"second_best_score_cp": line2.get("score_cp", eval_score_cp),
		"second_best_move": line2.get("best_move", ""),
		"multipv_lines": _multipv_data.duplicate()
	}

	_results.append(eval_dict)
	position_evaluated.emit(fen, eval_dict)
	progress_updated.emit(_current_idx + 1, _queue.size())

	_current_idx += 1
	if _current_idx < _queue.size():
		_step_next()
	else:
		_is_running = false
		session_completed.emit(_results)

func _step_next() -> void:
	if not _is_running or _client == null or _current_idx >= _queue.size():
		return

	_multipv_data.clear()
	var item = _queue[_current_idx]
	var fen = item.get("fen", "")

	# Cek apakah posisi terminal langsung tanpa perlu komputasi engine
	if item.get("is_terminal", false):
		_record_current_and_continue("")
		return

	var turn = item.get("turn", 0)
	_current_req_id += 1
	var sid = _client.start_new_search(turn)

	_client.send_command("position fen %s" % fen)
	if _max_time_ms > 0:
		_client.send_command("go depth %d movetime %d" % [_target_depth, _max_time_ms])
	else:
		_client.send_command("go depth %d" % _target_depth)
