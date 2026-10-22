class_name ConfettiBurst
extends Control

var left_cannon: CPUParticles2D = null
var right_cannon: CPUParticles2D = null
var particle_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_ribbon_texture()
	_setup_cannons()
	resized.connect(_update_cannon_positions)

func _create_ribbon_texture() -> void:
	var img = Image.create(12, 6, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	particle_texture = ImageTexture.create_from_image(img)

func _setup_cannons() -> void:
	left_cannon = _create_cannon(Vector2(0.55, -0.85).normalized())
	right_cannon = _create_cannon(Vector2(-0.55, -0.85).normalized())
	add_child(left_cannon)
	add_child(right_cannon)
	_update_cannon_positions()

func _create_cannon(dir: Vector2) -> CPUParticles2D:
	var p = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = 80
	p.lifetime = 2.4
	p.explosiveness = 0.88
	p.texture = particle_texture
	p.direction = dir
	p.spread = 38.0
	p.initial_velocity_min = 450.0
	p.initial_velocity_max = 750.0
	p.gravity = Vector2(0, 520.0)
	p.angular_velocity_min = -420.0
	p.angular_velocity_max = 420.0
	p.angle_min = -180.0
	p.angle_max = 180.0
	p.scale_amount_min = 0.8
	p.scale_amount_max = 1.5

	# Gradient warna-warni pesta cerah (Gold, Emerald, Cyan, Crimson, Violet, Amber)
	var grad = Gradient.new()
	grad.colors = PackedColorArray([
		Color(1.0, 0.84, 0.0),    # Emas
		Color(0.2, 0.88, 0.45),   # Hijau Zamrud
		Color(0.18, 0.72, 1.0),   # Biru Langit
		Color(1.0, 0.32, 0.42),   # Merah Cerah
		Color(0.78, 0.4, 1.0),    # Ungu
		Color(1.0, 0.58, 0.16)    # Oranye Amber
	])
	grad.offsets = PackedFloat32Array([0.0, 0.2, 0.4, 0.6, 0.8, 1.0])
	p.color_initial_ramp = grad
	return p

func _update_cannon_positions() -> void:
	if left_cannon and right_cannon:
		var w = size.x
		var h = size.y
		if (w <= 0.0 or h <= 0.0) and is_inside_tree():
			var vp_size = get_viewport_rect().size
			w = vp_size.x
			h = vp_size.y
		if w <= 0.0:
			w = 720.0
		if h <= 0.0:
			h = 1280.0
		left_cannon.position = Vector2(w * 0.05, h)
		right_cannon.position = Vector2(w * 0.95, h)

func burst() -> void:
	_update_cannon_positions()
	if left_cannon:
		left_cannon.restart()
		left_cannon.emitting = true
	if right_cannon:
		right_cannon.restart()
		right_cannon.emitting = true

func stop() -> void:
	if left_cannon:
		left_cannon.emitting = false
	if right_cannon:
		right_cannon.emitting = false
