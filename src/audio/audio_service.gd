extends Node

var sounds: Dictionary = {}
var audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

func _ready() -> void:
	# Buat pool AudioStreamPlayer agar sound effect bisa overlap secara alami
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		add_child(player)
		audio_players.append(player)

	load_sound("move", "res://assets/sounds/move.mp3")
	load_sound("capture", "res://assets/sounds/capture.mp3")
	load_sound("castle", "res://assets/sounds/castle.mp3")
	load_sound("check", "res://assets/sounds/check.mp3")
	load_sound("checkmate", "res://assets/sounds/checkmate.mp3")
	load_sound("illegal", "res://assets/sounds/illegal.mp3")
	load_sound("promote", "res://assets/sounds/promote.mp3")
	load_sound("victory", "res://assets/sounds/victory.wav")
	load_sound("game_end", "res://assets/sounds/game-end.wav")
	load_sound("button_press", "res://assets/sounds/button_press.wav")
	load_sound("button_release", "res://assets/sounds/button_release.wav")

	# Tema suara button tactile: mechanical, modern, soft, mouse
	load_sound("btn_press_mechanical", "res://assets/sounds/btn_press_mechanical.wav")
	load_sound("btn_release_mechanical", "res://assets/sounds/btn_release_mechanical.wav")
	load_sound("btn_press_modern", "res://assets/sounds/btn_press_modern.wav")
	load_sound("btn_release_modern", "res://assets/sounds/btn_release_modern.wav")
	load_sound("btn_press_soft", "res://assets/sounds/btn_press_soft.wav")
	load_sound("btn_release_soft", "res://assets/sounds/btn_release_soft.wav")
	load_sound("btn_press_mouse", "res://assets/sounds/btn_press_mouse.wav")
	load_sound("btn_release_mouse", "res://assets/sounds/btn_release_mouse.wav")

	_setup_tree_connections()

func _notification(what: int) -> void:
	if what == NOTIFICATION_ENTER_TREE:
		_setup_tree_connections()

func _setup_tree_connections() -> void:
	if not is_inside_tree():
		return
	var tree = get_tree()
	if tree and tree.root:
		_connect_tree_buttons(tree.root)
		if not tree.node_added.is_connected(_on_node_added):
			tree.node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_button(node)

func _connect_tree_buttons(root_node: Node) -> void:
	if not root_node:
		return
	if root_node is BaseButton:
		_register_button(root_node)
	for child in root_node.get_children():
		_connect_tree_buttons(child)

func register_button(btn: BaseButton) -> void:
	_register_button(btn)

func _register_button(btn: BaseButton) -> void:
	if btn.has_meta(&"no_tactile_sfx"):
		return
	if not btn.button_down.is_connected(_on_button_down):
		btn.button_down.connect(_on_button_down)
	if not btn.button_up.is_connected(_on_button_up):
		btn.button_up.connect(_on_button_up)

func _on_button_down() -> void:
	play_button_down()

func _on_button_up() -> void:
	play_button_up()

func load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			sounds[key] = stream

func _get_sound_enabled() -> bool:
	var gs = get_node_or_null("/root/GameSettings")
	return gs.sound_enabled if gs else true

func _get_sound_volume() -> float:
	var gs = get_node_or_null("/root/GameSettings")
	return gs.sound_volume if gs else 1.0

func play_sfx(sound_name: String, volume_multiplier: float = 1.0, pitch_scale: float = 1.0) -> void:
	if not _get_sound_enabled():
		return
	if not sounds.has(sound_name):
		return

	var stream = sounds[sound_name]
	var vol_db = linear_to_db(clampf(_get_sound_volume() * volume_multiplier, 0.001, 1.0))
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.pitch_scale = pitch_scale
			player.volume_db = vol_db
			player.play()
			return

	# Fallback ke player pertama jika semua sibuk
	var p0 = audio_players[0]
	p0.stream = stream
	p0.pitch_scale = pitch_scale
	p0.volume_db = vol_db
	p0.play()

func play(sound_name: String) -> void:
	play_sfx(sound_name, 1.0, 1.0)

func _get_button_sound_theme() -> String:
	var gs = get_node_or_null("/root/GameSettings")
	if gs and "button_sound_theme" in gs:
		return str(gs.button_sound_theme)
	return "mechanical"

func play_button_down(override_theme: String = "") -> void:
	var theme = override_theme if not override_theme.is_empty() else _get_button_sound_theme()
	if theme == "off":
		return
	var sound_key = "btn_press_" + theme
	if not sounds.has(sound_key):
		sound_key = "button_press"
	var vol := 0.55
	if theme == "soft":
		vol = 0.45
	elif theme == "mouse":
		vol = 0.52
	play_sfx(sound_key, vol, randf_range(0.98, 1.02))

func play_button_up(override_theme: String = "") -> void:
	var theme = override_theme if not override_theme.is_empty() else _get_button_sound_theme()
	if theme == "off":
		return
	var sound_key = "btn_release_" + theme
	if not sounds.has(sound_key):
		sound_key = "button_release"
	var vol := 0.42
	if theme == "soft":
		vol = 0.35
	elif theme == "mouse":
		vol = 0.40
	play_sfx(sound_key, vol, randf_range(0.98, 1.02))

func preview_button_sound(theme: String) -> void:
	if theme == "off":
		return
	play_button_down(theme)
	var t = get_tree()
	if t:
		await t.create_timer(0.09, false).timeout
		play_button_up(theme)

func play_move() -> void:
	play("move")

func play_capture() -> void:
	play("capture")

func play_castle() -> void:
	play("castle")

func play_check() -> void:
	play("check")

func play_checkmate() -> void:
	play("checkmate")

func play_illegal() -> void:
	play("illegal")

func play_promote() -> void:
	play("promote")

func play_victory() -> void:
	play("victory")
