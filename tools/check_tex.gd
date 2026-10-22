extends SceneTree

func _init() -> void:
	var tex = load("res://assets/ui/tactile_gray_normal.png")
	if tex:
		print("Texture size:", tex.get_size())
	quit(0)
