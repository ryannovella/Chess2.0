class_name TactileStyles
extends RefCounted

const TEX_GRAY_NORMAL = preload("res://assets/ui/tactile_gray_normal.png")
const TEX_GRAY_HOVER = preload("res://assets/ui/tactile_gray_hover.png")
const TEX_GRAY_PRESSED = preload("res://assets/ui/tactile_gray_pressed.png")
const TEX_GRAY_ACTIVE = preload("res://assets/ui/tactile_gray_active.png")
const TEX_GRAY_ACTIVE_HOVER = preload("res://assets/ui/tactile_gray_active_hover.png")
const TEX_GRAY_ACTIVE_PRESSED = preload("res://assets/ui/tactile_gray_active_pressed.png")

const TEX_GREEN_NORMAL = preload("res://assets/ui/tactile_green_normal.png")
const TEX_GREEN_HOVER = preload("res://assets/ui/tactile_green_hover.png")
const TEX_GREEN_PRESSED = preload("res://assets/ui/tactile_green_pressed.png")

static func create_gray_style(state: String = "normal", compact: bool = false) -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 14.0
	sb.texture_margin_right = 18.0
	var h_margin = 6.0 if compact else 14.0

	match state:
		"normal":
			sb.texture = TEX_GRAY_NORMAL
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"hover":
			sb.texture = TEX_GRAY_HOVER
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"pressed":
			sb.texture = TEX_GRAY_PRESSED
			sb.texture_margin_bottom = 16.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 11.0
			sb.content_margin_bottom = 9.0
		"active":
			sb.texture = TEX_GRAY_ACTIVE
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"active_hover":
			sb.texture = TEX_GRAY_ACTIVE_HOVER
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"active_pressed":
			sb.texture = TEX_GRAY_ACTIVE_PRESSED
			sb.texture_margin_bottom = 16.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 11.0
			sb.content_margin_bottom = 9.0
		"disabled":
			sb.texture = TEX_GRAY_NORMAL
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = h_margin
			sb.content_margin_right = h_margin
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
			sb.modulate_color = Color(0.65, 0.65, 0.65, 0.45)
	return sb

static func create_green_style(state: String = "normal") -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 14.0
	sb.texture_margin_right = 18.0

	match state:
		"normal":
			sb.texture = TEX_GREEN_NORMAL
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = 14.0
			sb.content_margin_right = 14.0
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"hover":
			sb.texture = TEX_GREEN_HOVER
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = 14.0
			sb.content_margin_right = 14.0
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
		"pressed":
			sb.texture = TEX_GREEN_PRESSED
			sb.texture_margin_bottom = 16.0
			sb.content_margin_left = 14.0
			sb.content_margin_right = 14.0
			sb.content_margin_top = 11.0
			sb.content_margin_bottom = 9.0
		"disabled":
			sb.texture = TEX_GREEN_NORMAL
			sb.texture_margin_bottom = 18.0
			sb.content_margin_left = 14.0
			sb.content_margin_right = 14.0
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 12.0
			sb.modulate_color = Color(0.65, 0.65, 0.65, 0.45)
	return sb

static func apply_tactile_button(btn: Button, is_green: bool = false, is_active: bool = false, compact: bool = false) -> void:
	if is_green:
		btn.add_theme_stylebox_override("normal", create_green_style("normal"))
		btn.add_theme_stylebox_override("hover", create_green_style("hover"))
		btn.add_theme_stylebox_override("pressed", create_green_style("pressed"))
		btn.add_theme_stylebox_override("focus", create_green_style("hover"))
		btn.add_theme_stylebox_override("disabled", create_green_style("disabled"))
	elif is_active:
		btn.add_theme_stylebox_override("normal", create_gray_style("active", compact))
		btn.add_theme_stylebox_override("hover", create_gray_style("active_hover", compact))
		btn.add_theme_stylebox_override("pressed", create_gray_style("active_pressed", compact))
		btn.add_theme_stylebox_override("focus", create_gray_style("active_hover", compact))
		btn.add_theme_stylebox_override("disabled", create_gray_style("disabled", compact))
	else:
		btn.add_theme_stylebox_override("normal", create_gray_style("normal", compact))
		btn.add_theme_stylebox_override("hover", create_gray_style("hover", compact))
		btn.add_theme_stylebox_override("pressed", create_gray_style("pressed", compact))
		btn.add_theme_stylebox_override("focus", create_gray_style("hover", compact))
		btn.add_theme_stylebox_override("disabled", create_gray_style("disabled", compact))
