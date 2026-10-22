extends SceneTree

## Audit skala tampil aset visual (AGENTS.md seksi 3). Menghitung UKURAN GAMBAR SEBENARNYA
## yang dipakai Godot saat merender, bukan sekadar ukuran node:
##  - TextureRect: bergantung pada expand_mode + stretch_mode
##  - Button: icon digambar seukuran native kecuali expand_icon = true
##  - StyleBoxTexture: hanya region tengah 9-slice yang diregangkan
## Lalu menandai aset yang di-minify (butuh mipmap) atau di-magnify (butuh sumber lebih besar).
## Pengecualian: skin tombol 9-patch (StyleBoxTexture) TIDAK boleh memakai mipmap - sembilan
## potongannya digambar pada skala berbeda sehingga sambungannya menjadi garis blur (AGENTS.md B23).
## Jalankan: & "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://tools/audit_texture_display.gd

const SCENES: Array = [
	"res://src/ui/menu/main_menu.tscn",
	"res://src/ui/hud/game_review_panel.tscn",
	"res://src/ui/hud/game_controls.tscn",
	"res://src/ui/hud/analysis_panel.tscn",
	"res://src/ui/hud/move_history.tscn",
	"res://src/ui/hud/eval_bar.tscn",
	"res://src/ui/hud/elo_slider.tscn",
	"res://src/ui/hud/review_settings_dialog.tscn",
	"res://src/ui/dialogs/pause_menu.tscn",
	"res://src/ui/dialogs/game_over_dialog.tscn",
	"res://src/ui/dialogs/promotion_dialog.tscn",
	"res://src/ui/painter/chess_painter.tscn",
	"res://src/ui/board/chess_board.tscn",
	"res://src/main.tscn"
]

var _rows: Dictionary = {}
var _layout_rows: Dictionary = {}
var _snap_rows: Dictionary = {}
var _scene_root: Node = null
var _scene_tag: String = ""

func _init() -> void:
	print("\n======= AUDIT SKALA TAMPIL ASET VISUAL (ukuran gambar nyata) =======")
	print("Autoload GameSettings: ", root.get_node_or_null("GameSettings") != null)

	for scene_path in SCENES:
		await _inspect_scene(scene_path)

	print("\n-- RINGKASAN: native vs ukuran gambar sebenarnya --")
	print("%-44s %-14s %-14s %-7s %s" % ["tekstur [peran]", "native", "digambar", "rasio", "status"])
	var keys: Array = _rows.keys()
	keys.sort()
	for key in keys:
		var r: Dictionary = _rows[key]
		var ratio: float = r["ratio"]
		var status := "OK"
		if bool(r["nine_patch"]):
			# StyleBoxTexture menggambar sembilan potongan pada skala berbeda-beda (sudut 1:1,
			# tengah sampai 0.04x), sehingga level mip dipilih per potongan dan sambungannya
			# menjadi garis blur. Skin 9-patch justru WAJIB tanpa mipmap (AGENTS.md seksi 3.1, B23).
			status = "9-patch -> level 0, tanpa mipmap"
		elif ratio < 0.75:
			status = "MINIFY -> wajib mipmap"
		elif ratio > 1.15:
			status = "MAGNIFY -> sumber kurang besar"
		print("%-44s %-14s %-14s %-7.2f %s" % [
			str(key).trim_prefix("res://"), str(r["native"]), str(r["drawn"]), ratio, status
		])
	print("\n-- NODE YANG UKURANNYA DIIKUTI TEKSTUR (menaikkan svg/scale akan menggeser layout) --")
	print("%-44s %-22s %-16s %s" % ["tekstur", "pemilik", "custom_min_size", "expand/stretch"])
	var layout_keys: Array = _layout_rows.keys()
	layout_keys.sort()
	for key in layout_keys:
		var r: Dictionary = _layout_rows[key]
		print("%-44s %-22s %-16s %s" % [
			str(r["texture"]).trim_prefix("res://"), str(r["owner"]), str(r["min_size"]), str(r["mode"])
		])
	if layout_keys.is_empty():
		print("(tidak ada)")

	print("\n-- SNAPSHOT LAYOUT (untuk diff sebelum/sesudah perubahan import) --")
	var snap_keys: Array = _snap_rows.keys()
	snap_keys.sort()
	for key in snap_keys:
		print("SNAP|%s" % str(_snap_rows[key]))

	print("\n==================================================================")
	quit()

func _inspect_scene(scene_path: String) -> void:
	if not ResourceLoader.exists(scene_path):
		return
	var packed: PackedScene = load(scene_path)
	if packed == null:
		print("[SKIP] %s gagal dimuat (butuh autoload)" % scene_path)
		return

	var holder := Control.new()
	holder.size = Vector2(720, 1280)
	root.add_child(holder)
	var inst: Node = packed.instantiate()
	holder.add_child(inst)
	for _i in range(4):
		await process_frame

	_scene_root = inst
	_scene_tag = scene_path.get_file().get_basename()
	_walk(inst)
	_scene_root = null

	holder.remove_child(inst)
	inst.free()
	holder.free()

