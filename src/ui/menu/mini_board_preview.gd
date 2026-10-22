class_name MiniBoardPreview
extends Control

@export var board_pixels: float = 440.0
@export var is_banner_mode: bool = false # True jika hanya merender crop banner atas (untuk modal settings)

var sq_size: float = 55.0

# Posisi awal catur standar
const INITIAL_SETUP = [
	["bR", "bN", "bB", "bQ", "bK", "bB", "bN", "bR"],
	["bP", "bP", "bP", "bP", "bP", "bP", "bP", "bP"],
	["",   "",   "",   "",   "",   "",   "",   ""],
	["",   "",   "",   "",   "",   "",   "",   ""],
	["",   "",   "",   "",   "",   "",   "",   ""],
	["",   "",   "",   "",   "",   "",   "",   ""],
	["wP", "wP", "wP", "wP", "wP", "wP", "wP", "wP"],
	["wR", "wN", "wB", "wQ", "wK", "wB", "wN", "wR"]
]

var piece_textures: Dictionary = {}

func _ready() -> void:
	_update_dimensions()
	mouse_filter = MOUSE_FILTER_IGNORE
	# Bidak 270-400 px digambar ke petak ~50 px, jadi filter linear + mipmap dipasang
	# eksplisit (tidak bergantung pada pewarisan filter container) agar tepi bidak halus.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_textures()
	GameSettings.theme_changed.connect(func(_thm): queue_redraw())
	GameSettings.piece_set_changed.connect(func(_set):
		_load_textures()
		queue_redraw()
	)

func _update_dimensions() -> void:
	if is_banner_mode:
		sq_size = board_pixels / 8.0
		custom_minimum_size = Vector2(board_pixels, sq_size * 3.0)
	else:
		sq_size = board_pixels / 8.0
		custom_minimum_size = Vector2(board_pixels, board_pixels)
	size = custom_minimum_size

func _load_textures() -> void:
	piece_textures.clear()
	var piece_set_name = GameSettings.piece_set if is_inside_tree() and get_node_or_null("/root/GameSettings") else "cburnett"
	if piece_set_name.is_empty():
		piece_set_name = "cburnett"
	var pieces = ["wP", "wN", "wB", "wR", "wQ", "wK", "bP", "bN", "bB", "bR", "bQ", "bK"]
	for p in pieces:
		var path = "res://assets/pieces/%s/%s.png" % [piece_set_name, p]
		if not ResourceLoader.exists(path):
			path = "res://assets/pieces/%s/%s.svg" % [piece_set_name, p]
		if ResourceLoader.exists(path):
			piece_textures[p] = load(path)
		else:
			var fb_path = "res://assets/pieces/cburnett/%s.svg" % p
			if ResourceLoader.exists(fb_path):
				piece_textures[p] = load(fb_path)

func _draw() -> void:
	var theme_data = BoardThemes.get_theme(GameSettings.board_theme)
	var light_col: Color = theme_data.get("light_color", Color(0.86, 0.85, 0.82))
	var dark_col: Color = theme_data.get("dark_color", Color(0.45, 0.52, 0.38))

	var max_rows = 3 if is_banner_mode else 8
	var is_flipped = (GameSettings.chosen_side == "black")

	for r in range(max_rows):
		var actual_r = (7 - r) if is_flipped else r
		for f in range(8):
			var actual_f = (7 - f) if is_flipped else f
			var is_dark = ((actual_r + actual_f) % 2 == 1)
			var col = dark_col if is_dark else light_col
			var rect = Rect2(Vector2(f * sq_size, r * sq_size), Vector2(sq_size, sq_size))
			draw_rect(rect, col)

			# Gambar bidak
			var piece_code = INITIAL_SETUP[actual_r][actual_f]
			if not piece_code.is_empty() and piece_textures.has(piece_code):
				var tex: Texture2D = piece_textures[piece_code]
				if tex:
					var p_margin = sq_size * 0.05
					var p_rect = Rect2(rect.position + Vector2(p_margin, p_margin), Vector2(sq_size - p_margin * 2, sq_size - p_margin * 2))
					draw_texture_rect(tex, p_rect, false)

	# Border luar
	var total_h = (max_rows * sq_size) if is_banner_mode else board_pixels
	draw_rect(Rect2(Vector2.ZERO, Vector2(board_pixels, total_h)), Color(0.24, 0.22, 0.2, 0.8), false, 2.0)
