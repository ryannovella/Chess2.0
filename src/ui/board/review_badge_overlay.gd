class_name ReviewBadgeOverlay
extends Control

const GameReviewService = preload("res://src/core/game_review_service.gd")
const ChessTypes = preload("res://src/core/chess_types.gd")

# Layer terdepan: z_index = 50 memastikan badge move classification selalu berada di atas
# seluruh kemungkinan state bidak catur (Knight hop z_index = 30, topple = 25, drag = 20, dll).
const BADGE_Z_INDEX: int = 50

# Geometri lencana relatif terhadap petak papan (86 px): diameter 0.46 petak,
# digeser 0.04 petak dari tepi kanan & atas petak.
const BADGE_SIZE_RATIO: float = 0.46
const BADGE_CORNER_INSET_RATIO: float = 0.04

var current_badge: Dictionary = {} # {"square": "e4", "classification": GameReviewService.Classification.BEST}
var is_flipped: bool = false
var square_size: float = 64.0
var _font: Font = null
var _textures_cache: Dictionary = {}

var anim_scale: float = 1.0:
	set(val):
		anim_scale = val
		queue_redraw()

var anim_alpha: float = 1.0:
	set(val):
		anim_alpha = val
		queue_redraw()

var _tween: Tween = null

# Badge memakai artwork resmi chess.com (PNG 256x256 di assets/ui/icons/review/).
# Warna sudah menyatu di dalam artwork, jadi tidak ada tint yang diterapkan.
const ICON_DIR: String = "res://assets/ui/icons/review/"

static func get_icon_path(cls: int) -> String:
	match cls:
		GameReviewService.Classification.BOOK: return ICON_DIR + "book.png"
		GameReviewService.Classification.BRILLIANT: return ICON_DIR + "brilliant.png"
		GameReviewService.Classification.GREAT: return ICON_DIR + "great.png"
		GameReviewService.Classification.BEST: return ICON_DIR + "best.png"
		GameReviewService.Classification.EXCELLENT: return ICON_DIR + "excellent.png"
		GameReviewService.Classification.GOOD: return ICON_DIR + "good.png"
		GameReviewService.Classification.INACCURACY: return ICON_DIR + "inaccuracy.png"
		GameReviewService.Classification.MISTAKE: return ICON_DIR + "mistake.png"
		GameReviewService.Classification.MISS: return ICON_DIR + "miss.png"
		GameReviewService.Classification.BLUNDER: return ICON_DIR + "blunder.png"
		_: return ICON_DIR + "good.png"

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = BADGE_Z_INDEX

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = BADGE_Z_INDEX
	custom_minimum_size = Vector2(512, 512)
	if ResourceLoader.exists("res://assets/fonts/ChessSans-Bold.ttf"):
		_font = load("res://assets/fonts/ChessSans-Bold.ttf")
	elif ResourceLoader.exists("res://assets/fonts/Montserrat-Regular.ttf"):
		_font = load("res://assets/fonts/Montserrat-Regular.ttf")

