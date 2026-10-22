class_name PieceSmearEffect
extends Control

var start_pt: Vector2 = Vector2.ZERO
var end_pt: Vector2 = Vector2.ZERO
var target_node: Control = null
var center_offset: Vector2 = Vector2.ZERO
var smear_color: Color = Color.WHITE
var smear_width: float = 28.0
var alpha_fade: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func trigger(from_pos: Vector2, moving_node: Control, piece_color: int, piece_size: float, duration: float = 0.25) -> void:
	start_pt = from_pos
	target_node = moving_node
	center_offset = Vector2(piece_size * 0.5, piece_size * 0.5)
	end_pt = from_pos
	smear_width = piece_size * 0.44

	if piece_color == ChessTypes.PieceColor.WHITE:
		smear_color = Color(1.0, 1.0, 1.0, 0.40)
	else:
		smear_color = Color(0.12, 0.14, 0.18, 0.45)

	alpha_fade = 1.0
	queue_redraw()

	var tween = create_tween()
	# Dissolve / fade out seiring meluncurnya bidak
	tween.tween_property(self, "alpha_fade", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		target_node = null
		queue_free()
	)

func _process(_delta: float) -> void:
	if target_node != null and is_instance_valid(target_node):
		# End point terus mengikuti posisi aktual bidak yang sedang meluncur (sehingga trail selalu berada di belakang bidak)
		end_pt = target_node.position + center_offset
	queue_redraw()

func _draw() -> void:
	if alpha_fade <= 0.005 or start_pt.distance_to(end_pt) < 6.0:
		return

	var cur_color = smear_color
	cur_color.a *= alpha_fade

	var dir = (end_pt - start_pt).normalized()
	var ortho = Vector2(-dir.y, dir.x)

	# Continuous tapered ribbon: meruncing di ekor asal dan melebar mengikuti bagian belakang bidak
	var p1 = start_pt - ortho * (smear_width * 0.20)
	var p2 = start_pt + ortho * (smear_width * 0.20)
	var p3 = end_pt + ortho * (smear_width * 0.48)
	var p4 = end_pt - ortho * (smear_width * 0.48)

	var points = PackedVector2Array([p1, p2, p3, p4])
	var uvs = PackedVector2Array([Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
	var colors = PackedColorArray([
		Color(cur_color.r, cur_color.g, cur_color.b, cur_color.a * 0.15),
		Color(cur_color.r, cur_color.g, cur_color.b, cur_color.a * 0.15),
		cur_color,
		cur_color
	])

	draw_primitive(points, colors, uvs)
	# Rounded cap di belakang bidak dan ekor asal
	draw_circle(end_pt, smear_width * 0.48, cur_color, true, -1.0, true)
	draw_circle(start_pt, smear_width * 0.20, Color(cur_color.r, cur_color.g, cur_color.b, cur_color.a * 0.15), true, -1.0, true)
