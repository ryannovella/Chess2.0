extends SceneTree

const ChessBoardState = preload("res://src/core/chess_board_state.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")
const ChessSAN = preload("res://src/core/chess_san.gd")
const RepertoireTree = preload("res://src/core/repertoire/repertoire_tree.gd")

func _init() -> void:
	print("Starting Traps Repertoire Generator...")
	var success_white = generate_white_traps()
	var success_black = generate_black_traps()
	if success_white and success_black:
		print("ALL TRAPS REPERTOIRES GENERATED AND VALIDATED SUCCESSFULLY!")
		quit(0)
	else:
		printerr("FAILED to generate traps repertoires!")
		quit(1)

func generate_white_traps() -> bool:
	print("\n--- Generating Traps Variation (White) ---")
	var lines = get_white_traps_lines()
	print("Loaded %d lines for White Traps." % lines.size())
	
	var root_dict = build_tree_from_lines(lines)
	if root_dict.is_empty():
		printerr("Failed to build White tree!")
		return false
		
	var rep_dict = {
		"id": "traps_variation_white",
		"name": "Traps Variation (White)",
		"eco": "C50",
		"color": "white",
		"description": "Koleksi jebakan pembukaan mematikan untuk Putih: Legal's Mate, Damiano Trap, Caro-Kann Smothered Mate, dan Petrov Copycat dengan berbagai variasi counter-attack.",
		"root": root_dict
	}
	
	var json_str = JSON.stringify(rep_dict, "  ")
	var out_path = "res://assets/data/repertoire/traps_variation_white.json"
	var file = FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to write to: ", out_path)
		return false
	file.store_string(json_str)
	file.close()
	print("Saved to: ", out_path)
	
	var tree = RepertoireTree.new()
	if not tree.load_from_dict(rep_dict):
		printerr("Failed to validate White tree through RepertoireTree!")
		return false
	print("White tree validated: %d lines, %d player moves." % [tree.get_total_lines(), tree.get_total_player_moves()])
	return true

func generate_black_traps() -> bool:
	print("\n--- Generating Traps Variation (Black) ---")
	var lines_e4 = get_black_traps_e4_lines()
	var lines_d4 = get_black_traps_d4_lines()
	print("Loaded %d e4 lines and %d d4 lines for Black Traps." % [lines_e4.size(), lines_d4.size()])
	
	var root_e4 = build_tree_from_lines(lines_e4)
	var root_d4 = build_tree_from_lines(lines_d4)
	if root_e4.is_empty() or root_d4.is_empty():
		printerr("Failed to build Black tree roots!")
		return false
		
	var rep_dict = {
		"id": "traps_variation_black",
		"name": "Traps Variation (Black)",
		"eco": "C50",
		"color": "black",
		"description": "Koleksi jebakan pembukaan mematikan untuk Hitam: Blackburne Shilling Gambit, Fishing Pole, King's Gambit Free Pawn, Queen's Gambit Fake Pin, dan Lasker Trap.",
		"roots": [root_e4, root_d4]
	}
	
	var json_str = JSON.stringify(rep_dict, "  ")
	var out_path = "res://assets/data/repertoire/traps_variation_black.json"
	var file = FileAccess.open(out_path, FileAccess.WRITE)
	if not file:
		printerr("Failed to write to: ", out_path)
		return false
	file.store_string(json_str)
	file.close()
	print("Saved to: ", out_path)
	
	var tree = RepertoireTree.new()
	if not tree.load_from_dict(rep_dict):
		printerr("Failed to validate Black tree through RepertoireTree!")
		return false
	print("Black tree validated: %d lines, %d player moves." % [tree.get_total_lines(), tree.get_total_player_moves()])
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
						"human_freq": freqs.get(m_idx, 0.70),
						"children": []
					}
					if blurbs.has(m_idx):
						root_node["blurb"] = blurbs[m_idx]
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

