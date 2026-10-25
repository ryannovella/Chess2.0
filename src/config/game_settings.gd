extends Node

signal settings_changed
signal elo_changed(new_elo: int)
signal theme_changed(theme_name: String)
signal piece_set_changed(set_name: String)
signal arrows_toggled
signal engine_depth_changed(new_depth: int)
signal ai_delay_changed(new_mode: String, new_custom_delay: float)
signal ai_engine_type_changed(new_type: String)

static func get_settings_path() -> String:
	if OS.has_feature("editor") or not OS.has_feature("standalone"):
		return ProjectSettings.globalize_path("res://settings.json")
	return OS.get_executable_path().get_base_dir().path_join("settings.json")

var ai_engine_type: String = "maia3" # "maia3" | "stockfish"
var ai_elo: int = 1200 # Rentang: 200 s/d 3000
var engine_depth: int = 16 # Rentang: 8 s/d 24 (Kedalaman analisis panah best move)
var ai_delay_mode: String = "natural" # "natural" | "fast" | "relaxed" | "instant" | "custom"
var ai_custom_delay: float = 1.2 # Rentang: 0.0 s/d 5.0 detik
var player_color: int = ChessTypes.PieceColor.WHITE
var chosen_side: String = "white" # "white" | "black" | "random"
var selected_repertoire_id: String = "fried_liver_attack"
var piece_set: String = "neo"
var board_theme: String = "emerald"
var show_white_engine_arrows: bool = true
var show_white_threat_arrows: bool = true
var show_black_engine_arrows: bool = true
var show_black_threat_arrows: bool = true

# Backward-compatible accessors
var show_engine_arrows: bool:
	get: return show_white_engine_arrows or show_black_engine_arrows
	set(val):
		show_white_engine_arrows = val
		show_black_engine_arrows = val

var show_threat_arrows: bool:
	get: return show_white_threat_arrows or show_black_threat_arrows
	set(val):
		show_white_threat_arrows = val
		show_black_threat_arrows = val

var sound_enabled: bool = true
var sound_volume: float = 0.8
var is_flipped: bool = false
var current_game_mode: String = "vs_ai"
var open_painter_on_launch: bool = false

# Pola Pembelajaran Check & Checkmate Highlights
var show_forbidden_squares: bool = true
var show_defender_highlights: bool = true
var show_savior_badges: bool:
	get: return show_defender_highlights
	set(val): set_show_defender_highlights(val)

# Konfigurasi Game Review Engine (Stockfish)
var review_strength: String = "fast" # "fast" | "standard" | "deep" | "max"
var review_depth: int = 14 # 10 s/d 26
var review_max_time_ms: int = 800 # 300 s/d 10000 ms
var review_multipv: int = 2 # 1 s/d 5 (MultiPV 2 memungkinkan deteksi Brilliant & Only-Move)
var review_threads: int = 1 # 1 s/d 8
var review_hash_mb: int = 64 # 16 s/d 512 MB

func _ready() -> void:
	load_settings()

func set_ai_engine_type(new_type: String) -> void:
	if new_type != "maia3" and new_type != "stockfish":
		new_type = "maia3"
	if ai_engine_type != new_type:
		ai_engine_type = new_type
		ai_engine_type_changed.emit(ai_engine_type)
		settings_changed.emit()
		save_settings()

func set_elo(new_elo: int) -> void:
	new_elo = clampi(new_elo, 200, 3000)
	if ai_elo != new_elo:
		ai_elo = new_elo
		elo_changed.emit(ai_elo)
		save_settings()

func set_engine_depth(new_depth: int) -> void:
	new_depth = clampi(new_depth, 8, 24)
	if engine_depth != new_depth:
		engine_depth = new_depth
		engine_depth_changed.emit(engine_depth)
		save_settings()

func set_ai_delay_mode(mode: String) -> void:
	if ai_delay_mode != mode:
		ai_delay_mode = mode
		ai_delay_changed.emit(ai_delay_mode, ai_custom_delay)
		settings_changed.emit()
		save_settings()

func set_ai_custom_delay(val: float) -> void:
	val = clampf(val, 0.0, 5.0)
	if not is_equal_approx(ai_custom_delay, val):
		ai_custom_delay = val
		ai_delay_changed.emit(ai_delay_mode, ai_custom_delay)
		settings_changed.emit()
		save_settings()

func set_piece_set(new_set: String) -> void:
	if new_set.is_empty() or (new_set != "cburnett" and new_set != "staunty" and new_set != "horsey" and new_set != "neo"):
		return
	if piece_set != new_set:
		piece_set = new_set
		piece_set_changed.emit(piece_set)
		save_settings()

