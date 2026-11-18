extends SceneTree

const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const RepertoireTree = preload("res://src/core/repertoire/repertoire_tree.gd")

func _init() -> void:
	print("Starting King's Indian Defense repertoire generator...")
	var success = run_generator()
	print("Generator finished with success: ", success)
	quit(0 if success else 1)

func run_generator() -> bool:
	var lines = get_kid_lines_data()
	print("Loaded %d lines to process." % lines.size())
	
	# Verify all lines for legality and build tree
	var root_dict = build_tree_from_lines(lines)
	if root_dict.is_empty():
		printerr("Failed to build tree from lines!")
		return false
		
	var rep_dict = {
		"id": "kings_indian_defense",
		"name": "King's Indian Defense",
		"eco": "E60",
		"color": "black",
		"description": "Pertahanan hipermodern dinamis melawan 1. d4 dengan formasi g6, Bg7, dan counter-strike sentral tajam e5 atau c5.",
		"root": root_dict
	}
	
	var json_str = JSON.stringify(rep_dict, "  ")
	var out_path = "res://assets/data/repertoire/kings_indian_defense.json"
	var file = FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to open output file: ", out_path)
		return false
	file.store_string(json_str)
	file.close()
	print("Successfully saved repertoire to: ", out_path)
	
	# Validate by loading into RepertoireTree
	var tree = RepertoireTree.new()
	if not tree.load_from_dict(rep_dict):
		printerr("Failed to validate repertoire through RepertoireTree!")
		return false
		
	print("Tree validated successfully!")
	print("Total player moves: ", tree.get_total_player_moves())
	print("Total lines: ", tree.get_total_lines())
	return true

func build_tree_from_lines(lines: Array) -> Dictionary:
	var root_node = null
	
	for line_idx in range(lines.size()):
		var line_data = lines[line_idx]
		var moves = line_data["moves"]
		var blurbs = line_data.get("blurbs", {})
		var blunders = line_data.get("blunders", {})
		var freqs = line_data.get("freqs", {})
		
		var state = ChessBoardState.new()
		var parent_node = null
		
		for m_idx in range(moves.size()):
			var move_san_target = moves[m_idx]
			var legal_moves = ChessMoveGenerator.get_legal_moves(state)
			var matched_move = null
			for lm in legal_moves:
				var san = ChessSAN.move_to_san(state, lm)
				if san == move_san_target:
					matched_move = lm
					break
			
			if matched_move == null:
				printerr("ILLEGAL MOVE in line %d, move %d: %s (FEN: %s)" % [line_idx + 1, m_idx + 1, move_san_target, state.to_fen()])
				return {}
			
			var uci = matched_move.to_uci()
			var san = ChessSAN.move_to_san(state, matched_move)
			
			if m_idx == 0:
				if root_node == null:
					root_node = {
						"move": uci,
						"san": san,
						"human_freq": freqs.get(m_idx, 0.65),
						"blurb": blurbs.get(m_idx, "White membuka permainan dengan Queen pawn untuk menguasai ruang sentral d4 dan e5."),
						"children": []
					}
				parent_node = root_node
			else:
				var found_child = null
				for child in parent_node["children"]:
					if child["move"] == uci:
						found_child = child
						break
				if found_child == null:
					var new_node = {
						"move": uci,
						"san": san,
						"children": []
					}
					if blurbs.has(m_idx):
						new_node["blurb"] = blurbs[m_idx]
					if blunders.has(m_idx):
						new_node["is_blunder"] = true
						new_node["annotation"] = blunders[m_idx]
					if freqs.has(m_idx):
						new_node["human_freq"] = freqs[m_idx]
					parent_node["children"].append(new_node)
					parent_node = new_node
				else:
					if not found_child.has("blurb") and blurbs.has(m_idx):
						found_child["blurb"] = blurbs[m_idx]
					if blunders.has(m_idx):
						found_child["is_blunder"] = true
						found_child["annotation"] = blunders[m_idx]
					parent_node = found_child
			
			ChessMoveGenerator.apply_move_unchecked(state, matched_move)
			
	return root_node if root_node != null else {}

