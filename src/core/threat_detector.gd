class_name ThreatDetector
extends RefCounted

# Porting 1:1 dari ChessAcademy threatDetectors.ts
# Mendeteksi ancaman terhadap bidak pemain oleh lawan:
# - 'threat-hanging' (merah): Bidak pemain bisa dimakan lawan tanpa ada penjaga yang membalas makan (recapture).
# - 'threat-defended' (pink): Bidak pemain bisa dimakan lawan namun ada penjaga (recapture siap).
static func detect_threats(state: ChessBoardState, player_color: int) -> Array[Dictionary]:
	var opp_color = ChessTypes.PieceColor.BLACK if player_color == ChessTypes.PieceColor.WHITE else ChessTypes.PieceColor.WHITE
	var arrows: Array[Dictionary] = []
	var processed_pairs = {}

	# Siapkan state dengan giliran lawan untuk mengecek langkah pemakanannya
	var opp_state = state.clone()
	opp_state.turn = opp_color
	opp_state.ep_square = "-"

	# Cari semua langkah legal lawan yang merupakan capture terhadap bidak pemain
	var opp_moves = ChessMoveGenerator.get_legal_moves(opp_state)
	var legal_captures: Array[ChessMove] = []
	for m in opp_moves:
		var target_piece = opp_state.get_piece(m.to_sq)
		if target_piece != null and target_piece["color"] == player_color:
			legal_captures.append(m)

	for cap in legal_captures:
		var pair_key = "%s-%s" % [cap["from"], cap["to"]]
		if processed_pairs.has(pair_key):
			continue
		processed_pairs[pair_key] = true

		# Uji pertahanan: Simulasikan lawan memakan bidak pemain, lalu periksa apakah pemain bisa memakan balik (recapture) di petak tujuan
		var is_hanging = true
		var test_state = opp_state.clone()
		ChessMoveGenerator.apply_move_unchecked(test_state, cap)

		# Langkah balasan pemain
		var player_replies = ChessMoveGenerator.get_legal_moves(test_state)
		for reply in player_replies:
			if reply["to"] == cap["to"]:
				is_hanging = false
				break

		var threat_type = "threat-hanging" if is_hanging else "threat-defended"
		arrows.append({
			"from": cap["from"],
			"to": cap["to"],
			"type": threat_type,
			"rank": 1 if is_hanging else 2,
			"target_color": player_color
		})

	return arrows
