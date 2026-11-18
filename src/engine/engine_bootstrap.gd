class_name EngineBootstrap
extends Node

signal download_started
signal download_progress(downloaded_bytes: int, total_bytes: int, percent: float, status_text: String)
signal download_completed(success: bool, message: String)

const STOCKFISH_REL_PATH := "res://engine/stockfish.exe"
const MAIA_EXE_REL_PATH := "res://engine/maia3.exe"
const MAIA_MODEL_REL_PATH := "res://engine/maia3-5m.pt"
const MIN_STOCKFISH_BYTES := 1000000
const MIN_BINARY_BYTES := 4096

const STOCKFISH_URLS: Array[String] = [
	"https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64-avx2.zip",
	"https://github.com/official-stockfish/Stockfish/releases/download/sf_18/stockfish-windows-x86-64-sse41-popcnt.zip",
]

var _http: HTTPRequest = null
var _is_downloading: bool = false
var _url_index: int = 0
var _temp_zip_path: String = ""

static func get_stockfish_path() -> String:
	return ProjectSettings.globalize_path(STOCKFISH_REL_PATH)

static func is_valid_binary(path: String, min_bytes: int = MIN_BINARY_BYTES) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var length := f.get_length()
	f.close()
	return length >= min_bytes

static func is_stockfish_ready() -> bool:
	return is_valid_binary(get_stockfish_path(), MIN_STOCKFISH_BYTES)

static func is_maia_ready() -> bool:
	var exe_path := ProjectSettings.globalize_path(MAIA_EXE_REL_PATH)
	var model_path := ProjectSettings.globalize_path(MAIA_MODEL_REL_PATH)
	return is_valid_binary(exe_path, MIN_BINARY_BYTES) and is_valid_binary(model_path, MIN_STOCKFISH_BYTES)

func is_downloading() -> bool:
	return _is_downloading

func start_stockfish_download() -> void:
	if _is_downloading:
		return
	if is_stockfish_ready():
		download_completed.emit(true, "Stockfish 18 is already installed.")
		return

	_is_downloading = true
	_url_index = 0
	_temp_zip_path = ProjectSettings.globalize_path("user://stockfish_setup_temp.zip")
	download_started.emit()
	_begin_http_download()

func _begin_http_download() -> void:
	if _url_index >= STOCKFISH_URLS.size():
		_finish_with_error("Failed to download Stockfish 18. Check your internet connection or run setup_engines.ps1.")
		return

	if _http != null:
		_http.queue_free()
		_http = null

	if FileAccess.file_exists(_temp_zip_path):
		DirAccess.remove_absolute(_temp_zip_path)

	_http = HTTPRequest.new()
	_http.use_threads = true
	_http.download_file = _temp_zip_path
	_http.timeout = 120.0
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)

	var url := STOCKFISH_URLS[_url_index]
	download_progress.emit(0, 0, 0.0, "Downloading Stockfish 18...")
	var err := _http.request(url)
	if err != OK:
		_url_index += 1
		_begin_http_download()

func _process(_delta: float) -> void:
	if not _is_downloading or _http == null:
		return
	var downloaded := _http.get_downloaded_bytes()
	var total := _http.get_body_size()
	if total > 0:
		var pct := clampf((float(downloaded) / float(total)) * 90.0, 0.0, 90.0)
		var mb_done := float(downloaded) / 1048576.0
		var mb_total := float(total) / 1048576.0
		download_progress.emit(downloaded, total, pct, "Downloading Stockfish 18 (%.1f / %.1f MB)..." % [mb_done, mb_total])
	elif downloaded > 0:
		var mb_done := float(downloaded) / 1048576.0
		download_progress.emit(downloaded, 0, 15.0, "Downloading Stockfish 18 (%.1f MB)..." % mb_done)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_url_index += 1
		_begin_http_download()
		return

	download_progress.emit(1, 1, 92.0, "Extracting Stockfish 18...")
	var extract_ok := _extract_stockfish_from_zip(_temp_zip_path, get_stockfish_path())
	if FileAccess.file_exists(_temp_zip_path):
		DirAccess.remove_absolute(_temp_zip_path)

	if extract_ok and is_stockfish_ready():
		_is_downloading = false
		_cleanup_http()
		download_progress.emit(1, 1, 100.0, "Stockfish 18 ready.")
		download_completed.emit(true, "Stockfish 18 installed successfully.")
	else:
		_url_index += 1
		_begin_http_download()

static func _extract_stockfish_from_zip(zip_path: String, dest_exe_path: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false

	var exe_entry := ""
	for file_name in reader.get_files():
		if file_name.to_lower().ends_with(".exe"):
			exe_entry = file_name
			break

	if exe_entry.is_empty():
		reader.close()
		return false

	var data := reader.read_file(exe_entry)
	reader.close()
	if data.size() < MIN_STOCKFISH_BYTES:
		return false

	var dest_dir := dest_exe_path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dest_dir)

	var out := FileAccess.open(dest_exe_path, FileAccess.WRITE)
	if out == null:
		return false
	out.store_buffer(data)
	out.close()
	return true

func _finish_with_error(msg: String) -> void:
	_is_downloading = false
	_cleanup_http()
	if not _temp_zip_path.is_empty() and FileAccess.file_exists(_temp_zip_path):
		DirAccess.remove_absolute(_temp_zip_path)
	download_completed.emit(false, msg)

func _cleanup_http() -> void:
	if _http != null:
		_http.queue_free()
		_http = null