func _walk(node: Node) -> void:
	if node is Control and _scene_root != null:
		var ctrl := node as Control
		var min_size := ctrl.get_combined_minimum_size()
		var rel := str(_scene_root.get_path_to(ctrl))
		_snap_rows["%s|%s" % [_scene_tag, rel]] = "%s|%s|min=%.2fx%.2f|size=%.2fx%.2f|tex=%s" % [
			_scene_tag, rel, min_size.x, min_size.y, ctrl.size.x, ctrl.size.y, _control_texture(ctrl)
		]

	if node is TextureRect:
		var tr := node as TextureRect
		_record_texture("TextureRect", tr.texture, _texture_rect_drawn(tr))
		if tr.texture != null and not tr.texture.resource_path.is_empty() \
				and tr.expand_mode == TextureRect.EXPAND_KEEP_SIZE \
				and tr.custom_minimum_size == Vector2.ZERO:
			_note_layout(tr.texture.resource_path, tr.get_path(), tr.custom_minimum_size,
				"expand=KEEP_SIZE stretch=%d" % tr.stretch_mode)
	elif node is Button:
		var btn := node as Button
		_record_texture("Button.icon", btn.icon, _button_icon_drawn(btn))
		if btn.icon != null and not btn.icon.resource_path.is_empty() and btn.custom_minimum_size == Vector2.ZERO:
			_note_layout(btn.icon.resource_path, btn.get_path(), btn.custom_minimum_size,
				"Button.icon expand_icon=%s" % str(btn.expand_icon))
		_record_stylebox("Button.normal", btn.get_theme_stylebox("normal"), btn.size)
		_record_stylebox("Button.hover", btn.get_theme_stylebox("hover"), btn.size)
		_record_stylebox("Button.pressed", btn.get_theme_stylebox("pressed"), btn.size)
	elif node is Sprite2D:
		var sp := node as Sprite2D
		if sp.texture != null:
			_record_texture("Sprite2D", sp.texture, sp.texture.get_size() * sp.scale)

	for child in node.get_children():
		_walk(child)

func _control_texture(ctrl: Control) -> String:
	var tex: Texture2D = null
	if ctrl is TextureRect:
		tex = (ctrl as TextureRect).texture
	elif ctrl is Button:
		tex = (ctrl as Button).icon
	if tex == null:
		return "-"
	return tex.resource_path.trim_prefix("res://")

func _note_layout(tex_path: String, owner_path: NodePath, min_size: Vector2, mode: String) -> void:
	var key := "%s|%s" % [tex_path, str(owner_path)]
	_layout_rows[key] = {"texture": tex_path, "owner": str(owner_path), "min_size": min_size, "mode": mode}

func _texture_rect_drawn(tr: TextureRect) -> Vector2:
	if tr.texture == null:
		return Vector2.ZERO
	var native := tr.texture.get_size()
	var rect := tr.size
	if rect.x <= 0.0 or rect.y <= 0.0:
		rect = tr.custom_minimum_size
	if rect.x <= 0.0 or rect.y <= 0.0:
		return native
	match tr.stretch_mode:
		TextureRect.STRETCH_SCALE:
			return rect
		TextureRect.STRETCH_TILE, TextureRect.STRETCH_KEEP, TextureRect.STRETCH_KEEP_CENTERED:
			return native
		TextureRect.STRETCH_KEEP_ASPECT, TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			return native * minf(rect.x / native.x, rect.y / native.y)
		TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			return native * maxf(rect.x / native.x, rect.y / native.y)
	return native

func _button_icon_drawn(btn: Button) -> Vector2:
	if btn.icon == null:
		return Vector2.ZERO
	var native := btn.icon.get_size()
	var max_w: float = btn.get_theme_constant("icon_max_width")
	if max_w > 0.0 and native.x > max_w:
		native = native * (max_w / native.x)
	if not btn.expand_icon:
		return native
	var rect := btn.size
	if rect.x <= 0.0 or rect.y <= 0.0:
		return native
	return native * minf(rect.x / native.x, rect.y / native.y)

func _record_texture(kind: String, tex: Texture2D, drawn: Vector2) -> void:
	if tex == null or tex.resource_path.is_empty():
		return
	if drawn.x <= 0.0 or drawn.y <= 0.0:
		return
	_store("%s [%s]" % [tex.resource_path, kind], tex.get_size(), drawn)

func _record_stylebox(kind: String, sb: StyleBox, ctrl_size: Vector2) -> void:
	if not (sb is StyleBoxTexture):
		return
	var sbt := sb as StyleBoxTexture
	var tex := sbt.texture
	if tex == null or tex.resource_path.is_empty():
		return
	if ctrl_size.x <= 0.0 or ctrl_size.y <= 0.0:
		return
	var native := tex.get_size()
	var ml := sbt.texture_margin_left
	var mr := sbt.texture_margin_right
	var mt := sbt.texture_margin_top
	var mb := sbt.texture_margin_bottom
	# Godot mengecilkan margin secara proporsional bila kontrol lebih kecil dari margin.
	if ml + mr > ctrl_size.x:
		var f := ctrl_size.x / maxf(ml + mr, 0.001)
		ml *= f
		mr *= f
	if mt + mb > ctrl_size.y:
		var f := ctrl_size.y / maxf(mt + mb, 0.001)
		mt *= f
		mb *= f
	var src_mid := Vector2(maxf(native.x - (sbt.texture_margin_left + sbt.texture_margin_right), 1.0),
		maxf(native.y - (sbt.texture_margin_top + sbt.texture_margin_bottom), 1.0))
	var dst_mid := Vector2(maxf(ctrl_size.x - (ml + mr), 1.0), maxf(ctrl_size.y - (mt + mb), 1.0))
	# Region tengah adalah bagian yang paling parah dimampatkan; itu penentu kekasaran tekstur.
	_store("%s [%s]" % [tex.resource_path, kind], src_mid, dst_mid, true)

func _store(key: String, native: Vector2, drawn: Vector2, is_nine_patch: bool = false) -> void:
	var ratio := minf(drawn.x / native.x, drawn.y / native.y)
	var prev: Dictionary = _rows.get(key, {})
	if prev.is_empty() or ratio < float(prev["ratio"]):
		_rows[key] = {"native": native, "drawn": drawn, "ratio": ratio, "nine_patch": is_nine_patch}
