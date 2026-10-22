# Chess 2.0 — Project Rules & Invariants

Single source of truth for project rules. **[MANDATORY]** = hard invariant enforced by tests · **[PROCEDURE]** = required workflow step.
Every logic/UI change MUST pass §5 before you report a task as complete.

## 0. Quick Reference

| Need | Command (`& "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" ...`) |
| :--- | :--- |
| Verification gate (445 assertions) | `--headless --path . -s res://tests/test_runner.gd` |
| Reimport assets after editing `.import`/SVG/PNG | `--headless --path . --import` |
| Asset audit (mipmaps, raster size, font metadata) | `--headless --path . -s res://tools/audit_visual_assets.gd` |
| Display-scale audit + layout snapshot (`SNAP\|`) | `--headless --path . -s res://tools/audit_texture_display.gd` |

**Key numbers:** viewport 720×1280 (window override 540×960, `canvas_items` → 0.75 canvas scale) · board 688 px → 86 px square · `HUDTabContainer` floor 148 px · tab content budget 124 px · badge `z_index` 50 (diameter 0.46 square).

## 1. Scene & Node Integrity
- **Node paths & `@onready` [MANDATORY]:** every rename/restructure of a `.tscn` node MUST come with an updated `@onready` path in `.gd` (and vice-versa).
- **Explicit preloads [MANDATORY]:** root coordinators (`src/main.gd`) declare `const Name = preload("res://...")` for sub-scenes/dialogs/singletons — prevents parser races and circular-dependency failures during boot and in the headless test runner.
- **UID safety [MANDATORY]:** never delete or corrupt `uid="uid://..."` in `.tscn` files or `.uid` sidecars.

## 2. Board & Piece Lifecycle (CRITICAL)
- **`ChessBoard.setup_board()` order [MANDATORY]:** `_position_cells() -> _update_coordinates() -> _refresh_all_squares() -> _refresh_pieces()`. Errors or checkmate calculations inside `_refresh_all_squares()` MUST NOT abort piece rendering (guard with null checks).
- **Game init [MANDATORY]:** `start_new_game()` is guaranteed to run at the end of `_ready()` in `src/main.gd`; never place throwing init code above it.
- **Piece textures:** `res://assets/pieces/<set>/<w|b><SAN>.svg` (pawns use `P`); the fallback to `cburnett` must never break.

## 3. Visual Asset Quality (anti-rough & anti-pixelated)
**[PROCEDURE]** Every addition, adjustment, or maintenance pass on image assets MUST satisfy these five rules.
1. **Raster mipmaps [MANDATORY]:** every PNG/JPG under `res://assets/**` MUST set `mipmaps/generate=true` + `process/fix_alpha_border=true` in its `.import`, then be reimported headlessly. Without a mip chain, downscaling (badge 256 px → 16–40 px) produces rough, shimmering, broken edges.
   - **Nine-patch exception [MANDATORY]:** the nine `assets/ui/tactile_*.png` button skins MUST stay at `mipmaps/generate=false`. `StyleBoxTexture` draws nine regions at wildly different scales (corners 1:1, middle band 0.19×), so the GPU picks a mip level **per region**: the seams between regions and every thin feature of the skin (outline, top highlight, bottom lip, active-tab underline) come out blurry. Measured on the `Moves` tab: mip `107,145,66` vs level 0 `117,161,71`. A 9-patch skin is therefore level-0 by contract, and this is the one sanctioned exemption in the guard below.
