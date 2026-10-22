extends SceneTree

## Audit standar visual (AGENTS.md seksi 3): mipmap raster, filter, dan metadata font.
## Jalankan: & "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://tools/audit_visual_assets.gd

const RASTER_EXT: Array = ["png", "jpg", "jpeg", "webp"]
const VECTOR_EXT: Array = ["svg"]
const FONT_EXT: Array = ["ttf", "otf"]

func _init() -> void:
	var roots: Array = ["res://assets", "res://engine/maia3/assets", "res://zzdiag"]
	var rasters: Array = []
	var vectors: Array = []
	var fonts: Array = []

	for root_dir in roots:
		_scan(root_dir, rasters, vectors, fonts)

	print("\n================ AUDIT ASET VISUAL ================")
	print("\n-- RASTER (PNG/JPG) --")
	print("%-58s %-12s %-6s %s" % ["path", "size", "mip", "status"])
	for path in rasters:
		_report_texture(path)

	print("\n-- VEKTOR (SVG, diraster saat import) --")
	print("%-58s %-12s %-6s %s" % ["path", "size", "mip", "status"])
	for path in vectors:
		_report_texture(path)

	print("\n-- FONT --")
	print("%-40s %-8s %-8s %-10s %-8s %s" % ["path", "aa", "hint", "subpixel", "msdf", "mip"])
	for path in fonts:
		var f: FontFile = load(path)
		if f == null:
			print("%-40s GAGAL DIMUAT" % path)
			continue
		print("%-40s %-8d %-8d %-10d %-8s %s" % [
			path.get_file(), f.antialiasing, f.hinting, f.subpixel_positioning,
			str(f.multichannel_signed_distance_field), str(f.generate_mipmaps)
		])

	print("\n==================================================")
	quit()

func _scan(dir_path: String, rasters: Array, vectors: Array, fonts: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		var full := dir_path.path_join(file_name)
		if dir.current_is_dir():
			if not file_name.begins_with("."):
				_scan(full, rasters, vectors, fonts)
		else:
			var ext := file_name.get_extension().to_lower()
			if RASTER_EXT.has(ext):
				rasters.append(full)
			elif VECTOR_EXT.has(ext):
				vectors.append(full)
			elif FONT_EXT.has(ext):
				fonts.append(full)
		file_name = dir.get_next()
	dir.list_dir_end()
	rasters.sort()
	vectors.sort()
	fonts.sort()

func _report_texture(path: String) -> void:
	var tex: Texture2D = load(path)
	if tex == null:
		print("%-58s GAGAL DIMUAT" % path)
		return
	var size := tex.get_size()
	var mips := 0
	if tex is CompressedTexture2D:
		var img: Image = (tex as CompressedTexture2D).get_image()
		if img != null:
			mips = img.get_mipmap_count()
	var status := "OK" if mips > 1 else "TANPA MIPMAP"
	print("%-58s %-12s %-6d %s" % [path.trim_prefix("res://"), str(size), mips, status])
