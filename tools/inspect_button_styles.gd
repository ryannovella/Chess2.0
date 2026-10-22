extends Node

## Mendata setiap Button pada scene yang berjalan: ukuran, jenis stylebox, tekstur, margin,
## dan apakah area tengah 9-patch menyusut (degenerate) atau terminifikasi.
##   & "...Godot...exe" --path . res://tools/inspect_button_styles.tscn [--scene=res://src/main.tscn]

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene_path := "res://src/main.tscn"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--scene="):
			scene_path = arg.trim_prefix("--scene=")

	var scene: Node = load(scene_path).instantiate()
	add_child(scene)
	for i in range(6):
		await get_tree().process_frame

	print("\n================ BUTTON STYLE INSPECTION ================")
	var buttons: Array = get_tree().root.find_children("*", "Button", true, false)
	print("total Button: %d" % buttons.size())
	for node in buttons:
		_report(node as Button)
	print("=========================================================\n")
	get_tree().quit(0)

func _report(btn: Button) -> void:
	var visible_in_tree := btn.is_visible_in_tree()
	var size := btn.size
	var lines: Array = []
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var sb: StyleBox = btn.get_theme_stylebox(state)
		if sb == null:
			continue
		if sb is StyleBoxTexture:
			var st := sb as StyleBoxTexture
			var tex_name := "-"
			if st.texture != null:
				tex_name = st.texture.resource_path.get_file()
			var center_w: float = size.x - st.texture_margin_left - st.texture_margin_right
			var center_h: float = size.y - st.texture_margin_top - st.texture_margin_bottom
			var tex_size := Vector2.ZERO
			if st.texture != null:
				tex_size = st.texture.get_size()
			var scale_x := (center_w / (tex_size.x - st.texture_margin_left - st.texture_margin_right)) if tex_size.x > 0.0 else 0.0
			var scale_y := (center_h / (tex_size.y - st.texture_margin_top - st.texture_margin_bottom)) if tex_size.y > 0.0 else 0.0
			lines.append("%s=StyleBoxTexture(%s m=%.0f/%.0f/%.0f/%.0f center=%.1fx%.1f scale=%.2fx%.2fx%s)" % [
				state, tex_name, st.texture_margin_left, st.texture_margin_top,
				st.texture_margin_right, st.texture_margin_bottom, center_w, center_h,
				scale_x, scale_y, "  DEGENERATE" if (center_w <= 0.0 or center_h <= 0.0) else ""])
		else:
			lines.append("%s=%s" % [state, sb.get_class()])
	print("\n%s  size=(%.0f,%.0f) visible=%s filter=%d" % [
		str(btn.get_path()), size.x, size.y, str(visible_in_tree), btn.texture_filter])
	for line in lines:
		print("    ", line)