2. **Explicit texture filter [MANDATORY]:** set `texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS` explicitly on `TextureRect`/`Sprite2D` nodes and on every `draw_texture*` call — never rely on container inheritance (helper: `game_review_panel._apply_badge_icon_filter()`).
3. **Pixel snapping at rest [MANDATORY]:** in manual `_draw` code and dynamic Control placement, round `Rect2`/positions (`round()`) once an animation has settled (`anim_scale == 1.0`); sub-pixel coordinates are allowed only while an animation is running (`ReviewBadgeOverlay.get_badge_rect()`).
4. **Primitive anti-aliasing [MANDATORY]:** `draw_colored_polygon()` has no AA → inset the fill (`_inset_polygon(pts, 0.35)`) and cover it with `draw_polyline(..., true)`; `draw_line`/`draw_circle` MUST pass `antialiased = true`. A curve edge may be smoothed with a polyline using the **identical color** as the fill (never a differently colored stroke) — see the Eval Graph Contract in §8.
5. **Source resolution vs display size [MANDATORY]:** measured contract — UI icons 18–32 px → raster source ≥ 24 px (ideally 48 px for icons displayed at 30–32 px); pieces 70–116 px → raster source 240–512 px.
   - **`svg/scale` trap:** raising `svg/scale` on a texture that is also used as a `Button.icon` is **not** layout-neutral — `Button.get_minimum_size()` uses the icon's native size. Measured: `icon_palette`/`icon_pause`/`icon_people` 1.0 → 2.0 grew the minimum height of `GameControls` toolbar buttons and `TopBar/BtnPause` from 48 → 72 px and `GameLayout` from 1201 → 1225 px (a B15-class regression). Every `svg/scale`/source-resolution change MUST therefore be verified with a `SNAP|` diff from [`tools/audit_texture_display.gd`](tools/audit_texture_display.gd) (ignore the `BottomPlayerCard/HBox` node — its badge text is noisy between runs).
   - **Automated guard:** Category 17 `test_visual_asset_quality_standards()` — mipmaps on all rasters+SVGs except the nine sanctioned 9-patch button skins (the guard asserts that exact list), piece raster range 240–512 px, valid font enums, toolbar button height ≤ 56 px, `MiniBoardPreview` filter.

## 4. UI, Control & Tween (Godot 4.x)
- **Programmatic Control sizing [MANDATORY]:** when creating a `TextureRect`/`Control` with `EXPAND_IGNORE_SIZE` (e.g. `PieceView`, `SquareCell`), assign both `custom_minimum_size` and `size` explicitly during setup and right after `add_child()` — Godot 4.x collapses them to `(0, 0)` when unbounded.
- **Viewport/CanvasLayer size fallbacks:** during `_ready()` or before the first layout pass, `size` may be `Vector2.ZERO` (e.g. `ConfettiBurst`, `GameOverDialog`, `PauseMenu`). Fallback order: `control.size` → `custom_minimum_size` → `get_viewport_rect().size` → base resolution `Vector2(1280, 720)`.
- **Dialog zoom tween [MANDATORY]:** set `pivot_offset = safe_size * 0.5` before a scale tween (`0.8 → 1.0`) so scaling is center-anchored instead of skewing toward the top-left.
- **Meter/bar interpolation [MANDATORY]:** meters and progress bars (e.g. `EngineProgressBar`) use smooth `Tween`s of ~0.12–0.18 s, never raw value jumps.

## 5. Verification Gate
**[MANDATORY]** After any logic/UI change, run this suite and confirm **everything passes with zero compile/runtime errors**:

```
& "D:\Tools\Godot\Godot_v4.7.2-stable_win64_console.exe" --headless --path . -s res://tests/test_runner.gd
```

Currently **445 assertions**. Most frequently relevant guards: Category 9 (savior shield), Category 14 (Game Review + ASCII), Category 15 (review overhaul + icons), Category 16 (review layout floor), Category 17 (visual asset quality).

## 6. UI/UX, Anti-Slop & Window Fit
- **Window fit [MANDATORY]:** the layout is fixed at 720×1280. Sub-panels inside `SidePanel/HUDTabContainer` must not exceed their vertical budget (~245 px); `MainLayout` must not exceed the viewport.
- **Tab height stability [MANDATORY]:** keep `HUDTabContainer.custom_minimum_size = Vector2(0, 148)` as a constant floor. Without it, the minimum height tracks the active tab (Moves 120 / Engine 148 / Review 254) → `SidePanel` grows, `MainLayout` exceeds 1280 px, and `CenterContainer` shifts the whole layout (board included).
- **Tab content budget = 124 px [MANDATORY]:** the 148 px floor only binds while the content minimum stays ≤ 124 px (the remaining 24 px is chrome: `StyleBoxFlat_tab_panel` margin 8+8 in [`src/main.tscn`](src/main.tscn) plus the `Review` MarginContainer margin 4+4). Measured: Summary 60 px, Graph 98 px, Moves 98 px. Content that can grow unbounded (summary, autowrap labels) MUST be wrapped in a `ScrollContainer` or given `clip_text = true`; keep the primary action (`BtnStartReview`) outside the scroll area.
  - **Guard:** `test_review_layout_floor()` (Category 16) must stay a coroutine — `get_combined_minimum_size()` returns a stale cache within the same frame. [`tools/test_review_layout.gd`](tools/test_review_layout.gd) measures the same budget against a replica TabContainer carrying the real chrome.