func get_white_traps_lines() -> Array:
	return [
		# --- TRAP 1: LEGAL'S MATE (Légal Trap) ---
		# 1. Main Line Checkmate
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "d6", "Nc3", "Bg4", "h3", "Bh5", "Nxe5", "Bxd1", "Bxf7+", "Ke7", "Nd5#"],
			"blunders": {9: "Bh5?! Mundur pasif mempertahankan pin semu, memicu jebakan pengorbanan Ratu!", 11: "Bxd1?? Blunder fatal mengambil umpan Ratu yang berujung skakmat seketika!"},
			"blurbs": {
				0: "Buka sentral dengan 1.e4 untuk mengontrol petak d5 dan f5.",
				2: "Kembangkan Knight ke f3 menekan pion e5.",
				4: "Bc4 membidik petak lemah f7.",
				6: "Nc3 memperkuat kontrol petak d5.",
				8: "5.h3! Menguji niat Bishop lawan dan menyiapkan jebakan Legal's Mate.",
				10: "6.Nxe5!! Pengorbanan Ratu spektakuler! Mengosongkan diagonal dan petak d5.",
				12: "7.Bxf7+! Skak tajam memaksa King melangkah ke petak terbuka e7.",
				14: "8.Nd5#!! Legal's Mate sempurna! Tiga perwira ringan mengeksekusi skakmat indah."
			}
		},
		# 2. Black avoids Queen grab with 6...Nxe5
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "d6", "Nc3", "Bg4", "h3", "Bh5", "Nxe5", "Nxe5", "Qxh5", "Nxc4", "Qb5+", "c6", "Qxc4"],
			"blurbs": {
				10: "6.Nxe5! Taktik sentral yang merebut keunggulan material.",
				12: "7.Qxh5! Rebut Bishop yang menggantung di h5.",
				14: "8.Qb5+! Skak garpu mematikan terhadap King dan Knight c4.",
				16: "9.Qxc4! Tangkap kembali Knight c4, White unggul satu pion bersih dan kontrol pusat."
			}
		},
		# 3. Black plays 6...dxe5
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "d6", "Nc3", "Bg4", "h3", "Bh5", "Nxe5", "dxe5", "Qxh5", "Qd7", "d3", "Nf6", "Qd1"],
			"blurbs": {
				12: "7.Qxh5! Menghukum kesalahan Black dengan menangkap Bishop h5 serta mengancam f7.",
				14: "8.d3! Perkokoh pion sentral dan buka diagonal dark-squared Bishop.",
				16: "9.Qd1! Tarik Ratu ke posisi aman dengan keunggulan satu pion bersih."
			}
		},
		# 4. Black trades on f3 (5...Bxf3)
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "d6", "Nc3", "Bg4", "h3", "Bxf3", "Qxf3", "Nf6", "d3", "Be7", "Be3", "O-O", "O-O"],
			"blurbs": {
				10: "6.Qxf3! Ambil dengan Ratu untuk membidik f7 dan mempertahankan bishop pair.",
				12: "7.d3! Struktur pion kokoh menguasai sentral.",
				14: "8.Be3! Selesaikan pengembangan perwira ringan.",
				16: "9.O-O! Amankan King dengan keunggulan sepasang Gajah."
			}
		},

		# --- TRAP 2: DAMIANO TRAP ---
		# 5. Damiano Trap - Main Line (Greedy 3...fxe5??)
		{
			"moves": ["e4", "e5", "Nf3", "f6", "Nxe5", "fxe5", "Qh5+", "Ke7", "Qxe5+", "Kf7", "Bc4+", "d5", "Bxd5+", "Kg6", "h4", "h5", "Bxb7", "Bd6", "Qa5", "Nc6", "Bxc6", "Rb8", "d4"],
			"blunders": {3: "2...f6? Damiano Defense yang sangat melemahkan diagonal raja e8-h5!", 5: "3...fxe5?? Menerima Knight mengundang pembongkaran total sayap raja!"},
			"blurbs": {
				4: "3.Nxe5!! Pengorbanan Knight legendaris untuk membongkar kelemahan f6.",
				6: "4.Qh5+! Skak tajam memanfaatkan diagonal yang terbuka lebar.",
				8: "5.Qxe5+! Ambil pion sentral sambil terus menyerang King Black.",
				10: "6.Bc4+! Aktifkan Bishop membimbing King ke tengah medan terbuka.",
				12: "7.Bxd5+! Ambil pion penutup dengan tempo skak.",
				14: "8.h4! Dorong h-pawn mengancam h5+ yang mematikan.",
				16: "9.Bxb7! Taktik defleksi brilian terhadap Rook a8 dan Bishop c8.",
				18: "10.Qa5! Amankan Ratu sambil tetap menekan posisi Black.",
				20: "11.Bxc6! Bersihkan perwira pertahanan lawan.",
				22: "12.d4! Kuasai pusat penuh dengan keunggulan material mutlak."
			}
		},
		# 6. Damiano Trap - 8...h6 fatal checkmate
		{
			"moves": ["e4", "e5", "Nf3", "f6", "Nxe5", "fxe5", "Qh5+", "Ke7", "Qxe5+", "Kf7", "Bc4+", "d5", "Bxd5+", "Kg6", "h4", "h6", "h5+", "Kh7", "Qf5+", "g6", "Qxg6#"],
			"blunders": {15: "8...h6? Melemahkan sayap raja lebih parah memicu gelombang skak penutup!"},
			"blurbs": {
				14: "8.h4! Ciptakan ancaman skakmat langsung.",
				16: "9.h5+! Paksa King Black mundur ke pojok h7.",
				18: "10.Qf5+! Skak diagonal memaksa penutupan g6.",
				20: "11.Qxg6#!! Skakmat mutlak di petak g6 dengan dukungan Bishop d5!"
			}
		},
		# 7. Damiano Trap - Black blocks with 4...g6
		{
			"moves": ["e4", "e5", "Nf3", "f6", "Nxe5", "fxe5", "Qh5+", "g6", "Qxe5+", "Qe7", "Qxh8", "Nf6", "d3", "d5", "Bg5", "Nbd7", "Nc3", "c6", "O-O-O"],
			"blurbs": {
				8: "5.Qxe5+! Skak ganda memenangkan Rook h8.",
				10: "6.Qxh8! Tangkap Rook gratis di sudut papan.",
				12: "7.d3! Siapkan jalan keluar bagi Queen melalui petak sentral.",
				14: "8.Bg5! Pin Knight f6 untuk mematahkan serangan balik Black.",
				16: "9.Nc3! Tambah tekanan pada pion d5.",
				18: "10.O-O-O! Amankan King ke queenside dengan keunggulan satu Benteng penuh."
			}
		},
		# 8. Damiano Trap - Black retreats 3...Qe7
		{
			"moves": ["e4", "e5", "Nf3", "f6", "Nxe5", "Qe7", "Nf3", "Qxe4+", "Be2", "d5", "O-O", "Be6", "Re1"],
			"blurbs": {
				6: "4.Nf3! Tarik Knight kembali ke petak aman f3.",
				8: "5.Be2! Kembangkan Bishop sekaligus menutupi jalur skak.",
				10: "6.O-O! Amankan King ke tempat terlindung.",
				12: "7.Re1! Buka jalur e-file menyerang Queen Black yang terisolasi."
			}
		},

		# --- TRAP 3: CARO-KANN SMOTHERED MATE ---
		# 9. Caro-Kann Smothered Mate - Main Line
		{
			"moves": ["e4", "c6", "d4", "d5", "Nc3", "dxe4", "Nxe4", "Nd7", "Qe2", "Ngf6", "Nd6#"],
			"blunders": {9: "5...Ngf6?? Langkah alami yang menjadi blunder fatal akibat pin c7!"},
			"blurbs": {
				2: "2.d4! Bangun duet pion sentral klasik melawan Caro-Kann.",
				4: "3.Nc3! Kembangkan Knight mempertahankan pion sentral.",
				6: "4.Nxe4! Tangkap kembali pion di e4 dengan perwira aktif.",
				8: "5.Qe2! Langkah jebakan licik memasang pin tak terlihat pada pion c7.",
				10: "6.Nd6#!! Smothered mate spektakuler! Pion c7 terpin ke King oleh Ratu e2!"
			}
		},
		# 10. Caro-Kann - Black defends with 5...e6
		{
			"moves": ["e4", "c6", "d4", "d5", "Nc3", "dxe4", "Nxe4", "Nd7", "Qe2", "e6", "Nf3", "Ngf6", "Bg5", "Be7", "O-O-O", "O-O"],
			"blurbs": {
				10: "6.Nf3! Kembangkan sayap raja secara harmonis.",
				12: "7.Bg5! Pin Knight f6 untuk membatasi manuver lawan.",
				14: "8.O-O-O! Castling queenside dengan inisiatif serangan tajam."
			}
		},
		# 11. Caro-Kann - Black plays 5...Ndf6
		{
			"moves": ["e4", "c6", "d4", "d5", "Nc3", "dxe4", "Nxe4", "Nd7", "Qe2", "Ndf6", "Nxf6+", "Nxf6", "Nf3", "Bg4", "c3", "e6", "h3", "Bh5", "g4", "Bg6"],
			"blurbs": {
				10: "6.Nxf6+! Tukar Knight untuk merusak koordinasi bidak lawan.",
				12: "7.Nf3! Terus kembangkan perwira ke petak ideal.",
				14: "8.c3! Perkuat pengawalan pion d4.",
				16: "9.h3! Usir Bishop lawan dari diagonal pin.",
				18: "10.g4! Rebut ruang di sayap raja dan usir Bishop ke g6."
			}
		},
		# 12. Caro-Kann - Black plays 5...Qc7
		{
			"moves": ["e4", "c6", "d4", "d5", "Nc3", "dxe4", "Nxe4", "Nd7", "Qe2", "Qc7", "g3", "Ngf6", "Bf4", "Qa5+", "Bd2", "Qc7", "Bg2", "Nxe4", "Qxe4"],
			"blurbs": {
				10: "6.g3! Siapkan Bf4 untuk menekan Queen Black.",
				12: "7.Bf4! Serang Ratu Black dengan tempo perwira aktif.",
				14: "8.Bd2! Mundur taktis menangkis skak sambil mempertahankan ancaman.",
				16: "9.Bg2! Tempatkan Bishop di diagonal panjang.",
				18: "10.Qxe4! Tangkap kembali dengan sentralisasi Ratu yang dominan."
			}
		},

		# --- TRAP 4: PETROV COPYCAT TRAP ---
		# 13. Petrov Copycat - Main Line (Knight retreats 4...Nf6??)
		{
			"moves": ["e4", "e5", "Nf3", "Nf6", "Nxe5", "Nxe4", "Qe2", "Nf6", "Nc6+", "Be7", "Nxd8", "Kxd8"],
			"blunders": {5: "3...Nxe4? Copycat prematur sebelum memainkan 3...d6!", 7: "4...Nf6?? Menarik Knight mundur membiarkan skak terbuka mematikan!"},
			"blurbs": {
				4: "3.Nxe5! Ambil pion sentral e5 pada Petrov Defense.",
				6: "4.Qe2! Langkah kunci memanfaatkan pin e-file terhadap King lawan.",
				8: "5.Nc6+! Discovered check spektakuler yang langsung memenangkan Ratu!",
				10: "6.Nxd8! Tangkap Ratu Black, White unggul Ratu penuh pada langkah ke-6."
			}
		},
		# 14. Petrov Copycat - Black plays 4...Qe7 (pin break)
		{
			"moves": ["e4", "e5", "Nf3", "Nf6", "Nxe5", "Nxe4", "Qe2", "Qe7", "Qxe4", "d6", "d4", "dxe5", "dxe5", "Nc6", "Nc3", "Qxe5", "Qxe5+", "Nxe5", "Bf4", "Bd6", "O-O-O"],
			"blurbs": {
				8: "5.Qxe4! Rebut Knight di e4.",
				10: "6.d4! Dukung penguasaan sentral d4 yang kokoh.",
				12: "7.dxe5! Rebut kembali pion dengan keunggulan struktur.",
				14: "8.Nc3! Kembangkan perwira dan bersiap castling sayap ratu.",
				16: "9.Qxe5+! Sederhanakan posisi menuju endgame unggul satu pion.",
				18: "10.Bf4! Kembangkan Bishop menyerang Knight c7/e5.",
				20: "11.O-O-O! Amankan King ke d1 dengan dominasi ruang yang jelas."
			}
		},
		# 15. Petrov Copycat - Black defends with 4...d5
		{
			"moves": ["e4", "e5", "Nf3", "Nf6", "Nxe5", "Nxe4", "Qe2", "d5", "d3", "Qe7", "dxe4", "Qxe5", "exd5", "Bd6", "Nc3", "O-O", "Qxe5", "Bxe5", "Bd2"],
			"blurbs": {
				8: "5.d3! Usir Knight e4 yang sedang terpin pada e-file.",
				10: "6.dxe4! Tangkap Knight e4 dengan keunggulan material.",
				12: "7.exd5! Menangkan pion sentral d5 dengan pin Ratu.",
				14: "8.Nc3! Tambah penjagaan pada d5 dan percepat development.",
				16: "9.Qxe5! Tukar Queen menuju babak akhir yang sangat menguntungkan.",
				18: "10.Bd2! Kembangkan Bishop untuk menyelesaikan formasi."
			}
		},
		# 16. Petrov Copycat - 6...f6 in response to 6.d4
		{
			"moves": ["e4", "e5", "Nf3", "Nf6", "Nxe5", "Nxe4", "Qe2", "Qe7", "Qxe4", "d6", "d4", "f6", "Nc3", "dxe5", "Nd5", "Qd6", "Bf4", "Nd7", "O-O-O"],
			"blurbs": {
				12: "7.Nc3! Kembangkan Knight bersiap melompat ke d5.",
				14: "8.Nd5! Sentralisasi agresif menekan Ratu dan titik c7.",
				16: "9.Bf4! Manfaatkan pin mutlak pada pion e5.",
				18: "10.O-O-O! Tekanan ganda pada d-file menghancurkan pertahanan Black."
			}
		}
	]

