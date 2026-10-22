class_name EngineService
extends Node

signal engine_ready
signal eval_updated(score_cp: int, is_mate: bool, mate_in: int, depth: int)
signal arrows_updated(arrows: Array[Dictionary])
signal ai_move_ready(move_uci: String)
signal analysis_progress_updated(current_depth: int, target_depth: int, is_final: bool)

var client: UCIClient = null
var maia_client: UCIClient = null
var is_maia_ready: bool = false
var current_fen: String = ""

## Elo di mana bot berhenti meniru manusia dan memakai Stockfish penuh.
const SUPERNUMAN_ELO := 2800
## Rentang pengkondisian Elo Maia-3 yang dipakai proyek ini. Label Elo yang
## dilihat pemain dikirim apa adanya ke model (kalibrasi 1:1).
const MAIA_ELO_MIN := 200
const MAIA_ELO_MAX := 2799
## Sampel setia dari distribusi policy manusia. Menggeser temperature atau TopP
## menjauhkan sebaran langkah dari data manusia, jadi keduanya dikunci di 1.0.
const MAIA_TEMPERATURE := 1.0
const MAIA_TOP_P := 1.0

var _history_start_fen: String = ""
var _history_moves: PackedStringArray = PackedStringArray()
var multipv_lines: Dictionary = {} # multipv index (1..3) -> eval_dict
var is_waiting_for_ai: bool = false
var is_analyzing: bool = false
var is_flushing_for_analysis: bool = false
var pending_analysis_fen: String = ""
var pending_analysis_depth: int = 16
var current_analysis_depth: int = 0
var current_analysis_multipv: int = 1
var target_analysis_depth: int = 16
var _last_arrow_emit: int = 0

func _ready() -> void:
	client = UCIClient.new()
	client.engine_ready.connect(_on_engine_ready)
	client.evaluation_updated.connect(_on_evaluation_updated)
	client.best_move_received.connect(_on_best_move_received)
	client.start()
	_init_maia_engine()

func _init_maia_engine() -> void:
	var maia_exe = ProjectSettings.globalize_path("res://engine/maia3.exe")
	if FileAccess.file_exists(maia_exe):
		maia_client = UCIClient.new()
		maia_client.engine_ready.connect(func(): is_maia_ready = true)
		maia_client.best_move_received.connect(_on_maia_best_move_received)
		maia_client.start("res://engine/maia3.exe")

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if client != null:
			client.stop()
		if maia_client != null:
			maia_client.stop()

func _exit_tree() -> void:
	if client != null:
		client.stop()
	if maia_client != null:
		maia_client.stop()

func _on_engine_ready() -> void:
	if is_flushing_for_ai:
		_start_flushed_ai_search()
		return
	if is_flushing_for_analysis:
		is_flushing_for_analysis = false
		_start_analysis_search(pending_analysis_fen, pending_analysis_depth)
		return
	client.send_command("setoption name MultiPV value 3")
	engine_ready.emit()

func configure_elo(elo: int) -> void:
	elo = clampi(elo, 200, 3000)
	if elo >= SUPERNUMAN_ELO:
		# Paling susah: Stockfish 18 unconstrained full power (Superhuman >3500 Elo)
		client.send_command("setoption name UCI_LimitStrength value false")
		client.send_command("setoption name Skill Level value 20")
	elif elo >= 1320:
		# 1320 s/d 2799: Kalibrasi resmi Stockfish UCI_Elo
		client.send_command("setoption name UCI_LimitStrength value true")
		client.send_command("setoption name UCI_Elo value %d" % elo)
		client.send_command("setoption name Skill Level value 20")
	else:
		# Jalur cadangan (Maia-3 tidak tersedia). 1320 adalah lantai resmi
		# kalibrasi Stockfish; di bawah itu Stockfish tidak punya skala yang
		# jujur, dan menyuntik blunder buatan justru menghasilkan langkah
		# "alien" yang tidak pernah dimainkan manusia. Kekuatan rendah yang
		# benar-benar manusiawi hanya datang dari policy Maia-3.
		client.send_command("setoption name UCI_LimitStrength value true")
		client.send_command("setoption name UCI_Elo value 1320")
		client.send_command("setoption name Skill Level value 0")

