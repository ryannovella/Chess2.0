class_name ChessBoard
extends HBoxContainer

signal move_made(move: Variant)

const BOARD_PIXELS: float = 688.0
const PieceSmearEffectClass = preload("res://src/ui/effects/piece_smear_effect.gd")
const ReviewBadgeOverlayClass = preload("res://src/ui/board/review_badge_overlay.gd")

@onready var board_viewport: Control = $BoardArea/BoardViewport
@onready var board_underlay: ColorRect = $BoardArea/BoardViewport/BoardUnderlay
@onready var squares_container: Control = $BoardArea/BoardViewport/SquaresContainer
@onready var pieces_container: Control = $BoardArea/BoardViewport/PiecesContainer
@onready var badge_overlay: Control = $BoardArea/BoardViewport/BadgeOverlay
@onready var arrow_overlay: ArrowOverlay = $BoardArea/BoardViewport/ArrowOverlay
@onready var ranks_container: VBoxContainer = $RanksContainer
@onready var files_container: HBoxContainer = $BoardArea/FilesContainer
var review_badge_overlay: Control = null
var pending_review_badge: Dictionary = {} # Badge review yang bertahan melewati setup_board()

var current_state: ChessBoardState = null
var square_cells: Dictionary = {} # "e4" -> SquareCell
var piece_views: Dictionary = {}  # "e4" -> PieceView
var selected_square: String = ""
var hovered_square: String = ""
var legal_moves: Array = []
var last_move: Dictionary = {}
var is_flipped: bool = false
var square_size: float = 86.0 # 688 / 8

# Drag & Drop State
var is_dragging: bool = false
var drag_piece_view: PieceView = null
var drag_start_square: String = ""
var drag_hover_square: String = ""
var drag_mouse_moved: bool = false
var drag_was_already_selected: bool = false
var last_move_was_drag: bool = false
var is_interactive: bool = true

func _ensure_nodes() -> void:
	if board_viewport == null:
		board_viewport = get_node_or_null("BoardArea/BoardViewport")
	if board_underlay == null and board_viewport != null:
		board_underlay = board_viewport.get_node_or_null("BoardUnderlay")
	if squares_container == null and board_viewport != null:
		squares_container = board_viewport.get_node_or_null("SquaresContainer")
	if pieces_container == null and board_viewport != null:
		pieces_container = board_viewport.get_node_or_null("PiecesContainer")
	if badge_overlay == null and board_viewport != null:
		badge_overlay = board_viewport.get_node_or_null("BadgeOverlay")
	if arrow_overlay == null and board_viewport != null:
		arrow_overlay = board_viewport.get_node_or_null("ArrowOverlay") as ArrowOverlay
	if review_badge_overlay == null and board_viewport != null:
		review_badge_overlay = board_viewport.get_node_or_null("ReviewBadgeOverlay") as Control
		if review_badge_overlay == null:
			review_badge_overlay = ReviewBadgeOverlayClass.new()
			review_badge_overlay.name = "ReviewBadgeOverlay"
			review_badge_overlay.custom_minimum_size = Vector2(BOARD_PIXELS, BOARD_PIXELS)
			review_badge_overlay.size = review_badge_overlay.custom_minimum_size
			review_badge_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			review_badge_overlay.z_index = ReviewBadgeOverlayClass.BADGE_Z_INDEX
			board_viewport.add_child(review_badge_overlay)
			review_badge_overlay.size = review_badge_overlay.custom_minimum_size
	if review_badge_overlay != null:
		review_badge_overlay.z_index = ReviewBadgeOverlayClass.BADGE_Z_INDEX
		review_badge_overlay.move_to_front()
	if ranks_container == null:
		ranks_container = get_node_or_null("RanksContainer") as VBoxContainer
	if files_container == null:
		files_container = get_node_or_null("BoardArea/FilesContainer") as HBoxContainer