func get_black_traps_e4_lines() -> Array:
	return [
		# --- TRAP 5: BLACKBURNE SHILLING GAMBIT ---
		# 1. Main Line Smothered Mate
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "Nd4", "Nxe5", "Qg5", "Nxf7", "Qxg2", "Rf1", "Qxe4+", "Be2", "Nf3#"],
			"blunders": {6: "4.Nxe5? Memakan pion e5 yang tampak gratis tanpa mengantisipasi serangan balik Ratu!", 8: "5.Nxf7? Tergoda fork Ratu dan Benteng, jatuh ke dalam jebakan skakmat!"},
			"blurbs": {
				1: "Buka sentral dengan 1...e5 mengontrol d4 dan f4.",
				3: "Kembangkan Knight ke c6 mengawal pion e5.",
				5: "3...Nd4!? Blackburne Shilling Gambit! Umpan pion e5 untuk memicu serangan tajam.",
				7: "4...Qg5! Serangan balik ganda ke Knight e5 dan pion lemah g2!",
				9: "5...Qxg2! Hancurkan sayap raja White dan serang Rook h1.",
				11: "6...Qxe4+! Skak sentral memanfaatkan kelemahan e-file.",
				13: "7...Nf3#!! Smothered mate legendaris! White mati kutu oleh Knight f3!"
			}
		},
		# 2. White tries 5.Bxf7+
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "Nd4", "Nxe5", "Qg5", "Bxf7+", "Ke7", "O-O", "Qxe5", "Bxg8", "Rxg8", "c3", "Nc6", "d4", "Qf6"],
			"blurbs": {
				9: "5...Ke7! Geser King ke petak aman sambil tetap mempertahankan ancaman g2.",
				11: "6...Qxe5! Tangkap Knight e5, Black unggul satu perwira bersih.",
				13: "7...Rxg8! Bersihkan Bishop lawan dan buka jalur file g.",
				15: "8...Nc6! Tarik Knight kembali mengawal petak e5 dan d4.",
				17: "9...Qf6! Amankan Ratu dengan keunggulan material satu perwira."
			}
		},
		# 3. White trades 4.Nxd4
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "Nd4", "Nxd4", "exd4", "O-O", "d6", "d3", "Nf6", "f4", "Be7", "Nd2", "O-O"],
			"blurbs": {
				7: "4...exd4! Tangkap kembali dengan pion, mengganggu koordinasi perwira White.",
				9: "5...d6! Buka diagonal Bishop dan amankan petak e5.",
				11: "6...Nf6! Kembangkan Knight menuju kingside castling.",
				13: "7...Be7! Siapkan rokade dengan pertahanan solid.",
				15: "8...O-O! Amankan King, Black meraih kesetaraan posisi yang nyaman."
			}
		},
		# 4. White plays 4.c3
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bc4", "Nd4", "c3", "Nxf3+", "Qxf3", "Nf6", "d4", "d6", "h3", "Be7", "O-O", "O-O"],
			"blurbs": {
				7: "4...Nxf3+! Lakukan pertukaran Knight untuk mengurangi tekanan White.",
				9: "5...Nf6! Kembangkan perwira kedua mengontrol sentral.",
				11: "6...d6! Perkokoh pion sentral e5.",
				13: "7...Be7! Siapkan castling tanpa ada kelemahan struktural.",
				15: "8...O-O! King Black aman dengan posisi seimbang."
			}
		},

		# --- TRAP 6: FISHING POLE TRAP ---
		# 5. Fishing Pole - Main Line Checkmate
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bb5", "Nf6", "O-O", "Ng4", "h3", "h5", "hxg4", "hxg4", "Ne1", "Qh4", "f3", "g3", "Rf2", "Qh1#"],
			"blunders": {10: "6.hxg4? Mengambil umpan Knight g4 membuka h-file untuk serangan mematikan!", 12: "7.Ne1? Mundur pasif membiarkan Ratu masuk ke h4 tanpa perlawanan!"},
			"blurbs": {
				1: "1...e5 membentuk pertahanan sentral terbuka.",
				3: "2...Nc6 mengembangkan Knight mengawal e5.",
				5: "3...Nf6 Berlin Defense yang kokoh.",
				7: "4...Ng4!? Umpan pembuka Fishing Pole yang provokatif!",
				9: "5...h5! Trik Fishing Pole! Abaikan ancaman h3 untuk membuka file h.",
				11: "6...hxg4! Buka lajur h-file dengan ancaman langsung terhadap King White.",
				13: "7...Qh4! Ratu meluncur ke h4 mengancam skakmat di h1 dan h2.",
				15: "8...g3! Kunci petak pelarian f2 raja White secara permanen.",
				17: "9...Qh1#!! Checkmate indah di sudut papan memanfaatkan h-file terbuka!"
			}
		},
		# 6. Fishing Pole - White plays 8.f4
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bb5", "Nf6", "O-O", "Ng4", "h3", "h5", "hxg4", "hxg4", "Ne1", "Qh4", "f4", "g3", "Rf3", "Qh1#"],
			"blurbs": {
				15: "8...g3! Tetap dorong g3 mengunci King White dari petak f2.",
				17: "9...Qh1#!! Checkmate tak terelakkan di lajur h!"
			}
		},
		# 7. Fishing Pole - White plays 7.Nh2
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bb5", "Nf6", "O-O", "Ng4", "h3", "h5", "hxg4", "hxg4", "Nh2", "Qh4", "Re1", "Qxh2+", "Kf1", "Nd4"],
			"blurbs": {
				13: "7...Qh4! Tekan petak h2 secara frontal bersama Rook h8.",
				15: "8...Qxh2+! Hantam sayap raja White dengan skak telak.",
				17: "9...Nd4! Langkah tenang yang mengancam skakmat tak terhentikan di h1."
			}
		},
		# 8. Fishing Pole - White avoids grab with 6.c3
		{
			"moves": ["e4", "e5", "Nf3", "Nc6", "Bb5", "Nf6", "O-O", "Ng4", "h3", "h5", "c3", "a6", "Ba4", "Bc5", "d4", "Ba7"],
			"blurbs": {
				11: "6...a6! Uji penempatan Bishop White di b5.",
				13: "7...Bc5! Kembangkan Bishop membidik f2.",
				15: "8...Ba7! Mundur teratur menjaga diagonal serang sayap raja."
			}
		},

		# --- TRAP 7: KING'S GAMBIT FREE PAWN TRAP ---
		# 9. King's Gambit Free Pawn - Main Line (Winning Rook)
		{
			"moves": ["e4", "e5", "f4", "Bc5", "fxe5", "Qh4+", "g3", "Qxe4+", "Qe2", "Qxh1", "Nf3", "Nc6", "c3", "d6", "d4", "Bg4", "Nbd2", "O-O-O"],
			"blunders": {4: "3.fxe5?? Memakan pion e5 membiarkan diagonal maut d8-h4 terbuka lebar!"},
			"blurbs": {
				1: "1...e5 menyambut King's Gambit.",
				3: "2...Bc5! King's Gambit Declined, mengontrol diagonal kritis a7-g1.",
				5: "3...Qh4+! Hukuman brutal atas keserakahan White di e5!",
				7: "4...Qxe4+! Skak garpu ganda menyerang King dan Rook h1.",
				9: "5...Qxh1! Tangkap Rook gratis di h1 dengan keunggulan masif.",
				11: "6...Nc6! Kembangkan perwira menekan petak d4.",
				13: "7...d6! Buka diagonal light-squared Bishop untuk serangan susulan.",
				15: "8...Bg4! Pin Knight f3 dan lumpuhkan koordinasi White.",
				17: "9...O-O-O! Castling queenside dengan keunggulan materi Benteng penuh."
			}
		},
		# 10. King's Gambit Free Pawn - Move 4 Checkmate (4.Ke2??)
		{
			"moves": ["e4", "e5", "f4", "Bc5", "fxe5", "Qh4+", "Ke2", "Qxe4#"],
			"blunders": {6: "4.Ke2?? Berjalan ke petak terbuka menghasilkan skakmat instan!"},
			"blurbs": {
				5: "3...Qh4+! Skak diagonal memanfaatkan ketiadaan Knight f3.",
				7: "4...Qxe4#!! Skakmat kilat di langkah ke-4! King White terperangkap di tengah papan!"
			}
		},
		# 11. King's Gambit Free Pawn - White blocks with 5.Ne2
		{
			"moves": ["e4", "e5", "f4", "Bc5", "fxe5", "Qh4+", "g3", "Qxe4+", "Ne2", "Qxh1", "d4", "Be7", "Nbc3", "d6", "Bf4", "Bh3"],
			"blurbs": {
				9: "5...Qxh1! Tangkap Rook di sudut papan.",
				11: "6...Be7! Mundur taktis mempertahankan Bishop berharga.",
				13: "7...d6! Dobrak sentral untuk membuka ruang perwira sayap ratu.",
				15: "8...Bh3! Serang Bishop f1 yang terpin secara mutlak."
			}
		},
		# 12. King's Gambit Declined - White plays correct 3.Nf3
		{
			"moves": ["e4", "e5", "f4", "Bc5", "Nf3", "d6", "Bc4", "Nf6", "d3", "Nc6", "Nc3", "a6", "f5", "h6"],
			"blurbs": {
				5: "3...d6! Perkokoh pion sentral e5 dan batasi dorongan White.",
				7: "4...Nf6! Kembangkan Knight menekan e4.",
				9: "5...Nc6! Kontrol petak d4 dengan perkembangan harmonis.",
				11: "6...a6! Sediakan petak mundur bagi Bishop c5.",
				13: "7...h6! Cegah manuver Bg5 atau Ng5 dari White."
			}
		}
	]