var pending_ai_fen: String = ""
var pending_ai_elo: int = 1200
var pending_ai_movetime: int = 800
var is_flushing_for_ai: bool = false
var ai_request_id: int = 0
var ai_request_start_time: int = 0

func _is_using_maia() -> bool:
	if maia_client == null or not is_maia_ready:
		return false
	var tree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("GameSettings"):
		var gs = tree.root.get_node("GameSettings")
		var engine_type = str(gs.get("ai_engine_type"))
		if engine_type == "stockfish":
			return false
	return true

func _request_stockfish_move(fen: String, elo: int) -> void:
	var parts = fen.strip_edges().split(" ")
	var turn = ChessTypes.PieceColor.BLACK if (parts.size() > 1 and parts[1] == "b") else ChessTypes.PieceColor.WHITE

	configure_elo(elo)
	client.start_new_search(turn)

	var movetime = 800
	if elo < 500:
		movetime = 150
	elif elo < 1000:
		movetime = 300
	elif elo < 1600:
		movetime = 500
	elif elo < 2400:
		movetime = 800
	elif elo < 2800:
		movetime = 1200
	else:
		movetime = 1500
	pending_ai_movetime = movetime

	# Stop analisa sebelumnya dan tunggu readyok agar tidak menangkap sisa bestmove lama
	is_waiting_for_ai = false
	is_flushing_for_ai = true
	client.send_command("stop")
	client.send_command("isready")

func request_ai_move(fen: String, elo: int) -> void:
	# Batalkan analisa latar belakang jika sedang berjalan
	is_analyzing = false
	is_flushing_for_analysis = false
	analysis_progress_updated.emit(0, target_analysis_depth, false)

	ai_request_id += 1
	ai_request_start_time = Time.get_ticks_msec()
	pending_ai_fen = fen
	pending_ai_elo = elo

	var parts = fen.strip_edges().split(" ")
	var turn = ChessTypes.PieceColor.BLACK if (parts.size() > 1 and parts[1] == "b") else ChessTypes.PieceColor.WHITE

	# Seluruh rentang di bawah Superhuman dilayani policy manusia Maia-3.
	# Tidak ada lagi penyuntikan blunder buatan: kelemahan datang dari model
	# yang memang dilatih memprediksi langkah manusia pada Elo tersebut.
	if _is_using_maia() and elo < SUPERNUMAN_ELO:
		is_waiting_for_ai = true
		maia_client.start_new_search(turn)
		configure_maia_elo(elo)
		maia_client.send_command(build_position_command(fen))
		maia_client.send_command("go")
		return

	_request_stockfish_move(fen, elo)

func configure_maia_elo(elo: int) -> void:
	if maia_client == null:
		return
	# Kalibrasi 1:1: label Elo yang dilihat pemain sama persis dengan
	# pengkondisian model, dan distribusinya tidak diwarping temperature/TopP.
	var self_elo = clampi(elo, MAIA_ELO_MIN, MAIA_ELO_MAX)
	maia_client.send_command("setoption name SelfElo value %d" % self_elo)
	maia_client.send_command("setoption name OppoElo value %d" % self_elo)
	maia_client.send_command("setoption name Temperature value %.2f" % MAIA_TEMPERATURE)
	maia_client.send_command("setoption name TopP value %.2f" % MAIA_TOP_P)

func set_move_history(start_fen: String, moves_uci: PackedStringArray) -> void:
	_history_start_fen = start_fen
	_history_moves = moves_uci