func _ready() -> void:
	_ensure_nodes()
	custom_minimum_size = Vector2(BOARD_PIXELS + 20, BOARD_PIXELS + 20)
	square_size = BOARD_PIXELS / 8.0
	_update_underlay_color()
	_build_board_grid()
	_build_coordinates()
	if squares_container and not squares_container.mouse_exited.is_connected(_on_board_mouse_exited):
		squares_container.mouse_exited.connect(_on_board_mouse_exited)
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS:
			if not GS.theme_changed.is_connected(_on_theme_changed):
				GS.theme_changed.connect(_on_theme_changed)
			if not GS.piece_set_changed.is_connected(_on_piece_set_changed):
				GS.piece_set_changed.connect(_on_piece_set_changed)
			if not GS.settings_changed.is_connected(_refresh_all_squares):
				GS.settings_changed.connect(_refresh_all_squares)

func _get_piece_set() -> String:
	if is_inside_tree():
		var GS = get_node_or_null("/root/GameSettings")
		if GS and not GS.piece_set.is_empty():
			return GS.piece_set
	return "cburnett"

func setup_board(state: ChessBoardState, flipped: bool = false) -> void:
	_ensure_nodes()
	if square_cells.is_empty() and squares_container != null:
		_build_board_grid()
		_build_coordinates()
	current_state = state
	is_flipped = flipped
	last_move.clear()
	selected_square = ""
	legal_moves.clear()
	is_interactive = true
	_position_cells()
	_update_coordinates()
	_refresh_all_squares()
	_refresh_pieces()
	update_arrows([], [])
	_restore_review_badge()

func clear_last_move() -> void:
	last_move.clear()
	_refresh_all_squares()

func set_analysis_progress(_cur_depth: int, _target_depth: int, _is_final: bool) -> void:
	pass

func update_mate_popup(_is_mate: bool, _mate_in: int) -> void:
	pass

func _build_board_grid() -> void:
	for child in squares_container.get_children():
		child.queue_free()
	square_cells.clear()

	for r in range(8):
		for f in range(8):
			var sq_name = ChessTypes.coord_to_square(f, r)
			var is_dark = (f + r) % 2 == 0
			var cell = SquareCell.new()
			cell.setup(sq_name, is_dark, square_size)
			cell.gui_input.connect(_on_cell_gui_input.bind(sq_name))
			cell.mouse_entered.connect(_on_cell_mouse_entered.bind(sq_name))
			cell.mouse_exited.connect(_on_cell_mouse_exited.bind(sq_name))
			squares_container.add_child(cell)
			square_cells[sq_name] = cell

	_position_cells()

func _position_cells() -> void:
	for r in range(8):
		for f in range(8):
			var sq_name = ChessTypes.coord_to_square(f, r)
			var cell = square_cells.get(sq_name)
			if cell:
				var pos = get_square_position(sq_name)
				cell.position = pos
				cell.size = Vector2(square_size, square_size)

func _build_coordinates() -> void:
	for child in ranks_container.get_children():
		child.queue_free()
	for child in files_container.get_children():
		child.queue_free()

	for i in range(8):
		var lbl_r = Label.new()
		lbl_r.custom_minimum_size = Vector2(24, square_size)
		lbl_r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_r.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_r.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 0.8))
		lbl_r.add_theme_font_size_override("font_size", 16)
		ranks_container.add_child(lbl_r)

		var lbl_f = Label.new()
		lbl_f.custom_minimum_size = Vector2(square_size, 24)
		lbl_f.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_f.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_f.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 0.8))
		lbl_f.add_theme_font_size_override("font_size", 16)
		files_container.add_child(lbl_f)

	_update_coordinates()

func _update_coordinates() -> void:
	if ranks_container == null or files_container == null:
		return
	var ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
	var files = ["a", "b", "c", "d", "e", "f", "g", "h"]
	if is_flipped:
		ranks.reverse()
		files.reverse()

	var r_children = ranks_container.get_children()
	for i in range(min(r_children.size(), ranks.size())):
		r_children[i].text = ranks[i]

	var f_children = files_container.get_children()
	for i in range(min(f_children.size(), files.size())):
		f_children[i].text = files[i]

func get_square_position(sq: String) -> Vector2:
	var coord = ChessTypes.square_to_coord(sq)
	var f = coord.x
	var r = coord.y
	var visual_f = (7 - f) if is_flipped else f
	var visual_r = r if is_flipped else (7 - r)
	return Vector2(visual_f * square_size, visual_r * square_size)

