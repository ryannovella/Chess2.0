extends SceneTree

const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessMove = preload("res://src/core/chess_move.gd")
const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const EngineService = preload("res://src/engine/engine_service.gd")
const UCIClient = preload("res://src/engine/uci_client.gd")
const GameReviewService = preload("res://src/core/game_review_service.gd")
const CoachExplanationGenerator = preload("res://src/core/coach_explanation_generator.gd")
const ReviewBadgeOverlay = preload("res://src/ui/board/review_badge_overlay.gd")
const BadgeOverlay = preload("res://src/ui/board/badge_overlay.gd")
const GameReviewPanel = preload("res://src/ui/hud/game_review_panel.gd")
const OpeningBook = preload("res://src/core/opening_book.gd")
const ReviewRules = preload("res://src/core/review_rules.gd")
const ReviewEngineSession = preload("res://src/engine/review_engine_session.gd")
const TactileStyles = preload("res://src/theme/tactile_styles.gd")
const CapturedPiecesView = preload("res://src/ui/hud/captured_pieces_view.gd")
const CardPalette = preload("res://src/ui/card_palette.gd")
const RepertoireService = preload("res://src/core/repertoire/repertoire_service.gd")
const RepertoireTree = preload("res://src/core/repertoire/repertoire_tree.gd")
const SRSEngine = preload("res://src/core/repertoire/srs_engine.gd")
const RepertoireNode = preload("res://src/core/repertoire/repertoire_node.gd")
const OpeningTrainerScene = preload("res://src/ui/trainer/opening_trainer.tscn")

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

## Beberapa unit test memanggil setter GameSettings yang menulis settings.json
## milik pemain (termasuk pengacakan sisi "random"). Cadangkan sebelum dan
## pulihkan sesudah, supaya suite pengujian tidak pernah mengubah konfigurasi
## nyata pemain.
func _backup_settings_file() -> String:
	var GSClass = load("res://src/config/game_settings.gd")
	var path = GSClass.get_settings_path()
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)
	return ""

func _restore_settings_file(backup: String) -> void:
	var GSClass = load("res://src/config/game_settings.gd")
	var path = GSClass.get_settings_path()
	if backup.is_empty():
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
		return
	var f = FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(backup)
		f.flush()

func _init() -> void:
	print("\n=======================================================")
	print("          CHESS 2.0 - AUTOMATED TEST SUITE             ")
	print("=======================================================\n")

	var start_time = Time.get_ticks_msec()

	# 1. Unit Tests: ChessMove Structure & Interop
	test_chess_move_class()

	# 2. Unit Tests: FEN Import/Export Fidelity
	test_fen_fidelity()

	# 3. Unit Tests: Aturan Catur Khusus (Rokade, En Passant, Promosi)
	test_castling_rules()
	test_en_passant_rules()
	test_promotion_rules()

	# 4. Unit Tests: Kondisi Akhir Permainan (Skakmat & Remis Resmi)
	test_checkmate_detection()
	test_stalemate_detection()
	test_threefold_repetition()
	test_insufficient_material()

	# 5. Unit Tests: Skala Kesulitan AI ELO & Jeda Berpikir Alami
	test_elo_difficulty_scaling()
	test_maia_move_history_plumbing()
	test_ai_delay_timing()

	# 6. Unit Tests: Dynamic Role Mapping Arrows (Player vs Opponent)
	test_dynamic_arrow_settings()

	# 7. Unit Tests: PieceView & Animasi Bidak
	test_piece_animations()

	# 8. Unit Tests: Play As Side Selection & Piece Set Assets
	test_side_selection_and_assets()

	# 9. Unit Tests: Forbidden Squares & Savior Piece Highlights on Check (Pattern Checkmate)
	test_forbidden_and_defender_highlights()

	# 10. Unit Tests: Local Settings Persistence (user://settings.json)
	test_local_settings_persistence()

	# 11. Unit Tests: Victory Celebration & King Topple
	test_victory_celebration()

	# 12. Unit Tests: Engine Assist & Loading Bar Invariants
	test_engine_assist_lifecycle()

	# 13. Unit Tests: UCI Protocol & Parser Optimization
	test_uci_parser()

	# 14. Unit Tests: Game Review & AI Coach Explanation
	test_game_review_and_coach()

	# 15. Unit Tests: Game Review Overhaul, Opening Book & Vector Assets Invariants
	test_game_review_overhaul_invariants()

	# 15b. Layout Guard: lantai tinggi segmen Game Review (butuh frame, jadi async)
	await test_review_layout_floor()

	# 15c. Standar kualitas aset visual (anti-kasar & anti-pixelated)
	await test_visual_asset_quality_standards()

	# 15d. Captured Pieces & Material Advantage Points (Chess.com Style)
	test_captured_pieces_and_material_points()

	# 15e. Kartu pemain terang/gelap + formula kontras WCAG
	test_player_card_contrast_formula()

	# 15f. Unit Tests: Opening Repertoire & Spaced Repetition System (Chessreps Parity)
	test_opening_repertoire_and_srs()

	# 16. Performance Test: Perft Suite (Initial & Kiwipete)
	test_perft_suite()

	var elapsed = (Time.get_ticks_msec() - start_time) / 1000.0

	print("\n-------------------------------------------------------")
	print("HASIL PENGUJIAN: %d Total | %d LULUS (PASS) | %d GAGAL (FAIL)" % [total_tests, passed_tests, failed_tests])
	print("Waktu Eksekusi: %.3f detik" % elapsed)
	print("-------------------------------------------------------")

	if failed_tests == 0:
		print(">> SEMUA PENGUJIAN LULUS DENGAN SEMPURNA! (SUCCESS)\n")
		quit(0)
	else:
		print(">> DITEMUKAN PENGUJIAN YANG GAGAL! (FAILURE)\n")
		quit(1)

