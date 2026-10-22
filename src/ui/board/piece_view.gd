class_name PieceView
extends TextureRect

var piece_color: int = ChessTypes.PieceColor.WHITE
var piece_type: int = ChessTypes.PieceType.PAWN
var current_square: String = ""
var is_animating: bool = false
var active_tween: Tween = null

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = MOUSE_FILTER_IGNORE
	if custom_minimum_size != Vector2.ZERO:
		size = custom_minimum_size

func setup(color: int, type: int, sq: String, piece_set: String, size_px: float) -> void:
	cancel_animation()
	rotation_degrees = 0.0
	scale = Vector2.ONE
	pivot_offset = Vector2.ZERO
	piece_color = color
	piece_type = type
	current_square = sq
	custom_minimum_size = Vector2(size_px, size_px)
	size = custom_minimum_size
	
	# Force expansion & high quality texture filtering
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = MOUSE_FILTER_IGNORE

	var color_char = "w" if color == ChessTypes.PieceColor.WHITE else "b"
	var type_char = ChessTypes.piece_type_to_san_char(type)
	if type == ChessTypes.PieceType.PAWN:
		type_char = "P"
	
	var texture_path = "res://assets/pieces/%s/%s%s.png" % [piece_set, color_char, type_char]
	if not ResourceLoader.exists(texture_path):
		texture_path = "res://assets/pieces/%s/%s%s.svg" % [piece_set, color_char, type_char]
	if ResourceLoader.exists(texture_path):
		texture = load(texture_path)
	else:
		# Fallback to cburnett
		var fallback_path = "res://assets/pieces/cburnett/%s%s.svg" % [color_char, type_char]
		if ResourceLoader.exists(fallback_path):
			texture = load(fallback_path)
		else:
			# Debugging path
			print("Could not load piece texture: ", texture_path)

func animate_move_to(target_pos: Vector2, duration: float = 0.18, on_complete: Callable = Callable(), on_impact: Callable = Callable(), is_drag: bool = false, d_squares: int = 1) -> void:
	if size == Vector2.ZERO and custom_minimum_size != Vector2.ZERO:
		size = custom_minimum_size
	pivot_offset = size * 0.5

	if is_drag:
		_animate_drop_settle(target_pos, on_impact, on_complete)
		return

	match piece_type:
		ChessTypes.PieceType.KNIGHT:
			_animate_knight_hop(target_pos, duration, on_impact, on_complete)
		ChessTypes.PieceType.PAWN:
			_animate_pawn_move(target_pos, duration, on_impact, on_complete, d_squares)
		ChessTypes.PieceType.KING:
			_animate_king_stride(target_pos, duration, on_impact, on_complete)
		_:
			_animate_slider_dash(target_pos, duration, on_impact, on_complete, d_squares)

func _animate_drop_settle(target_pos: Vector2, on_impact: Callable, on_complete: Callable) -> void:
	cancel_animation()
	is_animating = true
	z_index = 15
	pivot_offset = size * 0.5
	position = target_pos

	if on_impact.is_valid():
		on_impact.call()

	active_tween = create_tween()
	active_tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_property(self, "scale", Vector2.ONE, 0.05).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	active_tween.finished.connect(func():
		is_animating = false
		z_index = 0
		scale = Vector2.ONE
		rotation_degrees = 0.0
		pivot_offset = size * 0.5
		position = target_pos
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)