func get_square_from_position(pos: Vector2) -> String:
	var visual_f = int(pos.x / square_size)
	var visual_r = int(pos.y / square_size)
	if visual_f < 0 or visual_f > 7 or visual_r < 0 or visual_r > 7:
		return ""
	var f = (7 - visual_f) if is_flipped else visual_f
	var r = visual_r if is_flipped else (7 - visual_r)
	return ChessTypes.coord_to_square(f, r)

func _refresh_pieces() -> void:
	_ensure_nodes()
	if pieces_container == null:
		return
	for child in pieces_container.get_children():
		pieces_container.remove_child(child)
		child.queue_free()
	piece_views.clear()

	if current_state == null:
		return

	for i in range(64):
		var p = current_state.squares[i]
		if p != null:
			var sq_name = ChessTypes.index_to_square(i)
			var view = PieceView.new()
			view.setup(p["color"], p["type"], sq_name, _get_piece_set(), square_size)
			pieces_container.add_child(view)
			view.position = get_square_position(sq_name)
			view.size = Vector2(square_size, square_size)
			view.custom_minimum_size = Vector2(square_size, square_size)
			piece_views[sq_name] = view

func _refresh_all_squares(animate_legal: bool = false) -> void:
	var king_in_check_sq = ""
	var forbidden_squares = {}
	var defender_squares = {}
	var GS = get_node_or_null("/root/GameSettings") if is_inside_tree() else null
	var allow_forbidden = GS.show_forbidden_squares if GS else true
	var allow_defenders = GS.show_defender_highlights if GS else true

	if current_state != null and ChessMoveGenerator.is_in_check(current_state, current_state.turn):
		var king_idx = ChessMoveGenerator.find_king(current_state, current_state.turn)
		if king_idx != -1:
			king_in_check_sq = ChessTypes.index_to_square(king_idx)
			if allow_forbidden:
				# Find legal escape moves for the King
				var king_moves = ChessMoveGenerator.get_legal_moves(current_state, king_in_check_sq)
				var safe_escapes = {}
				for km in king_moves:
					if km is ChessMove:
						safe_escapes[km.to_sq] = true
					elif km is Dictionary:
						safe_escapes[km.get("to", "")] = true

				var kf = king_idx % 8
				var kr = king_idx / 8
				for dir in ChessMoveGenerator.KING_DIRS:
					var tf = kf + dir.x
					var tr = kr + dir.y
					if tf >= 0 and tf <= 7 and tr >= 0 and tr <= 7:
						var adj_sq = ChessTypes.coord_to_square(tf, tr)
						var occ_piece = current_state.get_piece(adj_sq)
						if occ_piece == null:
							# Petak unoccupied di sekeliling raja: merah jika tidak aman (bukan safe escape)
							if not safe_escapes.has(adj_sq):
								forbidden_squares[adj_sq] = true

		if allow_defenders:
			# Temukan seluruh bidak kawan (selain Raja) yang memiliki langkah legal untuk menyelamatkan dari skak/skakmat
			var all_legal = ChessMoveGenerator.get_legal_moves(current_state)
			for lm in all_legal:
				var src_sq = lm.from_sq if lm is ChessMove else (lm.get("from", "") if lm is Dictionary else "")
				if not src_sq.is_empty() and src_sq != king_in_check_sq:
					defender_squares[src_sq] = true

	var legal_targets = {}
	for m in legal_moves:
		if m is ChessMove:
			legal_targets[m.to_sq] = true
		elif m is Dictionary:
			legal_targets[m.get("to", "")] = true

	# Hitung delay ripple/cascade berdasarkan jarak Euclidean dari selected_square
	var delays = {}
	if animate_legal and not selected_square.is_empty() and not legal_targets.is_empty():
		var from_coord = ChessTypes.square_to_coord(selected_square)
		var min_dist = 999.0
		var distances = {}
		for to_sq in legal_targets:
			var to_coord = ChessTypes.square_to_coord(to_sq)
			var dist = from_coord.distance_to(to_coord)
			distances[to_sq] = dist
			if dist < min_dist:
				min_dist = dist
		for to_sq in distances:
			var diff = distances[to_sq] - min_dist
			delays[to_sq] = diff * 0.03

	var last_from = last_move.get("from", "")
	var last_to = last_move.get("to", "")

	for sq in square_cells:
		var cell = square_cells[sq]
		var is_sel = (sq == selected_square)
		var is_last = (sq == last_from or sq == last_to)
		var is_chk = (sq == king_in_check_sq)
		var is_leg = legal_targets.has(sq)
		var is_forbid = forbidden_squares.has(sq)
		var is_def = defender_squares.has(sq)
		var is_cap = false
		if is_leg and current_state != null:
			is_cap = (current_state.get_piece(sq) != null) or (current_state.ep_square == sq)
		cell.set_highlights(is_sel, is_last, is_chk, is_leg, is_cap, is_forbid, is_def)
		if is_leg:
			if animate_legal and delays.has(sq):
				cell.animate_legal_indicator(delays[sq])
			else:
				cell.set_legal_scale_immediate(1.0)
		else:
			cell.stop_legal_animation()

	var active_badge_overlay = badge_overlay
	if active_badge_overlay == null and board_viewport != null:
		active_badge_overlay = board_viewport.get_node_or_null("BadgeOverlay")
	if active_badge_overlay != null and active_badge_overlay.has_method("update_badges"):
		active_badge_overlay.update_badges(defender_squares, selected_square, legal_moves, is_flipped, square_size)

