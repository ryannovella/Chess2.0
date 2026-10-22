# Graph Report - Chess2.0  (2026-09-24)

## Corpus Check
- Corpus is ~28,792 words - fits in a single context window. You may not need a graph.

## Summary
- 76 nodes · 38 edges · 43 communities (3 shown, 40 thin omitted)
- Extraction: 63% EXTRACTED · 37% INFERRED · 0% AMBIGUOUS · INFERRED: 14 edges (avg confidence: 0.93)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Board and Piece Display
- Chess Engine and Rules
- Evaluation and Rating HUD
- Piece Art cburnett black Bishop
- Piece Art cburnett black King
- Piece Art cburnett black Knight
- Piece Art cburnett black Pawn
- Piece Art cburnett black Queen
- Piece Art cburnett black Rook
- Piece Art cburnett white Bishop
- Piece Art cburnett white King
- Piece Art cburnett white Knight
- Piece Art cburnett white Pawn
- Piece Art cburnett white Queen
- Piece Art cburnett white Rook
- Board State and Types
- Game Controls UI
- Move History UI
- Piece Art Black Bishop (Horsey Theme)
- Piece Art Black King (Horsey Theme)
- Piece Art Black Knight (Horsey Theme)
- Piece Art Black Pawn (Horsey Theme)
- Piece Art Black Queen (Horsey Theme)
- Piece Art Black Rook (Horsey Theme)
- Piece Art Black Piece (Horsey Theme)
- Piece Art King Black (Horsey Theme)
- Piece Art King White (Horsey Theme)
- Piece Art Knight Black (Horsey Theme)
- Piece Art Knight White (Horsey Theme)
- Piece Art Pawn Black (Horsey Theme)
- Piece Art Pawn White (Horsey Theme)
- Piece Art Queen Black (Horsey Theme)
- Piece Art Queen White (Horsey Theme)
- Piece Art Rook Black (Horsey Theme)
- Piece Art Rook White (Horsey Theme)
- Piece Art White Bishop (Horsey Theme)
- Piece Art White King (Horsey Theme)
- Piece Art White Knight (Horsey Theme)
- Piece Art White Pawn (Horsey Theme)
- Piece Art White Queen (Horsey Theme)
- Piece Art White Rook (Horsey Theme)
- Audio Service
- Board Themes Configuration

## God Nodes (most connected - your core abstractions)
1. `ChessBoard` - 7 edges
2. `MainGame` - 4 edges
3. `ChessPainter` - 4 edges
4. `ArrowOverlay` - 3 edges
5. `ChessMoveGenerator` - 2 edges
6. `ChessSAN` - 2 edges
7. `ThreatDetector` - 2 edges
8. `EngineService` - 2 edges
9. `ChessBoard Scene` - 2 edges
10. `PieceView` - 2 edges

## Surprising Connections (you probably didn't know these)
- `ChessBoard` --semantically_similar_to--> `ChessPainter`  [INFERRED] [semantically similar]
  src/ui/board/chess_board.gd → src/ui/painter/chess_painter.gd
- `EvalBar` --semantically_similar_to--> `EloSlider`  [INFERRED] [semantically similar]
  src/ui/hud/eval_bar.gd → src/ui/hud/elo_slider.gd
- `cburnett black Bishop` --semantically_similar_to--> `staunty black Bishop`  [INFERRED] [semantically similar]
  assets/pieces/cburnett/bB.svg → assets/pieces/staunty/bB.svg
- `cburnett black King` --semantically_similar_to--> `staunty black King`  [INFERRED] [semantically similar]
  assets/pieces/cburnett/bK.svg → assets/pieces/staunty/bK.svg
- `cburnett black Knight` --semantically_similar_to--> `staunty black Knight`  [INFERRED] [semantically similar]
  assets/pieces/cburnett/bN.svg → assets/pieces/staunty/bN.svg

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Board Presentation Subsystem** — src_ui_board_chess_board_chessboard, src_ui_board_square_cell_squarecell, src_ui_board_piece_view_pieceview, src_ui_board_arrow_overlay_arrowoverlay [INFERRED 0.95]
- **Move Execution and Promotion Flow** — src_ui_board_chess_board_chessboard, src_ui_board_piece_view_pieceview, src_ui_dialogs_promotion_dialog_promotiondialog [INFERRED 0.85]
- **HUD Game Analysis and Control** — src_ui_hud_game_controls_gamecontrols, src_ui_hud_elo_slider_eloslider, src_ui_hud_eval_bar_evalbar, src_ui_hud_move_history_movehistory [INFERRED 0.85]
- **cburnett piece set** — assets_pieces_cburnett_bb, assets_pieces_cburnett_bk, assets_pieces_cburnett_bn, assets_pieces_cburnett_bp, assets_pieces_cburnett_bq, assets_pieces_cburnett_br, assets_pieces_cburnett_wb, assets_pieces_cburnett_wk, assets_pieces_cburnett_wn, assets_pieces_cburnett_wp, assets_pieces_cburnett_wq, assets_pieces_cburnett_wr [INFERRED 0.85]
- **staunty piece set** — assets_pieces_staunty_bb, assets_pieces_staunty_bk, assets_pieces_staunty_bn, assets_pieces_staunty_bp, assets_pieces_staunty_bq, assets_pieces_staunty_br, assets_pieces_staunty_wb, assets_pieces_staunty_wk, assets_pieces_staunty_wn, assets_pieces_staunty_wp, assets_pieces_staunty_wq, assets_pieces_staunty_wr [INFERRED 0.85]
- **Horsey Theme Chess Piece Set** — assets_pieces_horsey_bb, assets_pieces_horsey_bk, assets_pieces_horsey_bn, assets_pieces_horsey_bp, assets_pieces_horsey_bq, assets_pieces_horsey_br, assets_pieces_horsey_bw, assets_pieces_horsey_kb, assets_pieces_horsey_kw, assets_pieces_horsey_nb, assets_pieces_horsey_nw, assets_pieces_horsey_pb, assets_pieces_horsey_pw, assets_pieces_horsey_qb, assets_pieces_horsey_qw, assets_pieces_horsey_rb, assets_pieces_horsey_rw, assets_pieces_horsey_wb, assets_pieces_horsey_wk, assets_pieces_horsey_wn, assets_pieces_horsey_wp, assets_pieces_horsey_wq, assets_pieces_horsey_wr [INFERRED 0.85]

## Communities (43 total, 40 thin omitted)

### Community 0 - "Board and Piece Display"
Cohesion: 0.29
Nodes (10): ArrowOverlay, ArrowOverlay.compute_arrow_polygon, ChessBoard, ChessBoard Scene, PieceView, SquareCell, PromotionDialog, PromotionDialog Scene (+2 more)

### Community 1 - "Chess Engine and Rules"
Cohesion: 0.33
Nodes (7): GameSettings, ChessMoveGenerator, ChessSAN, ThreatDetector, EngineService, UCIClient, MainGame

### Community 2 - "Evaluation and Rating HUD"
Cohesion: 0.50
Nodes (4): EloSlider, EloSlider Scene, EvalBar, EvalBar Scene

## Knowledge Gaps
- **61 isolated node(s):** `AudioService`, `BoardThemes`, `GameSettings`, `ChessBoardState`, `ChessTypes` (+56 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 61 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **40 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What connects `AudioService`, `BoardThemes`, `GameSettings` to the rest of the system?**
  _61 weakly-connected nodes found - possible documentation gaps or missing edges._