func assert_true(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		print("  [FAIL] %s <--- FAILED" % test_name)

func assert_equal(actual: Variant, expected: Variant, test_name: String) -> void:
	total_tests += 1
	if actual == expected:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		print("  [FAIL] %s: didapat '%s', diharapkan '%s'" % [test_name, str(actual), str(expected)])

## Guard teks: label UI tidak boleh mengandung karakter non-ASCII. Karakter rusak
## (mojibake hasil salah decode UTF-8 seperti "â˜…") pernah lolos ke badge coach dan
## tampil sebagai sampah di layar, jadi setiap label diperiksa di sini.
func _is_clean_ascii(text: String) -> bool:
	for i in range(text.length()):
		if text.unicode_at(i) > 127:
			return false
	return true

# -----------------------------------------------------------------
# 17. Standar Kualitas Aset Visual (anti-kasar & anti-pixelated)
# -----------------------------------------------------------------
## Setiap penambahan / penyesuaian / pemeliharaan aset visual WAJIB lolos kategori ini
## (AGENTS.md seksi 3). Kasus nyata yang sudah pernah terjadi: lencana klasifikasi
## 256 px digambar 16-40 px TANPA mipmap sehingga tepinya kasar, tombol tactile
## 128x64 dimampatkan sampai 0.19x tanpa mipmap, bidak horsey diraster 2400x2400
## (30 MB VRAM per bidak), dan nilai import font di luar rentang enum.
func test_visual_asset_quality_standards() -> void:
	print("\n[Kategori 17: Standar Kualitas Aset Visual (anti-kasar & anti-pixelated)]")

	# 1. Semua tekstur raster di res://assets wajib punya rantai mipmap, KECUALI skin
	#    tombol 9-patch. StyleBoxTexture menggambar sembilan potongan pada skala yang
	#    berbeda jauh (sudut 1:1, area tengah sampai 0.19x), sehingga level mip dipilih
	#    per potongan: sambungan antar potongan menjadi garis blur dan aksen tipis
	#    (garis bawah tab hijau) pudar - terukur mip (107,145,66) vs level 0 (117,161,71).
	#    Skin 9-patch karena itu harus disampel di level 0 dan tidak boleh punya mipmap.
	var nine_patch_skins := [
		"assets/ui/tactile_gray_active.png",
		"assets/ui/tactile_gray_active_hover.png",
		"assets/ui/tactile_gray_active_pressed.png",
		"assets/ui/tactile_gray_hover.png",
		"assets/ui/tactile_gray_normal.png",
		"assets/ui/tactile_gray_pressed.png",
		"assets/ui/tactile_green_hover.png",
		"assets/ui/tactile_green_normal.png",
		"assets/ui/tactile_green_pressed.png",
	]
	var rasters: Array = []
	_collect_visual_assets("res://assets", rasters, ["png", "jpg", "jpeg", "webp"])
	assert_true(rasters.size() > 0, "Audit menemukan berkas raster di res://assets")
	var raster_without_mipmap: Array = []
	for path in rasters:
		if _texture_mipmap_count(path) <= 1:
			raster_without_mipmap.append(path.trim_prefix("res://"))
	raster_without_mipmap.sort()
	assert_equal(raster_without_mipmap, nine_patch_skins,
		"Hanya 9 skin tombol 9-patch yang tanpa mipmap, %d raster lainnya punya mipmap chain" % rasters.size())

	# 2. Ikon SVG juga diraster saat import, jadi mipmap wajib dengan alasan yang sama.
	var vectors: Array = []
	_collect_visual_assets("res://assets/ui", vectors, ["svg"])
	var vector_without_mipmap: Array = []
	for path in vectors:
		if _texture_mipmap_count(path) <= 1:
			vector_without_mipmap.append(path.trim_prefix("res://"))
	assert_true(vector_without_mipmap.is_empty(),
		"Semua %d ikon SVG punya mipmap chain (tanpa mipmap: %s)" % [vectors.size(), str(vector_without_mipmap)])

	# 3. Sumber raster ikon harus cukup untuk ukuran tampilnya (18-32 px), termasuk
	#    cadangan untuk skala kanvas / layar high-DPI.
	var icons: Array = []
	_collect_visual_assets("res://assets/ui/icons", icons, ["svg"])
	for path in icons:
		var icon_size: Vector2 = load(path).get_size()
		assert_true(icon_size.x >= 24.0 and icon_size.y >= 24.0,
			"Ikon %s punya sumber >= 24 px agar tidak blur saat diperbesar (raster %d px)" % [path.get_file(), int(icon_size.x)])

	# 4. Bidak: 240 px menjamin tajam pada tampilan 70-116 px + layar high-DPI, dan
	#    512 px adalah plafon agar VRAM tidak membengkak (horsey sempat 2400 px).
	var pieces: Array = []
	_collect_visual_assets("res://assets/pieces", pieces, ["svg"])
	assert_true(pieces.size() >= 36, "Audit menemukan seluruh berkas bidak SVG (%d berkas)" % pieces.size())
	var pieces_out_of_budget: Array = []
	for path in pieces:
		var piece_size: Vector2 = load(path).get_size()
		if piece_size.x < 240.0 or piece_size.x > 512.0:
			pieces_out_of_budget.append("%s=%dpx" % [path.get_file(), int(piece_size.x)])
	assert_true(pieces_out_of_budget.is_empty(),
		"Semua bidak diraster dalam rentang 240-512 px (di luar rentang: %s)" % str(pieces_out_of_budget))

	# 5. Nilai import font harus berada di dalam rentang enum TextServer. hinting=3 dan
	#    subpixel_positioning=4 pernah tertulis di .import (di luar rentang) sehingga
	#    engine diam-diam memakai nilai default, bukan yang tertulis. Daftar ini hanya
	#    memuat font yang benar-benar dipakai theme/kode: theme_modern.tres memakai
	#    ChessSans Regular/Bold/ExtraBold, dan review_badge_overlay.gd memakai
	#    Montserrat-Regular sebagai fallback. Roboto/OpenSans sudah dihapus sebagai orphan.
	var font_files := [
		"ChessSans-Regular", "ChessSans-Bold", "ChessSans-ExtraBold", "Montserrat-Regular"
	]
	for font_name in font_files:
		var import_path := "res://assets/fonts/%s.ttf.import" % font_name
		assert_true(FileAccess.file_exists(import_path), "Berkas import font %s tersedia" % import_path.get_file())
		var import_text := FileAccess.get_file_as_string(import_path)
		var hinting := _read_import_int(import_text, "hinting")
		var subpixel := _read_import_int(import_text, "subpixel_positioning")
		assert_true(hinting >= 0 and hinting <= 2,
			"Font %s hinting=%d berada dalam rentang enum (0..2)" % [font_name, hinting])
		assert_true(subpixel >= 0 and subpixel <= 3,
			"Font %s subpixel_positioning=%d berada dalam rentang enum (0..3)" % [font_name, subpixel])

	# 6. Ukuran intrinsik ikon Button.icon menambah tinggi minimum tombol. Menaikkan
	#    svg/scale ikon yang juga dipakai Button.icon (palette/pause/people) terukur
	#    menaikkan toolbar GameControls dan TopBar/BtnPause dari 48 px menjadi 72 px,
	#    yang mendorong MainLayout/GameLayout membengkak 1201 -> 1225 px.
	var controls_scene = load("res://src/ui/hud/game_controls.tscn")
	var controls_inst = controls_scene.instantiate()
	root.add_child(controls_inst)
	for _i in range(3):
		await process_frame
	var toolbar: Node = controls_inst.get_node_or_null("Margin/Toolbar")
	assert_true(toolbar != null, "Toolbar GameControls ter-resolusi untuk guard tinggi tombol")
	if toolbar != null:
		var too_tall: Array = []
		for child in toolbar.get_children():
			if child is Button:
				var btn_height: float = (child as Button).get_combined_minimum_size().y
				if btn_height > 56.0:
					too_tall.append("%s=%.0fpx" % [child.name, btn_height])
		assert_true(too_tall.is_empty(),
			"Tinggi minimum tombol toolbar tetap <= 56 px (melebihi: %s) - sumber ikon Button.icon terlalu besar" % str(too_tall))
	controls_inst.free()

	# 7. Pratinjau papan kecil menggambar bidak 270-400 px ke petak ~50 px, jadi
	#    filternya harus eksplisit linear + mipmap, bukan mewarisi container.
	var preview_script = load("res://src/ui/menu/mini_board_preview.gd")
	var preview_inst = preview_script.new()
	preview_inst._ready()
	assert_equal(preview_inst.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
		"MiniBoardPreview memakai LINEAR_WITH_MIPMAPS eksplisit untuk bidak yang diperkecil")
	preview_inst.free()

## Mengumpulkan berkas aset secara rekursif berdasarkan ekstensi (huruf kecil).
func _collect_visual_assets(dir_path: String, out: Array, extensions: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			if not entry.begins_with("."):
				_collect_visual_assets(full_path, out, extensions)
		elif extensions.has(entry.get_extension().to_lower()):
			out.append(full_path)
		entry = dir.get_next()
	dir.list_dir_end()

## Jumlah level mipmap tekstur; 0/1 berarti tidak punya rantai mipmap.
func _texture_mipmap_count(path: String) -> int:
	var tex: Texture2D = load(path)
	if tex == null:
		return 0
	if tex is CompressedTexture2D:
		var img: Image = (tex as CompressedTexture2D).get_image()
		if img != null:
			return img.get_mipmap_count()
	return 0

## Membaca nilai integer dari baris "key=value" di berkas .import.
func _read_import_int(import_text: String, key: String) -> int:
	for line in import_text.split("\n"):
		var trimmed: String = line.strip_edges()
		if trimmed.begins_with(key + "="):
			return int(trimmed.split("=")[1])
	return -1

# -----------------------------------------------------------------
# 1. Test ChessMove Class
# -----------------------------------------------------------------
func test_chess_move_class() -> void:
	print("[Kategori 1: Class ChessMove & Kompatibilitas]")
	var mv = ChessMove.new("e2", "e4")
	assert_equal(mv.from_sq, "e2", "ChessMove from_sq properti")
	assert_equal(mv.to_sq, "e4", "ChessMove to_sq properti")
	assert_equal(mv.from_idx, 12, "ChessMove from_idx konversi")
	assert_equal(mv.to_idx, 28, "ChessMove to_idx konversi")
	assert_equal(mv.to_uci(), "e2e4", "ChessMove to_uci() konversi")

	# Uji bracket indexing compatibility
	assert_equal(mv["from"], "e2", "ChessMove bracket indexing mv['from']")
	assert_equal(mv["to"], "e4", "ChessMove bracket indexing mv['to']")
	assert_equal(mv["promotion"], ChessTypes.PieceType.NONE, "ChessMove bracket indexing mv['promotion']")

	# Uji promosi
	var promo_mv = ChessMove.new("e7", "e8", ChessTypes.PieceType.QUEEN)
	assert_equal(promo_mv.to_uci(), "e7e8q", "ChessMove to_uci() dengan promosi Ratu")

	# Uji to_dict dan from_dict
	var d = mv.to_dict()
	assert_equal(d["from"], "e2", "ChessMove to_dict()['from']")
	var mv_from_d = ChessMove.from_dict(d)
	assert_true(mv.equals(mv_from_d), "ChessMove from_dict() kesetaraan objek")

# -----------------------------------------------------------------
# 2. Test FEN Fidelity
# -----------------------------------------------------------------
func test_fen_fidelity() -> void:
	print("\n[Kategori 2: Serialisasi FEN]")
	var fens = [
		"rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
		"r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1",
		"8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1",
		"r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
	]
	for fen in fens:
		var state = ChessBoardState.new(fen)
		assert_equal(state.to_fen(), fen, "FEN round-trip: %s" % fen.substr(0, 30))

# -----------------------------------------------------------------
# 3. Test Aturan Catur Khusus
# -----------------------------------------------------------------
func test_castling_rules() -> void:
	print("\n[Kategori 3.1: Aturan Rokade]")
	# Posisi bersih untuk rokade putih
	var state = ChessBoardState.new("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	var moves = ChessMoveGenerator.get_legal_moves(state)
	var has_kingside = false
	var has_queenside = false
	for m in moves:
		if m.from_sq == "e1" and m.to_sq == "g1" and m.is_castling:
			has_kingside = true
		if m.from_sq == "e1" and m.to_sq == "c1" and m.is_castling:
			has_queenside = true
	assert_true(has_kingside, "Rokade Kingside Putih (e1-g1) valid")
	assert_true(has_queenside, "Rokade Queenside Putih (e1-c1) valid")

	# Rokade terhalang skak pada petak lintasan f1
	var blocked_state = ChessBoardState.new("r3k2r/8/8/8/8/5r2/8/R3K2R w KQkq - 0 1")
	var blocked_moves = ChessMoveGenerator.get_legal_moves(blocked_state)
	var kingside_blocked = true
	for m in blocked_moves:
		if m.from_sq == "e1" and m.to_sq == "g1":
			kingside_blocked = false
	assert_true(kingside_blocked, "Rokade batal jika petak lintasan diserang (f1 attacked)")

func test_en_passant_rules() -> void:
	print("\n[Kategori 3.2: Aturan En Passant]")
	# Posisi di mana pion putih di e5 bisa memakan pion hitam di d5 yang baru saja maju 2 petak (ep square d6)
	var state = ChessBoardState.new("rnbqkbnr/ppp1pppp/8/3pP3/8/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 1")
	var moves = ChessMoveGenerator.get_legal_moves(state, "e5")
	var has_ep = false
	var ep_move: ChessMove = null
	for m in moves:
		if m.to_sq == "d6" and m.is_en_passant:
			has_ep = true
			ep_move = m
	assert_true(has_ep, "Langkah En Passant (e5xd6) terdeteksi legal")

	if ep_move:
		ChessMoveGenerator.apply_move_unchecked(state, ep_move)
		assert_equal(state.get_piece("d5"), null, "Pion lawan di d5 terhapus setelah en passant")
		assert_true(state.get_piece("d6") != null, "Pion pemakan menempati petak d6")

func test_promotion_rules() -> void:
	print("\n[Kategori 3.3: Aturan Promosi Pion]")
	# Pion putih di a7 siap promosi di a8
	var state = ChessBoardState.new("8/P7/8/8/8/8/8/4K2k w - - 0 1")
	var moves = ChessMoveGenerator.get_legal_moves(state, "a7")
	assert_equal(moves.size(), 4, "Pion di rank 7 memiliki tepat 4 opsi promosi (Q, R, B, N)")
	var promos = []
	for m in moves:
		promos.append(m.promotion)
	assert_true(promos.has(ChessTypes.PieceType.QUEEN), "Tersedia opsi promosi Ratu")
	assert_true(promos.has(ChessTypes.PieceType.ROOK), "Tersedia opsi promosi Benteng")
	assert_true(promos.has(ChessTypes.PieceType.BISHOP), "Tersedia opsi promosi Gajah")
	assert_true(promos.has(ChessTypes.PieceType.KNIGHT), "Tersedia opsi promosi Kuda")

# -----------------------------------------------------------------
# 4. Test Skakmat & Remis Resmi
# -----------------------------------------------------------------
func test_checkmate_detection() -> void:
	print("\n[Kategori 4.1: Deteksi Skakmat (Checkmate)]")
	# Fool's Mate (1. f3 e5 2. g4 Qh4#)
	var state = ChessBoardState.new("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
	assert_true(ChessMoveGenerator.is_in_check(state, state.turn), "Raja dalam keadaan skak")
	assert_true(ChessMoveGenerator.is_checkmate(state), "Deteksi Fool's Mate skakmat")
	assert_true(ChessMoveGenerator.is_game_over(state), "is_game_over bernilai true pada skakmat")

func test_stalemate_detection() -> void:
	print("\n[Kategori 4.2: Deteksi Stalemate (Remis Buntu)]")
	# Posisi stalemate: King hitam di a8 tidak dalam skak, tapi tidak punya langkah legal
	var state = ChessBoardState.new("k7/8/1Q6/8/8/8/8/4K3 b - - 0 1")
	assert_true(not ChessMoveGenerator.is_in_check(state, state.turn), "Raja tidak dalam skak pada stalemate")
	assert_true(ChessMoveGenerator.is_stalemate(state), "Deteksi Stalemate remis")
	assert_true(ChessMoveGenerator.is_game_over(state), "is_game_over bernilai true pada stalemate")

func test_threefold_repetition() -> void:
	print("\n[Kategori 4.3: Deteksi Threefold Repetition (Remis 3x Posisi)]")
	var state = ChessBoardState.new()
	# Jalankan pengulangan langkah Kuda:
	# 1. Nf3 Nf6 2. Ng1 Ng8 (posisi ke-2) 3. Nf3 Nf6 4. Ng1 Ng8 (posisi ke-3)
	var move_seq = [
		["g1", "f3"], ["g8", "f6"],
		["f3", "g1"], ["f6", "g8"],
		["g1", "f3"], ["f6", "g8"],
		["f3", "g1"], ["g8", "f6"]
	]
	# Uji manual repetition counter
	var test_state = ChessBoardState.new()
	var key0 = test_state.get_position_key()
	assert_true(test_state.position_history.has(key0), "Posisi awal tercatat di history")

	# Tambahkan key yang sama 2 kali lagi untuk simulasi tepat
	test_state.position_history.append(key0)
	test_state.position_history.append(key0)
	assert_true(ChessMoveGenerator.is_threefold_repetition(test_state), "Deteksi Threefold Repetition aktif saat posisi berulang 3 kali")
	assert_true(ChessMoveGenerator.is_game_over(test_state), "is_game_over true pada Threefold Repetition")

func test_insufficient_material() -> void:
	print("\n[Kategori 4.4: Deteksi Insufficient Material]")
	# Raja vs Raja
	var kvk = ChessBoardState.new("8/8/8/4k3/8/8/4K3/8 w - - 0 1")
	assert_true(ChessMoveGenerator.is_insufficient_material(kvk), "Remis: Raja vs Raja")

	# Raja + Kuda vs Raja
	var knvk = ChessBoardState.new("8/8/8/4k3/8/5N2/4K3/8 w - - 0 1")
	assert_true(ChessMoveGenerator.is_insufficient_material(knvk), "Remis: Raja + Kuda vs Raja")

	# Raja + Gajah vs Raja
	var kbvk = ChessBoardState.new("8/8/8/4k3/8/5B2/4K3/8 w - - 0 1")
	assert_true(ChessMoveGenerator.is_insufficient_material(kbvk), "Remis: Raja + Gajah vs Raja")

	# Raja + Ratu vs Raja (Materi Cukup)
	var kqvk = ChessBoardState.new("8/8/8/4k3/8/5Q2/4K3/8 w - - 0 1")
	assert_true(not ChessMoveGenerator.is_insufficient_material(kqvk), "Bukan remis: Raja + Ratu vs Raja")

# -----------------------------------------------------------------
# 5. Test Perft Suite (FIDE Official Benchmark)
# -----------------------------------------------------------------
func test_perft_suite() -> void:
	print("\n[Kategori 5: Perft Benchmark Suite (Pembangkitan Langkah Catur)]")

	# Posisi Awal (Initial Position)
	var init_state = ChessBoardState.new()
	var d1 = ChessMoveGenerator.perft(init_state, 1)
	assert_equal(d1, 20, "Perft Posisi Awal Depth 1 (harus 20 nodes)")

	var d2 = ChessMoveGenerator.perft(init_state, 2)
	assert_equal(d2, 400, "Perft Posisi Awal Depth 2 (harus 400 nodes)")

	var d3 = ChessMoveGenerator.perft(init_state, 3)
	assert_equal(d3, 8902, "Perft Posisi Awal Depth 3 (harus 8,902 nodes)")

	# Posisi Kiwipete (Benchmark posisi penuh pin, skak, rokade, en-passant)
	var kiwipete = ChessBoardState.new("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
	var k_d1 = ChessMoveGenerator.perft(kiwipete, 1)
	assert_equal(k_d1, 48, "Perft Kiwipete Depth 1 (harus 48 nodes)")

	var k_d2 = ChessMoveGenerator.perft(kiwipete, 2)
	assert_equal(k_d2, 2039, "Perft Kiwipete Depth 2 (harus 2,039 nodes)")

func test_elo_difficulty_scaling() -> void:
	print("\n[Kategori 5: Skala Kesulitan & Kalibrasi Elo Bot]")

	# 1. Batas minimum ELO adalah 200
	var clamped_min = clampi(100, 200, 3000)
	assert_equal(clamped_min, 200, "Batas minimum ELO adalah 200")

	# 2. Ambang superhuman: di bawahnya policy manusia Maia-3 yang melangkah
	assert_equal(EngineService.SUPERNUMAN_ELO, 2800, "Ambang Superhuman tetap 2800")
	assert_true(2799 < EngineService.SUPERNUMAN_ELO, "ELO 2799 masih dilayani policy manusia")
	assert_true(2800 >= EngineService.SUPERNUMAN_ELO, "ELO 2800 beralih ke Stockfish full power")

	# 3. Kalibrasi 1:1 - label ELO yang dilihat pemain sama dengan pengkondisian
	#    model, tanpa penjepitan diam-diam di tengah rentang.
	for elo in [200, 800, 1400, 2000, 2400, 2799]:
		var mapped = clampi(elo, EngineService.MAIA_ELO_MIN, EngineService.MAIA_ELO_MAX)
		assert_equal(mapped, elo, "ELO %d diteruskan apa adanya ke Maia-3 (kalibrasi 1:1)" % elo)
	assert_equal(EngineService.MAIA_ELO_MAX, EngineService.SUPERNUMAN_ELO - 1,
		"Plafon pengkondisian Maia-3 tepat di bawah ambang Superhuman (tidak ada celah label)")
	assert_equal(clampi(100, EngineService.MAIA_ELO_MIN, EngineService.MAIA_ELO_MAX), 200,
		"ELO di bawah 200 dijepit ke lantai model")
	assert_equal(clampi(5000, EngineService.MAIA_ELO_MIN, EngineService.MAIA_ELO_MAX), 2799,
		"ELO di atas plafon dijepit ke 2799, bukan dibiarkan tak terkondisi")

	# 4. Distribusi manusia tidak diwarping: temperature & TopP dikunci di 1.0
	assert_equal(EngineService.MAIA_TEMPERATURE, 1.0,
		"Temperature dikunci 1.0 agar sampel setia dari distribusi policy manusia")
	assert_equal(EngineService.MAIA_TOP_P, 1.0,
		"TopP dikunci 1.0 agar langkah manusia berekor tipis tidak dipangkas")

	# 5. Blunder buatan sudah dibuang: tidak ada lagi pemilih langkah heuristik
	var probe = EngineService.new()
	assert_true(not probe.has_method("select_move_for_elo"),
		"Pemilih blunder heuristik select_move_for_elo sudah dibuang dari EngineService")
	assert_true(probe.has_method("build_position_command"),
		"EngineService mengekspos perintah position beriwayat")
	assert_true(probe.has_method("set_move_history"),
		"EngineService menerima riwayat langkah dari koordinator")
	probe.free()

func test_maia_move_history_plumbing() -> void:
	print("\n[Kategori 5.3: Konteks Temporal Maia-3 (Riwayat Langkah UCI)]")

	var es = EngineService.new()

	# 1. Tanpa riwayat -> FEN tunggal (perilaku lama tetap aman)
	es.set_move_history("", PackedStringArray())
	assert_equal(es.build_position_command("8/8/8/8/8/8/8/K6k w - - 0 1"),
		"position fen 8/8/8/8/8/8/8/K6k w - - 0 1",
		"Tanpa riwayat, perintah position hanya membawa FEN tunggal")

	# 2. Dengan riwayat -> FEN awal + seluruh langkah, agar 8 slot Chessformer terisi
	var start_fen = ChessBoardState.DEFAULT_FEN
	var moves := PackedStringArray(["e2e4", "e7e5", "g1f3", "b8c6"])
	es.set_move_history(start_fen, moves)
	var cmd = es.build_position_command("r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 2 3")
	assert_true(cmd.begins_with("position fen %s moves " % start_fen),
		"Perintah position memuat FEN awal permainan")
	assert_true(cmd.ends_with("e2e4 e7e5 g1f3 b8c6"),
		"Seluruh langkah dikirim berurutan sebagai riwayat: %s" % cmd)
	assert_equal(cmd.split(" ").size(), 1 + 1 + 6 + 1 + 4,
		"Format perintah persis `position fen <6 field> moves <n langkah>`")

	# 3. Riwayat satu langkah tetap valid
	es.set_move_history(start_fen, PackedStringArray(["e2e4"]))
	assert_true(es.build_position_command("x").ends_with("moves e2e4"),
		"Riwayat satu langkah tetap dikirim")

	# 4. Langkah kosong pada daftar tidak menghasilkan perintah rusak
	es.set_move_history(start_fen, PackedStringArray())
	assert_equal(es.build_position_command("FEN_DISINI"), "position fen FEN_DISINI",
		"Daftar langkah kosong jatuh kembali ke FEN tunggal, bukan `moves ` kosong")
	es.free()

func test_ai_delay_timing() -> void:
	print("\n[Kategori 5.2: Pacing & Jeda Waktu AI Alami (Human Feel)]")

	# 1. Mode Instant harus selalu 0 detik
	var d_instant = EngineService.calculate_human_delay(ChessBoardState.DEFAULT_FEN, 1200, "", "instant")
	assert_equal(d_instant, 0.0, "Mode Instant menghasilkan jeda 0.0 detik")

	# 2. Mode Fast harus berada dalam rentang 0.35s s/d 0.65s
	var d_fast = EngineService.calculate_human_delay(ChessBoardState.DEFAULT_FEN, 1200, "", "fast")
	assert_true(d_fast >= 0.35 and d_fast <= 0.65, "Mode Fast menghasilkan jeda cepat (0.35s - 0.65s): %.2fs" % d_fast)

	# 3. Mode Relaxed harus berada dalam rentang santai 2.2s s/d 3.8s
	var d_relaxed = EngineService.calculate_human_delay(ChessBoardState.DEFAULT_FEN, 1200, "", "relaxed")
	assert_true(d_relaxed >= 2.2 and d_relaxed <= 3.8, "Mode Relaxed menghasilkan jeda santai (2.2s - 3.8s): %.2fs" % d_relaxed)

	# 4. Mode Custom harus mengikuti nilai custom yang diatur
	var d_custom = EngineService.calculate_human_delay(ChessBoardState.DEFAULT_FEN, 1200, "", "custom", 2.0)
	assert_true(d_custom >= 1.7 and d_custom <= 2.3, "Mode Custom 2.0s menghasilkan rentang valid: %.2fs" % d_custom)

	# 5. Mode Natural (Feel Alami):
	# A. Pembukaan (Opening move) -> respon cepat
	var opening_fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
	var d_opening = EngineService.calculate_human_delay(opening_fen, 1500, "", "natural")
	assert_true(d_opening >= 0.3 and d_opening <= 1.3, "Mode Natural di pembukaan berlangsung lincah: %.2fs" % d_opening)

	# B. Sedang diskak (In check) -> berpikir lebih hati-hati
	var check_fen = "rnb1kbnr/pppp1ppp/8/4p3/5PPq/8/PPPPP2P/RNBQKBNR w KQkq - 1 3"
	var d_check = EngineService.calculate_human_delay(check_fen, 1500, "", "natural")
	assert_true(d_check >= 1.0, "Mode Natural saat kena skak berpikir lebih teliti: %.2fs" % d_check)

func test_dynamic_arrow_settings() -> void:
	print("\n[Kategori 6: Dynamic Role Mapping Panah (Player vs Opponent)]")
	var settings_backup = _backup_settings_file()
	var GS = root.get_node_or_null("GameSettings") if root else null
	var owns_gs = false
	if GS == null:
		var GSClass = load("res://src/config/game_settings.gd")
		GS = GSClass.new()
		GS._ready()
		owns_gs = true

	# 1. Test saat player memilih Putih
	GS.chosen_side = "white"
	GS.player_color = ChessTypes.PieceColor.WHITE
	GS.show_white_engine_arrows = true
	GS.show_black_engine_arrows = false
	GS.show_white_threat_arrows = true
	GS.show_black_threat_arrows = false

	assert_equal(GS.get_player_engine_arrows(), true, "Player Putih: get_player_engine_arrows() == true")
	assert_equal(GS.get_opponent_engine_arrows(), false, "Player Putih: get_opponent_engine_arrows() == false")
	assert_equal(GS.get_player_threat_arrows(), true, "Player Putih: get_player_threat_arrows() == true")
	assert_equal(GS.get_opponent_threat_arrows(), false, "Player Putih: get_opponent_threat_arrows() == false")

	# Mutasi via helper
	GS.set_player_engine_arrows(false)
	assert_equal(GS.show_white_engine_arrows, false, "Player Putih: set_player_engine_arrows(false) mengubah show_white_engine_arrows")
	GS.set_opponent_engine_arrows(true)
	assert_equal(GS.show_black_engine_arrows, true, "Player Putih: set_opponent_engine_arrows(true) mengubah show_black_engine_arrows")

	# 2. Test saat player memilih Hitam
	GS.chosen_side = "black"
	GS.player_color = ChessTypes.PieceColor.BLACK
	GS.show_white_engine_arrows = false
	GS.show_black_engine_arrows = true
	GS.show_white_threat_arrows = false
	GS.show_black_threat_arrows = true

	assert_equal(GS.get_player_engine_arrows(), true, "Player Hitam: get_player_engine_arrows() membaca panah hitam")
	assert_equal(GS.get_opponent_engine_arrows(), false, "Player Hitam: get_opponent_engine_arrows() membaca panah putih")
	assert_equal(GS.get_player_threat_arrows(), true, "Player Hitam: get_player_threat_arrows() membaca ancaman hitam")
	assert_equal(GS.get_opponent_threat_arrows(), false, "Player Hitam: get_opponent_threat_arrows() membaca ancaman putih")

	GS.toggle_player_engine_arrows()
	assert_equal(GS.show_black_engine_arrows, false, "Player Hitam: toggle_player_engine_arrows() membalik nilai show_black_engine_arrows")

	GS.toggle_opponent_engine_arrows()
	assert_equal(GS.show_white_engine_arrows, true, "Player Hitam: toggle_opponent_engine_arrows() membalik nilai show_white_engine_arrows")

	GS.toggle_player_threat_arrows()
	assert_equal(GS.get_player_threat_arrows(), false, "Player Hitam: toggle_player_threat_arrows() membalik nilai player threat")

	GS.toggle_opponent_threat_arrows()
	assert_equal(GS.get_opponent_threat_arrows(), true, "Player Hitam: toggle_opponent_threat_arrows() membalik nilai opponent threat")

	# 3. Test pertukaran sisi (side swap persistence by role)
	GS.chosen_side = "white"
	GS.set_player_engine_arrows(true)
	GS.set_opponent_engine_arrows(false)
	
	# Simulasikan switch ke hitam di UI Menu
	var p_e = GS.get_player_engine_arrows()
	var o_e = GS.get_opponent_engine_arrows()
	GS.chosen_side = "black"
	GS.set_player_engine_arrows(p_e)
	GS.set_opponent_engine_arrows(o_e)
	
	assert_equal(GS.get_player_engine_arrows(), true, "Setelah ganti sisi ke Hitam, panah Player tetap menyala")
	assert_equal(GS.show_black_engine_arrows, true, "Panah Hitam fisik kini menyala karena menjadi bidak Player")
	assert_equal(GS.show_white_engine_arrows, false, "Panah Putih fisik kini mati karena menjadi bidak Opponent")

	# 4. Test persistensi panah saat random side
	GS.chosen_side = "random"
	GS.set_player_engine_arrows(true)
	GS.set_opponent_engine_arrows(false)
	GS.resolve_player_side()
	assert_equal(GS.get_player_engine_arrows(), true, "Random side: player engine arrows tetap true")
	assert_equal(GS.get_opponent_engine_arrows(), false, "Random side: opponent engine arrows tetap false")

	# 5. Test reset last_move pada setup_board
	var board_scn = preload("res://src/ui/board/chess_board.tscn")
	var board_inst = board_scn.instantiate()
	var test_state = ChessBoardState.new(ChessBoardState.DEFAULT_FEN)
	board_inst.last_move = {"from": "e2", "to": "e4"}
	board_inst.setup_board(test_state, false)
	assert_true(board_inst.last_move.is_empty(), "setup_board mengosongkan last_move (tidak ada jejak petak kuning pada New Game)")
	board_inst.free()

	if owns_gs and GS != null:
		GS.free()

	_restore_settings_file(settings_backup)
	assert_equal(FileAccess.get_file_as_string(load("res://src/config/game_settings.gd").get_settings_path()), settings_backup,
		"Kategori 6 memulihkan settings.json pemain apa adanya (tidak ada pengacakan sisi yang bocor)")

func test_piece_animations() -> void:
	print("[Kategori 7: PieceView & Animasi Bidak]")
	var PieceViewClass = preload("res://src/ui/board/piece_view.gd")
	var view = PieceViewClass.new()
	root.add_child(view)
	view.setup(ChessTypes.PieceColor.WHITE, ChessTypes.PieceType.KNIGHT, "g1", "cburnett", 70.0)
	assert_equal(view.piece_color, ChessTypes.PieceColor.WHITE, "PieceView color Putih")
	assert_equal(view.piece_type, ChessTypes.PieceType.KNIGHT, "PieceView type Knight")
	assert_equal(view.current_square, "g1", "PieceView initial square g1")
	assert_equal(view.is_animating, false, "PieceView is_animating awal false")
	
	# Test knight hop animation initiation
	view.animate_move_to(Vector2(200, 200), 0.22)
	assert_equal(view.is_animating, true, "Knight hop mengaktifkan is_animating = true")
	assert_equal(view.z_index, 30, "Knight hop mengangkat z_index = 30 (melompati bidak lain secara tinggi)")

	view.cancel_animation()
	assert_equal(view.z_index, 0, "PieceView z_index normal 0 setelah cancel")
	assert_equal(view.scale, Vector2.ONE, "Scale kembali normal Vector2.ONE setelah cancel")
	assert_equal(view.rotation_degrees, 0.0, "Rotation degrees kembali 0.0 setelah cancel")

	# Test pawn animation: tidak boleh miring (rotation_degrees tetap 0.0)
	var pawn_view = PieceViewClass.new()
	root.add_child(pawn_view)
	pawn_view.setup(ChessTypes.PieceColor.WHITE, ChessTypes.PieceType.PAWN, "e2", "cburnett", 70.0)
	pawn_view.animate_move_to(Vector2(70, 0), 0.18, Callable(), Callable(), false, 1)
	assert_equal(pawn_view.rotation_degrees, 0.0, "Pawn marching step rotasi tetap 0.0 (tidak miring)")
	pawn_view.cancel_animation()
	pawn_view.free()

	# Test rook animation: tegap lurus (rotation_degrees tetap 0.0)
	var rook_view = PieceViewClass.new()
	root.add_child(rook_view)
	rook_view.setup(ChessTypes.PieceColor.WHITE, ChessTypes.PieceType.ROOK, "a1", "cburnett", 70.0)
	rook_view.animate_move_to(Vector2(280, 0), 0.25, Callable(), Callable(), false, 4)
	assert_equal(rook_view.rotation_degrees, 0.0, "Rook dash rotasi tetap 0.0 (tegap tanpa miring)")
	rook_view.cancel_animation()
	rook_view.free()

	# Test queen horizontal move: tegap lurus (rotation_degrees tetap 0.0)
	var queen_view = PieceViewClass.new()
	root.add_child(queen_view)
	queen_view.setup(ChessTypes.PieceColor.WHITE, ChessTypes.PieceType.QUEEN, "d1", "cburnett", 70.0)
	queen_view.animate_move_to(Vector2(280, 0), 0.25, Callable(), Callable(), false, 4)
	assert_equal(queen_view.rotation_degrees, 0.0, "Queen horizontal dash rotasi tetap 0.0 (tegap tanpa miring)")
	queen_view.cancel_animation()
	queen_view.free()

	# Test drop settle
	view.animate_move_to(Vector2(100, 100), 0.08, Callable(), Callable(), true)
	assert_equal(view.is_animating, true, "Drop settle mengaktifkan is_animating = true")
	view.cancel_animation()

	# Test PieceSmearEffect instantiation & color detection
	var SmearClass = preload("res://src/ui/effects/piece_smear_effect.gd")
	var smear = SmearClass.new()
	root.add_child(smear)
	smear.trigger(Vector2(50, 50), view, ChessTypes.PieceColor.WHITE, 64.0, 0.20)
	assert_true(smear.alpha_fade > 0.0, "PieceSmearEffect terinisialisasi dan aktif")
	assert_equal(smear.smear_color.r, 1.0, "Warna smear putih untuk bidak putih")
	smear.free()

	view.free()

func test_side_selection_and_assets() -> void:
	print("\n[Kategori 8: Play As Side Selection & Piece Set Assets]")
	var sets = ["cburnett", "staunty", "horsey", "neo"]
	for s in sets:
		var wk = "res://assets/pieces/%s/wK.svg" % s
		var bk = "res://assets/pieces/%s/bK.svg" % s
		var rk = "res://assets/pieces/%s/randK.svg" % s
		assert_true(ResourceLoader.exists(wk), "Piece set %s memiliki wK.svg" % s)
		assert_true(ResourceLoader.exists(bk), "Piece set %s memiliki bK.svg" % s)
		assert_true(ResourceLoader.exists(rk), "Piece set %s memiliki randK.svg split king" % s)

	assert_true(ResourceLoader.exists("res://assets/ui/random_side.svg"), "UI fallback random_side.svg tersedia")

	var GSClass = load("res://src/config/game_settings.gd")
	# resolve_player_side() menulis pilihan sisi ke settings.json pengguna,
	# termasuk saat sisi "random" diacak. Cadangkan lalu pulihkan agar suite
	# pengujian tidak pernah mengubah konfigurasi nyata pemain.
	var side_settings_backup = _backup_settings_file()
	var side_settings_path = GSClass.get_settings_path()

	var GS = GSClass.new()
	GS.set_chosen_side("white")
	assert_equal(GS.resolve_player_side(), ChessTypes.PieceColor.WHITE, "resolve_player_side 'white' -> WHITE")
	assert_equal(GS.is_flipped, false, "White side -> is_flipped false")

	GS.set_chosen_side("black")
	assert_equal(GS.resolve_player_side(), ChessTypes.PieceColor.BLACK, "resolve_player_side 'black' -> BLACK")
	assert_equal(GS.is_flipped, true, "Black side -> is_flipped true")

	GS.set_chosen_side("random")
	var r_color = GS.resolve_player_side()
	assert_true(r_color == ChessTypes.PieceColor.WHITE or r_color == ChessTypes.PieceColor.BLACK, "resolve_player_side 'random' -> valid color")
	GS.free()

	# Pulihkan settings.json pemain apa pun hasil acakan di atas
	_restore_settings_file(side_settings_backup)
	assert_equal(FileAccess.get_file_as_string(side_settings_path), side_settings_backup,
		"Suite pengujian memulihkan settings.json pemain apa adanya")

func test_forbidden_and_defender_highlights() -> void:
	print("\n[Kategori 9: Forbidden Squares & Savior Piece Highlights on Check]")
	var board_scn = preload("res://src/ui/board/chess_board.tscn")
	var board_inst = board_scn.instantiate()
	root.add_child(board_inst)
	board_inst._ready()

	# 1. Posisi Scholar's Mate (Skakmat: 0 bidak penyelamat)
	var mate_state = ChessBoardState.new("r1bqkb1r/pppp1Qpp/2n5/4p3/2B1n3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4")
	board_inst.setup_board(mate_state, false)

	assert_true(ChessMoveGenerator.is_in_check(mate_state, ChessTypes.PieceColor.BLACK), "Posisi skak: Black King in check")
	assert_true(ChessMoveGenerator.is_checkmate(mate_state), "Posisi skakmat penuh")

	var e8_cell: SquareCell = board_inst.square_cells.get("e8")
	var d8_cell: SquareCell = board_inst.square_cells.get("d8")
	var d7_cell: SquareCell = board_inst.square_cells.get("d7")
	var e7_cell: SquareCell = board_inst.square_cells.get("e7")
	var f7_cell: SquareCell = board_inst.square_cells.get("f7")
	var f8_cell: SquareCell = board_inst.square_cells.get("f8")
	var c6_cell: SquareCell = board_inst.square_cells.get("c6")

	assert_equal(e8_cell.is_in_check, true, "Petak King e8 memiliki is_in_check = true")
	assert_equal(d8_cell.is_forbidden, false, "Petak d8 kawan is_forbidden = false")
	assert_equal(d7_cell.is_forbidden, false, "Petak d7 kawan is_forbidden = false")
	assert_equal(e7_cell.is_forbidden, true, "Petak e7 unoccupied terlarang is_forbidden = true")
	assert_equal(f7_cell.is_forbidden, false, "Petak f7 musuh terlindungi is_forbidden = false")
	assert_equal(f8_cell.is_forbidden, false, "Petak f8 kawan is_forbidden = false")
	assert_equal(c6_cell.is_defender, false, "Kuda di c6 tidak bisa menyelamatkan -> is_defender = false")

	# 2. Posisi Skak dengan Bidak Penyelamat (Defender Pieces)
	# Black King di d8 diserang Kuda Putih di e6.
	# Gajah Hitam di c8 dapat memakan Kuda e6 (Bxe6), Ratu Hitam di d6 dapat memakan Kuda e6 (Qxe6), Pion f7 dapat memakan (fxe6).
	var check_def_state = ChessBoardState.new("r1bk1bnr/1p3pp1/p1nqN3/2p1p3/4P1PN/8/PPPP1P1P/R1BQKB1R b KQ - 0 1")
	board_inst.setup_board(check_def_state, false)

	assert_true(ChessMoveGenerator.is_in_check(check_def_state, ChessTypes.PieceColor.BLACK), "Posisi skak: Black King in check oleh Ne6")

	var c8_cell: SquareCell = board_inst.square_cells.get("c8")
	var d6_cell: SquareCell = board_inst.square_cells.get("d6")
	var f7_cell_2: SquareCell = board_inst.square_cells.get("f7")
	var a8_cell: SquareCell = board_inst.square_cells.get("a8")
	var h8_cell: SquareCell = board_inst.square_cells.get("h8")

	assert_equal(c8_cell.is_defender, true, "Gajah di c8 bisa memakan Kuda e6 -> is_defender = true (Savior Piece)")
	assert_equal(d6_cell.is_defender, true, "Ratu di d6 bisa memakan Kuda e6 -> is_defender = true (Savior Piece)")
	assert_equal(f7_cell_2.is_defender, true, "Pion di f7 bisa memakan Kuda e6 -> is_defender = true (Savior Piece)")
	assert_equal(a8_cell.is_defender, false, "Benteng di a8 tidak bisa memakan -> is_defender = false")
	assert_equal(h8_cell.is_defender, false, "Benteng di h8 tidak bisa memakan -> is_defender = false")

	# 3. Posisi Skak di mana King bisa capture bidak musuh di petak adjacent untuk kabur (b6)
	var check_escape_state = ChessBoardState.new("8/2k1Q2p/pNb1p3/3p4/3p4/8/PPP3PP/4R1K1 b - - 0 1")
	board_inst.setup_board(check_escape_state, false)
	var b6_cell: SquareCell = board_inst.square_cells.get("b6")
	assert_equal(b6_cell.is_forbidden, false, "Petak b6 tidak terhighlight merah karena King c7 bisa capture Knight b6 untuk escape")
	# Pastikan petak d6 yang unoccupied terlarang tetap is_forbidden = true
	var d6_cell_check: SquareCell = board_inst.square_cells.get("d6")
	assert_equal(d6_cell_check.is_forbidden, true, "Petak d6 unoccupied terancam Qe7 tetap is_forbidden = true")

	# 4. Perisai penyelamat (savior badge) harus tergambar halus: draw_colored_polygon
	# tidak punya anti-aliasing, jadi isian wajib digeser ke dalam agar tepi bergeriginya
	# tersembunyi di bawah inti garis outline AA.
	var shield_overlay: BadgeOverlay = BadgeOverlay.new()
	var shield_pts = PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 6), Vector2(5, 10), Vector2(0, 6)
	])
	var inset_pts: PackedVector2Array = shield_overlay._inset_polygon(shield_pts, 0.35)
	assert_equal(inset_pts.size(), shield_pts.size(), "Inset perisai menjaga jumlah verteks poligon")
	var all_vertices_inward := true
	for i in shield_pts.size():
		if inset_pts[i].distance_to(shield_pts[i]) <= 0.001:
			all_vertices_inward = false
	assert_true(all_vertices_inward, "Setiap verteks perisai tergeser ke dalam agar isian tidak menonjol melewati outline")
	assert_true(inset_pts[3].y < shield_pts[3].y, "Ujung bawah perisai ikut tergeser ke dalam")
	assert_equal(shield_overlay._inset_polygon(PackedVector2Array([Vector2.ZERO, Vector2.ONE]), 0.35).size(), 2, "Poligon < 3 verteks dikembalikan apa adanya")
	shield_overlay.free()

	board_inst.free()

func test_local_settings_persistence() -> void:
	print("\n[Kategori 10: Local Settings Persistence (Project/Game Directory)]")
	var GSClass = load("res://src/config/game_settings.gd")
	var settings_path = GSClass.get_settings_path()
	# Backup data settings asli pengguna agar tidak tertimpa oleh unit test
	var original_settings = ""
	if FileAccess.file_exists(settings_path):
		var f_read = FileAccess.open(settings_path, FileAccess.READ)
		if f_read:
			original_settings = f_read.get_as_text()

	var gs = GSClass.new()

	# 1. Tulis konfigurasi uji coba
	gs.set_elo(1850)
	gs.set_engine_depth(20)
	gs.set_board_theme("ocean")
	gs.set_piece_set("staunty")
	gs.set_ai_delay_mode("relaxed")
	gs.set_ai_custom_delay(2.5)
	gs.set_ai_engine_type("maia3")
	gs.set_chosen_side("black")
	gs.set_sound_enabled(false)
	gs.set_sound_volume(0.65)
	gs.set_show_forbidden_squares(true)
	gs.set_show_defender_highlights(true)
	gs.save_settings()

	# 2. Buka instance baru dan muat dari disk
	var gs_loaded = GSClass.new()
	gs_loaded.load_settings()

	assert_equal(gs_loaded.ai_elo, 1850, "Persistent ELO tersimpan dan termuat: 1850")
	assert_equal(gs_loaded.ai_engine_type, "maia3", "Persistent AI Engine Type tersimpan dan termuat: maia3")
	assert_equal(gs_loaded.engine_depth, 20, "Persistent Depth tersimpan dan termuat: 20")
	assert_equal(gs_loaded.board_theme, "ocean", "Persistent Theme tersimpan dan termuat: ocean")
	assert_equal(gs_loaded.piece_set, "staunty", "Persistent Piece Set tersimpan dan termuat: staunty")
	assert_equal(gs_loaded.ai_delay_mode, "relaxed", "Persistent Delay Mode tersimpan dan termuat: relaxed")
	assert_equal(gs_loaded.chosen_side, "black", "Persistent Chosen Side tersimpan dan termuat: black")
	assert_equal(gs_loaded.sound_enabled, false, "Persistent Sound Enabled tersimpan dan termuat: false")
	assert_equal(gs_loaded.show_forbidden_squares, true, "Persistent show_forbidden_squares tersimpan")
	assert_equal(gs_loaded.show_defender_highlights, true, "Persistent show_defender_highlights tersimpan")

	# Kembalikan file settings asli pengguna pasca pengujian selesai
	if not original_settings.is_empty():
		var f_write = FileAccess.open(settings_path, FileAccess.WRITE)
		if f_write:
			f_write.store_string(original_settings)
			f_write.flush()
	elif FileAccess.file_exists(settings_path):
		DirAccess.remove_absolute(settings_path)

	gs.free()
	gs_loaded.free()

func test_victory_celebration() -> void:
	print("\n[Kategori 11: Victory Celebration & King Topple]")
	# 1. PieceView Topple
	var PieceViewClass = preload("res://src/ui/board/piece_view.gd")
	var p_view = PieceViewClass.new()
	p_view.setup(ChessTypes.PieceColor.BLACK, ChessTypes.PieceType.KING, "e8", "cburnett", 64.0)
	p_view.animate_topple(1.0)
	assert_true(p_view.is_animating, "PieceView memulai animasi topple")
	p_view.cancel_animation()
	assert_equal(p_view.is_animating, false, "cancel_animation mereset state animasi topple")
	p_view.free()

	# 2. ConfettiBurst Component
	var ConfettiClass = preload("res://src/ui/effects/confetti_burst.gd")
	var confetti = ConfettiClass.new()
	confetti.size = Vector2(800, 600)
	confetti._ready()
	assert_true(confetti.left_cannon != null, "ConfettiBurst memiliki left_cannon")
	assert_true(confetti.right_cannon != null, "ConfettiBurst memiliki right_cannon")
	assert_equal(confetti.left_cannon.position, Vector2(40, 600), "Left cannon diposisikan di sudut kiri bawah")
	assert_equal(confetti.right_cannon.position, Vector2(760, 600), "Right cannon diposisikan di sudut kanan bawah")
	confetti.burst()
	assert_equal(confetti.left_cannon.emitting, true, "Left cannon aktif setelah burst()")
	assert_equal(confetti.right_cannon.emitting, true, "Right cannon aktif setelah burst()")
	confetti.stop()
	assert_equal(confetti.left_cannon.emitting, false, "Left cannon mati setelah stop()")
	confetti.free()

	# 3. GameOverDialog Component
	var dlg_scn = preload("res://src/ui/dialogs/game_over_dialog.tscn")
	var dlg = dlg_scn.instantiate()
	dlg.show_game_over("You Won!", "by Checkmate", "1 - 0", true, false)
	assert_equal(dlg.title_label.text, "You Won!", "GameOverDialog title sesuai")
	assert_equal(dlg.subtitle_label.text, "by Checkmate", "GameOverDialog subtitle sesuai")
	assert_equal(dlg.score_label.text, "1 - 0", "GameOverDialog score sesuai")
	dlg.free()

	# 4. ChessBoard topple_king integration
	var board_scn = preload("res://src/ui/board/chess_board.tscn")
	var board = board_scn.instantiate()
	board._ready()
	var state = ChessBoardState.new("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3") # Fool's mate
	board.setup_board(state, false)
	board.topple_king(ChessTypes.PieceColor.WHITE)
	var white_king_view = board.piece_views.get("e1")
	assert_true(white_king_view != null, "White king view ditemukan di e1")
	if white_king_view:
		assert_true(white_king_view.is_animating, "White king view menjalankan animasi topple saat checkmate")
	board.free()

func test_engine_assist_lifecycle() -> void:
	print("\n[Kategori 12: Engine Assist & Loading Bar Invariants]")
	var es = EngineService.new()
	es.is_analyzing = true
	es.target_analysis_depth = 16
	es.current_analysis_depth = 0

	var progress_data = {
		"cur": -1,
		"tgt": -1,
		"final": true
	}
	es.analysis_progress_updated.connect(func(cur, tgt, is_fin):
		progress_data["cur"] = cur
		progress_data["tgt"] = tgt
		progress_data["final"] = is_fin
	)

	var emitted_arrows: Array[Dictionary] = []
	es.arrows_updated.connect(func(arrs):
		emitted_arrows = arrs
	)

	# 1. Depth progres intermediate (d = 10, mpv = 1)
	es._on_evaluation_updated({
		"depth": 10,
		"multipv": 1,
		"score_cp": 35,
		"is_mate": false,
		"mate_in": 0,
		"best_move": "e2e4"
	})
	assert_equal(progress_data["cur"], 10, "Progress cur_depth terupdate ke 10")
	assert_equal(progress_data["final"], false, "Progres intermediate d=10 is_final bernilai false")
	var r10 = es.get_analysis_progress_ratio()
	assert_true(r10 >= 0.55 and r10 <= 0.65, "Rasio progres realtime d=10 mpv=1 valid: %.2f" % r10)

	# 2. Depth mencapai target (d = 16) tapi belum ada bestmove -> is_final HARUS false!
	es._on_evaluation_updated({
		"depth": 16,
		"multipv": 1,
		"score_cp": 40,
		"is_mate": false,
		"mate_in": 0,
		"best_move": "e2e4"
	})
	assert_equal(progress_data["cur"], 16, "Progress cur_depth mencapai 16")
	assert_equal(progress_data["final"], false, "Saat depth mencapai target (16), is_final TETAP false sebelum bestmove")
	var r16_1 = es.get_analysis_progress_ratio()
	assert_true(r16_1 >= 0.94 and r16_1 <= 0.96, "Rasio progres realtime d=16 mpv=1 dibatasi aman: %.2f" % r16_1)

	# 3. MultiPV 2 & 3 saat depth 16
	es._on_evaluation_updated({
		"depth": 16,
		"multipv": 2,
		"score_cp": 20,
		"is_mate": false,
		"mate_in": 0,
		"best_move": "d2d4"
	})
	es._on_evaluation_updated({
		"depth": 16,
		"multipv": 3,
		"score_cp": 10,
		"is_mate": false,
		"mate_in": 0,
		"best_move": "g1f3"
	})
	var arrows = es._build_engine_arrows()
	assert_equal(arrows.size(), 3, "Terdapat 3 panah rank MultiPV")
	assert_equal(arrows[0]["type"], "best", "Rank 1 bertipe best")
	assert_equal(arrows[1]["type"], "good", "Rank 2 bertipe good")
	assert_equal(arrows[2]["type"], "alternative", "Rank 3 bertipe alternative")
	assert_equal(es.current_analysis_multipv, 3, "current_analysis_multipv terlacak di 3")

	# 4. Saat bestmove diterima secara resmi -> is_final menjadi true & is_analyzing menjadi false!
	es._on_best_move_received("e2e4")
	assert_equal(es.is_analyzing, false, "is_analyzing menjadi false setelah bestmove")
	assert_equal(progress_data["final"], true, "is_final bernilai true saat bestmove diterima")
	assert_equal(es.get_analysis_progress_ratio(), 1.0, "Rasio progres final tepat 1.0 (100%)")

	# 5. Pasca final, evaluasi liar tidak boleh mengubah panah atau memicu progress
	es._on_evaluation_updated({
		"depth": 16,
		"multipv": 1,
		"score_cp": 999,
		"is_mate": false,
		"mate_in": 0,
		"best_move": "a2a3"
	})
	assert_equal(es.multipv_lines[1]["best_move"], "e2e4", "Panah engine terkunci dan tidak berubah pasca final")

	es.free()

func test_uci_parser() -> void:
	print("\n[Kategori 13: UCI Protocol & Parser Optimization]")
	var uci = UCIClient.new()
	var parsed_eval: Array = [{}]
	uci.evaluation_updated.connect(func(d):
		parsed_eval[0] = d
	)

	var received_bestmove: Array = [""]
	uci.best_move_received.connect(func(m):
		received_bestmove[0] = m
	)

	var is_ready: Array = [false]
	uci.engine_ready.connect(func():
		is_ready[0] = true
	)

	# 1. Test parsing info line centipawn (Turn White)
	var line_cp = "info depth 14 seldepth 18 multipv 1 score cp 42 nodes 52300 nps 1650000 hashfull 12 time 31 pv e2e4 e7e5 g1f3 b8c6 f1c4"
	uci._parse_info_line(line_cp, ChessTypes.PieceColor.WHITE)
	var p0 = parsed_eval[0]
	assert_equal(p0.get("depth", 0), 14, "UCI parser depth 14")
	assert_equal(p0.get("multipv", 0), 1, "UCI parser multipv 1")
	assert_equal(p0.get("score_cp", 0), 42, "UCI parser White score +42 cp")
	assert_equal(p0.get("is_mate", true), false, "UCI parser is_mate false")
	assert_equal(p0.get("nodes", 0), 52300, "UCI parser nodes 52300")
	assert_equal(p0.get("nps", 0), 1650000, "UCI parser nps 1650000")
	assert_equal(p0.get("time_ms", 0), 31, "UCI parser time_ms 31")
	assert_equal(p0.get("hashfull", 0), 12, "UCI parser hashfull 12")
	assert_equal(p0.get("best_move", ""), "e2e4", "UCI parser best_move 'e2e4'")
	assert_equal(p0.get("pv", []).size(), 5, "UCI parser PV size 5")
	assert_equal(p0.get("pv", [])[4], "f1c4", "UCI parser PV move 5 'f1c4'")

	# 2. Test score inversion saat turn Black
	uci._parse_info_line(line_cp, ChessTypes.PieceColor.BLACK)
	assert_equal(parsed_eval[0].get("score_cp", 0), -42, "UCI parser Black score inverted -42 cp")

	# 3. Test mate score parsing
	var line_mate = "info depth 8 multipv 1 score mate 2 nodes 1200 time 5 pv d1h5 g7g6 h5e5"
	uci._parse_info_line(line_mate, ChessTypes.PieceColor.WHITE)
	assert_equal(parsed_eval[0].get("is_mate", false), true, "UCI parser is_mate true")
	assert_equal(parsed_eval[0].get("mate_in", 0), 2, "UCI parser mate_in +2")
	assert_equal(parsed_eval[0].get("score_cp", 0), 99999, "UCI parser mate score_cp 99999")

	# 4. Test mate score inversion saat turn Black
	var line_black_mate = "info depth 6 multipv 1 score mate -3 nodes 800 time 2 pv f7f8q"
	uci._parse_info_line(line_black_mate, ChessTypes.PieceColor.BLACK)
	assert_equal(parsed_eval[0].get("is_mate", false), true, "UCI parser is_mate true (Black)")
	assert_equal(parsed_eval[0].get("mate_in", 0), 3, "UCI parser Black mate_in inverted +3")

	# 5. Test _process_line bestmove
	var search_id = uci.start_new_search(ChessTypes.PieceColor.WHITE)
	uci._process_line("bestmove e2e4 ponder e7e5", search_id, ChessTypes.PieceColor.WHITE)
	assert_equal(received_bestmove[0], "e2e4", "UCI process bestmove 'e2e4'")

	uci._process_line("bestmove (none)", search_id, ChessTypes.PieceColor.WHITE)
	assert_equal(received_bestmove[0], "", "UCI process bestmove (none) -> empty")

	# 6. Test readyok
	uci._process_line("readyok", search_id, ChessTypes.PieceColor.WHITE)
	assert_equal(is_ready[0], true, "UCI process readyok -> engine_ready emitted")

func test_game_review_and_coach() -> void:
	print("\n[Kategori 14: Game Review & AI Coach Explanation]")

	# 1. Sigmoid CAPS Win Probability Model
	var prob_even = GameReviewService.calculate_win_probability(0)
	assert_true(absf(prob_even - 0.5) < 0.001, "Win probability pada 0 cp adalah 50%")

	var prob_white_adv = GameReviewService.calculate_win_probability(400)
	assert_true(prob_white_adv > 0.90 and prob_white_adv < 0.92, "Win probability pada +400 cp adalah ~90.9%")

	var prob_black_adv = GameReviewService.calculate_win_probability(-400)
	assert_true(prob_black_adv > 0.08 and prob_black_adv < 0.10, "Win probability pada -400 cp adalah ~9.1%")

	var prob_max = GameReviewService.calculate_win_probability(99999)
	assert_equal(prob_max, 1.0, "Win probability pada forced mate Putih adalah 100%")

	var prob_min = GameReviewService.calculate_win_probability(-99999)
	assert_equal(prob_min, 0.0, "Win probability pada forced mate Hitam adalah 0%")

	# 2. Move Accuracy Formula
	var acc_perfect = GameReviewService.calculate_move_accuracy(0.5, 0.5)
	assert_equal(acc_perfect, 100.0, "Akurasi langkah sempurna (tanpa penurunan probabilitas) adalah 100%")

	var acc_slight_drop = GameReviewService.calculate_move_accuracy(0.5, 0.45)
	assert_true(acc_slight_drop >= 85.0 and acc_slight_drop <= 95.0, "Akurasi sedikit drop adalah ~88.2%")

	var acc_blunder_drop = GameReviewService.calculate_move_accuracy(0.8, 0.1)
	assert_true(acc_blunder_drop < 25.0, "Akurasi blunder fatal turun di bawah 25%")

	# 3. Klasifikasi Langkah (Move Classification)
	var cls_best = GameReviewService.classify_move_static(100, 100, "e2e4", "e2e4")
	assert_equal(cls_best, GameReviewService.Classification.BEST, "Langkah sama dengan bestmove -> BEST")

	var cls_brilliant = GameReviewService.classify_move_static(100, 200, "d1h5", "d1h5", true)
	assert_equal(cls_brilliant, GameReviewService.Classification.BRILLIANT, "Pengorbanan perwira terbaik -> BRILLIANT")

	var cls_miss = GameReviewService.classify_move_static(90000, 150, "e2e3", "d1h5", false, true, 2, false, 0)
	assert_equal(cls_miss, GameReviewService.Classification.MISS, "Melewatkan mate in 2 -> MISS")

	var cls_blunder = GameReviewService.classify_move_static(300, -200, "e2e3", "d2d4")
	assert_equal(cls_blunder, GameReviewService.Classification.BLUNDER, "Kehilangan evaluasi > 350 cp -> BLUNDER")

	var cls_mistake = GameReviewService.classify_move_static(100, 0, "e2e3", "d2d4")
	assert_equal(cls_mistake, GameReviewService.Classification.MISTAKE, "Kehilangan evaluasi 200 cp -> MISTAKE")

	var cls_inaccuracy = GameReviewService.classify_move_static(100, 45, "e2e3", "d2d4")
	assert_equal(cls_inaccuracy, GameReviewService.Classification.INACCURACY, "Kehilangan evaluasi 100 cp -> INACCURACY")

	var cls_good = GameReviewService.classify_move_static(100, 75, "e2e3", "d2d4")
	assert_equal(cls_good, GameReviewService.Classification.GOOD, "Kehilangan evaluasi 50 cp -> GOOD")

	var cls_excellent = GameReviewService.classify_move_static(100, 90, "e2e3", "d2d4")
	assert_equal(cls_excellent, GameReviewService.Classification.EXCELLENT, "Kehilangan evaluasi 10 cp -> EXCELLENT")

	# Test Cutoffs Chess.com V2
	assert_equal(ReviewRules.EP_CUTOFF_EXCELLENT, 0.02, "Cutoff Excellent 0.02")
	assert_equal(ReviewRules.EP_CUTOFF_GOOD, 0.05, "Cutoff Good 0.05")
	assert_equal(ReviewRules.EP_CUTOFF_INACCURACY, 0.10, "Cutoff Inaccuracy 0.10")
	assert_equal(ReviewRules.EP_CUTOFF_MISTAKE, 0.20, "Cutoff Mistake 0.20")

	# Test Tactical Miss & Great Move
	var cls_tactical_miss = ReviewRules.classify_chess_com(100, 0, "e2e3", "d2d4", false, false, false, false, 0, false, 0, -999999, true)
	assert_equal(cls_tactical_miss, ReviewRules.Classification.MISS, "Gagal menghukum blunder lawan -> MISS")

	var cls_great_only = ReviewRules.classify_chess_com(100, 100, "e2e4", "e2e4", false, false, true)
	assert_equal(cls_great_only, ReviewRules.Classification.GREAT, "Langkah satu-satunya solusi (Only Move) -> GREAT")

	var cls_great_mpv = ReviewRules.classify_chess_com(100, 100, "e2e4", "e2e4", false, false, false, false, 0, false, 0, -300)
	assert_equal(cls_great_mpv, ReviewRules.Classification.GREAT, "Langkah dengan alternatif rank 2 jauh lebih buruk -> GREAT")

	# 4. Badge Text, Symbol & Colors
	assert_equal(GameReviewService.classification_to_string(GameReviewService.Classification.BRILLIANT), "Brilliant", "String klasifikasi Brilliant")
	assert_equal(GameReviewService.classification_to_badge_symbol(GameReviewService.Classification.BRILLIANT), "!!", "Simbol badge Brilliant !!")
	assert_equal(GameReviewService.classification_to_badge_symbol(GameReviewService.Classification.BLUNDER), "??", "Simbol badge Blunder ??")
	assert_equal(GameReviewService.classification_to_badge_symbol(GameReviewService.Classification.BEST), "★", "Simbol badge Best ★")
	assert_true(GameReviewService.classification_to_color(GameReviewService.Classification.BLUNDER) == Color("ca3431"), "Warna badge Blunder merah chess.com")
	assert_true(GameReviewService.classification_to_color(GameReviewService.Classification.GREAT) == Color("1bada6"), "Warna badge Great mengikuti artwork PNG chess.com")
	assert_true(GameReviewService.classification_to_color(GameReviewService.Classification.BRILLIANT) == Color("1bada6"), "Warna badge Brilliant teal chess.com")

	# 5. Agregasi Akurasi Game (CAPS Summary)
	var sample_steps = [
		{ "color": ChessTypes.PieceColor.WHITE, "accuracy": 100.0, "classification": GameReviewService.Classification.BEST },
		{ "color": ChessTypes.PieceColor.WHITE, "accuracy": 90.0, "classification": GameReviewService.Classification.EXCELLENT },
		{ "color": ChessTypes.PieceColor.BLACK, "accuracy": 80.0, "classification": GameReviewService.Classification.GOOD },
		{ "color": ChessTypes.PieceColor.BLACK, "accuracy": 40.0, "classification": GameReviewService.Classification.BLUNDER }
	]
	var acc_summary = GameReviewService.compute_game_accuracy(sample_steps)
	assert_equal(acc_summary["white_accuracy"], 95.0, "Rata-rata akurasi Putih tepat 95.0%")
	assert_equal(acc_summary["black_accuracy"], 60.0, "Rata-rata akurasi Hitam tepat 60.0%")
	assert_equal(acc_summary["white_counts"][GameReviewService.Classification.BEST], 1, "Hitungan BEST Putih = 1")
	assert_equal(acc_summary["black_counts"][GameReviewService.Classification.BLUNDER], 1, "Hitungan BLUNDER Hitam = 1")

	# 6. AI Coach Explanation Generator
	var step_coach_brilliant = {
		"classification": GameReviewService.Classification.BRILLIANT,
		"fen_before": ChessBoardState.DEFAULT_FEN,
		"fen_after": ChessBoardState.DEFAULT_FEN,
		"played_uci": "e2e4",
		"best_uci": "e2e4",
		"san": "e4",
		"eval_before": 20,
		"eval_after": 50
	}
	var res_coach_brilliant = CoachExplanationGenerator.generate_explanation(step_coach_brilliant)
	assert_equal(res_coach_brilliant["emotion"], CoachExplanationGenerator.CoachEmotion.PROUD, "Coach emotion PROUD untuk Brilliant")
	assert_true(res_coach_brilliant["title"].contains("Brilian"), "Coach title berisi Brilian")
	assert_true(res_coach_brilliant["narrative"].length() > 10, "Narasi Coach terisi valid")

	var step_coach_blunder = {
		"classification": GameReviewService.Classification.BLUNDER,
		"fen_before": ChessBoardState.DEFAULT_FEN,
		"fen_after": ChessBoardState.DEFAULT_FEN,
		"played_uci": "f2f3",
		"best_uci": "e2e4",
		"san": "f3",
		"eval_before": 20,
		"eval_after": -300
	}
	var res_coach_blunder = CoachExplanationGenerator.generate_explanation(step_coach_blunder)
	assert_equal(res_coach_blunder["emotion"], CoachExplanationGenerator.CoachEmotion.SHOCKED, "Coach emotion SHOCKED untuk Blunder")
	assert_true(res_coach_blunder["title"].contains("Blunder"), "Coach title berisi Blunder")

	# 7. ReviewBadgeOverlay Layout Position & Coordinates
	var badge_overlay = ReviewBadgeOverlay.new()
	assert_equal(badge_overlay.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "ReviewBadgeOverlay menggunakan LINEAR_WITH_MIPMAPS agar tidak pixelated")
	assert_true(badge_overlay.z_index >= 50, "ReviewBadgeOverlay z_index >= 50 berada di layer paling depan di atas seluruh state bidak catur (max piece z_index = 30)")
	badge_overlay.set_review_badge("e4", GameReviewService.Classification.BEST, false, 64.0)
	assert_equal(badge_overlay.current_badge["square"], "e4", "Badge target e4")
	assert_equal(badge_overlay.current_badge["classification"], GameReviewService.Classification.BEST, "Badge classification BEST")
	assert_equal(badge_overlay.anim_scale, 1.0, "Anim scale bernilai 1.0 pada set badge")
	var badge_pos = badge_overlay._get_square_position("e4")
	assert_equal(badge_pos, Vector2(256, 256), "Badge square e4 posisi unflipped (256, 256)")
	badge_overlay.set_review_badge("e4", GameReviewService.Classification.BEST, true, 64.0)
	var badge_pos_flipped = badge_overlay._get_square_position("e4")
	assert_equal(badge_pos_flipped, Vector2(192, 192), "Badge square e4 posisi flipped (192, 192)")
	badge_overlay.clear_badge()
	assert_true(badge_overlay.current_badge.is_empty(), "Badge overlay berhasil dikosongkan")
	assert_equal(badge_overlay.anim_scale, 0.0, "Anim scale reset ke 0.0 saat badge dikosongkan")

	# 7b. Geometri lencana: artwork PNG 256x256 selalu tampil ~40 px di petak 86 px,
	# jadi rect tujuan wajib dikunci ke piksel utuh saat animasi selesai agar tepinya
	# tidak bergetar akibat sampling sub-piksel.
	badge_overlay.square_size = 86.0
	badge_overlay.set_review_badge("d5", GameReviewService.Classification.BLUNDER, false, 86.0)
	badge_overlay.anim_scale = 1.0
	var rest_rect: Rect2 = badge_overlay.get_badge_rect("d5")
	assert_equal(rest_rect.position, rest_rect.position.round(), "Badge diam dikunci ke piksel utuh (tidak bergetar)")
	assert_equal(rest_rect.size, rest_rect.size.round(), "Ukuran badge diam bulat penuh")
	assert_true(absf(rest_rect.size.x - (86.0 * ReviewBadgeOverlay.BADGE_SIZE_RATIO)) <= 1.0, "Diameter badge tetap ~0.46 petak setelah penguncian piksel")
	var d5_cell: Vector2 = badge_overlay._get_square_position("d5")
	assert_true(rest_rect.position.x >= d5_cell.x and rest_rect.position.y >= d5_cell.y, "Badge tetap berada di dalam petak (batas kiri atas)")
	assert_true(rest_rect.end.x <= d5_cell.x + 86.0 and rest_rect.end.y <= d5_cell.y + 86.0, "Badge tetap berada di dalam petak (batas kanan bawah)")
	badge_overlay.anim_scale = 0.5
	var anim_rect: Rect2 = badge_overlay.get_badge_rect("d5")
	assert_true(anim_rect.size.x < rest_rect.size.x, "Selama animasi scale badge mengecil tanpa dikunci piksel")
	badge_overlay.free()

	# 8. GameReviewPanel Segmented Architecture & Layout Fit
	var review_scene = load("res://src/ui/hud/game_review_panel.tscn")
	assert_true(review_scene != null, "Scene GameReviewPanel valid")
	var panel_inst = review_scene.instantiate()
	assert_true(panel_inst != null, "GameReviewPanel scene berhasil di-instantiate")
	root.add_child(panel_inst)
	panel_inst._ready()
	
	# Test Segment Switching
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.SUMMARY, "Default tab adalah SUMMARY")
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.MOVES, "Berhasil beralih ke tab MOVES")
	assert_true(panel_inst.move_review_box.visible, "MoveReviewBox visible saat tab MOVES")
	assert_true(not panel_inst.summary_box.visible, "SummaryBox tersembunyi saat tab MOVES")

	panel_inst.switch_tab(GameReviewPanel.ReviewTab.MOVES_LIST)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.MOVES_LIST, "Berhasil beralih ke tab MOVES_LIST")
	assert_true(panel_inst.moves_list_box.visible, "MovesListBox visible saat tab MOVES_LIST")
	assert_true(not panel_inst.move_review_box.visible, "MoveReviewBox tersembunyi saat tab MOVES_LIST")
	
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.SUMMARY)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.SUMMARY, "Berhasil beralih kembali ke tab SUMMARY")
	assert_true(panel_inst.summary_box.visible, "SummaryBox visible saat tab SUMMARY")
	assert_true(not panel_inst.move_review_box.visible, "MoveReviewBox tersembunyi saat tab SUMMARY")

	# Invariant Layout Fit (<= 240px vertical budget)
	var summary_min = panel_inst.get_combined_minimum_size()
	assert_true(summary_min.y <= 240.0, "Summary view fit dalam batas vertikal (<= 240px)")
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.MOVES)
	var moves_min = panel_inst.get_combined_minimum_size()
	assert_true(moves_min.y <= 240.0, "Move review view fit dalam batas vertikal (<= 240px)")
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.SUMMARY)

	# Test Data Population & Navigation
	var mock_review_data = {
		"white_accuracy": 92.5,
		"black_accuracy": 67.8,
		"white_counts": { GameReviewService.Classification.BEST: 3, GameReviewService.Classification.GREAT: 1 },
		"black_counts": { GameReviewService.Classification.BLUNDER: 2, GameReviewService.Classification.MISTAKE: 1 },
		"steps": [
			{
				"ply": 0,
				"san": "e4",
				"classification": GameReviewService.Classification.BEST,
				"best_move": "e2e4",
				"explanation": { "narrative": "Akurat! Memperkuat kontrol posisi.", "emotion": CoachExplanationGenerator.Emotion.HAPPY }
			},
			{
				"ply": 1,
				"san": "f6",
				"classification": GameReviewService.Classification.BLUNDER,
				"best_move": "e7e5",
				"explanation": { "narrative": "Blunder fatal. Melepas kontrol. Best Move: e5.", "emotion": CoachExplanationGenerator.Emotion.SHOCKED }
			}
		]
	}
	panel_inst.set_review_data(mock_review_data)
	# Guard wiring: kalau salah satu node Summary gagal diresolusi, kegagalan harus
	# muncul sebagai FAIL eksplisit. Sebelumnya pemanggilan metode pada node null
	# membatalkan sisa Kategori 14 tanpa satu pun FAIL (test hole).
	assert_true(panel_inst.white_accuracy_label != null, "white_accuracy_label ter-resolusi dari scene")
	assert_true(panel_inst.black_accuracy_label != null, "black_accuracy_label ter-resolusi dari scene")
	assert_true(panel_inst.white_perf_label != null, "white_perf_label ter-resolusi dari scene")
	assert_true(panel_inst.black_perf_label != null, "black_perf_label ter-resolusi dari scene")
	assert_true(panel_inst.opening_label != null, "opening_label ter-resolusi dari scene")
	assert_true(panel_inst.counts_container != null, "counts_container ter-resolusi dari scene")
	assert_equal(panel_inst.white_accuracy_label.text, "92.5%", "White accuracy label terformat benar")
	assert_equal(panel_inst.black_accuracy_label.text, "67.8%", "Black accuracy label terformat benar")
	assert_equal(panel_inst.opening_label.text, "Opening: Standard Chess (A00)", "Opening label terisi dari review_data")
	assert_true(panel_inst.counts_container.get_child_count() > 0, "Kategori langkah terpopulasi di counts_container")
	assert_true(panel_inst.counts_container.get_child_count() == 4, "Hanya 4 kategori dengan count > 0 yang dirender")

	# Test Jump via classification category
	panel_inst._jump_to_first_classification(GameReviewService.Classification.BLUNDER)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.MOVES, "Jumping via category otomatis beralih ke tab MOVES")
	# Test Show Best Move button conditional enablement & toggle
	assert_equal(panel_inst.btn_show_best.disabled, false, "BtnShowBest aktif untuk langkah Blunder non-best")
	var show_best_emitted: Array = []
	panel_inst.show_best_move_requested.connect(func(idx, mv, is_showing): show_best_emitted.append({"idx": idx, "mv": mv, "is_showing": is_showing}))
	panel_inst._on_show_best_pressed()
	assert_true(panel_inst.is_showing_best_move, "is_showing_best_move bernilai true saat toggle pertama")
	assert_equal(panel_inst.btn_show_best.text, "Show Played Move", "Label tombol berubah menjadi Show Played Move")
	assert_equal(show_best_emitted.size(), 1, "Signal show_best_move_requested ter-emit")
	assert_true(show_best_emitted[0]["is_showing"], "Signal membawa is_showing = true")

	panel_inst._on_show_best_pressed()
	assert_true(not panel_inst.is_showing_best_move, "is_showing_best_move kembali false saat toggle kedua")
	assert_equal(panel_inst.btn_show_best.text, "Show Best Move", "Label tombol kembali menjadi Show Best Move")

	# Test langkah yang sudah merupakan Best Move menonaktifkan BtnShowBest
	panel_inst.select_step(0)
	assert_equal(panel_inst.btn_show_best.disabled, true, "BtnShowBest dinonaktifkan ketika langkah sudah merupakan Best Move")

	# Test Bug Fix: Saat is_showing_best_move aktif, berpindah langkah otomatis mereset is_showing_best_move ke false
	panel_inst.select_step(1)
	panel_inst._on_show_best_pressed()
	assert_true(panel_inst.is_showing_best_move, "is_showing_best_move aktif di langkah 1")
	panel_inst.select_step(0)
	assert_true(not panel_inst.is_showing_best_move, "is_showing_best_move otomatis ter-reset ke false saat berpindah langkah")
	assert_equal(panel_inst.btn_show_best.text, "Show Best Move", "Label tombol kembali ke Show Best Move saat berpindah langkah")

	# Test Start Position (-1): Awal game review berada di posisi awal tanpa langkah aktif
	panel_inst.select_step(-1)
	assert_equal(panel_inst.current_step_index, -1, "Start Position indeks bernilai -1")
	assert_true(not panel_inst.coach_card.visible, "Card coach disembunyikan pada Start Position (tidak ada card placeholder kosong)")
	assert_equal(panel_inst.btn_prev_move.disabled, true, "BtnPrev disabled pada Start Position")
	assert_equal(panel_inst.btn_first.disabled, true, "BtnFirst disabled pada Start Position")
	assert_equal(panel_inst.btn_next_move.disabled, false, "BtnNext aktif pada Start Position")
	assert_equal(panel_inst.btn_show_best.disabled, true, "BtnShowBest disabled pada Start Position")

	# Test klik Next dari Start Position maju ke step 0
	panel_inst._on_next_move_pressed()
	assert_equal(panel_inst.current_step_index, 0, "Klik Next dari Start Position melangkah ke step 0")
	assert_equal(panel_inst.btn_prev_move.disabled, false, "BtnPrev aktif setelah melangkah ke step 0")

	# Test klik Prev dari step 0 kembali ke Start Position (-1)
	panel_inst._on_prev_move_pressed()
	assert_equal(panel_inst.current_step_index, -1, "Klik Prev dari step 0 kembali ke Start Position")
	assert_equal(panel_inst.btn_prev_move.disabled, true, "BtnPrev kembali disabled pada Start Position")

	# Test klik tab Move Review tidak boleh langsung menjalankan move
	panel_inst._on_tab_moves_pressed()
	assert_equal(panel_inst.current_step_index, -1, "Klik tab Move Review mempertahankan posisi awal, tidak langsung menjalankan move")
	assert_true(not panel_inst.coach_card.visible, "Card coach tetap tersembunyi pada posisi awal saat klik tab Move Review")

	# Test Last Book Move sebagai First Key Moment
	var mock_with_book = {
		"steps": [
			{ "ply": 0, "classification": GameReviewService.Classification.BOOK },
			{ "ply": 1, "classification": GameReviewService.Classification.BOOK },
			{ "ply": 2, "classification": GameReviewService.Classification.GOOD },
			{ "ply": 3, "classification": GameReviewService.Classification.BLUNDER }
		]
	}
	panel_inst.set_review_data(mock_with_book)
	assert_equal(panel_inst._get_last_book_move_index(), 1, "Last book move terdeteksi di indeks 1")
	assert_equal(panel_inst._find_next_key_moment(-1), 1, "Key moment pertama dari start adalah last book move")
	assert_equal(panel_inst._find_next_key_moment(1), 3, "Key moment setelah book move adalah blunder di indeks 3")

	# Test Close Review signal
	var close_emitted: Array = [false]
	panel_inst.review_closed.connect(func(): close_emitted[0] = true)
	panel_inst._on_close_review_pressed()
	assert_true(close_emitted[0], "Sinyal review_closed ter-emit saat tombol tutup ditekan")

	# 9. Segmen Eval Graph (kurva evaluasi + penanda langkah aktif)
	assert_true(panel_inst.btn_tab_graph != null, "Tombol segmen Graph tersedia")
	assert_true(panel_inst.eval_graph != null, "Node EvalGraph ter-resolusi dari scene")
	assert_true(panel_inst.graph_readout_label != null, "Label readout graph ter-resolusi dari scene")

	panel_inst.set_review_data(mock_review_data)
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.GRAPH)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.GRAPH, "Berhasil beralih ke segmen GRAPH")
	assert_true(panel_inst.graph_box.visible, "GraphBox visible saat segmen GRAPH")
	assert_true(not panel_inst.summary_box.visible, "SummaryBox tersembunyi saat segmen GRAPH")
	assert_true(not panel_inst.move_review_box.visible, "MoveReviewBox tersembunyi saat segmen GRAPH")
	assert_equal(panel_inst.eval_graph.get_point_count(), 3, "Graph menerima titik posisi awal + tiap langkah")
	var graph_min: Vector2 = panel_inst.get_combined_minimum_size()
	assert_true(graph_min.y <= 240.0, "Graph view fit dalam batas vertikal (<= 240px)")
	# Catatan: angka minimum size di dalam frame yang sama masih nilai cache lama,
	# sehingga guard lantai 148 px yang sesungguhnya diukur berbasis frame di
	# test_review_layout_floor() (Kategori 16).
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.GRAPH)

	# Kursor graph mengikuti navigasi langkah
	panel_inst.select_step(1)
	assert_equal(panel_inst.eval_graph.get_active_ply(), 1, "Kursor graph mengikuti langkah aktif (ply 1)")
	assert_true(panel_inst.graph_readout_label.text.contains("f6"), "Readout graph menampilkan notasi langkah aktif")
	assert_true(panel_inst.graph_readout_label.text.contains("Blunder"), "Readout graph menampilkan klasifikasi langkah")
	panel_inst.select_step(-1)
	assert_equal(panel_inst.eval_graph.get_active_ply(), 0, "Kursor graph kembali ke posisi awal (ply 0)")

	# Klik titik graph melompat ke langkah tersebut di Move Review
	panel_inst.switch_tab(GameReviewPanel.ReviewTab.GRAPH)
	panel_inst._on_graph_ply_clicked(1)
	assert_equal(panel_inst.current_tab, GameReviewPanel.ReviewTab.MOVES, "Klik graph berpindah ke Move Review")
	assert_equal(panel_inst.current_step_index, 1, "Klik titik ply 1 membuka step dengan ply yang sama")
	assert_true(panel_inst.coach_card.visible, "Kartu coach tampil kembali setelah memilih langkah")

	# Mode progresif: titik netral bertambah sebelum klasifikasi dibangun
	panel_inst.reset_view()
	panel_inst.set_analysis_progress(0, 5)
	assert_true(panel_inst.eval_graph.is_analysis_pending(), "Graph menandai area yang belum teranalisis")
	assert_true(panel_inst.graph_box.visible, "Segmen Graph tetap tampil selama analisis progresif")
	assert_true(panel_inst.btn_tab_moves.disabled, "Navigasi segmen dinonaktifkan selama analisis berjalan")
	assert_true(not panel_inst.btn_tab_graph.disabled, "Segmen Graph tetap aktif selama analisis progresif")
	panel_inst.append_graph_point(1, 120, false, 0)
	panel_inst.append_graph_point(2, -450, false, 0)
	assert_equal(panel_inst.eval_graph.get_point_count(), 2, "Titik progresif bertambah tiap posisi selesai dinilai")
	var graph_points: Array = panel_inst.eval_graph._points
	assert_equal(int(graph_points[0]["classification"]), -1, "Titik progresif belum memiliki klasifikasi")
	assert_true(float(graph_points[0]["wp"]) > 0.5, "Eval +1.20 untuk Putih menghasilkan peluang menang > 50%")
	assert_true(float(graph_points[1]["wp"]) < 0.5, "Eval -4.50 untuk Putih menghasilkan peluang menang < 50%")

	# Peluang menang memakai model yang sama dengan perhitungan akurasi
	assert_true(absf(float(graph_points[0]["wp"]) - ReviewRules.win_probability_chess_com(120)) < 0.0001, "Kurva graph memakai model peluang menang Chess.com yang sama dengan akurasi")

	# Regresi Checkmate Win: mate_in = 0 dengan eval_white_cp = +99999 (terminal checkmate)
	# tidak boleh menghasilkan wp = 0.0 (curam hitam ke bawah).
	var mate_win_point: Dictionary = panel_inst._graph_point_from_eval(10, 99999, true, 0, GameReviewService.Classification.BEST)
	assert_equal(mate_win_point["wp"], 1.0, "Checkmate win untuk Putih (eval=+99999, mate_in=0) menghasilkan wp=1.0 di puncak grafik")
	var mate_loss_point: Dictionary = panel_inst._graph_point_from_eval(10, -99999, true, 0, GameReviewService.Classification.BEST)
	assert_equal(mate_loss_point["wp"], 0.0, "Checkmate win untuk Hitam (eval=-99999, mate_in=0) menghasilkan wp=0.0 di dasar grafik")
	assert_equal(panel_inst._format_eval_white({"is_mate_after": true, "mate_in_after": 0, "eval_white_cp": 99999}), "+#", "Format eval Checkmate win untuk Putih adalah +#")
	assert_equal(panel_inst._format_eval_white({"is_mate_after": true, "mate_in_after": 0, "eval_white_cp": -99999}), "-#", "Format eval Checkmate win untuk Hitam adalah -#")

	panel_inst.reset_view()

	# 10. Paritas marker grafik + kebersihan teks badge (regresi mojibake)
	var marker_classes: Array = GameReviewPanel.EvalGraph.MARKER_CLASSIFICATIONS
	assert_true(marker_classes.has(GameReviewService.Classification.BOOK), "Book mendapat marker pada grafik")
	assert_true(marker_classes.has(GameReviewService.Classification.GREAT), "Great mendapat marker pada grafik")
	assert_true(marker_classes.has(GameReviewService.Classification.BLUNDER), "Blunder mendapat marker pada grafik")
	assert_true(not marker_classes.has(GameReviewService.Classification.BEST), "Best tanpa marker pada grafik (paritas Chess.com)")
	assert_true(not marker_classes.has(GameReviewService.Classification.EXCELLENT), "Excellent tanpa marker pada grafik (paritas Chess.com)")
	assert_true(not marker_classes.has(GameReviewService.Classification.GOOD), "Good tanpa marker pada grafik (paritas Chess.com)")

	panel_inst.set_review_data(mock_review_data)
	var all_classes: Array = [
		GameReviewService.Classification.BOOK,
		GameReviewService.Classification.BRILLIANT,
		GameReviewService.Classification.GREAT,
		GameReviewService.Classification.BEST,
		GameReviewService.Classification.EXCELLENT,
		GameReviewService.Classification.GOOD,
		GameReviewService.Classification.INACCURACY,
		GameReviewService.Classification.MISTAKE,
		GameReviewService.Classification.MISS,
		GameReviewService.Classification.BLUNDER
	]
	var dirty_badges: Array = []
	for cls in all_classes:
		panel_inst._update_coach_display(
			cls,
			"narrative",
			CoachExplanationGenerator.Emotion.HAPPY,
			{ "ply": 1, "san": "e4", "color": ChessTypes.PieceColor.WHITE }
		)
		if not _is_clean_ascii(panel_inst.coach_badge.text):
			dirty_badges.append(cls)
	assert_true(dirty_badges.is_empty(), "Label badge coach bebas karakter rusak (mojibake) di semua 10 class")
	panel_inst._update_coach_display(
		GameReviewService.Classification.GOOD,
		"narrative",
		CoachExplanationGenerator.Emotion.HAPPY,
		{ "ply": 1, "san": "e4", "color": ChessTypes.PieceColor.WHITE }
	)
	assert_equal(panel_inst.coach_badge.text, "Good Move", "Badge Good Move tampil sebagai teks bersih tanpa simbol rusak")
	assert_equal(panel_inst.coach_badge_icon.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS, "Ikon badge coach memakai filter LINEAR_WITH_MIPMAPS agar tepinya halus")
	assert_true(_is_clean_ascii(panel_inst.opening_label.text), "Label opening bebas karakter non-ASCII")

	root.remove_child(panel_inst)
	panel_inst.free()