- **Segmented view:** a panel needing both a summary and detailed inspection (`GameReviewPanel`) is partitioned into a switcher (`Summary` / `Graph` / `Moves` / `Move Review`), never stacked vertically.
- **UI text must be ASCII [MANDATORY]:** labels/buttons/badges/paragraphs must not contain non-ASCII characters. Class symbols (`!!`, `!`, `★`, `✓`, `?!`, `?`, `✕`, `??`) are delivered by icons via `ReviewBadgeOverlay.get_icon_path()`, not by font glyphs. Guard: `_is_clean_ascii()` plus a loop over all 10 classes in Category 14.
- **Engine & assist only while a game is running [MANDATORY]:** `_handle_game_end` hides and disables `BtnTabEngine` via `_set_engine_tab_available(false)` and moves the active tab to Moves when needed; `start_new_game()` restores it. The `HUDTabContainer` index is deliberately unchanged (tab switching is driven by the custom `HUDTabBar`).
- **Zero emoji & anti-slop:** no emoji in text/buttons/tabs/badges; no decorative arrows (`➔`, `→`); no conversational filler.
- **Chess terminology stays in English [MANDATORY]:** `White Accuracy`, `Black Accuracy`, `Best Move`, `Blunder`, `Fork`, `Pin`, `Checkmate`, `Forced Mate`, `Castling`, `Passed Pawn`, `Eval Loss`, `Show Best Move`, `Retry Move` — even when UI instructions are localized.
- **Typography:** header/accent metrics 20–22 px bold; primary labels/SAN/buttons 14–16 px; tags/chips/sub-labels 13–14 px; **never below 12 px**, with WCAG AA contrast.

## 7. Adaptive Error & Test Mismatch Prevention
- **Assertion parity [PROCEDURE]:** before changing any UI string/title/signal/constant, grep the assertions in [`tests/test_runner.gd`](tests/test_runner.gd) first. Example: an assertion like `res["title"].contains("Brilian")` means the key substring must be preserved.
- **Node path guarding [MANDATORY]:** provide `_ensure_nodes()` fallbacks and guard with `if node != null` before setting properties or connecting signals — a partial scene tree (headless tests) can leave nodes `null`.
- **Dynamic child population [MANDATORY]:** containers that are asserted (`counts_container.get_child_count() > 0`) must always be populated with at least one valid child; never drop the container reference during refactors.

## 8. Game Review & Expected Points
- **Expected Points model (Chess.com V2 parity):** `W = 1/(1+10^(-cp/400))`; mate = 1.0 (White) / 0.0 (Black). Move accuracy `acc = clamp(100 * exp(-2.5 * loss), 0, 100)`. Loss cutoffs ΔW: Best 0.00 · Excellent ≤ 0.02 · Good ≤ 0.05 · Inaccuracy ≤ 0.10 · Mistake ≤ 0.20 · Blunder > 0.20.
  - **Tactical Miss:** the opponent's previous move was a Mistake/Blunder/Miss (`prev_move_was_mistake`) and the player missed the tactical punishment (ΔW > 0.10).
  - **Great Move (only move):** the Best Move is the only positive move and the second-best alternative (`alt_best_eval_cp` from MultiPV rank 2) trails by ≥ 150 cp or a loss gap ≥ 0.15.
  - **Last Book Move** is flagged `is_last_book = true` and becomes the first Key Moment.
  - **Game Rating** uses the actual opponent Elo (bot Elo in vs-AI mode), bounded [100, 3000].