## Bangun perintah `position` lengkap dengan riwayat langkah.
##
## Maia-3 dibangun sebagai Chessformer yang menerima hingga `--history` posisi
## sebelumnya. Bila hanya FEN tunggal yang dikirim, engine mengisi seluruh slot
## riwayat dengan salinan posisi saat ini sehingga konteks temporal (rencana,
## pengulangan posisi, bidak yang baru bergerak) hilang total. Karena itu
## launcher selalu memakai `--use-uci-history` dan kita mengirim
## `position fen <awal> moves <semua langkah>`.
##
## Bila riwayat belum tersedia atau tidak sinkron dengan papan (mis. mode Retry
## di Game Review yang memundurkan papan tanpa mengubah riwayat), cukup kirim
## FEN tunggal supaya langkah yang dihasilkan tetap legal.
func build_position_command(fen: String) -> String:
	if _history_start_fen.is_empty() or _history_moves.is_empty():
		return "position fen %s" % fen
	return "position fen %s moves %s" % [_history_start_fen, " ".join(_history_moves)]

func _start_flushed_ai_search() -> void:
	is_flushing_for_ai = false
	is_waiting_for_ai = true
	var parts = pending_ai_fen.strip_edges().split(" ")
	var turn = ChessTypes.PieceColor.BLACK if (parts.size() > 1 and parts[1] == "b") else ChessTypes.PieceColor.WHITE
	client.start_new_search(turn)
	client.send_command("setoption name MultiPV value 1")
	client.send_command("position fen %s" % pending_ai_fen)
	client.send_command("go movetime %d" % pending_ai_movetime)

func _get_autoload_depth() -> int:
	var tree = Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null and tree.root.has_node("GameSettings"):
		var gs = tree.root.get_node("GameSettings")
		return int(gs.get("engine_depth"))
	return 16

func analyze_position(fen: String, depth: int = -1) -> void:
	if is_waiting_for_ai or is_flushing_for_ai:
		return

	var target_d = depth if depth > 0 else _get_autoload_depth()
	current_fen = fen
	pending_analysis_fen = fen
	pending_analysis_depth = target_d

	# Jika engine sedang aktif menganalisa atau sedang flushing, stop dulu secara sinkron dengan isready
	if is_analyzing or is_flushing_for_analysis:
		is_analyzing = false
		is_flushing_for_analysis = true
		client.send_command("stop")
		client.send_command("isready")
		return

	_start_analysis_search(fen, target_d)

func _start_analysis_search(fen: String, depth: int) -> void:
	multipv_lines.clear()
	current_analysis_depth = 0
	current_analysis_multipv = 1
	target_analysis_depth = depth
	is_analyzing = true

	var turn = ChessTypes.PieceColor.WHITE
	var parts = fen.strip_edges().split(" ")
	if parts.size() > 1 and parts[1] == "b":
		turn = ChessTypes.PieceColor.BLACK

	client.start_new_search(turn)
	analysis_progress_updated.emit(0, target_analysis_depth, false)

	client.send_command("setoption name UCI_LimitStrength value false")
	client.send_command("setoption name MultiPV value 3")
	client.send_command("position fen %s" % fen)
	client.send_command("go depth %d" % target_analysis_depth)

func get_analysis_progress_ratio() -> float:
	if not is_analyzing:
		return 1.0 if (current_analysis_depth >= target_analysis_depth and target_analysis_depth > 0) else 0.0
	if target_analysis_depth <= 0:
		return 0.0
	# Hitung progres berbobot berdasarkan kedalaman dan multipv (1..3)
	var base_completed_depth = maxf(0.0, float(current_analysis_depth - 1))
	var mpv_fraction = clampf(float(current_analysis_multipv) / 3.0, 0.0, 1.0)
	var effective_depth = base_completed_depth + mpv_fraction
	var raw_ratio = effective_depth / float(target_analysis_depth)
	# Batasi maksimal 0.96 sebelum bestmove tiba
	return clampf(raw_ratio, 0.0, 0.96)