func set_board_theme(new_theme: String) -> void:
	if new_theme.is_empty() or not BoardThemes.has_theme(new_theme):
		return
	if board_theme != new_theme:
		board_theme = new_theme
		theme_changed.emit(board_theme)
		save_settings()

func set_show_forbidden_squares(val: bool) -> void:
	if show_forbidden_squares != val:
		show_forbidden_squares = val
		settings_changed.emit()
		save_settings()

func set_show_defender_highlights(val: bool) -> void:
	if show_defender_highlights != val:
		show_defender_highlights = val
		settings_changed.emit()
		save_settings()

func set_sound_enabled(val: bool) -> void:
	if sound_enabled != val:
		sound_enabled = val
		settings_changed.emit()
		save_settings()

func set_sound_volume(val: float) -> void:
	val = clampf(val, 0.0, 1.0)
	if not is_equal_approx(sound_volume, val):
		sound_volume = val
		settings_changed.emit()
		save_settings()

func set_review_strength(strength: String) -> void:
	match strength:
		"fast":
			review_strength = "fast"
			review_depth = 14
			review_max_time_ms = 800
			review_multipv = 2
		"standard":
			review_strength = "standard"
			review_depth = 18
			review_max_time_ms = 1500
			review_multipv = 3
		"deep":
			review_strength = "deep"
			review_depth = 22
			review_max_time_ms = 3000
			review_multipv = 3
		"max":
			review_strength = "max"
			review_depth = 26
			review_max_time_ms = 6000
			review_multipv = 4
		_:
			return
	settings_changed.emit()
	save_settings()

func set_review_depth(depth: int) -> void:
	depth = clampi(depth, 10, 26)
	if review_depth != depth:
		review_depth = depth
		settings_changed.emit()
		save_settings()

func set_review_max_time_ms(time_ms: int) -> void:
	time_ms = clampi(time_ms, 300, 10000)
	if review_max_time_ms != time_ms:
		review_max_time_ms = time_ms
		settings_changed.emit()
		save_settings()

func set_review_multipv(mpv: int) -> void:
	mpv = clampi(mpv, 1, 5)
	if review_multipv != mpv:
		review_multipv = mpv
		settings_changed.emit()
		save_settings()

func set_review_threads(threads: int) -> void:
	threads = clampi(threads, 1, 8)
	if review_threads != threads:
		review_threads = threads
		settings_changed.emit()
		save_settings()

func set_review_hash_mb(hash_mb: int) -> void:
	hash_mb = clampi(hash_mb, 16, 512)
	if review_hash_mb != hash_mb:
		review_hash_mb = hash_mb
		settings_changed.emit()
		save_settings()

func toggle_white_engine_arrows() -> void:
	show_white_engine_arrows = not show_white_engine_arrows
	arrows_toggled.emit()
	save_settings()

func toggle_white_threat_arrows() -> void:
	show_white_threat_arrows = not show_white_threat_arrows
	arrows_toggled.emit()
	save_settings()

func toggle_black_engine_arrows() -> void:
	show_black_engine_arrows = not show_black_engine_arrows
	arrows_toggled.emit()
	save_settings()

func toggle_black_threat_arrows() -> void:
	show_black_threat_arrows = not show_black_threat_arrows
	arrows_toggled.emit()
	save_settings()

func get_effective_player_color() -> int:
	if chosen_side == "black":
		return ChessTypes.PieceColor.BLACK
	elif chosen_side == "white":
		return ChessTypes.PieceColor.WHITE
	return player_color

func get_player_engine_arrows() -> bool:
	return show_white_engine_arrows if get_effective_player_color() == ChessTypes.PieceColor.WHITE else show_black_engine_arrows

func set_player_engine_arrows(val: bool) -> void:
	if get_effective_player_color() == ChessTypes.PieceColor.WHITE:
		show_white_engine_arrows = val
	else:
		show_black_engine_arrows = val
	arrows_toggled.emit()
	save_settings()

func get_opponent_engine_arrows() -> bool:
	return show_black_engine_arrows if get_effective_player_color() == ChessTypes.PieceColor.WHITE else show_white_engine_arrows

func set_opponent_engine_arrows(val: bool) -> void:
	if get_effective_player_color() == ChessTypes.PieceColor.WHITE:
		show_black_engine_arrows = val
	else:
		show_white_engine_arrows = val
	arrows_toggled.emit()
	save_settings()

