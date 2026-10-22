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

func load_sound(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		var stream = load(path)
		if stream:
			sounds[key] = stream

func play(sound_name: String) -> void:
	if not GameSettings.sound_enabled:
		return
	if not sounds.has(sound_name):
		return

	var stream = sounds[sound_name]
	for player in audio_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(clampf(GameSettings.sound_volume, 0.01, 1.0))
			player.play()
			return

	# Fallback ke player pertama jika semua sibuk
	var p0 = audio_players[0]
	p0.stream = stream
	p0.volume_db = linear_to_db(clampf(GameSettings.sound_volume, 0.01, 1.0))
	p0.play()

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