func reanalyze() -> void:
	if not current_fen.is_empty() and not is_waiting_for_ai:
		analyze_position(current_fen, _get_autoload_depth())

func stop_analysis() -> void:
	ai_request_id += 1
	is_waiting_for_ai = false
	is_flushing_for_ai = false
	is_flushing_for_analysis = false
	if is_analyzing:
		is_analyzing = false
		analysis_progress_updated.emit(0, target_analysis_depth, false)
	if client != null:
		client.send_command("stop")
	if maia_client != null:
		maia_client.send_command("stop")

func _build_engine_arrows() -> Array[Dictionary]:
	var arrows: Array[Dictionary] = []
	for rank in [1, 2, 3]:
		if multipv_lines.has(rank):
			var data = multipv_lines[rank]
			var best_mv = data.get("best_move", "")
			if best_mv.length() >= 4:
				var from_sq = best_mv.substr(0, 2)
				var to_sq = best_mv.substr(2, 2)
				var arrow_type = "best" if rank == 1 else ("good" if rank == 2 else "alternative")
				arrows.append({
					"from": from_sq,
					"to": to_sq,
					"type": arrow_type,
					"rank": rank
				})
	return arrows

func _on_evaluation_updated(eval_dict: Dictionary) -> void:
	# Tolak update evaluasi jika engine tidak dalam status analisa aktif
	if not is_analyzing or is_waiting_for_ai or is_flushing_for_ai or is_flushing_for_analysis:
		return

	var mpv = eval_dict.get("multipv", 1)
	multipv_lines[mpv] = eval_dict

	var d = int(eval_dict.get("depth", 0))
	var progress_advanced = false
	if d > current_analysis_depth:
		current_analysis_depth = d
		current_analysis_multipv = mpv
		progress_advanced = true
	elif d == current_analysis_depth and mpv > current_analysis_multipv:
		current_analysis_multipv = mpv
		progress_advanced = true

	if progress_advanced:
		# Selama search belum mengirimkan bestmove, analisis BELUM final.
		analysis_progress_updated.emit(current_analysis_depth, target_analysis_depth, false)

	if mpv == 1:
		eval_updated.emit(
			eval_dict.get("score_cp", 0),
			eval_dict.get("is_mate", false),
			eval_dict.get("mate_in", 0),
			d
		)

	# Buat daftar panah engine (Best, Good, Alternative)
	var arrows = _build_engine_arrows()

	# Throttle arrow emission to every 200ms to reduce UI load during thinking
	var now = Time.get_ticks_msec()
	if now - _last_arrow_emit >= 200:
		_last_arrow_emit = now
		arrows_updated.emit(arrows)

## Tunda langkah AI sesuai jam berpikir manusia, lalu lepaskan ke papan.
func _finish_ai_move(chosen_move: String) -> void:
	var req_id = ai_request_id
	var target_delay = calculate_human_delay(pending_ai_fen, pending_ai_elo, chosen_move)
	var elapsed = float(Time.get_ticks_msec() - ai_request_start_time) / 1000.0
	var remaining = maxf(0.0, target_delay - elapsed)

	if remaining > 0.02:
		var tree = get_tree()
		if tree != null:
			await tree.create_timer(remaining, false).timeout

	if is_waiting_for_ai and req_id == ai_request_id:
		is_waiting_for_ai = false
		ai_move_ready.emit(chosen_move)

func _on_maia_best_move_received(move_uci: String) -> void:
	if not is_waiting_for_ai:
		return

	if move_uci.is_empty():
		# Maia tidak sanggup melangkah (protokol gagal, bukan posisi normal):
		# jatuhkan ke Stockfish supaya permainan tidak menggantung selamanya.
		is_waiting_for_ai = false
		_request_stockfish_move(pending_ai_fen, pending_ai_elo)
		return

	# Kebijakan `Elo` Maia-3 sudah memuat seluruh karakter kekuatan bot, jadi
	# langkah diteruskan apa adanya tanpa campur tangan heuristik.
	await _finish_ai_move(move_uci)

