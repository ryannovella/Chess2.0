class_name PositionRules
extends RefCounted

## Penyaring posisi kustom sebelum diserahkan ke Stockfish.
##
## Stockfish 18 menolak FEN yang tidak sah TANPA pesan apa pun: tidak ada
## `info string Illegal position`, tidak ada `bestmove`. `UCIClient` jadi
## menunggu selamanya dan bot tampak "thinking" sampai watchdog
## `EngineService` (6 detik) memainkan langkah darurat acak. Kasus nyata: Chess
## Painter menyusun bidak di papan kosong sementara checkbox rokade masih
## tercentang, sehingga FEN membawa `KQkq` padahal raja/bentengnya tidak ada.
##
## Semua aturan di sini adalah syarat sahnya FEN menurut UCI, bukan preferensi
## gaya bermain: menolak posisi yang sebenarnya diterima engine akan mematikan
## sandbox.

const ChessTypes = preload("res://src/core/chess_types.gd")
const ChessMoveGenerator = preload("res://src/core/chess_move_generator.gd")

const RIGHT_KINGSIDE_WHITE := "wK"
const RIGHT_QUEENSIDE_WHITE := "wQ"
const RIGHT_KINGSIDE_BLACK := "bK"
const RIGHT_QUEENSIDE_BLACK := "bQ"
const ALL_RIGHTS: Array[String] = ["wK", "wQ", "bK", "bQ"]

## Apakah hak rokade masih didukung bidak yang benar-benar ada di papan.
static func castling_available(state: ChessBoardState, right: String) -> bool:
	if state == null:
		return false
	var white := ChessTypes.PieceColor.WHITE
	var black := ChessTypes.PieceColor.BLACK
	var king := ChessTypes.PieceType.KING
	var rook := ChessTypes.PieceType.ROOK
	match right:
		RIGHT_KINGSIDE_WHITE:
			return _is_piece(state, "e1", white, king) and _is_piece(state, "h1", white, rook)
		RIGHT_QUEENSIDE_WHITE:
			return _is_piece(state, "e1", white, king) and _is_piece(state, "a1", white, rook)
		RIGHT_KINGSIDE_BLACK:
			return _is_piece(state, "e8", black, king) and _is_piece(state, "h8", black, rook)
		RIGHT_QUEENSIDE_BLACK:
			return _is_piece(state, "e8", black, king) and _is_piece(state, "a8", black, rook)
	return false

## Buang hak rokade yang tidak didukung posisi papan (raja/benteng sudah pindah
## atau memang tidak pernah diletakkan). Aman dipanggil untuk posisi apa pun.
static func sanitize_castling(state: ChessBoardState) -> void:
	if state == null:
		return
	for right in ALL_RIGHTS:
		if bool(state.castling.get(right, false)) and not castling_available(state, right):
			state.castling[right] = false

## Alasan posisi tidak bisa dimainkan; string kosong berarti sah.
static func get_playability_error(state: ChessBoardState) -> String:
	if state == null:
		return "There is no position to play."
	var white := ChessTypes.PieceColor.WHITE
	var black := ChessTypes.PieceColor.BLACK
	var white_kings := _count_pieces(state, white, ChessTypes.PieceType.KING)
	var black_kings := _count_pieces(state, black, ChessTypes.PieceType.KING)
	if white_kings != 1:
		return "White needs exactly 1 king, found %d." % white_kings
	if black_kings != 1:
		return "Black needs exactly 1 king, found %d." % black_kings
	for idx in range(64):
		var piece = state.squares[idx]
		if piece == null:
			continue
		if int(piece["type"]) != ChessTypes.PieceType.PAWN:
			continue
		var rank := int(idx / 8.0)
		if rank == 0 or rank == 7:
			return "A pawn cannot stand on the first or last rank."
	var waiting := black if state.turn == white else white
	if ChessMoveGenerator.is_in_check(state, waiting):
		return "The side not to move is already in check."
	if ChessMoveGenerator.get_legal_moves(state).is_empty():
		return "The side to move has no legal move."
	return ""

static func is_playable(state: ChessBoardState) -> bool:
	return get_playability_error(state).is_empty()

## FEN yang aman dikirim ke engine: hak rokade mustahil dibuang lebih dulu.
static func sanitized_fen(fen: String) -> String:
	var state = ChessBoardState.new(fen)
	sanitize_castling(state)
	return state.to_fen()

static func _is_piece(state: ChessBoardState, sq: String, color: int, type: int) -> bool:
	var piece = state.get_piece(sq)
	if piece == null:
		return false
	return int(piece["color"]) == color and int(piece["type"]) == type

static func _count_pieces(state: ChessBoardState, color: int, type: int) -> int:
	var count := 0
	for piece in state.squares:
		if piece == null:
			continue
		if int(piece["color"]) == color and int(piece["type"]) == type:
			count += 1
	return count