- **Opening Book (3-field EPD):** normalized key `pieces turn castling` (`%s %s %s`) in `res://assets/data/openings.json` (7,914 ECO entries) — prevents false negatives caused by en-passant target differences between FEN and EPD.
- **Dual perspective [MANDATORY]:** store both `eval_white_cp` (White's perspective, used by the eval meter/bar) and `eval_mover_cp` (the moving player's perspective, used for accuracy and classification).
- **Terminal checkmate [MANDATORY]:** never send a checkmate position to the engine (with 0 legal moves it may return 0 cp) — mark it terminal at ±99999 cp.
- **Animated review steps [MANDATORY]:** forward (+1 ply) → `ChessBoard.animate_move(...)`; backward (−1 ply) → `ChessBoard.animate_undo_move(...)`; non-sequential jumps → `ChessBoard.setup_board(...)`.
- **Review closed restoration [MANDATORY]:** when the review closes, restore the board to `state_history[history_index]`, clear the badge, and return tab focus to `Moves`.
- **Foremost badge layer [MANDATORY]:** `ReviewBadgeOverlay.z_index = 50` (above every piece state 0–30: knight hop 30, topple 25, drag 20, pawn 15, promo 12) plus `move_to_front()` inside `board_viewport`.
- **Game active guard:** the review must not terminate a running game (`is_game_active`); warn the user that a game is still in progress.
- **Eval Graph Contract ([`src/ui/hud/eval_graph.gd`](src/ui/hud/eval_graph.gd)):** a pure presentation node; input is `{ ply:int, wp:float 0..1 (White win probability), classification:int }` where `classification = -1` means a neutral point (used during progressive analysis).
  - The Y axis MUST use `ReviewRules.win_probability_chess_com(eval_white_cp)` (the same model as accuracy) so the curve and the accuracy numbers can never contradict each other. Mate: `wp = 1.0` when `mate_in > 0`, otherwise `0.0`.
  - Ply 0 uses the first move's `win_prob_before` (converted to White's perspective when the first move is not White).
  - Keep the node's minimum height small (56 px) with `size_flags_vertical = 3` so it expands into the Review strip (~230 px) without breaking the 148 px floor.
  - Required shape matches Chess.com: White's advantage area filled `#f7f7f7` from the bottom edge up to the curve; the space above the curve is left unfilled so the dark panel background acts as Black's area; plus one 0.0 reference line. Never return to the "two full bands split by a center line" model, and never draw a differently colored stroke over the fill (AA with an identical color is allowed).
  - Markers only for `MARKER_CLASSIFICATIONS` = Book, Brilliant, Great, Inaccuracy, Mistake, Miss, Blunder; Best/Excellent/Good get no dot (verified by pixel sampling: zero green `#96bc4b` pixels). Locked in Category 14.
