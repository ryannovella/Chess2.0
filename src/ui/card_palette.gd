class_name CardPalette
extends RefCounted

## Palet kartu pemain beserta formula kontras WCAG 2.1.
##
## Kartu pemain yang memegang buah Putih memakai latar terang, kartu Hitam
## memakai latar gelap. Semua elemen latar depan (nama, badge, poin material,
## ikon, badge mate) TIDAK PERNAH di-hardcode: masing-masing diturunkan lewat
## formula luminansi relatif + rasio kontras WCAG, sehingga kombinasi
## "putih di atas putih" secara struktural tidak mungkin terjadi.
##
## Formula (WCAG 2.1):
##   kanal linear : c_lin = c / 12.92                     jika c <= 0.03928
##                        = ((c + 0.055) / 1.055) ^ 2.4    jika c > 0.03928
##   luminansi    : L = 0.2126 R_lin + 0.7152 G_lin + 0.0722 B_lin
##   rasio kontras: (L_terang + 0.05) / (L_gelap + 0.05)

const DARK_CARD_BG := Color(0.149, 0.141, 0.133, 0.95)
const LIGHT_CARD_BG := Color(0.949, 0.957, 0.965, 0.98)

const LIGHT_INK := Color(0.93, 0.945, 0.965, 1.0)
const DARK_INK := Color(0.11, 0.12, 0.14, 1.0)

const DARK_CARD_BORDER := Color(0.255, 0.245, 0.23, 0.6)
const LIGHT_CARD_BORDER := Color(0.706, 0.729, 0.769, 0.9)

## Ambang WCAG: 4.5 untuk teks normal, 3.0 untuk teks besar & grafik non-teks.
const AA_TEXT := 4.5
const AA_LARGE := 3.0

const MATE_GREEN := Color(0.22, 0.85, 0.45)
const MATE_RED := Color(0.95, 0.28, 0.28)

## Warna garis seluruh ikon di res://assets/ui/icons (chess.com green).
const ICON_GREEN := Color(0.506, 0.714, 0.298)

static func srgb_to_linear(channel: float) -> float:
	if channel <= 0.03928:
		return channel / 12.92
	return pow((channel + 0.055) / 1.055, 2.4)

static func relative_luminance(color: Color) -> float:
	return 0.2126 * srgb_to_linear(color.r) \
		+ 0.7152 * srgb_to_linear(color.g) \
		+ 0.0722 * srgb_to_linear(color.b)

static func contrast_ratio(a: Color, b: Color) -> float:
	var la = relative_luminance(a)
	var lb = relative_luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)

## Latar disebut terang bila lebih dekat ke putih daripada ke hitam, dinilai
## dengan rasio kontras (bukan ambang luminansi yang sewenang-wenang).
static func is_light(bg: Color) -> bool:
	return contrast_ratio(bg, Color.BLACK) > contrast_ratio(bg, Color.WHITE)

static func card_bg(is_white_card: bool) -> Color:
	return LIGHT_CARD_BG if is_white_card else DARK_CARD_BG

static func card_border(bg: Color) -> Color:
	return LIGHT_CARD_BORDER if is_light(bg) else DARK_CARD_BORDER

## Formula inti tinta: pilih kandidat dengan rasio kontras tertinggi terhadap
## latar, lalu dorong menuju hitam/putih sampai target WCAG terpenuhi.
static func ink(bg: Color, target: float = AA_TEXT) -> Color:
	var best = DARK_INK
	var best_ratio = contrast_ratio(DARK_INK, bg)
	var light_ratio = contrast_ratio(LIGHT_INK, bg)
	if light_ratio > best_ratio:
		best = LIGHT_INK
		best_ratio = light_ratio
	return _push_to_target(best, bg, target)

## Tinta sekunder (badge, sub-label): versi tinta utama yang diredupkan, tetapi
## tetap dipaksa memenuhi ambang kontras.
static func muted_ink(bg: Color, target: float = AA_TEXT) -> Color:
	var base = ink(bg, target + 2.0)
	return _push_to_target(base.lerp(bg, 0.30), bg, target)

## Warna aksen (hijau/merah mate, ikon): dipertahankan pada latar gelap, tapi
## otomatis digelapkan pada latar terang sampai memenuhi ambang.
static func accent(base_color: Color, bg: Color, target: float = AA_TEXT) -> Color:
	return _push_to_target(base_color, bg, target)

## Pengali grayscale untuk "modulate" ikon berwarna agar hue-nya tetap utuh
## namun kontrasnya memenuhi ambang grafik non-teks.
static func icon_tint(bg: Color, base_color: Color = ICON_GREEN, target: float = AA_LARGE) -> Color:
	if contrast_ratio(base_color, bg) >= target:
		return Color(1, 1, 1, 1)
	var direction = -1.0 if is_light(bg) else 1.0
	for step in range(1, 101):
		var scale = 1.0 + direction * (float(step) / 100.0)
		if scale < 0.0:
			break
		var candidate = Color(base_color.r * scale, base_color.g * scale, base_color.b * scale, 1.0)
		if contrast_ratio(candidate, bg) >= target:
			return Color(scale, scale, scale, 1.0)
	return Color(0.4, 0.4, 0.4, 1.0) if is_light(bg) else Color(1, 1, 1, 1)

static func _push_to_target(color: Color, bg: Color, target: float) -> Color:
	if contrast_ratio(color, bg) >= target:
		return color
	var toward = Color.BLACK if is_light(bg) else Color.WHITE
	for step in range(1, 101):
		var candidate = color.lerp(toward, float(step) / 100.0)
		if contrast_ratio(candidate, bg) >= target:
			return candidate
	return toward