func test_game_review_overhaul_invariants() -> void:
	print("\n[Kategori 15: Game Review Overhaul, Opening Book & Vector Assets Invariants]")

	# 1. OpeningBook Tests
	var initial_epd = OpeningBook.fen_to_epd(ChessBoardState.DEFAULT_FEN)
	assert_equal(initial_epd, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq", "EPD posisi awal terformat benar 3 field")

	# Lookup move 1. e4
	var e4_fen = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq -"
	var e4_info = OpeningBook.lookup_position(e4_fen)
	assert_true(e4_info.get("found", false), "Posisi 1. e4 terdaftar dalam OpeningBook")
	assert_true(e4_info.get("eco", "").begins_with("B") or e4_info.get("eco", "").begins_with("C"), "ECO 1. e4 valid")
	assert_true(OpeningBook.is_book_move(e4_fen, 1), "1. e4 diklasifikasikan sebagai Book Move")

	# Ply cap > 24 bukan book move
	assert_true(not OpeningBook.is_book_move(e4_fen, 25), "Langkah ply > 24 bukan Book Move")

	# 2. ReviewRules Tests & 10 Classifications
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.BOOK), "Book", "String Book")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.BRILLIANT), "Brilliant", "String Brilliant")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.GREAT), "Great", "String Great")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.BEST), "Best", "String Best")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.EXCELLENT), "Excellent", "String Excellent")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.GOOD), "Good", "String Good")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.INACCURACY), "Inaccuracy", "String Inaccuracy")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.MISTAKE), "Mistake", "String Mistake")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.MISS), "Miss", "String Miss")
	assert_equal(ReviewRules.classification_to_string(ReviewRules.Classification.BLUNDER), "Blunder", "String Blunder")

	# Test Performance Rating Estimator
	var perf_high = ReviewRules.estimate_performance_rating(95.0, 1500)
	assert_true(perf_high >= 2000 and perf_high <= 2800, "Akurasi 95% menghasilkan performance rating kuat (~2000-2800)")
	var perf_low = ReviewRules.estimate_performance_rating(50.0, 1000)
	assert_true(perf_low >= 500 and perf_low <= 1450, "Akurasi 50% menghasilkan performance rating moderat (~1000-1400)")
	var perf_vs_master = ReviewRules.estimate_performance_rating(85.0, 2400)
	var perf_vs_novice = ReviewRules.estimate_performance_rating(85.0, 600)
	assert_true(perf_vs_master > perf_vs_novice, "Performance rating melawan Master lebih tinggi daripada Novice pada akurasi sama")


	# 3. Move Classification Artwork (PNG resmi chess.com) Existence Check
	var vector_icons = [
		"res://assets/ui/icons/review/brilliant.png",
		"res://assets/ui/icons/review/great.png",
		"res://assets/ui/icons/review/best.png",
		"res://assets/ui/icons/review/excellent.png",
		"res://assets/ui/icons/review/good.png",
		"res://assets/ui/icons/review/book.png",
		"res://assets/ui/icons/review/inaccuracy.png",
		"res://assets/ui/icons/review/mistake.png",
		"res://assets/ui/icons/review/miss.png",
		"res://assets/ui/icons/review/blunder.png"
	]
	for icon_path in vector_icons:
		assert_true(ResourceLoader.exists(icon_path) or FileAccess.file_exists(icon_path), "Ikon badge %s tersedia" % icon_path.get_file())

	# 3b. Mipmap chain: artwork 256 px selalu digambar 16-40 px, jadi tanpa mipmap
	# penskalaan linear hanya mengambil sebagian texel dan tepi badge tampak kasar.
	for icon_path in vector_icons:
		var badge_tex: Texture2D = load(icon_path)
		var mip_count := 0
		if badge_tex is CompressedTexture2D:
			var badge_img: Image = badge_tex.get_image()
			if badge_img != null:
				mip_count = badge_img.get_mipmap_count()
		assert_true(mip_count > 1, "Ikon badge %s punya mipmap chain agar halus saat diperkecil (mip=%d)" % [icon_path.get_file(), mip_count])

	# 4. ReviewBadgeOverlay Icon Path Mapping
	assert_equal(ReviewBadgeOverlay.get_icon_path(GameReviewService.Classification.BRILLIANT), "res://assets/ui/icons/review/brilliant.png", "Badge icon Brilliant valid")
	assert_equal(ReviewBadgeOverlay.get_icon_path(GameReviewService.Classification.BLUNDER), "res://assets/ui/icons/review/blunder.png", "Badge icon Blunder valid")
	assert_equal(ReviewBadgeOverlay.get_icon_path(GameReviewService.Classification.BEST), "res://assets/ui/icons/review/best.png", "Badge icon Best valid")

	# 5. TactileStyles Factory Invariants
	var style_normal = TactileStyles.create_gray_style("normal")
	assert_true(style_normal != null and style_normal is StyleBoxTexture, "Tactile gray normal StyleBox valid")
	var style_pressed = TactileStyles.create_gray_style("pressed")
	assert_true(style_pressed != null and style_pressed.content_margin_top > style_normal.content_margin_top, "Tactile pressed memiliki offset tekan mikro")

	# 6. Review Settings Configuration & Preset Switch
	var gs = root.get_node_or_null("GameSettings")
	if gs == null:
		var GSClass = load("res://src/config/game_settings.gd")
		gs = GSClass.new()
		gs._ready()

	gs.set_review_strength("fast")
	assert_equal(gs.review_strength, "fast", "Review strength set to fast")
	assert_equal(gs.review_depth, 14, "Fast preset depth = 14")
	assert_equal(gs.review_max_time_ms, 800, "Fast preset time = 800ms")
	assert_equal(gs.review_multipv, 2, "Fast preset multipv = 2")

	gs.set_review_strength("deep")
	assert_equal(gs.review_strength, "deep", "Review strength set to deep")
	assert_equal(gs.review_depth, 22, "Deep preset depth = 22")
	assert_equal(gs.review_max_time_ms, 3000, "Deep preset time = 3000ms")

	gs.set_review_strength("standard")
	assert_equal(gs.review_depth, 18, "Standard preset depth = 18")
	assert_equal(gs.review_max_time_ms, 1500, "Standard preset time = 1500ms")

	# Restore default preset bawaan game (Fast)
	gs.set_review_strength("fast")

	if gs != null and not gs.is_inside_tree():
		gs.free()

	# 7. ReviewEngineSession State & Lifecycle Invariants
	var rev_session = ReviewEngineSession.new()
	assert_equal(rev_session._is_running, false, "ReviewEngineSession default is_running false")
	assert_equal(rev_session._is_engine_ready, false, "ReviewEngineSession default is_engine_ready false")
	assert_equal(rev_session._current_idx, 0, "ReviewEngineSession current_idx awal 0")
	rev_session.stop_analysis()
	assert_equal(rev_session._is_running, false, "stop_analysis mematikan status running")
	rev_session.dispose()
	assert_true(rev_session._client == null, "dispose membersihkan UCIClient")

	# 8. Regresi B13: Flag taktis (promosi/en-passant/castling) ter-propagar ke step review
	# agar papan review merender pion promosi sebagai perwira, bukan tetap pion.
	var review_svc = GameReviewService.new()
	var promo_prev_fen = "4k3/P7/8/8/8/8/8/4K3 w - - 0 1"
	var promo_after_fen = "Q3k3/8/8/8/8/8/8/4K3 b - - 0 1"
	var promo_history: Array[Dictionary] = [
		{
			"fen": promo_prev_fen, "from_sq": "", "to_sq": "", "san_history": [],
			"is_cap": false, "is_castle": false, "is_ep": false, "promo": ChessTypes.PieceType.NONE
		},
		{
			"fen": promo_after_fen, "from_sq": "a7", "to_sq": "a8", "from": "a7", "to": "a8",
			"san": "a8=Q", "san_history": ["a8=Q"], "is_cap": false, "is_castle": false,
			"is_ep": false, "promo": ChessTypes.PieceType.QUEEN
		}
	]
	var promo_evals: Array[Dictionary] = [
		{ "score_cp": 0, "best_move": "a7a8q", "pv": ["a7a8q"], "is_mate": false, "mate_in": 0, "second_best_score_cp": 0 },
		{ "score_cp": 900, "best_move": "", "pv": [], "is_mate": false, "mate_in": 0, "second_best_score_cp": 0 }
	]
	var emitted_steps: Array = []
	review_svc.review_completed.connect(func(res: Dictionary): emitted_steps.append_array(res.get("steps", [])))
	review_svc._history_items = promo_history
	review_svc._build_and_emit_review_result(promo_evals)
	assert_equal(emitted_steps.size(), 1, "Analisis review menghasilkan satu langkah")
	if emitted_steps.size() == 1:
		assert_equal(emitted_steps[0].get("promo", -1), ChessTypes.PieceType.QUEEN, "Flag promosi pion ter-propagar ke step review")
		assert_equal(emitted_steps[0].get("is_castle", true), false, "Flag castling tersedia pada step review")
		assert_equal(emitted_steps[0].get("is_ep", true), false, "Flag en-passant tersedia pada step review")

	# 9. Regresi B14: Badge review harus bertahan melewati setup_board(), karena
	# finalize_undo memanggil setup_board() tepat setelah animasi mundur selesai.
	var board_scn = preload("res://src/ui/board/chess_board.tscn")
	var review_board = board_scn.instantiate()
	root.add_child(review_board)
	review_board.setup_board(ChessBoardState.new(promo_after_fen), false)
	review_board.set_review_badge("a8", GameReviewService.Classification.BEST)
	assert_true(not review_board.review_badge_overlay.current_badge.is_empty(), "Badge review terpasang di papan")
	assert_true(review_board.review_badge_overlay.z_index >= 50, "review_badge_overlay pada ChessBoard selalu diatur ke layer terdepan z_index >= 50")
	review_board.setup_board(ChessBoardState.new(promo_prev_fen), false)
	assert_equal(review_board.review_badge_overlay.current_badge.get("square", ""), "a8", "Badge review bertahan melewati setup_board saat animasi undo")
	review_board.clear_review_badge()
	assert_true(review_board.review_badge_overlay.current_badge.is_empty(), "clear_review_badge melepas badge sepenuhnya")
	root.remove_child(review_board)
	review_board.free()