func get_player_threat_arrows() -> bool:
	return show_white_threat_arrows if get_effective_player_color() == ChessTypes.PieceColor.WHITE else show_black_threat_arrows

func set_player_threat_arrows(val: bool) -> void:
	if get_effective_player_color() == ChessTypes.PieceColor.WHITE:
		show_white_threat_arrows = val
	else:
		show_black_threat_arrows = val
	arrows_toggled.emit()
	save_settings()

func get_opponent_threat_arrows() -> bool:
	return show_black_threat_arrows if get_effective_player_color() == ChessTypes.PieceColor.WHITE else show_white_threat_arrows

func set_opponent_threat_arrows(val: bool) -> void:
	if get_effective_player_color() == ChessTypes.PieceColor.WHITE:
		show_black_threat_arrows = val
	else:
		show_white_threat_arrows = val
	arrows_toggled.emit()
	save_settings()

func toggle_player_engine_arrows() -> void:
	set_player_engine_arrows(not get_player_engine_arrows())

func toggle_opponent_engine_arrows() -> void:
	set_opponent_engine_arrows(not get_opponent_engine_arrows())

func toggle_player_threat_arrows() -> void:
	set_player_threat_arrows(not get_player_threat_arrows())

func toggle_opponent_threat_arrows() -> void:
	set_opponent_threat_arrows(not get_opponent_threat_arrows())

func toggle_engine_arrows() -> void:
	var next_state = not (show_white_engine_arrows or show_black_engine_arrows)
	show_white_engine_arrows = next_state
	show_black_engine_arrows = next_state
	arrows_toggled.emit()
	save_settings()

func toggle_threat_arrows() -> void:
	var next_state = not (show_white_threat_arrows or show_black_threat_arrows)
	show_white_threat_arrows = next_state
	show_black_threat_arrows = next_state
	arrows_toggled.emit()
	save_settings()

func set_chosen_side(side: String) -> void:
	chosen_side = side
	if side == "white":
		player_color = ChessTypes.PieceColor.WHITE
		is_flipped = false
	elif side == "black":
		player_color = ChessTypes.PieceColor.BLACK
		is_flipped = true
	save_settings()

func resolve_player_side() -> int:
	# 1. Simpan preferensi panah role pengguna (Player vs Opponent) saat ini
	var p_eng = get_player_engine_arrows()
	var o_eng = get_opponent_engine_arrows()
	var p_thr = get_player_threat_arrows()
	var o_thr = get_opponent_threat_arrows()

	# 2. Tentukan sisi pemain (Putih, Hitam, atau Random)
	if chosen_side == "white":
		player_color = ChessTypes.PieceColor.WHITE
		is_flipped = false
	elif chosen_side == "black":
		player_color = ChessTypes.PieceColor.BLACK
		is_flipped = true
	else: # "random"
		var is_white = (randi() % 2 == 0)
		player_color = ChessTypes.PieceColor.WHITE if is_white else ChessTypes.PieceColor.BLACK
		is_flipped = not is_white

	# 3. Terapkan preferensi role pengguna ke warna yang terpilih (agar tidak terbalik saat random hitam)
	if player_color == ChessTypes.PieceColor.WHITE:
		show_white_engine_arrows = p_eng
		show_black_engine_arrows = o_eng
		show_white_threat_arrows = p_thr
		show_black_threat_arrows = o_thr
	else:
		show_black_engine_arrows = p_eng
		show_white_engine_arrows = o_eng
		show_black_threat_arrows = p_thr
		show_white_threat_arrows = o_thr

	arrows_toggled.emit()
	settings_changed.emit()
	save_settings()
	return player_color

func set_flipped(flipped: bool) -> void:
	if is_flipped != flipped:
		is_flipped = flipped
		settings_changed.emit()
		save_settings()

func save_settings() -> void:
	var data = {
		"ai_engine_type": ai_engine_type,
		"ai_elo": ai_elo,
		"engine_depth": engine_depth,
		"ai_delay_mode": ai_delay_mode,
		"ai_custom_delay": ai_custom_delay,
		"player_color": player_color,
		"chosen_side": chosen_side,
		"piece_set": piece_set,
		"board_theme": board_theme,
		"show_white_engine_arrows": show_white_engine_arrows,
		"show_white_threat_arrows": show_white_threat_arrows,
		"show_black_engine_arrows": show_black_engine_arrows,
		"show_black_threat_arrows": show_black_threat_arrows,
		"player_engine_arrows": get_player_engine_arrows(),
		"opponent_engine_arrows": get_opponent_engine_arrows(),
		"player_threat_arrows": get_player_threat_arrows(),
		"opponent_threat_arrows": get_opponent_threat_arrows(),
		"show_engine_arrows": show_white_engine_arrows,
		"show_threat_arrows": show_white_threat_arrows,
		"sound_enabled": sound_enabled,
		"sound_volume": sound_volume,
		"show_forbidden_squares": show_forbidden_squares,
		"show_defender_highlights": show_defender_highlights,
		"review_strength": review_strength,
		"review_depth": review_depth,
		"review_max_time_ms": review_max_time_ms,
		"review_multipv": review_multipv,
		"review_threads": review_threads,
		"review_hash_mb": review_hash_mb,
		"current_game_mode": current_game_mode,
		"is_flipped": is_flipped
	}
	var path = get_settings_path()
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.flush()

