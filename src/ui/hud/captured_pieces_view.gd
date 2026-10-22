class_name CapturedPiecesView
extends Control

## Trophy row for captured pieces, Chess.com style.
##
## Pieces of the same type are drawn overlapping each other (so three captured
## pawns read as one tight cluster) while different types are separated by a
## small gap. The row keeps a bounded width: when an extreme material swing
## would make it wider than MAX_ROW_WIDTH the icons scale down instead of
## pushing the player card, and therefore MainLayout, past the viewport.

const PIECE_SET_FALLBACK := "cburnett"

const BASE_ICON_SIZE := 28.0
const MIN_ICON_SIZE := 18.0
const SAME_TYPE_STEP_RATIO := 0.50
const GROUP_GAP_RATIO := 0.25
const COMPACT_STEP_RATIO := 0.34
const COMPACT_GAP_RATIO := 0.16
const ADVANTAGE_GAP := 6.0
const ADVANTAGE_FONT_SIZE := 15
const MAX_ROW_WIDTH := 228.0

const FONT_BOLD := preload("res://assets/fonts/ChessSans-Bold.ttf")
const CardPalette = preload("res://src/ui/card_palette.gd")

static var _texture_cache: Dictionary = {}

var _groups: Array[Dictionary] = []
var _piece_color: int = ChessTypes.PieceColor.WHITE
var _advantage: int = 0
var _piece_set: String = PIECE_SET_FALLBACK
var _card_bg: Color = CardPalette.DARK_CARD_BG
var _advantage_color: Color = CardPalette.LIGHT_INK
var _icon_size: float = BASE_ICON_SIZE
var _step_ratio: float = SAME_TYPE_STEP_RATIO
var _gap_ratio: float = GROUP_GAP_RATIO
var _row_width: float = 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

static func clear_texture_cache() -> void:
	_texture_cache.clear()

static func resolve_texture(color: int, type: int, piece_set: String) -> Texture2D:
	var set_name = piece_set if not piece_set.is_empty() else PIECE_SET_FALLBACK
	var color_char = "w" if color == ChessTypes.PieceColor.WHITE else "b"
	var type_char = ChessTypes.piece_type_to_san_char(type)
	if type == ChessTypes.PieceType.PAWN:
		type_char = "P"

	var key = "%s/%s%s" % [set_name, color_char, type_char]
	if _texture_cache.has(key):
		return _texture_cache[key]

	var path = "res://assets/pieces/%s/%s%s.png" % [set_name, color_char, type_char]
	if not ResourceLoader.exists(path):
		path = "res://assets/pieces/%s/%s%s.svg" % [set_name, color_char, type_char]

	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		var fallback_path = "res://assets/pieces/%s/%s%s.svg" % [PIECE_SET_FALLBACK, color_char, type_char]
		if ResourceLoader.exists(fallback_path):
			tex = load(fallback_path)

	if tex != null:
		_texture_cache[key] = tex
	return tex

## captured must already be sorted ascending by piece value so equal types are
## consecutive; the view collapses them into per-type groups. card_bg drives the
## contrast formula for the material points text.
func set_captures(captured: Array, color: int, advantage: int, piece_set: String, card_bg: Color = CardPalette.DARK_CARD_BG) -> void:
	_piece_color = color
	_advantage = advantage
	_piece_set = piece_set if not piece_set.is_empty() else PIECE_SET_FALLBACK
	_card_bg = card_bg
	_advantage_color = CardPalette.muted_ink(card_bg)

	_groups.clear()
	for entry in captured:
		var piece_type = int(entry)
		if not _groups.is_empty() and int(_groups[_groups.size() - 1]["type"]) == piece_type:
			_groups[_groups.size() - 1]["count"] = int(_groups[_groups.size() - 1]["count"]) + 1
		else:
			_groups.append({"type": piece_type, "count": 1})

	_recompute_layout()
	queue_redraw()

func has_content() -> bool:
	return not _groups.is_empty() or _advantage > 0

func get_row_width() -> float:
	return _row_width

func get_icon_size() -> float:
	return _icon_size

func get_group_count() -> int:
	return _groups.size()

func get_step_ratio() -> float:
	return _step_ratio

func _recompute_layout() -> void:
	var reserve = 0.0
	if _advantage > 0:
		reserve = ADVANTAGE_GAP + _advantage_text_width()

	var budget = maxf(MIN_ICON_SIZE, MAX_ROW_WIDTH - reserve)

	# Tahap 1: ukuran penuh dengan penumpukan normal.
	var icon = BASE_ICON_SIZE
	var step = SAME_TYPE_STEP_RATIO
	var gap = GROUP_GAP_RATIO
	if _measure_pieces(icon, step, gap) > budget:
		# Tahap 2: rapatkan lebih dulu supaya ikon tetap besar dan terbaca.
		step = COMPACT_STEP_RATIO
		gap = COMPACT_GAP_RATIO

	var width = _measure_pieces(icon, step, gap)
	if width > budget:
		# Tahap 3: baru kecilkan ikon, tidak pernah di bawah MIN_ICON_SIZE.
		icon = maxf(MIN_ICON_SIZE, roundf(clampf(icon * (budget / width), MIN_ICON_SIZE, BASE_ICON_SIZE)))
		width = _measure_pieces(icon, step, gap)
		if width > budget:
			# Tahap 4: jaminan terakhir agar kartu pemain tidak pernah mendorong layout.
			var squeeze = clampf(budget / width, 0.5, 1.0)
			step *= squeeze
			gap *= squeeze
			width = _measure_pieces(icon, step, gap)

	_icon_size = icon
	_step_ratio = step
	_gap_ratio = gap
	_row_width = width + reserve

	custom_minimum_size = Vector2(_row_width, _icon_size)
	size = custom_minimum_size
	update_minimum_size()

func _measure_pieces(icon: float, step_ratio: float, gap_ratio: float) -> float:
	if _groups.is_empty():
		return 0.0

	var step = icon * step_ratio
	var gap = icon * gap_ratio
	var x = 0.0
	for group in _groups:
		x += icon + float(int(group["count"]) - 1) * step + gap
	return x - gap

func _advantage_text_width() -> float:
	var text = "+%d" % _advantage
	return FONT_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ADVANTAGE_FONT_SIZE).x

func _draw() -> void:
	if _groups.is_empty() and _advantage <= 0:
		return

	var step = _icon_size * _step_ratio
	var gap = _icon_size * _gap_ratio
	var y = maxf(0.0, (size.y - _icon_size) * 0.5)
	var x = 0.0

	for group in _groups:
		var tex = resolve_texture(_piece_color, int(group["type"]), _piece_set)
		var count = int(group["count"])
		for i in range(count):
			if tex != null:
				draw_texture_rect(tex, Rect2(Vector2(x, y), Vector2(_icon_size, _icon_size)), false)
			if i < count - 1:
				x += step
		x += _icon_size + gap

	if not _groups.is_empty():
		x -= gap

	if _advantage > 0:
		x += ADVANTAGE_GAP
		var text = "+%d" % _advantage
		var text_height = FONT_BOLD.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, ADVANTAGE_FONT_SIZE).y
		var baseline = (size.y - text_height) * 0.5 + FONT_BOLD.get_ascent(ADVANTAGE_FONT_SIZE)
		draw_string(FONT_BOLD, Vector2(x, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			ADVANTAGE_FONT_SIZE, _advantage_color)