# -----------------------------------------------------------------
# 16. Layout Guard: lantai tinggi segmen Game Review (berbasis frame)
# -----------------------------------------------------------------
## Minimum size sebuah Container baru segar setelah satu frame diproses. Di dalam
## frame yang sama, Control.get_combined_minimum_size() masih mengembalikan cache
## lama, sehingga guard lantai 148 px wajib diukur sebagai coroutine.
##
## Anggaran: HUDTabContainer punya lantai 148 px. Chrome di sekeliling panel Review
## adalah content margin panel TabContainer (8 atas + 8 bawah, lihat
## StyleBoxFlat_tab_panel di src/main.tscn) dan margin MarginContainer Review
## (4 + 4), total 24 px. Jadi lantai itu hanya benar-benar mengikat bila minimum
## tinggi panel <= 124 px di SETIAP segmen. Kalau salah satu segmen melewatinya,
## lantai tidak lagi menentukan dan seluruh layout bergeser saat berpindah segmen
## dari tab Moves/Engine (regresi B15).
func test_review_layout_floor() -> void:
	print("\n[Kategori 16: Layout Guard Segmen Game Review (lantai HUDTabContainer 148 px)]")

	var layout_mock := {
		"white_accuracy": 49.5,
		"black_accuracy": 51.3,
		"white_performance": 100,
		"black_performance": 100,
		"white_counts": { GameReviewService.Classification.BRILLIANT: 1, GameReviewService.Classification.MISTAKE: 3 },
		"black_counts": { GameReviewService.Classification.BLUNDER: 2, GameReviewService.Classification.MISS: 1 },
		"steps": [
			{
				"ply": 1, "san": "e4", "full_notation": "1. e4", "color": ChessTypes.PieceColor.WHITE,
				"classification": GameReviewService.Classification.BEST, "eval_white_cp": 35,
				"is_mate_after": false, "mate_in_after": 0, "win_prob_before": 0.5,
				"best_move": "e2e4", "played_uci": "e2e4",
				"explanation": { "narrative": "Menguasai pusat papan.", "emotion": CoachExplanationGenerator.Emotion.HAPPY }
			},
			{
				"ply": 2, "san": "f6", "full_notation": "1... f6", "color": ChessTypes.PieceColor.BLACK,
				"classification": GameReviewService.Classification.BLUNDER, "eval_white_cp": 320,
				"is_mate_after": false, "mate_in_after": 0, "win_prob_before": 0.52,
				"best_move": "e7e5", "played_uci": "e7f6", "eval_loss_cp": 285,
				"explanation": { "narrative": "Melepas kontrol pusat.", "emotion": CoachExplanationGenerator.Emotion.SHOCKED }
			}
		]
	}

	var holder := Control.new()
	holder.size = Vector2(708, 420)
	root.add_child(holder)
	var panel_inst = load("res://src/ui/hud/game_review_panel.tscn").instantiate()
	holder.add_child(panel_inst)
	panel_inst.set_review_data(layout_mock)

	# Dua frame: satu untuk propagasi minimum size, satu untuk layout container.
	await process_frame
	await process_frame

	var floor_budget: float = 148.0 - 16.0 - 8.0
	var measured: Dictionary = {}
	for segment in [
		GameReviewPanel.ReviewTab.SUMMARY,
		GameReviewPanel.ReviewTab.GRAPH,
		GameReviewPanel.ReviewTab.MOVES_LIST,
		GameReviewPanel.ReviewTab.MOVES
	]:
		panel_inst.switch_tab(segment)
		# Propagasi minimum size butuh beberapa frame: visibility baru berubah di
		# frame ini, update_minimum_size di-queue, dan layout induk menghitung ulang
		# pada frame berikutnya. Dengan satu-dua frame saja nilainya masih cache lama.
		for _i in range(6):
			await process_frame
		var min_size: Vector2 = panel_inst.get_combined_minimum_size()
		measured[segment] = min_size.y
		print("    segmen %d: minimum tinggi %.1f px (anggaran %.0f px)" % [segment, min_size.y, floor_budget])
		print("      rincian -> header=%.1f graph_box=%.1f summary_box=%.1f move_review_box=%.1f coach_card=%.1f" % [
			panel_inst.header_bar.get_combined_minimum_size().y if panel_inst.header_bar else -1.0,
			panel_inst.graph_box.get_combined_minimum_size().y if panel_inst.graph_box else -1.0,
			panel_inst.summary_box.get_combined_minimum_size().y if panel_inst.summary_box else -1.0,
			panel_inst.move_review_box.get_combined_minimum_size().y if panel_inst.move_review_box else -1.0,
			panel_inst.coach_card.get_combined_minimum_size().y if panel_inst.coach_card else -1.0
		])
		assert_true(min_size.y <= floor_budget, "Segmen %d tidak menaikkan lantai HUDTabContainer 148px" % segment)

	# Tinggi nyata yang tersedia saat review aktif jauh lebih besar dari lantai
	# (GameControls disembunyikan dan StatusPanel menyusut), sehingga grafik tetap
	# punya ruang mengembang walau minimumnya kecil.
	assert_true(measured[GameReviewPanel.ReviewTab.GRAPH] > 0.0, "Segmen Graph melaporkan minimum tinggi yang terukur, bukan 0")

	root.remove_child(holder)
	holder.free()

