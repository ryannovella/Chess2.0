extends Node

## Menangkap tangkapan layar UI (menu + in-game) untuk verifikasi visual tombol.
## Dijalankan sebagai scene utama agar autoload (GameSettings/AudioService) aktif:
##   & "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --path . res://tools/capture_ui_state.tscn
## Argumen tambahan:
##   --filter=<n>            paksa CanvasItem.texture_filter untuk semua CanvasItem (1=nearest,
##                           2=linear, 3=nearest+mipmap, 4=linear+mipmap)
##   --crop=name,x,y,w,h     potongan 6x dari hasil tangkapan <name>

const OUT_DIR := "res://zzdiag/"
const MENU_SCENE := "res://src/ui/menu/main_menu.tscn"
const GAME_SCENE := "res://src/main.tscn"

var _caps: Array[Dictionary] = []
var _filter := -1
var _suffix := ""

func _ready() -> void:
	_parse_args()
	call_deferred("_run")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			_filter = int(arg.trim_prefix("--filter="))
			_suffix = "_f" + str(_filter)
		elif arg.begins_with("--crop="):
			var parts: PackedStringArray = arg.trim_prefix("--crop=").split(",")
			if parts.size() == 5:
				_caps.append({
					"file": parts[0],
					"rect": Rect2i(int(parts[1]), int(parts[2]), int(parts[3]), int(parts[4]))
				})

func _apply_filter() -> void:
	if _filter < 0:
		return
	for node in get_tree().root.find_children("*", "CanvasItem", true, false):
		(node as CanvasItem).texture_filter = _filter as CanvasItem.TextureFilter

func _shot(file_name: String) -> void:
	for i in range(4):
		await get_tree().process_frame
	_apply_filter()
	for i in range(4):
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		return
	image.save_png(OUT_DIR + file_name + _suffix + ".png")
	print("saved: ", OUT_DIR + file_name + _suffix + ".png ", image.get_size())
	var index := 0
	for cap in _caps:
		if String(cap["file"]) != file_name:
			continue
		index += 1
		var rect: Rect2i = (cap["rect"] as Rect2i).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue
		var crop: Image = image.get_region(rect)
		var scale := 8
		crop.resize(crop.get_width() * scale, crop.get_height() * scale, Image.INTERPOLATE_NEAREST)
		var path := "%s%s%s_crop%d.png" % [OUT_DIR, file_name, _suffix, index]
		crop.save_png(path)
		print("saved: ", path, " ", crop.get_size(), " from ", rect)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var menu: Node = load(MENU_SCENE).instantiate()
	add_child(menu)
	await _shot("ui_menu")
	menu.queue_free()
	for i in range(3):
		await get_tree().process_frame

	var game: Node = load(GAME_SCENE).instantiate()
	add_child(game)
	await _shot("ui_game")

	get_tree().quit(0)