func update_arrows(engine_arrows: Array[Dictionary], threat_arrows: Array[Dictionary]) -> void:
	if arrow_overlay:
		arrow_overlay.update_arrows(engine_arrows, threat_arrows, square_size, is_flipped)

func set_last_move(from_sq: String, to_sq: String) -> void:
	last_move = {"from": from_sq, "to": to_sq}
	_refresh_all_squares()

# Umpan balik visual saat pion berubah menjadi perwira: bidak promosi membesar
# singkat dari kecil ke ukuran penuh agar pertukaran tekstur tidak terlihat "patah".
func _play_promotion_pop(view: PieceView) -> void:
	if view == null or not is_instance_valid(view) or not view.is_inside_tree():
		return
	view.z_index = 12
	view.pivot_offset = view.size * 0.5
	var pop = view.create_tween()
	pop.tween_property(view, "scale", Vector2(1.12, 1.12), 0.10).from(Vector2(0.72, 0.72)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop.tween_property(view, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.finished.connect(func():
		if is_instance_valid(view):
			view.scale = Vector2.ONE
			view.z_index = 0
	)

func topple_king(color: int, on_complete: Callable = Callable()) -> void:
	if current_state == null:
		if on_complete.is_valid():
			on_complete.call()
		return
	var king_idx = ChessMoveGenerator.find_king(current_state, color)
	if king_idx == -1:
		if on_complete.is_valid():
			on_complete.call()
		return
	var king_sq = ChessTypes.index_to_square(king_idx)
	var king_view: PieceView = piece_views.get(king_sq)
	if king_view and is_instance_valid(king_view):
		var coord = ChessTypes.square_to_coord(king_sq)
		var dir = -1.0 if coord.x >= 6 else 1.0
		king_view.animate_topple(dir, on_complete)
	else:
		if on_complete.is_valid():
			on_complete.call()

func shake_king_in_check() -> void:
	if current_state == null:
		return
	var king_idx = ChessMoveGenerator.find_king(current_state, current_state.turn)
	if king_idx == -1:
		return
	var king_sq = ChessTypes.index_to_square(king_idx)
	var king_view: PieceView = piece_views.get(king_sq)
	if king_view and is_instance_valid(king_view):
		king_view.animate_shake()

func animate_move(move: Variant, new_state: ChessBoardState, is_cap: bool, is_castle: bool, is_ep: bool, promo: int, callback: Callable = Callable(), on_impact: Callable = Callable()) -> void:
	current_state = new_state
	var from_sq = ""
	var to_sq = ""
	if move is ChessMove:
		from_sq = move.from_sq
		to_sq = move.to_sq
	elif move is Dictionary:
		from_sq = move.get("from", move.get("from_sq", ""))
		to_sq = move.get("to", move.get("to_sq", ""))

	set_last_move(from_sq, to_sq)
	clear_selection()

	var is_drag = last_move_was_drag
	last_move_was_drag = false

	var moving_view: PieceView = piece_views.get(from_sq)
	if moving_view == null:
		_refresh_pieces()
		_refresh_all_squares()
		if on_impact.is_valid():
			on_impact.call()
		if callback.is_valid():
			callback.call()
		return

	is_interactive = false

	var target_pos = get_square_position(to_sq)
	var captured_view: PieceView = piece_views.get(to_sq) if (is_cap and not is_ep) else null
	var ep_captured_view: PieceView = null
	var ep_sq_to_erase: String = ""
	if is_ep:
		var from_c = ChessTypes.square_to_coord(from_sq)
		var to_c = ChessTypes.square_to_coord(to_sq)
		ep_sq_to_erase = ChessTypes.coord_to_square(to_c.x, from_c.y)
		ep_captured_view = piece_views.get(ep_sq_to_erase)

	if captured_view and is_instance_valid(captured_view):
		captured_view.animate_capture_defeat()
	if ep_captured_view and is_instance_valid(ep_captured_view):
		ep_captured_view.animate_capture_defeat()

	var rook_view: PieceView = null
	var rook_target_pos: Vector2 = Vector2.ZERO
	var rook_from: String = ""
	var rook_to: String = ""

	if is_castle:
		if from_sq == "e1" and to_sq == "g1":
			rook_from = "h1"
			rook_to = "f1"
		elif from_sq == "e1" and to_sq == "c1":
			rook_from = "a1"
			rook_to = "d1"
		elif from_sq == "e8" and to_sq == "g8":
			rook_from = "h8"
			rook_to = "f8"
		elif from_sq == "e8" and to_sq == "c8":
			rook_from = "a8"
			rook_to = "d8"

		if not rook_from.is_empty():
			rook_view = piece_views.get(rook_from)
			if rook_view:
				rook_target_pos = get_square_position(rook_to)

	var finalize_move = func():
		if not ep_sq_to_erase.is_empty():
			piece_views.erase(ep_sq_to_erase)

		piece_views.erase(from_sq)
		piece_views[to_sq] = moving_view
		moving_view.current_square = to_sq
		moving_view.position = target_pos

		if promo != ChessTypes.PieceType.NONE:
			moving_view.setup(moving_view.piece_color, promo, to_sq, _get_piece_set(), square_size)
			_play_promotion_pop(moving_view)

		if rook_view:
			piece_views.erase(rook_from)
			piece_views[rook_to] = rook_view
			rook_view.current_square = rook_to
			rook_view.position = rook_target_pos

		_refresh_all_squares()

		if current_state != null and ChessMoveGenerator.is_in_check(current_state, current_state.turn):
			shake_king_in_check()

		is_interactive = true

		if callback.is_valid():
			callback.call()

	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	var d_squares = maxi(absi(to_coord.x - from_coord.x), absi(to_coord.y - from_coord.y))

	var anim_duration: float
	if is_drag:
		anim_duration = 0.08
	else:
		var norm_d = clampf(float(d_squares - 1) / 6.0, 0.0, 1.0)
		anim_duration = 0.16 + (0.36 - 0.16) * pow(norm_d, 0.45)

	# Efek smooth solid smear saat bidak melaju kencang (jarak > 2 petak, bukan Kuda)
	if not is_drag and d_squares > 2 and moving_view.piece_type != ChessTypes.PieceType.KNIGHT:
		if board_viewport:
			var smear = PieceSmearEffectClass.new()
			smear.z_index = 10
			board_viewport.add_child(smear)
			var origin_center = get_square_position(from_sq) + Vector2(square_size * 0.5, square_size * 0.5)
			smear.trigger(origin_center, moving_view, moving_view.piece_color, square_size, anim_duration * 0.90)

	if rook_view:
		rook_view.animate_move_to(rook_target_pos, anim_duration, Callable(), Callable(), is_drag, 2)
	moving_view.animate_move_to(target_pos, anim_duration, finalize_move, on_impact, is_drag, d_squares)

func animate_undo_move(move_info: Dictionary, target_state: ChessBoardState, callback: Callable = Callable()) -> void:
	var from_sq = move_info.get("from_sq", move_info.get("from", ""))
	var to_sq = move_info.get("to_sq", move_info.get("to", ""))
	var is_castle = move_info.get("is_castle", false)
	var is_ep = move_info.get("is_ep", false)
	var promo = move_info.get("promo", ChessTypes.PieceType.NONE)

	if from_sq.is_empty() or to_sq.is_empty():
		setup_board(target_state, is_flipped)
		if callback.is_valid():
			callback.call()
		return

	clear_selection()
	is_interactive = false
	current_state = target_state

	var moving_view: PieceView = piece_views.get(to_sq)
	if moving_view == null:
		setup_board(target_state, is_flipped)
		if callback.is_valid():
			callback.call()
		return

	# Revert promotion if applicable
	if promo != ChessTypes.PieceType.NONE:
		moving_view.setup(moving_view.piece_color, ChessTypes.PieceType.PAWN, to_sq, _get_piece_set(), square_size)

	# Restore captured piece if any was present in target_state
	var restored_sq = ""
	if is_ep:
		var from_c = ChessTypes.square_to_coord(from_sq)
		var to_c = ChessTypes.square_to_coord(to_sq)
		restored_sq = ChessTypes.coord_to_square(to_c.x, from_c.y)
	else:
		var cap = target_state.get_piece(to_sq)
		if cap != null:
			restored_sq = to_sq

	if not restored_sq.is_empty():
		var p = target_state.get_piece(restored_sq)
		if p != null:
			var restored_view = PieceView.new()
			restored_view.setup(p["color"], p["type"], restored_sq, _get_piece_set(), square_size)
			restored_view.position = get_square_position(restored_sq)
			restored_view.modulate.a = 0.0
			pieces_container.add_child(restored_view)
			piece_views[restored_sq] = restored_view
			var tween = create_tween()
			tween.tween_property(restored_view, "modulate:a", 1.0, 0.15)

	# Handle Castling Rook return
	var rook_view: PieceView = null
	var rook_target_pos: Vector2 = Vector2.ZERO
	var rook_from: String = ""
	var rook_to: String = ""

	if is_castle:
		if from_sq == "e1" and to_sq == "g1":
			rook_from = "h1"; rook_to = "f1"
		elif from_sq == "e1" and to_sq == "c1":
			rook_from = "a1"; rook_to = "d1"
		elif from_sq == "e8" and to_sq == "g8":
			rook_from = "h8"; rook_to = "f8"
		elif from_sq == "e8" and to_sq == "c8":
			rook_from = "a8"; rook_to = "d8"

		if not rook_to.is_empty():
			rook_view = piece_views.get(rook_to)
			if rook_view:
				rook_target_pos = get_square_position(rook_from)

	var target_pos = get_square_position(from_sq)
	var from_coord = ChessTypes.square_to_coord(from_sq)
	var to_coord = ChessTypes.square_to_coord(to_sq)
	var d_squares = maxi(absi(to_coord.x - from_coord.x), absi(to_coord.y - from_coord.y))
	var norm_d = clampf(float(d_squares - 1) / 6.0, 0.0, 1.0)
	var anim_duration = 0.16 + (0.36 - 0.16) * pow(norm_d, 0.45)

	var finalize_undo = func():
		setup_board(target_state, is_flipped)
		if callback.is_valid():
			callback.call()

	if rook_view:
		rook_view.animate_move_to(rook_target_pos, anim_duration, Callable(), Callable(), false, 2)
	moving_view.animate_move_to(target_pos, anim_duration, finalize_undo, Callable(), false, d_squares)

func select_square(sq: String, allow_toggle: bool = false) -> void:
	if not is_interactive or current_state == null:
		return

	var piece = current_state.get_piece(sq)
	# Jika petak yang diklik adalah salah satu legal target dari selected_square yang aktif
	if not selected_square.is_empty():
		for m in legal_moves:
			if m["to"] == sq:
				last_move_was_drag = false
				_try_execute_move(m)
				return

	# Jika klik petak yang sama dengan yang sedang diseleksi dan allow_toggle aktif, batalkan seleksi
	if sq == selected_square and allow_toggle:
		clear_selection()
		return

	# Jika klik bidak sendiri, ubah/pertahankan seleksi & update legal moves
	if piece != null and piece["color"] == current_state.turn:
		selected_square = sq
		legal_moves = ChessMoveGenerator.get_legal_moves(current_state, sq)
		_refresh_all_squares(true)
		_update_arrow_focus()
	# Jika klik bidak lawan yang memiliki panah, pilih untuk inspeksi panah persisten
	elif piece != null and arrow_overlay and arrow_overlay.has_arrows_for_square(sq):
		selected_square = sq
		legal_moves.clear()
		_refresh_all_squares()
		_update_arrow_focus()
	else:
		clear_selection()

func clear_selection() -> void:
	selected_square = ""
	legal_moves.clear()
	_set_drag_hover_square("")
	_refresh_all_squares()
	_update_arrow_focus()

func _try_execute_move(move: Variant) -> void:
	clear_selection()

	# Cek jika langkah merupakan promosi pion
	var piece = current_state.get_piece(move["from"])
	if piece != null and piece["type"] == ChessTypes.PieceType.PAWN:
		var target_coord = ChessTypes.square_to_coord(move["to"])
		var promo_rank = 7 if piece["color"] == ChessTypes.PieceColor.WHITE else 0
		if target_coord.y == promo_rank:
			_show_promotion_picker(move)
			return

	move_made.emit(move)

func _show_promotion_picker(base_move: Variant) -> void:
	# Bersihkan popup promosi sebelumnya jika ada
	for child in board_viewport.get_children():
		if child is PromotionDialog:
			child.queue_free()

	var from_sq = base_move.from_sq if base_move is ChessMove else base_move.get("from", "")
	var to_sq = base_move.to_sq if base_move is ChessMove else base_move.get("to", "")
	var target_pos = get_square_position(to_sq)

	var pawn_view: PieceView = piece_views.get(from_sq)

	var on_pawn_at_target = func():
		var dialog = preload("res://src/ui/dialogs/promotion_dialog.tscn").instantiate()
		board_viewport.add_child(dialog)
		dialog.z_index = 60
		dialog.setup(current_state.turn, _get_piece_set(), target_pos)

		dialog.piece_selected.connect(func(promo_type: int):
			var full_move: Variant
			if base_move is ChessMove:
				full_move = base_move.clone()
				full_move.promotion = promo_type
			elif base_move is Dictionary:
				full_move = base_move.duplicate()
				full_move["promotion"] = promo_type
			else:
				full_move = base_move
			last_move_was_drag = true
			move_made.emit(full_move)
		)

		dialog.canceled.connect(func():
			_refresh_pieces()
			clear_selection()
		)

	if pawn_view:
		if last_move_was_drag:
			pawn_view.position = target_pos
			on_pawn_at_target.call()
		else:
			is_interactive = false
			pawn_view.animate_move_to(target_pos, 0.18, on_pawn_at_target, Callable(), last_move_was_drag, 1)
	else:
		on_pawn_at_target.call()

func _set_drag_hover_square(sq: String) -> void:
	if drag_hover_square == sq:
		return
	if not drag_hover_square.is_empty() and square_cells.has(drag_hover_square):
		square_cells[drag_hover_square].set_drag_hover(false)
	drag_hover_square = sq
	if not drag_hover_square.is_empty() and square_cells.has(drag_hover_square):
		square_cells[drag_hover_square].set_drag_hover(true)

func _on_cell_gui_input(event: InputEvent, sq: String) -> void:
	if not is_interactive:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Mouse Down: mulai drag atau click seleksi
				if current_state != null:
					var p = current_state.get_piece(sq)
					if p != null and p["color"] == current_state.turn:
						drag_was_already_selected = (selected_square == sq)
						select_square(sq, false)
						is_dragging = true
						drag_mouse_moved = false
						drag_start_square = sq
						drag_piece_view = piece_views.get(sq)
						if drag_piece_view:
							drag_piece_view.z_index = 20
						_set_drag_hover_square(sq)
					elif not selected_square.is_empty():
						select_square(sq, false)
			else:
				# Mouse Up: lepaskan drag
				if is_dragging:
					is_dragging = false
					_set_drag_hover_square("")
					if drag_piece_view:
						drag_piece_view.z_index = 0

					# Cari petak di bawah cursor saat mouse dilepas
					var local_pos = squares_container.get_local_mouse_position()
					var dest_sq = get_square_from_position(local_pos)

					if not dest_sq.is_empty() and dest_sq != drag_start_square:
						for m in legal_moves:
							if m["to"] == dest_sq:
								last_move_was_drag = true
								_try_execute_move(m)
								return

					# Kembalikan posisi visual bidak jika drop tidak valid
					if drag_piece_view:
						drag_piece_view.position = get_square_position(drag_start_square)

					# Jika user hanya klik di tempat tanpa menggeser mouse dan sebelumnya sudah terseleksi: batalkan seleksi (toggle deselect)
					if not drag_mouse_moved and drag_was_already_selected and (dest_sq == drag_start_square or dest_sq.is_empty()):
						clear_selection()

	elif event is InputEventMouseMotion and is_dragging:
		drag_mouse_moved = true
		if drag_piece_view:
			var mouse_pos = squares_container.get_local_mouse_position()
			drag_piece_view.position = mouse_pos - Vector2(square_size, square_size) * 0.5
			var hover_sq = get_square_from_position(mouse_pos)
			_set_drag_hover_square(hover_sq)

func _on_theme_changed(_theme_name: String) -> void:
	_update_underlay_color()
	for cell in square_cells.values():
		cell.update_theme_colors()

func _update_underlay_color() -> void:
	if board_underlay:
		var th_name = "slate"
		if is_inside_tree():
			var GS = get_node_or_null("/root/GameSettings")
			if GS:
				th_name = GS.board_theme
		var theme_data = BoardThemes.get_theme(th_name)
		board_underlay.color = theme_data.get("dark_color", Color("#475569"))

func _on_piece_set_changed(_set_name: String) -> void:
	_refresh_pieces()

func _on_cell_mouse_entered(sq: String) -> void:
	if is_dragging:
		return
	if current_state != null and current_state.get_piece(sq) != null:
		hovered_square = sq
	else:
		hovered_square = ""
	_update_arrow_focus()

func _on_cell_mouse_exited(sq: String) -> void:
	if is_dragging:
		return
	if hovered_square == sq:
		hovered_square = ""
		_update_arrow_focus()

func _on_board_mouse_exited() -> void:
	if is_dragging:
		return
	hovered_square = ""
	_update_arrow_focus()

func _update_arrow_focus() -> void:
	if not arrow_overlay:
		return
	var focus_sq = ""
	# 1. Prioritas Utama: Bidak yang diklik (selected) mempertahankan panah secara persisten
	if not selected_square.is_empty() and arrow_overlay.has_arrows_for_square(selected_square):
		focus_sq = selected_square
	# 2. Prioritas Kedua: Jika tidak ada bidak yang diklik (idle), gunakan bidak yang di-hover
	elif not hovered_square.is_empty() and arrow_overlay.has_arrows_for_square(hovered_square):
		focus_sq = hovered_square

	arrow_overlay.set_focused_square(focus_sq)

func set_review_badge(target_square: String, classification: int) -> void:
	_ensure_nodes()
	if target_square.is_empty():
		clear_review_badge()
		return
	pending_review_badge = {"square": target_square, "classification": classification}
	if review_badge_overlay:
		review_badge_overlay.z_index = ReviewBadgeOverlayClass.BADGE_Z_INDEX
		review_badge_overlay.move_to_front()
		review_badge_overlay.set_review_badge(target_square, classification, is_flipped, square_size)

func clear_review_badge() -> void:
	pending_review_badge.clear()
	if review_badge_overlay:
		review_badge_overlay.clear_badge()

# setup_board() dipanggil di akhir animasi undo (finalize_undo), jadi badge yang dipasang
# sebelum animasi transisi tidak boleh hilang. Badge hanya dilepas via clear_review_badge().
func _restore_review_badge() -> void:
	if review_badge_overlay == null:
		_ensure_nodes()
	if review_badge_overlay == null:
		return
	review_badge_overlay.z_index = ReviewBadgeOverlayClass.BADGE_Z_INDEX
	review_badge_overlay.move_to_front()
	if pending_review_badge.is_empty():
		review_badge_overlay.clear_badge()
		return
	review_badge_overlay.set_review_badge(
		pending_review_badge.get("square", ""),
		int(pending_review_badge.get("classification", -1)),
		is_flipped,
		square_size
	)