func _on_best_move_received(move_uci: String) -> void:
	if is_waiting_for_ai:
		if move_uci.is_empty():
			is_waiting_for_ai = false
			return
		await _finish_ai_move(move_uci)
	elif is_analyzing:
		is_analyzing = false
		current_analysis_depth = target_analysis_depth
		current_analysis_multipv = 3

		if not move_uci.is_empty() and multipv_lines.has(1):
			multipv_lines[1]["best_move"] = move_uci

		# 1. Emit progress final 100% tepat saat search selesai secara resmi
		analysis_progress_updated.emit(target_analysis_depth, target_analysis_depth, true)

		# 2. Emit panah final yang definitif (bypass throttle) dan kunci posisi panah
		var final_arrows = _build_engine_arrows()
		_last_arrow_emit = Time.get_ticks_msec()
		arrows_updated.emit(final_arrows)

static func calculate_human_delay(fen: String, elo: int, chosen_move_uci: String = "", delay_mode: String = "", custom_val: float = -1.0) -> float:
	var mode = delay_mode
	if mode.is_empty():
		var tree = Engine.get_main_loop() as SceneTree
		if tree != null and tree.root != null and tree.root.has_node("GameSettings"):
			var gs = tree.root.get_node("GameSettings")
			mode = str(gs.get("ai_delay_mode"))
			if custom_val < 0.0:
				custom_val = float(gs.get("ai_custom_delay"))
		else:
			mode = "natural"
			if custom_val < 0.0:
				custom_val = 1.2

	if mode == "instant":
		return 0.0

	if mode == "fast":
		return randf_range(0.35, 0.65)

	if mode == "relaxed":
		return randf_range(2.2, 3.8)

	if mode == "custom":
		if custom_val <= 0.05:
			return 0.0
		return clampf(custom_val * randf_range(0.92, 1.08), 0.0, 5.0)

	# Mode "natural" (Feel Alami Manusiawi):
	if fen.is_empty():
		return randf_range(0.9, 1.6)

	var state = ChessBoardState.new(fen)
	var legal_moves = ChessMoveGenerator.get_legal_moves(state)
	var legal_count = legal_moves.size()

	# 1. Jika hanya 1 langkah legal (forced move), respon cepat
	if legal_count == 1:
		return randf_range(0.35, 0.65)

	# 2. Skak (In check)
	var in_check = ChessMoveGenerator.is_in_check(state, state.turn)

	# 3. Hitung jumlah bidak (Material density)
	var piece_count = 0
	for sq in state.squares:
		if sq != null:
			piece_count += 1

	# 4. Ambil nomor langkah (fullmove number)
	var parts = fen.strip_edges().split(" ")
	var fullmove_num = 1
	if parts.size() >= 6:
		fullmove_num = int(parts[5])

	var base_delay = 1.2

	if in_check:
		# Kena skak (berpikir hati-hati & waspada)
		base_delay = randf_range(1.4, 2.4)
	elif fullmove_num <= 4:
		# Pembukaan / book opening (cepat, percaya diri)
		base_delay = randf_range(0.5, 0.95)
	elif piece_count <= 10:
		# Endgame (perhitungan fokus)
		base_delay = randf_range(0.9, 1.8)
	elif legal_count > 25:
		# Posisi kompleks banyak cabang langkah
		base_delay = randf_range(1.3, 2.5)
	else:
		# Posisi normal
		base_delay = randf_range(0.85, 1.7)

	# Pengaruh ELO:
	if elo < 800:
		if randf() < 0.4:
			base_delay *= 0.65 # Main cepat impulsif
	elif elo >= 2200:
		base_delay = maxf(base_delay, 1.1)

	base_delay += randf_range(-0.15, 0.2)
	return clampf(base_delay, 0.3, 3.5)