func load_settings() -> void:
	var path = get_settings_path()
	if not FileAccess.file_exists(path):
		if FileAccess.file_exists("user://settings.json"):
			var old_file = FileAccess.open("user://settings.json", FileAccess.READ)
			if old_file:
				var content = old_file.get_as_text()
				var new_file = FileAccess.open(path, FileAccess.WRITE)
				if new_file:
					new_file.store_string(content)
					new_file.flush()
		else:
			return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	if err == OK and json.data is Dictionary:
		var d = json.data
		ai_engine_type = str(d.get("ai_engine_type", "maia3"))
		ai_elo = clampi(int(d.get("ai_elo", 1200)), 200, 3000)
		engine_depth = clampi(int(d.get("engine_depth", 16)), 8, 24)
		ai_delay_mode = str(d.get("ai_delay_mode", "natural"))
		ai_custom_delay = clampf(float(d.get("ai_custom_delay", 1.2)), 0.0, 5.0)
		chosen_side = str(d.get("chosen_side", "white"))
		player_color = int(d.get("player_color", ChessTypes.PieceColor.WHITE))
		if chosen_side == "white":
			player_color = ChessTypes.PieceColor.WHITE
			is_flipped = false
		elif chosen_side == "black":
			player_color = ChessTypes.PieceColor.BLACK
			is_flipped = true
		else:
			is_flipped = bool(d.get("is_flipped", false))
		piece_set = str(d.get("piece_set", "neo"))
		board_theme = str(d.get("board_theme", "emerald"))
		var legacy_engine = bool(d.get("show_engine_arrows", true))
		var legacy_threat = bool(d.get("show_threat_arrows", true))
		show_white_engine_arrows = bool(d.get("show_white_engine_arrows", legacy_engine))
		show_white_threat_arrows = bool(d.get("show_white_threat_arrows", legacy_threat))
		show_black_engine_arrows = bool(d.get("show_black_engine_arrows", legacy_engine))
		show_black_threat_arrows = bool(d.get("show_black_threat_arrows", legacy_threat))
		
		# Jika ada data role-level preference eksplisit, sinkronkan ke warna aktif
		if d.has("player_engine_arrows"):
			var p_e = bool(d.get("player_engine_arrows", true))
			var o_e = bool(d.get("opponent_engine_arrows", false))
			var p_t = bool(d.get("player_threat_arrows", true))
			var o_t = bool(d.get("opponent_threat_arrows", false))
			if player_color == ChessTypes.PieceColor.WHITE:
				show_white_engine_arrows = p_e
				show_black_engine_arrows = o_e
				show_white_threat_arrows = p_t
				show_black_threat_arrows = o_t
			else:
				show_black_engine_arrows = p_e
				show_white_engine_arrows = o_e
				show_black_threat_arrows = p_t
				show_white_threat_arrows = o_t
				
		sound_enabled = bool(d.get("sound_enabled", true))
		sound_volume = float(d.get("sound_volume", 0.8))
		show_forbidden_squares = bool(d.get("show_forbidden_squares", true))
		show_defender_highlights = bool(d.get("show_defender_highlights", true))
		review_strength = str(d.get("review_strength", "fast"))
		review_depth = clampi(int(d.get("review_depth", 14)), 10, 26)
		review_max_time_ms = clampi(int(d.get("review_max_time_ms", 800)), 300, 10000)
		review_multipv = clampi(int(d.get("review_multipv", 2)), 1, 5)
		review_threads = clampi(int(d.get("review_threads", 1)), 1, 8)
		review_hash_mb = clampi(int(d.get("review_hash_mb", 64)), 16, 512)
		current_game_mode = str(d.get("current_game_mode", "vs_ai"))
		is_flipped = bool(d.get("is_flipped", is_flipped))

