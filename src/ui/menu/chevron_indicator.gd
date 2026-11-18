class_name ChevronIndicator
extends Control

@export var is_expanded: bool = true:
	set(val):
		if is_expanded != val:
			is_expanded = val
			queue_redraw()

@export var chevron_color: Color = Color(0.75, 0.75, 0.75, 0.85):
	set(val):
		chevron_color = val
		queue_redraw()

@export var stroke_width: float = 2.2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(20, 20)

func _draw() -> void:
	var s: Vector2 = size
	var cx: float = round(s.x * 0.5)
	var cy: float = round(s.y * 0.5)
	var arm_x: float = round(min(s.x, s.y) * 0.28)
	var arm_y: float = round(min(s.x, s.y) * 0.16)
	
	var pts: PackedVector2Array = []
	if is_expanded:
		# Downward arrow: V shape
		pts.append(Vector2(cx - arm_x, cy - arm_y))
		pts.append(Vector2(cx, cy + arm_y))
		pts.append(Vector2(cx + arm_x, cy - arm_y))
	else:
		# Rightward arrow: > shape
		pts.append(Vector2(cx - arm_y, cy - arm_x))
		pts.append(Vector2(cx + arm_y, cy))
		pts.append(Vector2(cx - arm_y, cy + arm_x))
	
	draw_polyline(pts, chevron_color, stroke_width, true)
