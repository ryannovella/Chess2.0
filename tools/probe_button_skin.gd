extends Node

## Uji terkontrol skin tombol tactile: satu kolom tombol berukuran nyata dari aplikasi.
## Jalankan dua kali (filter default proyek vs LINEAR tanpa mipmap) lalu bandingkan.
##   & "...Godot...exe" --path . res://tools/probe_button_skin.tscn -- <out.png> [--filter=2]

const TactileStyles = preload("res://src/theme/tactile_styles.gd")

const SIZES: Array = [
	[46, 46], [224, 40], [234, 38], [209, 59], [300, 56], [500, 48],
]

var _filter := -1

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var out_path := "res://zzdiag/probe_button_skin.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			_filter = int(arg.trim_prefix("--filter="))
		elif not arg.begins_with("--"):
			out_path = arg

	var bg := ColorRect.new()
	bg.color = Color(0.086, 0.086, 0.094)
	bg.size = Vector2(720, 1280)
	add_child(bg)

	var y := 20.0
	var index := 0
	for entry in SIZES:
		var size := Vector2(float(entry[0]), float(entry[1]))
		var btn := Button.new()
		btn.text = "%dx%d" % [int(size.x), int(size.y)]
		btn.custom_minimum_size = size
		btn.size = size
		btn.position = Vector2(24.0, y)
		btn.clip_text = true
		TactileStyles.apply_tactile_button(btn, false, false, size.x <= 120.0)
		add_child(btn)
		y += size.y + 30.0
		index += 1

	for i in range(4):
		await get_tree().process_frame
	if _filter >= 0:
		for node in get_tree().root.find_children("*", "CanvasItem", true, false):
			(node as CanvasItem).texture_filter = _filter as CanvasItem.TextureFilter
	for i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image != null:
		image.save_png(out_path)
		print("saved: ", out_path, " ", image.get_size())
	get_tree().quit(0)
