class_name BoardThemes
extends RefCounted

const THEMES: Dictionary = {
	"slate": {
		"name": "Modern Slate",
		"light_color": Color("#e2e8f0"), # Slate 200
		"dark_color": Color("#475569"),  # Slate 600
		"highlight_color": Color(0.2, 0.6, 1.0, 0.45), # Soft blue
		"last_move_color": Color(0.96, 0.82, 0.25, 0.42), # Warm yellow
		"check_color": Color(0.94, 0.27, 0.27, 0.65), # Red pulse
		"forbidden_color": Color(0.92, 0.2, 0.22, 0.35),
		"forbidden_cross_color": Color(0.96, 0.3, 0.3, 0.75),
		"defender_color": Color(0.22, 0.65, 1.0, 0.95)
	},
	"wood": {
		"name": "Classic Wood",
		"light_color": Color("#f0d9b5"),
		"dark_color": Color("#b58863"),
		"highlight_color": Color(0.45, 0.75, 0.25, 0.45),
		"last_move_color": Color(0.88, 0.76, 0.18, 0.45),
		"check_color": Color(0.95, 0.2, 0.2, 0.65),
		"forbidden_color": Color(0.92, 0.2, 0.22, 0.35),
		"forbidden_cross_color": Color(0.96, 0.3, 0.3, 0.75),
		"defender_color": Color(0.2, 0.65, 1.0, 0.95)
	},
	"emerald": {
		"name": "Emerald Green",
		"light_color": Color("#ffffdd"),
		"dark_color": Color("#86a666"),
		"highlight_color": Color(0.18, 0.78, 0.82, 0.45),
		"last_move_color": Color(0.95, 0.85, 0.2, 0.45),
		"check_color": Color(0.95, 0.2, 0.2, 0.65),
		"forbidden_color": Color(0.92, 0.2, 0.22, 0.35),
		"forbidden_cross_color": Color(0.96, 0.3, 0.3, 0.75),
		"defender_color": Color(0.22, 0.7, 1.0, 0.95)
	},
	"ocean": {
		"name": "Ocean Blue",
		"light_color": Color("#dbeafe"),
		"dark_color": Color("#2563eb"),
		"highlight_color": Color(0.2, 0.9, 0.6, 0.45),
		"last_move_color": Color(0.98, 0.8, 0.2, 0.45),
		"check_color": Color(0.95, 0.2, 0.2, 0.65),
		"forbidden_color": Color(0.92, 0.2, 0.22, 0.35),
		"forbidden_cross_color": Color(0.96, 0.3, 0.3, 0.75),
		"defender_color": Color(0.35, 0.85, 1.0, 0.95)
	},
	"midnight": {
		"name": "Midnight Dark",
		"light_color": Color("#334155"),
		"dark_color": Color("#0f172a"),
		"highlight_color": Color(0.5, 0.3, 0.9, 0.5),
		"last_move_color": Color(0.9, 0.6, 0.1, 0.45),
		"check_color": Color(0.95, 0.2, 0.2, 0.7),
		"forbidden_color": Color(0.92, 0.2, 0.22, 0.35),
		"forbidden_cross_color": Color(0.96, 0.35, 0.35, 0.8),
		"defender_color": Color(0.3, 0.8, 1.0, 0.95)
	}
}

static var custom_themes: Dictionary = {}

static func has_theme(theme_name: String) -> bool:
	return custom_themes.has(theme_name) or THEMES.has(theme_name)

static func get_theme_ids() -> Array[String]:
	var list: Array[String] = []
	for k in THEMES.keys():
		list.append(str(k))
	for k in custom_themes.keys():
		if not list.has(str(k)):
			list.append(str(k))
	return list

static func register_theme(theme_id: String, raw_data: Dictionary) -> void:
	custom_themes[theme_id] = derive_theme_palette(raw_data)

static func get_theme(theme_name: String) -> Dictionary:
	if custom_themes.has(theme_name):
		return custom_themes[theme_name]
	if THEMES.has(theme_name):
		return derive_theme_palette(THEMES[theme_name])
	return derive_theme_palette(THEMES["slate"])

## Derivasi otomatis & adaptif untuk palet warna tema papan
## Memastikan tema baru di masa depan selalu memiliki warna highlight & last move yang serasi,
## kontras terbaca di petak gelap/terang, dan tidak bentrok secara estetika.
static func derive_theme_palette(raw_theme: Dictionary) -> Dictionary:
	var result = raw_theme.duplicate()
	var light_col: Color = result.get("light_color", Color("#e2e8f0"))
	var dark_col: Color = result.get("dark_color", Color("#475569"))

	var dark_h: float = dark_col.h
	var dark_s: float = dark_col.s

	# 1. Adaptasi Otomatis: Last Move Highlight (Recent Move)
	if not result.has("last_move_color"):
		if dark_s < 0.18:
			# Tema Netral/Slate/Monokrom -> Amber kuning hangat bersih
			result["last_move_color"] = Color(0.96, 0.82, 0.25, 0.42)
		elif dark_h >= 0.04 and dark_h <= 0.16:
			# Tema Hangat/Kayu/Cokelat -> Emas madu hangat serasi
			result["last_move_color"] = Color(0.88, 0.76, 0.18, 0.45)
		elif dark_h > 0.16 and dark_h < 0.45:
			# Tema Hijau/Emerald -> Kuning emas cerah kontras
			result["last_move_color"] = Color(0.95, 0.85, 0.20, 0.45)
		elif dark_h >= 0.45 and dark_h <= 0.72:
			# Tema Biru/Ocean -> Kuning matahari komplementer seimbang
			result["last_move_color"] = Color(0.98, 0.80, 0.20, 0.45)
		else:
			# Tema Ungu/Merah/Midnight -> Topaz kuning hangat
			result["last_move_color"] = Color(0.92, 0.68, 0.15, 0.45)

	# 2. Adaptasi Otomatis: Selected Piece Highlight (Bidak Terpilih)
	if not result.has("highlight_color"):
		if dark_s < 0.18:
			# Slate/Netral -> Biru elektrik lembut modern
			result["highlight_color"] = Color(0.20, 0.60, 1.00, 0.45)
		elif dark_h >= 0.04 and dark_h <= 0.16:
			# Kayu/Cokelat -> Hijau daun musim semi segar
			result["highlight_color"] = Color(0.45, 0.75, 0.25, 0.45)
		elif dark_h > 0.16 and dark_h < 0.45:
			# Hijau/Emerald -> Aqua teal segar
			result["highlight_color"] = Color(0.18, 0.78, 0.82, 0.45)
		elif dark_h >= 0.45 and dark_h <= 0.72:
			# Biru/Ocean -> Cyan emerald menyala
			result["highlight_color"] = Color(0.20, 0.90, 0.60, 0.45)
		else:
			# Ungu/Midnight -> Lavender indigo bercahaya
			result["highlight_color"] = Color(0.50, 0.30, 0.90, 0.50)

	# 3. Check warning color
	if not result.has("check_color"):
		result["check_color"] = Color(0.95, 0.25, 0.25, 0.65)

	# 4. Forbidden escape square colors
	if not result.has("forbidden_color"):
		result["forbidden_color"] = Color(0.92, 0.20, 0.22, 0.32)
	if not result.has("forbidden_cross_color"):
		result["forbidden_cross_color"] = Color(0.96, 0.30, 0.32, 0.75)

	# 5. Defender / Savior piece color
	if not result.has("defender_color"):
		result["defender_color"] = Color(0.22, 0.65, 1.0, 0.95)

	return result