- **Progressive signal:** `ReviewEngineSession.position_evaluated` includes `ply` in `eval_dict`; `GameReviewService` forwards it as `review_position_evaluated(ply, eval_white_cp, is_mate, mate_in)` (White's perspective) alongside `review_progress`; `main.gd` forwards it to `GameReviewPanel.append_graph_point()` so the curve grows incrementally (progressive points stay neutral until classifications exist).
- **Coach card visibility [MANDATORY]:** `reset_view()` hides `CoachCard`, so `select_step()` MUST show it again (`coach_card.visible = true`) — otherwise the entire Move Review body (badge, notation, narrative, Eval Loss) is never visible.

## 9. Postmortem Index (B1–B23)
Symptom → root cause/fix. The derived rules are already normalized in §1–§8; this table exists to recognize recurring regressions.

| ID | Symptom | Root cause → fix |
| :--- | :--- | :--- |
| B1 | Clicking the Review tab killed a running game | `start_game_review()` had no guard → guard in `select_hud_tab(2)` |
| B2 | Flipped SAN move numbers | `ply % 2 == 0` although ply 1 is White → use the explicit `color` property or `((ply-1)/2)+1` |
| B3 | Eval bar inverted when Black moved | mover-perspective eval was passed to `eval_bar.set_eval()` → separate `eval_white_cp` and `eval_after` |
| B4 | Checkmate position evaluated as 0 cp | engine has no legal move → pre-check terminal checkmate in the review session |
| B5 | Static CP thresholds unfair in lopsided positions | → switched fully to Chess.com V2 Expected Points Loss |
| B6 | Brilliant/Great never detected | MultiPV 1 → `ReviewEngineSession` uses MultiPV 3 |
| B7 | Empty board at boot | missing `@onready var game_over_dialog` → compile error, `_ready()` aborted, `setup_board()` never ran |
| B8 | Silent review navigation | added `_play_review_move_sfx` (+ undo audio) in `_on_review_move_selected` |
| B9 | Show Best Move drawn on the post-move position | rewind to `prev_fen`, animate the best move with arrow/star, and provide a toggle back |
| B10 | Review best move shifted by 1 ply | double `readyok` (`start()` + `start_analysis()`) → `_is_engine_ready` guard, drop the extra `isready`, ignore `bestmove` when `_is_running == false` |
| B11 | Residual best-move piece; review lacked a Start Position | `is_showing_best_move_active` guard + initialize `current_step_index = -1` |
| B12 | Tactical Miss and Great Move never appeared | cutoffs too loose (0.03/0.08/0.18/0.30) and `prev_move_was_mistake`/`alt_best_eval_cp` never plumbed → official cutoffs + plumb MultiPV rank 2 |
| B13 | Pawn stayed a pawn after promotion in review | `step_dict` lacked `promo`/`is_ep`/`is_castle` → plumb the flags (defensively derived from `prev_board`) + `_play_promotion_pop()` |
| B14 | Badge vanished on Previous Move | `animate_undo_move()` calls `setup_board()`, which always calls `clear_review_badge()` → `pending_review_badge` + apply the badge in the `_apply_review_badge()` callback |
| B15 | Layout shifted when switching tabs | TabContainer minimum height tracked the active tab (120/148/254) + a 333 px autowrap label → 148 px floor, `ScrollContainer`, `clip_text` |
| B16 | Summary tab completely dead yet undetected | six `@onready` paths pointed at nonexistent nodes → `null`, assertions aborted silently, suite still reported "294/294 PASS" → align paths + `!= null` assertion per node |
| B17 | Move Review badge/notation/narrative never shown | `reset_view()` hid `CoachCard` with no path restoring it → `select_step()` sets `visible = true` |
| B18 | Corrupted badge text (`"aoe" Good Move`) | UTF-8 mojibake → ASCII-only labels, class symbols delivered by icons |
| B19 | Eval graph dived to 0.0 on the mating move; eval bar showed `-M0` | instant checkmate has `mate_in == 0` while detection only checked `mate_in > 0` → check `(eval_white_cp > 0 or mate_in > 0)` and format `+#` |
| B20 | Two stacked tab bars in review mode | `HUDTabBar` hidden during review; the `Moves` tab moved inside `GameReviewPanel` |
| B21 | Classification badge looked rough/not smooth | 256 px PNG drawn at 16–40 px without mipmaps + savior shield fill without AA → mipmaps, explicit filter, pixel snapping, `_inset_polygon` |
| B22 | Asset audit: tactile at 0.19× without mipmaps, checkbox SVGs without mipmaps, horsey pieces at 2400 px (~368 MB VRAM), font enums out of range, orphan assets | mipmaps on **2 checkbox** files (`tactile_*.png` was set here too and had to be reverted, see B23) · horsey `svg/scale` 6.0 → 1.0 (400 px) · fonts normalized · `svg/scale` on `Button.icon` textures is NOT layout-neutral (toolbar 48 → 72 px, GameLayout 1201 → 1225 px) so a snapshot diff is mandatory · 6 zero-reference assets deleted (smoke puff, logo, ico, Roboto, OpenSans, `zzdiag/`) |
| B23 | Every button suddenly showed blurry vertical/horizontal lines (button outline, top highlight, bottom lip, active-tab underline) | B22 added `mipmaps/generate=true` to the 9 `tactile_*.png` **9-patch** skins. `StyleBoxTexture` rasterises its nine regions at very different scales (corners 1:1, middle band down to 0.04–0.19×), so the mip level is chosen **per region**: seams between regions and every thin feature of the skin get averaged away. Measured on the `Moves` tab: green underline `107,145,66` with mipmaps vs `117,161,71` at level 0; zoomed captures show a fuzzy muted border vs a crisp saturated one → `mipmaps/generate=false` on the 9 skins + Category 17 now asserts that exact exemption list (a mip chain is still mandatory for every other raster; the icons drawn on the same `Button` keep theirs) |

**Asset audit methodology notes (from B22):** when scanning for orphan assets, (a) `.import` files produce false references because they contain both the source name and the `.ctex` name, (b) the audit documentation itself (AGENTS.md) also counts as a "reference" and must be excluded from the corpus, and (c) test guards that iterate over a file list (e.g. a font list) are phantom references that must be updated whenever a file is deleted.

<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, read `antislop.md` (core) and then the skill for the task:
- UI / visual: `skills/antislop-ui/SKILL.md`
- Copy & text: `skills/antislop-copywriting/SKILL.md`
- People: `skills/antislop-human/SKILL.md`
- Mobile / responsive: `skills/antislop-layoutmobile/SKILL.md`
- Code comments: `skills/antislop-code/SKILL.md`
<!-- antislop:end -->
