class_name UCIClient
extends RefCounted

signal line_received(line: String)
signal engine_ready
signal evaluation_updated(eval_dict: Dictionary)
signal best_move_received(move_uci: String)

var pid: int = -1
var stdio: FileAccess = null
var is_running: bool = false
var is_ready: bool = false
var thread: Thread = null
var mutex: Mutex = null

var current_search_id: int = 0
var active_analyzing_turn: int = ChessTypes.PieceColor.WHITE

func _init() -> void:
	mutex = Mutex.new()

func start_new_search(turn: int) -> int:
	mutex.lock()
	current_search_id += 1
	active_analyzing_turn = turn
	var sid = current_search_id
	mutex.unlock()
	return sid

func start(custom_exe_path: String = "") -> bool:
	var target_rel = custom_exe_path if not custom_exe_path.is_empty() else "res://engine/stockfish.exe"
	var exe_path = ProjectSettings.globalize_path(target_rel)
	if not FileAccess.file_exists(exe_path):
		printerr("Engine binary not found at: ", exe_path)
		return false
	var check_file := FileAccess.open(exe_path, FileAccess.READ)
	if check_file == null or check_file.get_length() < 4096:
		if check_file != null:
			check_file.close()
		printerr("Engine binary is empty or invalid at: ", exe_path)
		return false
	check_file.close()

	var pipe = OS.execute_with_pipe(exe_path, PackedStringArray([]))
	if not pipe.has("stdio"):
		printerr("Failed to execute engine with pipe: ", exe_path)
		return false

	stdio = pipe["stdio"]
	pid = pipe.get("pid", -1)
	is_running = true

	thread = Thread.new()
	thread.start(_read_stdout_loop)

	send_command("uci")
	send_command("isready")
	return true

func stop() -> void:
	if not is_running:
		return
	is_running = false

	mutex.lock()
	if stdio != null:
		stdio.store_line("quit")
		stdio.flush()
	mutex.unlock()

	var wait_cycles = 0
	while pid > 0 and OS.is_process_running(pid) and wait_cycles < 5:
		OS.delay_msec(10)
		wait_cycles += 1

	if pid > 0 and OS.is_process_running(pid):
		OS.kill(pid)
		pid = -1

	if thread != null and thread.is_started():
		thread.wait_to_finish()
		thread = null

	mutex.lock()
	if stdio != null:
		stdio.close()
		stdio = null
	mutex.unlock()

func send_command(cmd: String) -> void:
	if not is_running or stdio == null:
		return
	mutex.lock()
	if stdio != null:
		stdio.store_line(cmd)
		stdio.flush()
	mutex.unlock()

func _read_stdout_loop() -> void:
	while is_running:
		if stdio == null:
			break
		var line = stdio.get_line()
		if not is_running:
			break
		if line.is_empty():
			if stdio == null or stdio.eof_reached():
				break
			OS.delay_msec(2)
			continue

		var is_info_pv = line.begins_with("info ") and line.contains(" score ") and line.contains(" pv ")
		var is_bestmove = line.begins_with("bestmove")
		var is_ready_signal = (line == "readyok" or line == "uciok")
		var has_listener = line_received.get_connections().size() > 0

		if not (is_info_pv or is_bestmove or is_ready_signal or has_listener):
			continue

		mutex.lock()
		var sid = current_search_id
		var turn = active_analyzing_turn
		mutex.unlock()

		_process_line.call_deferred(line, sid, turn)

func _process_line(line: String, sid: int, turn: int) -> void:
	if line_received.get_connections().size() > 0:
		line_received.emit(line)

	if line == "readyok":
		is_ready = true
		engine_ready.emit()
	elif line == "uciok":
		is_ready = true
	elif line.begins_with("bestmove"):
		if sid == current_search_id:
			var parts = line.split(" ", false)
			if parts.size() > 1 and parts[1] != "(none)":
				best_move_received.emit(parts[1])
			else:
				best_move_received.emit("")
	elif line.begins_with("info ") and line.contains(" score ") and line.contains(" pv "):
		if sid == current_search_id:
			_parse_info_line(line, turn)

func _parse_info_line(line: String, turn: int) -> void:
	var pv_idx = line.find(" pv ")
	var meta_str = line
	var pv: Array[String] = []

	if pv_idx != -1:
		meta_str = line.substr(0, pv_idx)
		var pv_sub = line.substr(pv_idx + 4).strip_edges()
		if not pv_sub.is_empty():
			for mv in pv_sub.split(" ", false):
				pv.append(mv)

	var depth = 0
	var multipv = 1
	var score_cp = 0
	var is_mate = false
	var mate_in = 0
	var nodes = 0
	var nps = 0
	var time_ms = 0
	var hashfull = 0

	var parts = meta_str.split(" ", false)
	var count = parts.size()
	var i = 0
	while i < count:
		var token = parts[i]
		if token == "depth" and i + 1 < count:
			depth = parts[i + 1].to_int()
			i += 2
		elif token == "multipv" and i + 1 < count:
			multipv = parts[i + 1].to_int()
			i += 2
		elif token == "cp" and i + 1 < count:
			score_cp = parts[i + 1].to_int()
			is_mate = false
			i += 2
		elif token == "mate" and i + 1 < count:
			mate_in = parts[i + 1].to_int()
			is_mate = true
			score_cp = 99999 if mate_in > 0 else -99999
			i += 2
		elif token == "nodes" and i + 1 < count:
			nodes = parts[i + 1].to_int()
			i += 2
		elif token == "nps" and i + 1 < count:
			nps = parts[i + 1].to_int()
			i += 2
		elif token == "time" and i + 1 < count:
			time_ms = parts[i + 1].to_int()
			i += 2
		elif token == "hashfull" and i + 1 < count:
			hashfull = parts[i + 1].to_int()
			i += 2
		else:
			i += 1

	var normalized_score = -score_cp if turn == ChessTypes.PieceColor.BLACK else score_cp
	var normalized_mate = -mate_in if turn == ChessTypes.PieceColor.BLACK else mate_in

	var eval_dict = {
		"depth": depth,
		"multipv": multipv,
		"score_cp": normalized_score,
		"is_mate": is_mate,
		"mate_in": normalized_mate,
		"best_move": pv[0] if not pv.is_empty() else "",
		"pv": pv,
		"nodes": nodes,
		"nps": nps,
		"time_ms": time_ms,
		"hashfull": hashfull
	}
	evaluation_updated.emit(eval_dict)