func test_captured_pieces_and_material_points() -> void:
	print("\n[Kategori 18: Captured Pieces & Material Advantage Points (Chess.com Style)]")

	# 1. Posisi Awal: Material seimbang, belum ada bidak yang dicapture
	var init_state = ChessBoardState.new(ChessBoardState.DEFAULT_FEN)
	var init_mat = ChessBoardState.calculate_material_and_captured(init_state)
	assert_equal(init_mat["white_material"], 39, "Material awal Putih bernilai 39 poin")
	assert_equal(init_mat["black_material"], 39, "Material awal Hitam bernilai 39 poin")
	assert_equal(init_mat["white_advantage"], 0, "Selisih material awal adalah 0")
	assert_equal(init_mat["black_captured"].size(), 0, "Bidak hitam yang dicapture di awal adalah 0")
	assert_equal(init_mat["white_captured"].size(), 0, "Bidak putih yang dicapture di awal adalah 0")

	# 2. Posisi di mana Putih unggul Kuda (Hitam kehilangan 1 Kuda di g8)
	var state_w_up = ChessBoardState.new("rnbqkb1r/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
	var mat_w_up = ChessBoardState.calculate_material_and_captured(state_w_up)
	assert_equal(mat_w_up["white_material"], 39, "Putih memiliki 39 poin")
	assert_equal(mat_w_up["black_material"], 36, "Hitam memiliki 36 poin (-1 Kuda)")
	assert_equal(mat_w_up["white_advantage"], 3, "Keunggulan Putih adalah +3 poin")
	assert_equal(mat_w_up["black_captured"].size(), 1, "Tepat 1 bidak hitam yang dicapture")
	assert_equal(mat_w_up["black_captured"][0], ChessTypes.PieceType.KNIGHT, "Bidak hitam yang dicapture adalah Kuda")
	assert_equal(mat_w_up["white_captured"].size(), 0, "Putih tidak kehilangan bidak")

	# 3. Posisi di mana Hitam unggul Ratu (Putih kehilangan Ratu di d1)
	var state_b_up = ChessBoardState.new("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNB1KBNR w KQkq - 0 1")
	var mat_b_up = ChessBoardState.calculate_material_and_captured(state_b_up)
	assert_equal(mat_b_up["white_material"], 30, "Putih memiliki 30 poin (-1 Ratu)")
	assert_equal(mat_b_up["black_material"], 39, "Hitam memiliki 39 poin")
	assert_equal(mat_b_up["white_advantage"], -9, "Keunggulan Putih adalah -9 (Hitam unggul +9 poin)")
	assert_equal(mat_b_up["white_captured"].size(), 1, "Tepat 1 bidak putih yang dicapture")
	assert_equal(mat_b_up["white_captured"][0], ChessTypes.PieceType.QUEEN, "Bidak putih yang dicapture adalah Ratu")
	assert_equal(mat_b_up["black_captured"].size(), 0, "Hitam tidak kehilangan bidak")

	# 4. Multi-piece captures: Pertukaran kompleks berbagai bidak
	var state_multi = ChessBoardState.new("rnb1kbnr/pppp1ppp/8/8/8/8/PPP1PP1P/1NBQKBNR w Kkq - 0 1")
	var mat_multi = ChessBoardState.calculate_material_and_captured(state_multi)
	assert_true(mat_multi["black_captured"].size() >= 1, "Bidak hitam terdeteksi dicapture pada multi-capture")
	assert_true(mat_multi["white_captured"].size() >= 1, "Bidak putih terdeteksi dicapture pada multi-capture")
	assert_equal(mat_multi["white_advantage"], mat_multi["white_material"] - mat_multi["black_material"], "Material advantage konsisten dengan selisih poin")

	# 5. Order invariant: Bidak yang dicapture terurut dari nilai terendah (Pawn -> Knight -> Bishop -> Rook -> Queen)
	for i in range(mat_multi["black_captured"].size() - 1):
		var p1 = mat_multi["black_captured"][i]
		var p2 = mat_multi["black_captured"][i + 1]
		assert_true(ChessBoardState.PIECE_VALUES[p1] <= ChessBoardState.PIECE_VALUES[p2],
			"Urutan bidak dicapture Chess.com terurut ascending berdasar nilai")

	# 6. Tampilan trophy: bidak sejenis berdempetan (overlap), antar jenis diberi jarak.
	var view = CapturedPiecesView.new()
	root.add_child(view)

	assert_equal(view.texture_filter, CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS,
		"View bidak dicapture memakai filter mipmap agar tepi bidak halus")
	assert_true(CapturedPiecesView.BASE_ICON_SIZE > 20.0,
		"Ikon bidak dicapture diperbesar dari basis lama 20 px menjadi %.0f px" % CapturedPiecesView.BASE_ICON_SIZE)

	# Tiga pion sejenis harus tumpang tindih rapat
	view.set_captures([ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN, ChessTypes.PieceType.PAWN],
		ChessTypes.PieceColor.BLACK, 0, "neo")
	var icon_px = view.get_icon_size()
	var three_pawns = view.get_row_width()
	assert_equal(view.get_group_count(), 1, "Tiga pion sejenis dikelompokkan menjadi 1 grup")
	assert_true(three_pawns < icon_px * 3.0 - 8.0,
		"Tiga pion berdempetan rapat (lebar %.1f px < 3 x %.0f px tanpa overlap)" % [three_pawns, icon_px])
	assert_true(three_pawns > icon_px,
		"Tiga pion tetap lebih lebar dari satu bidak (%.1f px)" % three_pawns)
	assert_true(view.get_step_ratio() <= CapturedPiecesView.SAME_TYPE_STEP_RATIO + 0.001,
		"Langkah penumpukan bidak sejenis %.0f%% dari lebar bidak" % (view.get_step_ratio() * 100.0))
	assert_true(absf(three_pawns - (icon_px + 2.0 * icon_px * view.get_step_ratio())) < 0.6,
		"Tiga pion = 1 bidak penuh + 2 langkah penumpukan (%.1f px)" % three_pawns)

	# Bidak berbeda jenis dipisahkan jarak, jadi selalu lebih lebar dari pasangan sejenis
	view.set_captures([ChessTypes.PieceType.PAWN, ChessTypes.PieceType.KNIGHT],
		ChessTypes.PieceColor.BLACK, 0, "neo")
	var pawn_knight = view.get_row_width()
	assert_equal(view.get_group_count(), 2, "Pion + Kuda membentuk 2 grup terpisah")
	assert_true(pawn_knight > three_pawns,
		"Pasangan beda jenis (%.1f px) lebih renggang daripada pasangan sejenis (%.1f px)" % [pawn_knight, three_pawns])

	# Beban maksimum 15 bidak: lebar dikunci agar tidak mendorong kartu pemain keluar viewport
	var full_trophy: Array = []
	for _i in range(8):
		full_trophy.append(ChessTypes.PieceType.PAWN)
	for _i in range(2):
		full_trophy.append(ChessTypes.PieceType.KNIGHT)
	for _i in range(2):
		full_trophy.append(ChessTypes.PieceType.BISHOP)
	for _i in range(2):
		full_trophy.append(ChessTypes.PieceType.ROOK)
	full_trophy.append(ChessTypes.PieceType.QUEEN)

	view.set_captures(full_trophy, ChessTypes.PieceColor.BLACK, 9, "neo")
	assert_equal(view.get_group_count(), 5, "15 bidak 5 jenis dikelompokkan menjadi 5 grup")
	assert_true(view.get_row_width() <= CapturedPiecesView.MAX_ROW_WIDTH + 0.5,
		"Baris bidak dicapture termaksimum %.0f px walau 15 bidak tertangkap (terukur %.1f px)" % [
			CapturedPiecesView.MAX_ROW_WIDTH, view.get_row_width()])
	assert_true(view.get_icon_size() >= CapturedPiecesView.MIN_ICON_SIZE,
		"Pengecilan ikon tidak turun di bawah %.0f px agar tetap terbaca" % CapturedPiecesView.MIN_ICON_SIZE)
	assert_true(view.get_icon_size() > 20.0,
		"Bahkan pada 15 bidak ikon masih lebih besar dari basis lama 20 px (terukur %.0f px)" % view.get_icon_size())
	assert_true(view.custom_minimum_size.y <= 40.0,
		"Tinggi baris bidak (%0.1f px) tetap muat di area konten kartu pemain (40 px)" % view.custom_minimum_size.y)

	# Resolusi tekstur untuk seluruh jenis bidak pada set yang berbeda
	var resolved_all = true
	for piece_type in [ChessTypes.PieceType.PAWN, ChessTypes.PieceType.KNIGHT, ChessTypes.PieceType.BISHOP,
			ChessTypes.PieceType.ROOK, ChessTypes.PieceType.QUEEN]:
		for piece_color in [ChessTypes.PieceColor.WHITE, ChessTypes.PieceColor.BLACK]:
			var tex = CapturedPiecesView.resolve_texture(piece_color, piece_type, "neo")
			if tex == null:
				resolved_all = false
	assert_true(resolved_all, "Seluruh jenis bidak dicapture punya tekstur valid pada set aktif")
	assert_true(CapturedPiecesView.resolve_texture(ChessTypes.PieceColor.WHITE, ChessTypes.PieceType.PAWN, "set_tidak_ada") != null,
		"Set bidak tak dikenal jatuh ke fallback cburnett tanpa ikon kosong")

	CapturedPiecesView.clear_texture_cache()
	root.remove_child(view)
	view.free()

func test_player_card_contrast_formula() -> void:
	print("\n[Kategori 19: Kartu Pemain Terang/Gelap & Formula Kontras WCAG]")

	# 1. Formula dasar: luminansi relatif & rasio kontras WCAG 2.1
	assert_true(absf(CardPalette.relative_luminance(Color.WHITE) - 1.0) < 0.0005,
		"Luminansi relatif putih tepat 1.0")
	assert_true(absf(CardPalette.relative_luminance(Color.BLACK)) < 0.0005,
		"Luminansi relatif hitam tepat 0.0")
	assert_true(absf(CardPalette.contrast_ratio(Color.WHITE, Color.BLACK) - 21.0) < 0.01,
		"Rasio kontras putih vs hitam tepat 21:1")
	assert_true(absf(CardPalette.contrast_ratio(Color.WHITE, Color.WHITE) - 1.0) < 0.001,
		"Rasio kontras warna identik adalah 1:1")
	assert_true(CardPalette.contrast_ratio(Color.WHITE, Color(0.5, 0.5, 0.5)) < CardPalette.AA_TEXT,
		"Abu-abu 50%% gagal ambang 4.5:1 di atas putih - justru alasan tinta tidak boleh ditebak manual")
	assert_true(CardPalette.contrast_ratio(CardPalette.ink(Color.WHITE), Color.WHITE) > 10.0,
		"Formula memilih tinta dengan rasio jauh lebih tinggi daripada abu-abu polos (>10:1)")

	# 2. Kartu Putih berlatar terang, kartu Hitam berlatar gelap
	var light_bg = CardPalette.card_bg(true)
	var dark_bg = CardPalette.card_bg(false)
	assert_true(CardPalette.is_light(light_bg), "Kartu pemain Putih memakai latar terang")
	assert_true(not CardPalette.is_light(dark_bg), "Kartu pemain Hitam memakai latar gelap")
	assert_true(CardPalette.relative_luminance(light_bg) > 0.8,
		"Latar kartu Putih benar-benar near-white (L=%.3f)" % CardPalette.relative_luminance(light_bg))
	assert_true(CardPalette.relative_luminance(dark_bg) < 0.05,
		"Latar kartu Hitam tetap gelap (L=%.3f)" % CardPalette.relative_luminance(dark_bg))

	# 3. Anti "putih di atas putih": tinta nama pada kartu Putih harus GELAP
	var name_on_light = CardPalette.ink(light_bg)
	assert_true(CardPalette.relative_luminance(name_on_light) < 0.2,
		"Nama pemain di kartu Putih memakai tinta gelap, bukan terang")
	assert_true(name_on_light.r < 0.3 and name_on_light.g < 0.3 and name_on_light.b < 0.3,
		"Tinta nama kartu Putih tidak mengandung kanal terang")
	assert_true(name_on_light.a >= 0.99, "Tinta nama kartu Putih sepenuhnya opak")

	# 4. Semua kombinasi latar depan x latar kartu memenuhi ambang WCAG AA
	var ink_light = CardPalette.ink(light_bg)
	var ink_dark = CardPalette.ink(dark_bg)
	assert_true(CardPalette.contrast_ratio(ink_light, light_bg) >= CardPalette.AA_TEXT,
		"Tinta utama vs kartu Putih >= 4.5:1 (terukur %.2f:1)" % CardPalette.contrast_ratio(ink_light, light_bg))
	assert_true(CardPalette.contrast_ratio(ink_dark, dark_bg) >= CardPalette.AA_TEXT,
		"Tinta utama vs kartu Hitam >= 4.5:1 (terukur %.2f:1)" % CardPalette.contrast_ratio(ink_dark, dark_bg))

	for pair in [[light_bg, "Kartu Putih"], [dark_bg, "Kartu Hitam"]]:
		var bg: Color = pair[0]
		var label: String = pair[1]
		assert_true(CardPalette.contrast_ratio(CardPalette.muted_ink(bg), bg) >= CardPalette.AA_TEXT,
			"Badge ELO/warna pada %s >= 4.5:1 (terukur %.2f:1)" % [label, CardPalette.contrast_ratio(CardPalette.muted_ink(bg), bg)])

	# 5. Aksen mate (hijau/merah) diadaptasi per latar, bukan di-hardcode
	var green_on_light = CardPalette.accent(CardPalette.MATE_GREEN, light_bg, CardPalette.AA_TEXT)
	var green_on_dark = CardPalette.accent(CardPalette.MATE_GREEN, dark_bg, CardPalette.AA_TEXT)
	assert_true(CardPalette.contrast_ratio(green_on_light, light_bg) >= CardPalette.AA_TEXT,
		"Hijau mate di kartu Putih digelapkan sampai >= 4.5:1 (terukur %.2f:1)" % CardPalette.contrast_ratio(green_on_light, light_bg))
	assert_true(CardPalette.relative_luminance(green_on_light) < CardPalette.relative_luminance(CardPalette.MATE_GREEN),
		"Aksen pada kartu terang selalu lebih gelap dari warna aslinya")
	assert_true(green_on_dark.is_equal_approx(CardPalette.MATE_GREEN),
		"Aksen pada kartu gelap dipertahankan apa adanya (nol regresi visual)")
	assert_true(CardPalette.contrast_ratio(CardPalette.accent(CardPalette.MATE_RED, light_bg, CardPalette.AA_TEXT), light_bg) >= CardPalette.AA_TEXT,
		"Merah mate juga memenuhi ambang pada kartu terang")

	# 6. Ikon garis (hijau #81b64c) harus memenuhi kontras grafik non-teks 3:1
	var tint_light = CardPalette.icon_tint(light_bg)
	var tint_dark = CardPalette.icon_tint(dark_bg)
	assert_true(tint_light.r < 0.9 and tint_light.r == tint_light.g and tint_light.g == tint_light.b,
		"Ikon pada kartu terang digelapkan lewat pengali grayscale agar hue tetap")
	assert_true(CardPalette.contrast_ratio(CardPalette.ICON_GREEN * tint_light, light_bg) >= CardPalette.AA_LARGE,
		"Ikon di kartu Putih >= 3:1 (terukur %.2f:1)" % CardPalette.contrast_ratio(CardPalette.ICON_GREEN * tint_light, light_bg))
	assert_true(tint_dark.is_equal_approx(Color.WHITE),
		"Ikon di kartu Hitam tidak diubah (modulate 1.0)")
	assert_true(CardPalette.contrast_ratio(CardPalette.ICON_GREEN, dark_bg) >= CardPalette.AA_LARGE,
		"Ikon hijau memang sudah kontras di kartu Hitam")

	# 7. Garis tepi kartu tetap terlihat pada latarnya masing-masing
	assert_true(CardPalette.contrast_ratio(CardPalette.card_border(light_bg), light_bg) >= 1.2,
		"Garis tepi kartu Putih terlihat di atas latar terang")
	assert_true(CardPalette.contrast_ratio(CardPalette.card_border(dark_bg), dark_bg) >= 1.2,
		"Garis tepi kartu Hitam terlihat di atas latar gelap")

	# 8. Poin material di baris bidak dicapture memakai formula yang sama
	var view = CapturedPiecesView.new()
	root.add_child(view)
	view.set_captures([ChessTypes.PieceType.PAWN], ChessTypes.PieceColor.BLACK, 3, "neo", light_bg)
	assert_true(CardPalette.contrast_ratio(view._advantage_color, light_bg) >= CardPalette.AA_TEXT,
		"Teks +3 pada kartu Putih >= 4.5:1 (terukur %.2f:1)" % CardPalette.contrast_ratio(view._advantage_color, light_bg))
	assert_true(view._advantage_color.is_equal_approx(CardPalette.muted_ink(light_bg)),
		"Teks +3 memakai tinta hasil formula, bukan warna terang hardcoded")
	view.set_captures([ChessTypes.PieceType.PAWN], ChessTypes.PieceColor.WHITE, 3, "neo", dark_bg)
	assert_true(view._advantage_color.is_equal_approx(CardPalette.muted_ink(dark_bg)),
		"Teks +3 pada kartu Hitam memakai tinta hasil formula untuk latar gelap")
	root.remove_child(view)
	view.free()

func test_opening_repertoire_and_srs() -> void:
	print("\n[Kategori 20: Opening Repertoire & Spaced Repetition System (Chessreps Parity)]")

	# 1. Katalog Repertoire tersedia di assets/data/repertoire
	var reps = RepertoireService.get_available_repertoires()
	assert_true(reps.size() >= 2, "Tersedia minimal 2 repertoire pembukaan (ditemukan %d)" % reps.size())

	# 2. Repertoire White: Fried Liver Attack
	var fl = RepertoireService.load_repertoire("fried_liver_attack")
	assert_true(fl != null, "Repertoire Fried Liver Attack berhasil dimuat")
	assert_equal(fl.color, "white", "Fried Liver Attack adalah repertoire Putih")
	assert_equal(fl.eco, "C57", "ECO Fried Liver Attack adalah C57")
	assert_true(fl.get_total_player_moves() >= 10, "Fried Liver memiliki >= 10 langkah pemain (ditemukan %d)" % fl.get_total_player_moves())
	assert_true(fl.get_total_lines() >= 3, "Fried Liver memiliki >= 3 variasi cabang (ditemukan %d)" % fl.get_total_lines())

	# 3. Langkah awal Fried Liver dari posisi default FEN
	var fl_first = fl.get_expected_player_move_from_fen(ChessBoardState.DEFAULT_FEN)
	assert_true(fl_first != null, "Langkah pembuka Fried Liver terdeteksi dari start position")
	assert_equal(fl_first.san, "e4", "Langkah pembuka Fried Liver adalah 1. e4")

	# 4. Deteksi blunder manusia yang harus dihukum (5... Nxd5)
	var found_blunder_node = false
	for line in fl.flattened_lines:
		for node in line:
			if node.is_blunder:
				found_blunder_node = true
				break
	assert_true(found_blunder_node, "Repertoire memuat cabang blunder manusia (Lichess/club error) untuk dilatih")

	# 5. Repertoire Black: Caro-Kann Defense
	var ck = RepertoireService.load_repertoire("caro_kann_defense")
	assert_true(ck != null, "Repertoire Caro-Kann Defense berhasil dimuat")
	assert_equal(ck.color, "black", "Caro-Kann Defense adalah repertoire Hitam")
	assert_equal(ck.eco, "B12", "ECO Caro-Kann Defense adalah B12")
	assert_true(ck.get_total_player_moves() >= 6, "Caro-Kann memiliki >= 6 langkah pemain (ditemukan %d)" % ck.get_total_player_moves())

	# 6. Guard ASCII: Semua teks blurb dan anotasi bebas dari karakter non-ASCII
	var all_blurbs_ascii = true
	for rep_tree in [fl, ck]:
		for line in rep_tree.flattened_lines:
			for node in line:
				if not node.blurb.is_empty() and not _is_clean_ascii(node.blurb):
					all_blurbs_ascii = false
	assert_true(all_blurbs_ascii, "Seluruh blurb pembukaan berupa teks ASCII bersih tanpa mojibake")

	# 7. Respon lawan berbobot frekuensi manusia (human_freq)
	var opp_replies = ck.get_opponent_replies_from_fen(ChessBoardState.DEFAULT_FEN)
	assert_true(opp_replies.size() >= 1, "Respon lawan terdeteksi untuk pemain Hitam pada posisi awal")
	assert_equal(opp_replies[0].san, "e4", "Lawan memainkan e4 terhadap Caro-Kann")

	# 8. Mesin Spaced Repetition (SuperMemo SM-2 Math)
	var srs = SRSEngine.new()
	var test_id = "__guard_test_card__"
	var t0 = 1700000000

	# Initial: reps=0, due=true
	assert_true(srs.is_due(test_id, t0), "Kartu baru otomatis due untuk direview")
	assert_equal(srs.get_mastery_level(test_id), 0, "Level penguasaan kartu baru adalah 0 (New)")

	# Percobaan 1: Jawaban sempurna (q=5) -> interval 1 hari
	var res1 = srs.record_attempt(test_id, 5, t0)
	assert_equal(res1["reps"], 1, "SRS percobaan 1 menghasilkan reps = 1")
	assert_equal(res1["interval_days"], 1.0, "SRS percobaan 1 interval tepat 1.0 hari")
	assert_true(res1["ease_factor"] >= 2.5, "Ease factor bertambah atau tetap pada recall sempurna")

	# Percobaan 2: Jawaban sempurna (q=5) -> interval 6 hari
	var t1 = t0 + 86400
	var res2 = srs.record_attempt(test_id, 5, t1)
	assert_equal(res2["reps"], 2, "SRS percobaan 2 menghasilkan reps = 2")
	assert_equal(res2["interval_days"], 6.0, "SRS percobaan 2 interval tepat 6.0 hari")

	# Percobaan 3: Jawaban sempurna (q=5) -> interval = 6 * EF
	var t2 = t1 + (6 * 86400)
	var res3 = srs.record_attempt(test_id, 5, t2)
	assert_equal(res3["reps"], 3, "SRS percobaan 3 menghasilkan reps = 3")
	assert_true(res3["interval_days"] >= 15.0, "SRS percobaan 3 interval berkembang eksponensial (>= 15 hari)")
	assert_equal(srs.get_mastery_level(test_id), 2, "Level penguasaan reps=3 adalah 2 (Reviewing)")

	# Percobaan 4: Blunder / salah (q=1) -> reset reps ke 0 dan interval ke 1 hari
	var t3 = t2 + int(res3["interval_days"] * 86400)
	var res4 = srs.record_attempt(test_id, 1, t3)
	assert_equal(res4["reps"], 0, "SRS reset reps menjadi 0 setelah blunder")
	assert_equal(res4["interval_days"], 1.0, "SRS reset interval menjadi 1.0 hari setelah blunder")
	assert_true(res4["ease_factor"] >= 1.3, "Ease factor dijaga pada lantai minimum 1.3")

	# 9. Metrik Persentase Penguasaan (Mastery Percentage)
	var sample_ids: Array[String] = ["__item_a__", "__item_b__"]
	srs.record_attempt("__item_a__", 5, t0)
	srs.record_attempt("__item_a__", 5, t0 + 86400)
	srs.record_attempt("__item_a__", 5, t0 + 7 * 86400)
	srs.record_attempt("__item_a__", 5, t0 + 25 * 86400)
	srs.record_attempt("__item_a__", 5, t0 + 60 * 86400) # reps=5 -> Level 3 (Mastered)
	var pct = srs.get_mastery_percentage(sample_ids)
	assert_true(pct > 0.0 and pct <= 50.0, "Mastery percentage terhitung proporsional terhadap level (terukur %.1f%%)" % pct)

	# Bersihkan kartu pengujian
	srs.reset_item(test_id)
	srs.reset_item("__item_a__")
	srs.reset_item("__item_b__")

	# 10. OpeningTrainer UI Screen & Interactive Drill Controller
	var trainer = OpeningTrainerScene.instantiate()
	assert_true(trainer != null, "Scene OpeningTrainer berhasil di-instantiate")
	root.add_child(trainer)
	trainer._ready()

	assert_true(trainer.chess_board != null, "ChessBoard ter-resolusi dalam OpeningTrainer")
	assert_true(trainer.status_label != null, "StatusLabel ter-resolusi dalam OpeningTrainer")
	assert_true(trainer.blurb_label != null, "BlurbLabel ter-resolusi dalam OpeningTrainer")
	assert_true(trainer.btn_hint != null and trainer.btn_retry != null and trainer.btn_next_line != null,
		"Tombol kontrol (Hint, Retry, NextLine) lengkap di OpeningTrainer")

	assert_equal(trainer.current_tree.id, "fried_liver_attack", "Default opening aktif adalah Fried Liver Attack")
	assert_true(trainer.status_label.text.contains("Your Turn") or trainer.status_label.text.contains("Play"), "Opening trainer langsung meminta player menjawab langkah pertama")
	assert_true(trainer.chess_board.is_interactive, "Papan catur dalam status is_interactive = true agar bidak dapat digerakkan")

	# Simulasikan langkah salah (h2h4)
	trainer._on_board_move_made(ChessMove.new("h2", "h4"))
	assert_true(trainer.status_label.text.contains("Incorrect"), "Langkah di luar repertoire ditolak dengan status Incorrect")

	# Simulasikan Hint
	trainer._on_hint_pressed()
	assert_true(trainer.hint_used_on_step, "Tombol Hint menandai bendera hint_used_on_step")
	assert_true(trainer.blurb_label.text.contains("Hint:"), "Blurb menampilkan arahan langkah pembukaan saat hint ditekan")

	# Simulasikan langkah benar (e2e4)
	trainer._on_board_move_made(ChessMove.new("e2", "e4"))
	assert_true(trainer.status_label.text.contains("Correct"), "Langkah repertoire yang benar diterima dengan status Correct")

	# Toggle Learn / Drill mode
	var prev_mode = trainer.is_drill_mode
	trainer._on_mode_toggle_pressed()
	assert_true(trainer.is_drill_mode != prev_mode, "Mode toggle berhasil mengubah state antara Drill dan Learn")

	# Ganti repertoire ke Caro-Kann (Black)
	trainer.start_repertoire("caro_kann_defense")
	assert_true(trainer.is_flipped, "Papan otomatis diflip saat berganti ke repertoire Hitam (Caro-Kann)")

	root.remove_child(trainer)
	trainer.free()