func _animate_knight_hop(target_pos: Vector2, duration: float, on_impact: Callable, on_complete: Callable) -> void:
	cancel_animation()
	is_animating = true
	z_index = 30 # Melompat tinggi di atas seluruh bidak
	pivot_offset = size * 0.5
	var start_pos = position
	# Parabola tinggi (lofty cartoon arc ~95% ukuran petak)
	var hop_height = size.y * 0.95
	var dir_x = signf(target_pos.x - start_pos.x)
	var tilt_deg = 12.0 * (dir_x if dir_x != 0.0 else 1.0)

	var t_windup = maxf(duration * 0.15, 0.02)
	var t_air = maxf(duration * 0.65, 0.08)
	var t_settle = maxf(duration * 0.20, 0.04)

	active_tween = create_tween()

	# 1. Deep crouch anticipation
	active_tween.tween_property(self, "scale", Vector2(1.22, 0.78), t_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. In-flight arc: X linier halus, Y dengan kubah parabola & hang-time kartun di puncak
	var in_flight = active_tween.chain().set_parallel(true)
	in_flight.tween_property(self, "position:x", target_pos.x, t_air).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	in_flight.tween_method(func(prog: float):
		# Arc dengan hang-time di puncak (pangkat 0.82 melebarkan kubah atas)
		var s = clampf(sin(prog * PI), 0.0, 1.0)
		var arc = pow(s, 0.82) * hop_height
		position.y = lerpf(start_pos.y, target_pos.y, prog) - arc
	, 0.0, 1.0, t_air)

	# Stretch vertikal saat take-off, melayang sejenak di puncak, lalu menukik tajam
	in_flight.tween_property(self, "scale", Vector2(0.78, 1.28), t_air * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	in_flight.tween_property(self, "rotation_degrees", tilt_deg, t_air * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Touchdown impact & juicy squash
	active_tween.chain().tween_callback(func():
		position = target_pos
		rotation_degrees = 0.0
		if on_impact.is_valid():
			on_impact.call()
	)
	var impact_p = active_tween.chain().set_parallel(true)
	impact_p.tween_property(self, "scale", Vector2(1.30, 0.70), t_settle * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_p.tween_property(self, "rotation_degrees", -tilt_deg * 0.20, t_settle * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Springy settle bounce
	var settle_p = active_tween.chain().set_parallel(true)
	settle_p.tween_property(self, "scale", Vector2.ONE, t_settle * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	settle_p.tween_property(self, "rotation_degrees", 0.0, t_settle * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	active_tween.finished.connect(func():
		is_animating = false
		z_index = 0
		scale = Vector2.ONE
		rotation_degrees = 0.0
		pivot_offset = size * 0.5
		position = target_pos
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)

func _animate_pawn_move(target_pos: Vector2, duration: float, on_impact: Callable, on_complete: Callable, d_squares: int) -> void:
	cancel_animation()
	is_animating = true
	z_index = 15
	pivot_offset = size * 0.5
	var start_pos = position
	# Pion tegak lurus konsisten: rotation_degrees selalu 0.0
	rotation_degrees = 0.0

	var is_double = d_squares >= 2
	var t_windup = maxf(duration * 0.14, 0.02)
	var t_stride = maxf(duration * 0.60, 0.08)
	var t_settle = maxf(duration * 0.26, 0.04)
	var hop_height = size.y * (0.30 if is_double else 0.18)

	active_tween = create_tween()

	# 1. Marching foot-squash anticipation di petak asal
	active_tween.tween_property(self, "scale", Vector2(1.15, 0.85), t_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Stride hop melayang lurus ke petak tujuan (tetap tegak tanpa miring)
	var stride_p = active_tween.chain().set_parallel(true)
	stride_p.tween_property(self, "position:x", target_pos.x, t_stride).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	stride_p.tween_method(func(prog: float):
		var arc = sin(prog * PI) * hop_height
		position.y = lerpf(start_pos.y, target_pos.y, prog) - arc
	, 0.0, 1.0, t_stride)
	stride_p.tween_property(self, "scale", Vector2(0.90, 1.14), t_stride * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Touchdown impact di petak target
	active_tween.chain().tween_callback(func():
		position = target_pos
		rotation_degrees = 0.0
		if on_impact.is_valid():
			on_impact.call()
	)
	var impact_p = active_tween.chain().set_parallel(true)
	impact_p.tween_property(self, "scale", Vector2(1.18, 0.84), t_settle * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Springy settle empuk
	active_tween.chain().tween_property(self, "scale", Vector2.ONE, t_settle * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	active_tween.finished.connect(func():
		is_animating = false
		z_index = 0
		scale = Vector2.ONE
		rotation_degrees = 0.0
		pivot_offset = size * 0.5
		position = target_pos
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)

func _animate_king_stride(target_pos: Vector2, duration: float, on_impact: Callable, on_complete: Callable) -> void:
	cancel_animation()
	is_animating = true
	z_index = 18
	pivot_offset = size * 0.5
	var start_pos = position
	var dir_x = signf(target_pos.x - start_pos.x)
	var tilt_deg = 3.0 * dir_x

	var t_stride = maxf(duration * 0.70, 0.08)
	var t_settle = maxf(duration * 0.30, 0.04)

	active_tween = create_tween()
	var stride_p = active_tween.set_parallel(true)
	stride_p.tween_property(self, "position:x", target_pos.x, t_stride).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	stride_p.tween_method(func(prog: float):
		var arc = 4.0 * (size.y * 0.10) * prog * (1.0 - prog)
		position.y = lerpf(start_pos.y, target_pos.y, prog) - arc
	, 0.0, 1.0, t_stride)
	stride_p.tween_property(self, "scale", Vector2(0.96, 1.06), t_stride * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if absf(dir_x) > 0.01:
		stride_p.tween_property(self, "rotation_degrees", tilt_deg, t_stride * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	active_tween.chain().tween_callback(func():
		position = target_pos
		rotation_degrees = 0.0
		if on_impact.is_valid():
			on_impact.call()
	)
	var impact_p = active_tween.chain().set_parallel(true)
	impact_p.tween_property(self, "scale", Vector2(1.10, 0.92), t_settle * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_property(self, "scale", Vector2.ONE, t_settle * 0.55).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	active_tween.finished.connect(func():
		is_animating = false
		z_index = 0
		scale = Vector2.ONE
		rotation_degrees = 0.0
		pivot_offset = size * 0.5
		position = target_pos
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)

func _animate_slider_dash(target_pos: Vector2, duration: float, on_impact: Callable, on_complete: Callable, d_squares: int = 1) -> void:
	cancel_animation()
	is_animating = true
	z_index = 16
	var start_pos = position
	var delta = target_pos - start_pos
	var dir = delta.normalized()

	# Cek apakah gerakan diagonal untuk Queen atau Bishop dengan jarak > 2 petak
	var is_diag = absf(absf(delta.x) - absf(delta.y)) < (size.x * 0.35) and absf(delta.x) > 10.0
	var is_queen_or_bishop = (piece_type == ChessTypes.PieceType.QUEEN or piece_type == ChessTypes.PieceType.BISHOP)

	var target_tilt: float = 0.0
	if piece_type == ChessTypes.PieceType.ROOK:
		# Rook tegap lurus (rotasi 0.0), kokoh seperti benteng tanpa miring
		pivot_offset = size * 0.5
		target_tilt = 0.0
	elif is_queen_or_bishop and is_diag and d_squares > 2:
		if delta.y < -5.0:
			# Diagonal-ATAS: kepala condong mengarah ke petak tujuan (pivot di bawah)
			pivot_offset = Vector2(size.x * 0.5, size.y * 0.88)
			target_tilt = 28.0 if delta.x > 0.0 else -28.0
		else:
			# Diagonal-BAWAH: bagian bawah memimpin luncuran (pivot di atas)
			pivot_offset = Vector2(size.x * 0.5, size.y * 0.12)
			target_tilt = -28.0 if delta.x > 0.0 else 28.0
	else:
		# Gerakan lurus non-diagonal (horizontal / vertikal): tetap tegap tanpa miring
		pivot_offset = size * 0.5
		target_tilt = 0.0

	var t_windup = maxf(duration * 0.14, 0.02)
	var t_dash = maxf(duration * 0.60, 0.07)
	var t_impact = maxf(duration * 0.14, 0.02)
	var t_settle = maxf(duration * 0.12, 0.02)

	var is_rook = (piece_type == ChessTypes.PieceType.ROOK)
	var windup_scale = Vector2(1.18, 0.82) if is_rook else Vector2(1.12, 0.88)
	var dash_scale = Vector2(1.24, 0.78) if is_rook else Vector2(1.22, 0.82)
	var impact_scale = Vector2(1.25, 0.75) if is_rook else Vector2(1.18, 0.84)

	active_tween = create_tween()

	# 1. Anticipation: slight recoil opposite to movement + squash
	var windup_pos = start_pos - dir * (size.x * 0.05)
	var windup_p = active_tween.set_parallel(true)
	windup_p.tween_property(self, "position", windup_pos, t_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	windup_p.tween_property(self, "scale", windup_scale, t_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	windup_p.tween_property(self, "rotation_degrees", -target_tilt * 0.30, t_windup).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Dash in-flight: rotasi diagonal ekspresif + stretch
	var overshoot_pos = target_pos + dir * (size.x * 0.035)
	var dash_p = active_tween.chain().set_parallel(true)
	dash_p.tween_property(self, "position", overshoot_pos, t_dash).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	dash_p.tween_property(self, "scale", dash_scale, t_dash * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dash_p.tween_property(self, "rotation_degrees", target_tilt, t_dash * 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Touchdown impact & squash
	active_tween.chain().tween_callback(func():
		if on_impact.is_valid():
			on_impact.call()
	)
	var impact_p = active_tween.chain().set_parallel(true)
	impact_p.tween_property(self, "position", target_pos, t_impact).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_p.tween_property(self, "scale", impact_scale, t_impact).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	impact_p.tween_property(self, "rotation_degrees", 0.0, t_impact).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Elastic settle
	active_tween.chain().tween_property(self, "scale", Vector2.ONE, t_settle).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

	active_tween.finished.connect(func():
		is_animating = false
		z_index = 0
		scale = Vector2.ONE
		rotation_degrees = 0.0
		pivot_offset = size * 0.5
		position = target_pos
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)

func animate_capture_defeat() -> void:
	cancel_animation()
	is_animating = true
	z_index = 8
	pivot_offset = size * 0.5
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.35, 1.35), 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", position.y - size.y * 0.08, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(func():
		queue_free()
	)

func cancel_animation() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()
		active_tween = null
	is_animating = false
	z_index = 0
	rotation_degrees = 0.0
	scale = Vector2.ONE
	pivot_offset = Vector2.ZERO

func animate_shake(duration: float = 0.32) -> void:
	if is_animating:
		return
	cancel_animation()
	is_animating = true
	z_index = 10
	
	var base_pos = position
	pivot_offset = size * 0.5
	
	active_tween = create_tween()
	
	var shake_amp = size.x * 0.075
	var shake_rot = 4.5
	var step_time = duration / 6.0
	
	# 1. Kaget mendadak ke kanan + tilt sedikit
	active_tween.tween_property(self, "position:x", base_pos.x + shake_amp, step_time).set_trans(Tween.TRANS_SINE)
	var p1 = active_tween.parallel()
	p1.tween_property(self, "rotation_degrees", shake_rot, step_time)
	p1.tween_property(self, "scale", Vector2(0.94, 1.06), step_time)
	
	# 2. Getar ke kiri
	active_tween.chain().tween_property(self, "position:x", base_pos.x - shake_amp * 0.85, step_time).set_trans(Tween.TRANS_SINE)
	var p2 = active_tween.parallel()
	p2.tween_property(self, "rotation_degrees", -shake_rot * 0.85, step_time)
	p2.tween_property(self, "scale", Vector2(1.05, 0.95), step_time)
	
	# 3. Getar ke kanan lagi
	active_tween.chain().tween_property(self, "position:x", base_pos.x + shake_amp * 0.60, step_time).set_trans(Tween.TRANS_SINE)
	var p3 = active_tween.parallel()
	p3.tween_property(self, "rotation_degrees", shake_rot * 0.60, step_time)
	p3.tween_property(self, "scale", Vector2(0.97, 1.03), step_time)
	
	# 4. Getar ke kiri kecil
	active_tween.chain().tween_property(self, "position:x", base_pos.x - shake_amp * 0.35, step_time).set_trans(Tween.TRANS_SINE)
	var p4 = active_tween.parallel()
	p4.tween_property(self, "rotation_degrees", -shake_rot * 0.35, step_time)
	p4.tween_property(self, "scale", Vector2(1.02, 0.98), step_time)
	
	# 5. Getar ke kanan halus
	active_tween.chain().tween_property(self, "position:x", base_pos.x + shake_amp * 0.15, step_time).set_trans(Tween.TRANS_SINE)
	var p5 = active_tween.parallel()
	p5.tween_property(self, "rotation_degrees", shake_rot * 0.15, step_time)
	p5.tween_property(self, "scale", Vector2(0.99, 1.01), step_time)
	
	# 6. Settle kembali ke posisi awal
	active_tween.chain().tween_property(self, "position:x", base_pos.x, step_time).set_trans(Tween.TRANS_SINE)
	var p6 = active_tween.parallel()
	p6.tween_property(self, "rotation_degrees", 0.0, step_time)
	p6.tween_property(self, "scale", Vector2.ONE, step_time)
	
	active_tween.finished.connect(func():
		is_animating = false
		position = base_pos
		rotation_degrees = 0.0
		scale = Vector2.ONE
		z_index = 0
		active_tween = null
	)

func animate_topple(direction: float = 1.0, on_complete: Callable = Callable()) -> void:
	cancel_animation()
	is_animating = true
	z_index = 25
	
	var base_pos = position
	pivot_offset = size * 0.5
	var target_rot = 70.0 * direction
	var hop_height = size.y * 0.20

	active_tween = create_tween()
	
	# 1. Antisipasi squash kartun sebelum melompat (0.05s)
	active_tween.tween_property(self, "scale", Vector2(1.12, 0.88), 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Lompat kecil vertikal dengan stretch cartoony dan sedikit oleng (0.16s)
	var hop_tween = active_tween.parallel()
	hop_tween.tween_property(self, "position:y", base_pos.y - hop_height, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.tween_property(self, "scale", Vector2(0.90, 1.12), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop_tween.tween_property(self, "rotation_degrees", -6.0 * direction, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Terjatuh dan tumbang ke samping dengan ukuran penuh 100% (0.22s)
	active_tween.chain().tween_property(self, "position:y", base_pos.y + size.y * 0.04, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var fall_rot = active_tween.parallel()
	fall_rot.tween_property(self, "rotation_degrees", target_rot, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_rot.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# 4. Micro-bounce & settle empuk di atas lantai petak (0.16s)
	active_tween.chain().tween_property(self, "position:y", base_pos.y + size.y * 0.02, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var recoil_rot = active_tween.parallel()
	recoil_rot.tween_property(self, "rotation_degrees", (target_rot - 4.0 * direction), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	active_tween.chain().tween_property(self, "position:y", base_pos.y + size.y * 0.04, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var settle_rot = active_tween.parallel()
	settle_rot.tween_property(self, "rotation_degrees", target_rot, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	active_tween.finished.connect(func():
		is_animating = false
		active_tween = null
		if on_complete.is_valid():
			on_complete.call()
	)