func get_black_traps_d4_lines() -> Array:
	return [
		# --- TRAP 8: QUEEN'S GAMBIT FAKE PIN TRAP (Elephant Trap) ---
		# 13. Elephant Trap - Main Line (Winning a minor piece)
		{
			"moves": ["d4", "d5", "c4", "e6", "Nc3", "Nf6", "Bg5", "Nbd7", "cxd5", "exd5", "Nxd5", "Nxd5", "Bxd8", "Bb4+", "Qd2", "Bxd2+", "Kxd2", "Kxd8"],
			"blunders": {10: "6.Nxd5? Tertipu pin semu pada f6, White kehilangan perwira akibat antara-skak Bb4+!"},
			"blurbs": {
				1: "1...d5 menantang pion d4 White.",
				3: "2...e6 Queen's Gambit Declined yang kokoh.",
				5: "3...Nf6 mengontrol petak e4.",
				7: "4...Nbd7! Elephant Trap! Umpan pion d5 dengan pin semu pada f6.",
				9: "5...exd5 merebut kembali sentral.",
				11: "6...Nxd5!! Abaikan ancaman Ratu! Taktik defleksi mematikan.",
				13: "7...Bb4+! Antara-skak krusial yang memaksa White menutup dengan Ratu!",
				15: "8...Bxd2+! Tangkap Ratu White dengan skak ganda.",
				17: "9...Kxd8! Rebut kembali Bishop di d8, Black unggul satu perwira bersih!"
			}
		},
		# 14. Elephant Trap - White plays 7.a3 (avoids Queen grab)
		{
			"moves": ["d4", "d5", "c4", "e6", "Nc3", "Nf6", "Bg5", "Nbd7", "cxd5", "exd5", "Nxd5", "Nxd5", "a3", "Qxg5", "e4", "N5f6"],
			"blurbs": {
				13: "7...Qxg5! Tangkap Bishop g5 yang menggantung, Black unggul satu perwira bersih.",
				15: "8...N5f6! Tarik Knight ke f6 mengontrol sentral dan bersiap castling."
			}
		},
		# 15. Elephant Trap - White plays 6.e3 (avoids trap)
		{
			"moves": ["d4", "d5", "c4", "e6", "Nc3", "Nf6", "Bg5", "Nbd7", "cxd5", "exd5", "e3", "c6", "Bd3", "Be7", "Nf3", "O-O", "O-O", "Re8"],
			"blurbs": {
				11: "6...c6! Bentuk piramida pion pertahanan khas Semi-Slav / Orthodox.",
				13: "7...Be7! Lepaskan pin pada f6 dan siapkan castling.",
				15: "8...O-O! Amankan King ke kingside.",
				17: "9...Re8! Aktifkan Benteng pada open e-file dengan posisi seimbang."
			}
		},
		# 16. Queen's Gambit Declined - Cambridge Springs setup
		{
			"moves": ["d4", "d5", "c4", "e6", "Nc3", "Nf6", "Bg5", "Nbd7", "e3", "c6", "Nf3", "Qa5", "Nd2", "Bb4", "Qc2", "O-O"],
			"blurbs": {
				9: "5...c6 memperkuat d5.",
				11: "6...Qa5! Cambridge Springs Defense! Pin ganda terhadap Knight c3.",
				13: "7...Bb4! Tambah tekanan langsung pada titik c3.",
				15: "8...O-O! Amankan King dengan inisiatif serang aktif di sayap ratu."
			}
		},

		# --- TRAP 9: LASKER TRAP ---
		# 17. Lasker Trap - Main Line Underpromotion to Knight
		{
			"moves": ["d4", "d5", "c4", "e5", "dxe5", "d4", "e3", "Bb4+", "Bd2", "dxe3", "Bxb4", "exf2+", "Ke2", "fxg1=N+", "Ke1", "Qh4+", "Kd2", "Nc6", "Bc3", "Bg4"],
			"blunders": {8: "4.e3? Serangan tergesa-gesa pada pion d4 yang membuka celah diagonal!", 12: "6.Bxb4?? Blunder fatal termasyhur yang memicu promosi Kuda beruntun!"},
			"blurbs": {
				1: "1...d5 menyambut Queen's Pawn Game.",
				3: "2...e5! Albin Countergambit! Korbankan pion demi dominasi ruang sentral.",
				5: "3...d4! Dorong pion tajam menusuk wilayah pertahanan White.",
				7: "4...Bb4+! Skak tajam memaksa White memblokir dengan Bishop d2.",
				9: "5...dxe3! Pengorbanan Bishop spektakuler untuk membuka jalur f-file!",
				11: "6...exf2+! Ambil pion f2 dengan skak memaksa King melangkah ke e2.",
				13: "7...fxg1=N+!! Underpromotion legendaris ke Knight dengan skak! Jika jadi Ratu, White menukar Ratu di d8!",
				15: "8...Qh4+! Skak tajam menyerang King yang telanjang di tengah papan.",
				17: "9...Nc6! Kembangkan Knight menekan sayap ratu White.",
				19: "10...Bg4! Kunci Queen White dengan skewer mematikan!"
			}
		},
		# 18. Lasker Trap - White takes knight with 8.Rxg1
		{
			"moves": ["d4", "d5", "c4", "e5", "dxe5", "d4", "e3", "Bb4+", "Bd2", "dxe3", "Bxb4", "exf2+", "Ke2", "fxg1=N+", "Rxg1", "Bg4+", "Kf2", "Qxd1"],
			"blunders": {14: "8.Rxg1? Memakan Knight membiarkan skewer mutlak King dan Queen!"},
			"blurbs": {
				15: "8...Bg4+! Skewer brutal terhadap King dan Queen White!",
				17: "9...Qxd1! Tangkap Ratu White tanpa ampun, Black menang mutlak!"
			}
		},
		# 19. Lasker Trap - White plays 6.fxe3
		{
			"moves": ["d4", "d5", "c4", "e5", "dxe5", "d4", "e3", "Bb4+", "Bd2", "dxe3", "fxe3", "Qh4+", "g3", "Qe4", "Qf3", "Bxd2+", "Nxd2", "Qxe5"],
			"blurbs": {
				11: "6...Qh4+! Skak tajam menghancurkan struktur pion sayap raja White.",
				13: "7...Qe4! Serang ganda terhadap Rook h1 dan pion e5.",
				15: "8...Bxd2+! Sederhanakan pertukaran perwira ringan.",
				17: "9...Qxe5! Rebut kembali pion sentral dengan posisi Black yang jauh lebih aktif."
			}
		},
		# 20. Lasker Trap - White plays 5.Nc3
		{
			"moves": ["d4", "d5", "c4", "e5", "dxe5", "d4", "e3", "Bb4+", "Nc3", "Nc6", "Nf3", "Bg4", "Be2", "dxc3", "O-O", "Qxd1", "Rxd1", "c2"],
			"blurbs": {
				9: "5...Nc6! Perkuat kontrol petak sentral.",
				11: "6...Bg4! Pin Knight f3 meningkatkan tekanan pada d4.",
				13: "7...dxc3! Rebut perwira dengan membuka file c.",
				15: "8...Qxd1! Tukar Queen mempertahankan keunggulan satu perwira.",
				17: "9...c2! Tusuk pion ke baris kedua membelenggu Benteng White."
			}
		},
		# 21. Albin Countergambit - White avoids trap with 4.Nf3
		{
			"moves": ["d4", "d5", "c4", "e5", "dxe5", "d4", "Nf3", "Nc6", "a3", "Bg4", "Nbd2", "Qe7", "h3", "Bxf3", "Nxf3", "O-O-O"],
			"blurbs": {
				7: "4...Nc6! Kembangkan Knight menekan pion e5.",
				9: "5...Bg4! Pin Knight White untuk merebut inisiatif.",
				11: "6...Qe7! Tambah tekanan ganda pada pion e5.",
				13: "7...Bxf3! Tukar Bishop untuk merusak pertahanan pion White.",
				15: "8...O-O-O! Castling queenside dengan serangan balik tajam di sentral."
			}
		}
	]
