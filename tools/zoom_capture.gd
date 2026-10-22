extends SceneTree

## Memperbesar potongan tangkapan layar dengan penskalaan nearest (tanpa interpolasi)
## agar tepi piksel terlihat apa adanya. Headless.
##   & "...Godot...exe" --headless --path . -s res://tools/zoom_capture.gd -- in.png x y w h scale out.png

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 7:
		print("pemakaian: -- <in.png> <x> <y> <w> <h> <scale> <out.png>")
		quit(1)
		return
	var src := Image.load_from_file(args[0])
	if src == null:
		print("gagal memuat: ", args[0])
		quit(1)
		return
	var rect := Rect2i(int(args[1]), int(args[2]), int(args[3]), int(args[4])).intersection(
		Rect2i(Vector2i.ZERO, src.get_size()))
	if rect.size.x <= 0 or rect.size.y <= 0:
		print("potongan kosong: ", rect)
		quit(1)
		return
	var scale := int(args[5])
	var crop := src.get_region(rect)
	crop.resize(crop.get_width() * scale, crop.get_height() * scale, Image.INTERPOLATE_NEAREST)
	crop.save_png(args[6])
	print("disimpan: ", args[6], " ", crop.get_size(), " dari ", rect)
	quit(0)