func set_review_badge(target_square: String, classification: int, p_flipped: bool, p_sq_size: float) -> void:
	z_index = BADGE_Z_INDEX
	if target_square.is_empty():
		clear_badge()
		return

	var is_changed = current_badge.is_empty() or current_badge.get("square", "") != target_square or current_badge.get("classification", -1) != classification
	current_badge = {
		"square": target_square,
		"classification": classification
	}
	is_flipped = p_flipped
	square_size = p_sq_size

	if is_changed:
		if _tween and _tween.is_valid():
			_tween.kill()

		if is_inside_tree():
			anim_scale = 0.2
			anim_alpha = 0.0
			_tween = create_tween()
			_tween.set_parallel(true)
			_tween.tween_property(self, "anim_scale", 1.0, 0.25).from(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_tween.tween_property(self, "anim_alpha", 1.0, 0.16).from(0.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			anim_scale = 1.0
			anim_alpha = 1.0
			queue_redraw()
	else:
		queue_redraw()

func clear_badge() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	current_badge.clear()
	anim_scale = 0.0
	anim_alpha = 0.0
	queue_redraw()

func _draw() -> void:
	if current_badge.is_empty() or anim_alpha <= 0.001 or anim_scale <= 0.001:
		return

	var sq = current_badge.get("square", "")
	if sq.is_empty():
		return

	var cls = current_badge.get("classification", GameReviewService.Classification.GOOD)
	var badge_rect = get_badge_rect(sq)

	var icon_path = get_icon_path(cls)
	var tex: Texture2D = null
	if _textures_cache.has(icon_path):
		tex = _textures_cache[icon_path]
	elif ResourceLoader.exists(icon_path):
		tex = load(icon_path)
		_textures_cache[icon_path] = tex

	if tex != null:
		# Artwork PNG sudah memuat bayangan lingkaran sendiri, jadi cukup digambar
		# apa adanya dengan rect yang sama seperti jalur fallback. Artefak 256x256 ini
		# selalu tampil ~16-40 px, jadi tepinya bergantung pada mipmap
		# (mipmaps/generate=true di .import) + filter LINEAR_WITH_MIPMAPS.
		draw_texture_rect(tex, badge_rect, false, Color(1, 1, 1, anim_alpha))
	else:
		# Fallback vector bila tekstur tidak tersedia
		var badge_size = badge_rect.size.x
		var badge_center = badge_rect.get_center()
		var radius = badge_size * 0.5
		var col = GameReviewService.classification_to_color(cls)
		col.a *= anim_alpha
		var symbol = GameReviewService.classification_to_badge_symbol(cls)
		draw_circle(badge_center + Vector2(0, 1.5 * anim_scale), radius + (1.2 * anim_scale), Color(0, 0, 0, 0.40 * anim_alpha), true, -1.0, true)
		draw_circle(badge_center, radius + (1.5 * anim_scale), Color(0.1, 0.12, 0.16, 0.95 * anim_alpha), true, -1.0, true)
		draw_circle(badge_center, radius, col, true, -1.0, true)

		if not symbol.is_empty() and _font != null:
			var font_size = int(radius * 1.2)
			var text_sz = _font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = badge_center + Vector2(-text_sz.x * 0.5, text_sz.y * 0.35)
			draw_string(_font, text_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, anim_alpha))

## Rect tujuan artwork lencana pada petak `sq`. Lencana duduk di sudut kanan atas
## petak seperti di chess.com. Saat animasi scale sudah selesai (anim_scale == 1.0),
## rect dikunci ke piksel utuh supaya tepi artwork tidak bergetar karena sampling
## sub-piksel; selama animasi berjalan posisi pecahan dibiarkan agar gerak mulus.
func get_badge_rect(sq: String) -> Rect2:
	var cell = _get_square_position(sq)
	var badge_size = square_size * BADGE_SIZE_RATIO * anim_scale
	var badge_center = cell + Vector2(
		square_size - (badge_size * 0.5) - (square_size * BADGE_CORNER_INSET_RATIO),
		(badge_size * 0.5) + (square_size * BADGE_CORNER_INSET_RATIO)
	)
	var dest_size = Vector2(badge_size, badge_size)
	var dest_pos = badge_center - dest_size * 0.5
	if is_equal_approx(anim_scale, 1.0):
		dest_pos = dest_pos.round()
		dest_size = dest_size.round()
	return Rect2(dest_pos, dest_size)

func _get_square_position(sq: String) -> Vector2:
	var coord = ChessTypes.square_to_coord(sq)
	var f = coord.x
	var r = coord.y
	var visual_f = (7 - f) if is_flipped else f
	var visual_r = r if is_flipped else (7 - r)
	return Vector2(visual_f * square_size, visual_r * square_size)