func get_kid_lines_data() -> Array:
	return [
		# 1. Classical - Mar del Plata (9. Ne1 Main Line)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "Nc6", "d5", "Ne7", "Ne1", "Nd7", "Nd3", "f5", "Bd2", "Nf6", "f3", "f4"],
			"freqs": {0: 0.65, 2: 0.58, 4: 0.72, 6: 0.85, 8: 0.75, 10: 0.80, 12: 0.62, 14: 0.78, 16: 0.42, 18: 0.55, 20: 0.48, 22: 0.60},
			"blurbs": {
				1: "King's Indian Defense! Kembangkan Knight secara fleksibel mengawasi petak sentral e4 dan d5.",
				3: "Siapkan fianchetto King's Bishop untuk mengontrol diagonal panjang a1-h8.",
				5: "Tempatkan dark-squared Bishop di posisi ideal dan bersiap castling.",
				7: "Kunci struktur pawn d6 untuk menahan laju e4-e5 White serta membuka jalur light-squared Bishop.",
				9: "Castling kingside segera untuk mengamankan King sebelum pertarungan sentral dimulai.",
				11: "Serang pusat dengan e5! Gerakan khas KID untuk menantang dominasi White di d4.",
				13: "Kembangkan Knight ke c6 menekan sentral d4 dan memancing White mendorong d5.",
				15: "Reroute Knight ke e7 bersiap mendukung dobrakan f5 di sayap raja.",
				17: "Keluarkan Knight ke d7 untuk membuka jalan bagi dorongan pawn f5.",
				19: "Dobrakan f5! Mulai ekspansi agresif di sayap raja khas Mar del Plata.",
				21: "Kembangkan Knight ke f6 untuk menambah tekanan pada petak sentral e4.",
				23: "Dorong f4! Kunci sayap raja dan bersiap melancarkan serangan badai pawn g5-h5."
			}
		},
		# 2. Classical - Mar del Plata (9. b4 Bayonet Attack)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "Nc6", "d5", "Ne7", "b4", "Nh5", "Re1", "f5", "Ng5", "Nf6", "Bf3", "c6"],
			"freqs": {16: 0.35, 18: 0.60, 20: 0.45, 22: 0.50},
			"blurbs": {
				17: "Pindahkan Knight ke h5! Buka jalan pawn f sekaligus mengincar petak f4.",
				19: "Serang rantai sentral White dengan f5 dan aktifkan Rook di f-file.",
				21: "Kembalikan Knight ke f6 untuk mengontrol petak e4 dan menjaga d5.",
				23: "Kikis struktur pawn White dengan c6 untuk memperkuat ketahanan sentral."
			}
		},
		# 3. Classical - Mar del Plata (9. Nd2 Knight Maneuver)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "Nc6", "d5", "Ne7", "Nd2", "a5", "a3", "Nd7", "Rb1", "f5", "b4", "Kh8"],
			"freqs": {16: 0.18, 18: 0.55, 20: 0.62, 22: 0.70},
			"blurbs": {
				17: "Langkah profilaktik a5! Menghambat ekspansi cepat b4 White di sayap menteri.",
				19: "Reroute Knight ke d7 untuk mendukung dobrakan sayap raja f5.",
				21: "Luncurkan pion f5 untuk membuka diagonal dan menekan pion e4 White.",
				23: "Amankan King ke h8 agar bebas dari pin diagonal a2-g8 sebelum memulai badai pion."
			}
		},
		# 4. Classical - Petrosian System (7. d5)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "d5", "a5", "Bg5", "h6", "Bh4", "Na6", "O-O", "Qe8", "Nd2", "Nh7"],
			"freqs": {12: 0.20, 14: 0.65, 16: 0.70, 18: 0.60, 20: 0.50},
			"blurbs": {
				13: "Petrosian System: Kunci sayap menteri dengan a5 untuk mencegah b4.",
				15: "Tantang pin Bishop White segera dengan langkah h6.",
				17: "Kembangkan Knight ke a6 menuju pos ideal di c5 tanpa menghalangi pion c.",
				19: "Lepaskan pin dengan Qe8 sekaligus bersiap memfasilitasi dorongan f5.",
				21: "Reroute Knight ke h7 untuk membersihkan jalur bagi dobrakan f5."
			}
		},
		# 5. Classical - Gligoric System (7. Be3)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "Be3", "Ng4", "Bg5", "f6", "Bh4", "g5", "Bg3", "Nh6", "d5", "c5"],
			"freqs": {12: 0.12, 14: 0.85, 16: 0.75, 18: 0.80, 20: 0.55},
			"blurbs": {
				13: "Gligoric System: Serang langsung Bishop e3 dengan manuver agresif Ng4!",
				15: "Tolak pin Bishop dengan f6 sembari memperkuat perlindungan sayap raja.",
				17: "Usir Bishop White lebih jauh dengan dorongan g5.",
				19: "Tempatkan Knight di h6 untuk mengontrol petak f7 dan bersiap f5.",
				21: "Tutup sayap menteri dengan c5 untuk mengamankan struktur posisi."
			}
		},
		# 6. Classical - Exchange Variation (7. dxe5)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "dxe5", "dxe5", "Qxd8", "Rxd8", "Bg5", "Re8", "Nd5", "Nxd5", "cxd5", "c6", "Bc4", "cxd5", "Bxd5", "Na6"],
			"freqs": {12: 0.08, 14: 0.90, 16: 0.80, 18: 0.75, 20: 0.65, 22: 0.70, 24: 0.60},
			"blurbs": {
				13: "Ambil kembali pion sentral e5 dengan struktur seimbang.",
				15: "Recapture Queen dengan Rook untuk menguasai open d-file.",
				17: "Lindungi pion e5 dengan Re8 sekaligus keluar dari ancaman pin taktis.",
				19: "Tukarkan Knight untuk melenyapkan ancaman garpuan di c7.",
				21: "Kikis pion d5 White dengan c6 untuk membuka jalur bagi perwira Black.",
				23: "Makan pion d5 untuk merusak keunggulan ruang White di sentral.",
				25: "Kembangkan Knight ke a6 menuju pos kuat di c5 atau b4."
			}
		},
		# 7. Classical - Modern Open Classical (7... exd4)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "exd4", "Nxd4", "Re8", "f3", "c6", "Kh1", "Nbd7", "Bg5", "Qb6"],
			"freqs": {12: 0.62, 14: 0.90, 16: 0.85, 18: 0.70, 20: 0.65},
			"blurbs": {
				13: "Buka sentral dengan exd4 untuk memberi aktivitas penuh pada perwira Black.",
				15: "Tempatkan Rook di e8 untuk langsung menekan pion lemah e4 White.",
				17: "Perkuat kontrol petak d5 dengan c6 dan siapkan manuver Queen.",
				19: "Kembangkan Knight ke d7 untuk mendukung mobilitas sentral.",
				21: "Serang balik dengan Qb6 menargetkan pion b2 dan Knight d4 sekaligus!"
			}
		},
		# 8. Classical - Old Main Line (7... Nbd7)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "Nbd7", "Qc2", "c6", "Rd1", "Qe7", "Rb1", "a5", "d5", "Nc5"],
			"freqs": {12: 0.62, 14: 0.50, 16: 0.60, 18: 0.45, 20: 0.65},
			"blurbs": {
				13: "Kembangkan Knight ke d7 menjaga fleksibilitas formasi sentral.",
				15: "Perkokoh fondasi sentral dengan c6 untuk menahan tekanan d-file.",
				17: "Sentralisasi Queen ke e7 untuk menghubungkan kedua Rook.",
				19: "Cegah ekspansi sayap menteri White dengan a5.",
				21: "Tancapkan Knight di pos permanen c5 menekan pion e4 White."
			}
		},
		# 9. Classical - Center Fork Blunder Trap
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Be2", "e5", "O-O", "exd4", "Nxd4", "Nxe4", "Nxe4", "d5", "cxd5", "Qxd5", "Nb5", "Qxe4"],
			"freqs": {12: 0.62, 14: 0.90, 16: 0.80, 18: 0.60, 20: 0.50},
			"blunders": {14: "Mistake: White membiarkan center fork trick yang menghancurkan sentral."},
			"blurbs": {
				15: "Taktik jitu! Pengorbanan sementara Nxe4 memanfaatkan sentral yang longgar.",
				17: "Center fork trick! Dorong d5 menggarpu Knight e4 dan Bishop e2 White.",
				19: "Recapture dengan Queen di d5 merebut inisiatif sentral ganda.",
				21: "Makan pion e4 dengan Queen, Black unggul kompensasi dan aktivitas penuh."
			}
		},
		# 10. Sämisch Variation - Main Line (6. Be3 e5 7. d5)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f3", "O-O", "Be3", "e5", "d5", "c6", "Qd2", "cxd5", "cxd5", "a6", "O-O-O", "Nbd7", "Kb1", "b5"],
			"freqs": {8: 0.20, 10: 0.85, 12: 0.70, 14: 0.60, 16: 0.80, 18: 0.75, 20: 0.70},
			"blurbs": {
				9: "Samisch Variation: White memperkokoh e4 dengan f3. Castling Black tetap prioritas.",
				11: "Serang pusat dengan e5 menantang rantai pawn White.",
				13: "Kikis struktur pawn White di sayap menteri dengan dorongan c6.",
				15: "Buka c-file dengan cxd5 untuk mempersiapkan serangan balik sayap menteri.",
				17: "Siapkan badai pion sayap menteri dengan a6.",
				19: "Kembangkan Knight ke d7 menuju pos serangan c5 atau b6.",
				21: "Ekspansi agresif b5! Lancarkan serangan balik cepat ke King White di c1."
			}
		},
		# 11. Sämisch Variation - Panno System (6... Nc6)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f3", "O-O", "Be3", "Nc6", "Nge2", "a6", "Qd2", "Rb8", "h4", "h5", "O-O-O", "b5"],
			"freqs": {8: 0.20, 10: 0.85, 12: 0.65, 14: 0.80, 16: 0.70, 18: 0.85},
			"blurbs": {
				11: "Panno System: Kembangkan Knight ke c6 untuk mempersiapkan dorongan cepat a6 dan b5.",
				13: "Persiapkan ekspansi sayap menteri dengan a6.",
				15: "Tempatkan Rook di b8 untuk mendukung pembukaan jalur b-file.",
				17: "Hentikan pion badai White dengan h5 mengunci laju sayap raja.",
				19: "Dobrakan b5! Buka sayap menteri secara frontal menghadapi castling panjang White."
			}
		},
		# 12. Sämisch Variation - 6. Bg5 System
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f3", "O-O", "Bg5", "c5", "d5", "e6", "Qd2", "exd5", "cxd5", "Re8", "Nge2", "a6", "a4", "Nbd7"],
			"freqs": {8: 0.20, 10: 0.12, 12: 0.85, 14: 0.70, 16: 0.80, 18: 0.75, 20: 0.70},
			"blurbs": {
				11: "Tantang dominasi White dengan dorongan sayap c5 gaya Benoni.",
				13: "Gempur rantai sentral dengan e6 untuk membuka e-file.",
				15: "Buka file sentral dengan exd5 memanfaatkan diagonal bebas.",
				17: "Aktivasi Rook di e8 menekan jalur sentral e-file.",
				19: "Persiapkan kontrol sayap menteri dengan dorongan a6.",
				21: "Kembangkan Knight ke d7 menuju petak e5 yang strategis."
			}
		},
		# 13. Sämisch Variation - Early Exchange Blunder
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f3", "O-O", "Be3", "e5", "dxe5", "dxe5", "Qxd8", "Rxd8", "Nd5", "Nxd5", "cxd5", "c6", "Bc4", "b5", "Bb3", "Bb7"],
			"freqs": {8: 0.20, 10: 0.85, 12: 0.10, 14: 0.90, 16: 0.70, 18: 0.80, 20: 0.65},
			"blunders": {12: "Inaccuracy: White menukar Queen terlalu dini, melepaskan inisiatif endgame kepada Black."},
			"blurbs": {
				13: "Recapture pion e5 dengan aman menjaga kestabilan posisi.",
				15: "Kuasai d-file terbuka dengan Rook d8.",
				17: "Lenyapkan lompatan Knight White di d5 dengan pertukaran bersih.",
				19: "Gempur pion d5 White dengan c6.",
				21: "Usir Bishop White dengan dorongan sayap b5!",
				23: "Kembangkan Bishop ke b7 menekan balik pion d5 White."
			}
		},
		# 14. Averbakh Variation - 6... c5 Main Line
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Be2", "O-O", "Bg5", "c5", "d5", "e6", "Qd2", "exd5", "exd5", "Re8", "Nf3", "Bg4", "O-O", "Nbd7"],
			"freqs": {8: 0.08, 10: 0.70, 12: 0.80, 14: 0.65, 16: 0.75, 18: 0.70, 20: 0.85},
			"blurbs": {
				9: "Averbakh Variation: White menyiapkan pin Bg5 sebelum melangkahkan Nf3.",
				11: "Serang pusat dengan c5 meruntuhkan penguasaan petak gelap White.",
				13: "Kikis pion sentral dengan e6 membuka aktivitas e-file.",
				15: "Buka file sentral dengan exd5.",
				17: "Kuasai e-file dengan Re8 memberi tekanan konstan ke King White.",
				19: "Kembangkan light-squared Bishop ke g4 mem-pin Knight f3.",
				21: "Sentralisasi Knight ke d7 menghubungkan seluruh perwira Black."
			}
		},
		# 15. Averbakh Variation - 6... h6 System
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Be2", "O-O", "Bg5", "h6", "Be3", "e5", "d5", "a5", "Qd2", "Kh7", "h3", "Na6", "Nf3", "Nc5"],
			"freqs": {8: 0.08, 10: 0.70, 12: 0.85, 14: 0.60, 16: 0.75, 18: 0.65, 20: 0.80},
			"blurbs": {
				11: "Tantang Bishop White dengan h6 untuk memaksa mundur ke e3.",
				13: "Serang pusat dengan e5 begitu Bishop musuh mundur.",
				15: "Kunci sayap menteri dengan a5.",
				17: "Amankan King ke h7 sembari mempertahankan pion h6.",
				19: "Kembangkan Knight ke a6 menuju pos aktif.",
				21: "Tancapkan Knight di c5 dengan garpuan tekanan pada pion e4 dan b3."
			}
		},
		# 16. Four Pawns Attack - Main Line (7. d5)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f4", "O-O", "Nf3", "c5", "d5", "e6", "Be2", "exd5", "cxd5", "Re8", "e5", "dxe5", "fxe5", "Ng4", "Bg5", "Qb6"],
			"freqs": {8: 0.08, 10: 0.85, 12: 0.75, 14: 0.80, 16: 0.70, 18: 0.85, 20: 0.90, 22: 0.60},
			"blurbs": {
				9: "Four Pawns Attack! White merebut ruang masif tetapi memperlemah stabilitas King.",
				11: "Dobrakan sentral c5! Hancurkan dinding pion empat lapis White.",
				13: "Bongkar pilar d5 dengan e6.",
				15: "Recapture exd5 untuk membuka e-file menghadapi pion e4 yang overextended.",
				17: "Tempatkan Rook di e8 menekan pion e4/e5 White.",
				19: "Makan pion e5 dengan dxe5 untuk meruntuhkan rantai sentral musuh.",
				21: "Lompatkan Knight ke g4 menyerang pion lemah e5 secara ganda.",
				23: "Serang balik dengan Qb6 menargetkan titik lemah b2 dan Bishop g5!"
			}
		},
		# 17. Four Pawns Attack - 7. dxc5 Qa5 Pin
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "f4", "O-O", "Nf3", "c5", "dxc5", "Qa5", "Bd3", "Qxc5", "Qe2", "Bg4", "Be3", "Qa5", "O-O", "Nc6"],
			"freqs": {8: 0.08, 10: 0.85, 12: 0.20, 14: 0.80, 16: 0.75, 18: 0.85, 20: 0.80},
			"blurbs": {
				13: "Taktik jitu Qa5! Pin Knight c3 dan bersiap merebut kembali pion c5.",
				15: "Recapture dengan Queen di c5 mengamankan dominasi diagonal a7-g1.",
				17: "Kembangkan Bishop ke g4 untuk menekan Knight f3 White.",
				19: "Mundurkan Queen ke a5 menjaga pin dan tekanan sayap menteri.",
				21: "Kembangkan Knight ke c6 menempati petak ideal sentral."
			}
		},
		# 18. Fianchetto Variation - Main Line 6... Nbd7
		{
			"moves": ["d4", "Nf6", "c4", "g6", "g3", "Bg7", "Bg2", "O-O", "Nf3", "d6", "O-O", "Nbd7", "Nc3", "e5", "e4", "c6", "h3", "Re8", "Be3", "exd4", "Nxd4", "Nc5", "Qc2", "a5"],
			"freqs": {4: 0.20, 6: 0.90, 8: 0.90, 10: 0.90, 12: 0.70, 14: 0.75, 16: 0.80, 18: 0.60, 20: 0.85, 22: 0.75},
			"blurbs": {
				5: "Fianchetto Variation: White meniru formasi g3-Bg2 untuk meredam King's Bishop Black.",
				7: "Castling segera mengamankan King.",
				9: "Kunci pion d6 menjaga kestabilan petak pusat.",
				11: "Kembangkan Knight ke d7 bersiap mendukung dobrakan e5.",
				13: "Serang pusat dengan e5!",
				15: "Perkuat pion sentral dengan c6.",
				17: "Tempatkan Rook di e8 mengawasi petak e4.",
				19: "Buka posisi dengan exd4 untuk mengaktifkan diagonal Bishop g7.",
				21: "Tancapkan Knight di c5 menyerang pion e4 White.",
				23: "Langkah profilaktik a5 mengamankan pos Knight c5 dari dorongan b4."
			}
		},
		# 19. Fianchetto Variation - Panno System (6... Nc6)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "g3", "Bg7", "Bg2", "O-O", "Nf3", "d6", "O-O", "Nc6", "Nc3", "a6", "d5", "Na5", "Nd2", "c5", "Qc2", "Rb8", "b3", "b5"],
			"freqs": {4: 0.20, 6: 0.90, 8: 0.90, 10: 0.90, 12: 0.65, 14: 0.80, 16: 0.75, 18: 0.60, 20: 0.70},
			"blurbs": {
				11: "Panno System melawan Fianchetto: Kembangkan Knight ke c6 menekan sentral.",
				13: "Persiapkan manuver b5 dengan a6.",
				15: "Pindahkan Knight ke tepi di a5 menekan pion c4 White.",
				17: "Kunci ruang dengan c5 memperkokoh c-file.",
				19: "Tempatkan Rook di b8 untuk mendukung ekspansi b-file.",
				21: "Dobrakan sayap menteri b5! Rebut inisiatif dengan serangan balik tajam."
			}
		},
		# 20. Fianchetto Variation - Yugoslav System (6... c6)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "g3", "Bg7", "Bg2", "O-O", "Nf3", "d6", "O-O", "c6", "Nc3", "Qa5", "e4", "Bg4", "h3", "Bxf3", "Bxf3", "Nfd7", "Be3", "c5"],
			"freqs": {4: 0.20, 6: 0.90, 8: 0.90, 10: 0.90, 12: 0.50, 14: 0.70, 16: 0.65, 18: 0.85, 20: 0.70},
			"blurbs": {
				11: "Yugoslav System: Siapkan kontrol petak sentral dengan c6.",
				13: "Aktifkan Queen ke a5 menekan queenside White.",
				15: "Pin Knight f3 dengan Bg4.",
				17: "Tukarkan Bishop untuk melemahkan kontrol White atas petak sentral d4.",
				19: "Reroute Knight ke d7 untuk membuka jalan bagi pion c5.",
				21: "Dobrakan sentral c5! Hancurkan fondasi pion d4 White."
			}
		},
		# 21. Makogonov Variation (5. h3)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "h3", "O-O", "Be3", "e5", "d5", "Na6", "g4", "Nc5", "f3", "a5", "Qd2", "c6"],
			"freqs": {8: 0.05, 10: 0.80, 12: 0.75, 14: 0.65, 16: 0.80, 18: 0.70},
			"blurbs": {
				9: "Makogonov System: White mencegah Bg4/Ng4 dengan h3. Black tenang castling.",
				11: "Serang pusat dengan e5!",
				13: "Kembangkan Knight ke tepi di a6 bersiap melompat ke c5.",
				15: "Tancapkan Knight di c5 menyerang pion e4 White.",
				17: "Kunci laju b4 White dengan a5.",
				19: "Kikis rantai pion sentral White dengan c6."
			}
		},
		# 22. Smyslov System (5. Nf3 O-O 6. Bg5)
		{
			"moves": ["d4", "Nf6", "c4", "g6", "Nc3", "Bg7", "e4", "d6", "Nf3", "O-O", "Bg5", "c5", "d5", "h6", "Bh4", "g5", "Bg3", "Nh5", "Nd2", "Nxg3", "hxg3", "e6"],
			"freqs": {8: 0.75, 10: 0.10, 12: 0.80, 14: 0.85, 16: 0.80, 18: 0.60, 20: 0.90},
			"blurbs": {
				11: "Smyslov System: Tantang sentral White segera dengan c5.",
				13: "Usir Bishop White dengan h6.",
				15: "Rebut ruang sayap raja dengan g5.",
				17: "Incar sepasang Bishop musuh dengan manuver Nh5!",
				19: "Makan Bishop g3 melenyapkan perwira bertahan White.",
				21: "Bongkar pusat dengan e6 untuk membuka jalur serang Black."
			}
		},
		# 23. Anti-KID - London System (2. Bf4)
		{
			"moves": ["d4", "Nf6", "Bf4", "g6", "e3", "Bg7", "Nf3", "O-O", "Be2", "d6", "h3", "c5", "c3", "b6", "O-O", "Bb7", "Nbd2", "Nbd7", "a4", "a6"],
			"freqs": {2: 0.25, 4: 0.80, 6: 0.85, 8: 0.75, 10: 0.70, 12: 0.80, 14: 0.85, 16: 0.75, 18: 0.60},
			"blurbs": {
				3: "Hadapi London System dengan setup KID fleksibel g6 dan Bg7.",
				5: "Selesaikan perkembangan sayap raja dengan Bg7.",
				7: "Castling segera mengamankan King.",
				9: "Kunci petak d6 menjaga sentral tetap stabil.",
				11: "Serang rantai pion London dengan dorongan c5.",
				13: "Siapkan double-fianchetto dengan b6.",
				15: "Tempatkan Bishop di b7 mengontrol diagonal panjang a8-h1.",
				17: "Kembangkan Knight ke d7 menjaga koordinasi perwira harmonis.",
				19: "Profilaksis a6 mencegah dorongan a5 White dan mempertahankan posisi."
			}
		},
		# 24. Anti-KID - Torre Attack (2. Nf3 g6 3. Bg5)
		{
			"moves": ["d4", "Nf6", "Nf3", "g6", "Bg5", "Bg7", "Nbd2", "O-O", "e4", "d6", "c3", "c5", "Bd3", "cxd4", "cxd4", "Nc6", "O-O", "Bg4", "h3", "Bxf3", "Nxf3", "d5"],
			"freqs": {2: 0.15, 4: 0.40, 6: 0.75, 8: 0.70, 10: 0.65, 12: 0.60, 14: 0.85, 16: 0.75, 18: 0.80, 20: 0.85},
			"blurbs": {
				3: "Tetap tenang dalam formasi King's Indian dengan g6.",
				5: "Fianchetto Bishop mengawasi diagonal a1-h8.",
				7: "Castling kingside cepat.",
				9: "Kunci struktur dengan d6.",
				11: "Gempur sentral dengan c5 merusak formasi pion White.",
				13: "Tukarkan pion di d4 untuk melenyapkan rantai pusat White.",
				15: "Kembangkan Knight ke c6 menekan pion d4.",
				17: "Pin Knight f3 White dengan Bg4.",
				19: "Tukarkan Bishop untuk melemahkan kontrol sentral musuh.",
				21: "Dobrakan pamungkas d5! Hancurkan pusat White dan capai kesetaraan penuh."
			}
		}
	]
