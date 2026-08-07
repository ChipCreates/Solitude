# Solitude Migration: Phase-by-Phase Implementation Tasks

Companion to [RUST_MIGRATION_PLAN.md](RUST_MIGRATION_PLAN.md) — that document explains the *why* and the architecture; this one is the *how*, broken into small, ordered, checkable tasks.

## How to use this document

- Work top to bottom within a phase. Phases are ordered by dependency — don't start Phase 2 with Phase 1 boxes unchecked.
- Each phase ends with an explicit **exit criteria** checklist. Treat it as a gate, not a suggestion — the whole point of the phased plan (see RUST_MIGRATION_PLAN.md §3) is proving the architecture generalizes before mass-porting the remaining games.
- Tasks reference specific Dart source files to port from and specific new Rust/TS files to create — use them as the concrete cross-reference when a task description alone isn't enough context.
- "Port X" means: read the Dart implementation, re-express its *behavior* in idiomatic Rust/TS, and port the corresponding test cases as the acceptance check — not a line-by-line transliteration.

---

## Phase 0 — Workspace & Skeleton (no gameplay yet)

Goal: prove every piece of cross-cutting infrastructure works end-to-end — on all three platform targets — before any game logic exists.

### 0.1 Rust workspace
- [ ] Create `solitude-rs/` directory at the repo root (sibling to `lib/`)
- [ ] `cargo new --lib crates/engine-core`
- [ ] `cargo new --lib crates/engine-wasm`
- [ ] Create workspace-root `Cargo.toml` listing `engine-core`, `engine-wasm`, and (once scaffolded in 0.2) `tauri-backend` as members
- [ ] `engine-wasm/Cargo.toml`: add `wasm-bindgen`, `console_error_panic_hook`, `serde`, `serde_json`; set `crate-type = ["cdylib", "rlib"]`
- [ ] Confirm `engine-core` has **zero** `wasm-bindgen`/browser dependencies and `cargo test -p engine-core` runs on the host toolchain with no wasm target needed

### 0.2 Tauri project scaffold (desktop + Android)
- [ ] Scaffold a Tauri v2 + React + TypeScript project (`npm create tauri-app@latest` or manual) inside `solitude-rs/`
- [ ] Rename/relocate the generated backend crate to `crates/tauri-backend` per the planned layout (or keep the default `src-tauri/` name — pick one and note the choice in the workspace `Cargo.toml` comment)
- [ ] `tauri android init` to add the Android target (`gen/android/`)
- [ ] `tauri dev` boots an empty window with no errors
- [ ] `tauri android dev` boots on an emulator (requires Android SDK + an emulator image — install if not already present)

### 0.3 Web PWA build target
- [ ] `npm install -D vite-plugin-pwa`
- [ ] Create `vite.web.config.ts` (separate from the Tauri-targeted `vite.config.ts`), output directory `dist-web/`
- [ ] Add `build:web` / `preview:web` npm scripts
- [ ] `npm run build:web && npm run preview:web` serves a working static build in a plain browser tab

### 0.4 WASM build pipeline (prove the single-artifact claim)
- [ ] Wire a WASM-loading Vite plugin (`vite-plugin-wasm` + `vite-plugin-top-level-await`, or `wasm-pack` output consumed directly)
- [ ] Write one trivial exported function in `engine-wasm` (e.g. `#[wasm_bindgen] pub fn ping() -> u32 { 42 }`)
- [ ] `src/wasm/engine.ts`: load the module, call `ping()`, render the result in a placeholder React component
- [ ] Confirm this identical WASM artifact works under all three run targets: `tauri dev`, `tauri android dev`, and the plain `vite` web dev server — this is the concrete proof that one Rust build serves desktop, Android, and web with zero duplication

### 0.5 Canvas skeleton
- [ ] `canvas/GameCanvas.tsx`: single `useEffect` establishing a `requestAnimationFrame` loop
- [ ] Apply `window.devicePixelRatio` scaling on canvas element resize
- [ ] Draw a static placeholder (e.g. a grid of rectangles) to prove the render pipeline works before any real card data exists
- [ ] Confirm the rAF callback allocates no new closures/objects per frame (reuse a single 2D context reference held outside the loop)

### 0.6 Persistence skeleton
- [ ] `persistence/store.ts`: define the `GameStore` TypeScript interface (see RUST_MIGRATION_PLAN.md §4)
- [ ] `persistence/tauriStore.ts`: one Tauri command round-tripping a trivial file through the app-data directory
- [ ] `persistence/webStore.ts`: open one IndexedDB database, write/read one trivial record
- [ ] Wire the `isTauri()` runtime check selecting between them (`typeof window !== "undefined" && "__TAURI_INTERNALS__" in window`, per the WordSearch precedent)
- [ ] Confirm the round-trip works identically through both backends
- [ ] `capabilities/desktop.json` / `capabilities/mobile.json`: scope filesystem permission to exactly the one app-data path used above — no broader `fs:default` or wildcard scope

### Phase 0 exit criteria
- [ ] WASM function call from React works on desktop, Android emulator, and a web browser tab
- [ ] Canvas renders a static placeholder with correct DPI scaling
- [ ] One trivial record round-trips through both persistence backends
- [ ] All three run targets boot cleanly with no console errors

---

## Phase 1 — Klondike Vertical Slice

Goal: build every piece of shared infrastructure exactly once, proven against the most complex existing game (Klondike — draw modes, Vegas scoring, `isTrulyLost`, hand-rolled undo). Everything built here is reused by every later game.

### 1.1 Core data types (`engine-core`)
- [ ] `card.rs`: `Suit` enum (4 variants), `Rank` enum (13 variants), `CardId(u8)`, `Card { suit, rank, id, face_up }`
- [ ] `pile.rs`: `PileType` enum (stock, waste, foundation, tableau, cell, reserve, pyramid, discard), `Pile { kind, index, cards: Vec<Card> }`
- [ ] `deck.rs`: `build_deck(count: u8) -> Vec<Card>`, seeded Fisher-Yates `shuffle(seed: u64)`
- [ ] `mv.rs`: `MoveExtra` enum (start with `None` + Klondike's `StockRecycle` variant), `Move` struct
- [ ] Port `test/models/card_test.dart` cases → `card.rs` unit tests (all 52 cards, stacking rules, foundation rules, equality)
- [ ] Port `test/models/deck_test.dart` cases → `deck.rs` unit tests (creation, shuffle determinism given a fixed seed, draw)
- [ ] Port `test/models/pile_test.dart` cases → `pile.rs` unit tests
- [ ] Port `test/models/move_test.dart` cases → `mv.rs` unit tests
- [ ] `cargo test -p engine-core` green for all of the above

### 1.2 Generalized undo/redo (`engine-core`)
- [ ] Define `GameSnapshot` (piles + move_count + any scalar per-game state), deriving `Clone`, `Hash`
- [ ] `history.rs`: `History { past: Vec<GameSnapshot>, future: Vec<GameSnapshot> }` with `push`/`undo`/`redo`
- [ ] Unit test: push 3 snapshots, undo twice, redo once — confirm state at each step matches the expected snapshot
- [ ] Unit test: a new `push` after an `undo` clears the `future` stack (matches current Dart redo-clearing behavior)

### 1.3 `GameRules` trait + Klondike implementation (`engine-core`)
Reference: `lib/features/game/games/game_interface.dart`, `lib/features/game/games/klondike/klondike_game.dart` (831 lines).

- [ ] `game.rs`: define the `GameRules` trait (see RUST_MIGRATION_PLAN.md §2 for the exact signature)
- [ ] `games/klondike.rs`: `struct KlondikeGame` implementing `GameRules`
- [ ] Port the triangular deal (pile *i* gets *i+1* cards, only the last face-up; remainder to stock face-down)
- [ ] Port `DrawMode` (One, Three) as a constructor parameter — **not** a `SettingsProvider` dependency, per the trait-splitting decision in RUST_MIGRATION_PLAN.md §2
- [ ] Port Vegas-mode fields: `max_stock_recycles: Option<u32>`, `stock_recycle_count: u32`
- [ ] Port `is_valid_move`: foundation-stacking rule, tableau alternating-color-descending rule, empty-tableau-requires-King rule
- [ ] Port `execute_move`: card transfer + face-down-card-flip-on-exposure detection (`willFlipCard` in the Dart source)
- [ ] Port `tap_stock`: draw 1 or 3 cards to waste; recycle waste→stock respecting `max_stock_recycles`
- [ ] Wire `execute_move`/`tap_stock`/`undo`/`redo` through the generic `History` mechanism from 1.2 — **do not** hand-roll Klondike-specific undo logic; this is the proof point that the generalized mechanism actually replaces the 40-line Dart original
- [ ] Port `is_lost` (the Dart `isTrulyLost`, `klondike_game.dart:595`): full deterministic unwinnable-state detection
- [ ] Port `get_hint`'s 4-tier priority heuristic (foundation moves → moves exposing face-down cards → waste-to-tableau → tableau shuffling)
- [ ] Port `check_win`
- [ ] Port the Vegas scoring formula as a pure function of `deck_size` + foundation card counts, living in `engine-core` generically (not Klondike-specific — every game can use it)
- [ ] Port `test/games/klondike_game_test.dart` and `test/klondike_is_truly_lost_test.dart` cases → Rust unit tests
- [ ] `cargo test -p engine-core games::klondike` green

### 1.4 `GameFactory` (`engine-core`)
- [ ] `factory.rs`: `GameType` enum (Klondike only for now — others added in Phases 2/3), match-based `create_game(GameType) -> Box<dyn GameRules>`

### 1.5 WASM boundary (`engine-wasm`)
- [ ] `initialize(game_type: u8, seed: u64)`
- [ ] `execute_move(from_pile, from_idx, to_pile, to_idx, card_ids: &[u8]) -> i32`
- [ ] `tap_stock() -> i32`
- [ ] `undo() -> bool`, `redo() -> bool`
- [ ] `get_hint() -> JsValue` (or a packed struct/pointer per the plan's boundary design)
- [ ] `piles_layout_ptr()`/length accessor returning the packed pile/card buffer described in RUST_MIGRATION_PLAN.md §2
- [ ] `save_snapshot_ptr()`/`save_snapshot_len()`, `load_snapshot(ptr, len) -> i32`
- [ ] Wire `console_error_panic_hook` behind a debug-only feature flag
- [ ] Write a deliberately-malformed `load_snapshot` call and confirm it returns an error code, not a panic

### 1.6 React WASM wrapper
- [ ] `src/wasm/engine.ts`: typed wrapper functions matching every export from 1.5
- [ ] Implement the memory-view re-fetch helper — re-read `Uint8Array`/`Float32Array` from `memory.buffer` on **every** call site, never hold a view across frames or across a call that could allocate

### 1.7 Input layer (React)
Reference: `lib/features/game/widgets/pile_widget.dart` (`_PointerTapDetector`, `Draggable`/`DragTarget`), `lib/features/game/screens/game_screen.dart:84-138` (keyboard handling).

- [ ] `input/pointerController.ts`: `onPointerDown/Move/Up`, 8px move-threshold + 300ms double-tap window disambiguation (port the logic from Dart's `_PointerTapDetector`)
- [ ] Wire single-tap → select-card / attempt-best-move; double-tap → auto-move-to-foundation call
- [ ] Wire drag: pointerdown on a card → track drag state → pointerup over a target pile → validate (read-only `is_valid_move`-equivalent WASM call) → `execute_move` on success
- [ ] `input/keyboardNav.ts`: Tab/Shift-Tab pile cycling, Enter/Space activate, U/Ctrl+Z undo, N new game, H hint, A autoplay toggle, Esc settings
- [ ] Klondike's focusable-pile ordering as a small TS data table (stock→waste→foundations→tableau, matching the Dart `getNextFocus` order at `klondike_game.dart:797`)
- [ ] 44×44px minimum touch-target padding on every interactive pile/card hit-region (pad the hit-region, not just the visible art — matters most once the compact rendering tier is smaller than 44px)

### 1.8 Canvas rendering — both responsive tiers
Reference: `lib/features/game/widgets/card_widget.dart`, `card_gloss_painter.dart`, `lib/features/game/layouts/layout_strategy.dart`, `klondike_layout_strategy.dart`.

- [ ] `canvas/layout/gridLayout.ts`: port `GridLayoutMixin`'s formula verbatim — `cardWidth` from column count + 15%-of-width gap, clamped `[50,150]`px; `stackOffset` clamped to `[0.15,0.28]×cardHeight`
- [ ] Klondike-specific layout: stock/waste/gap/4-foundations top row + 7 tableau columns, including left-hand-mode mirroring
- [ ] `pipPositions.ts`: port `_getPipPositions`'s per-rank offset table verbatim
- [ ] Card gloss/sheen: port the 4-gradient single-pass composite from `card_gloss_painter.dart` to Canvas `createLinearGradient`
- [ ] Card-back procedural patterns: diamond, crosshatch, dots, waves (Canvas path-drawing functions)
- [ ] Face-card (J/Q/K) SVG: load once, rasterize to an offscreen canvas per rank/suit/theme combination at startup, cache, `drawImage` per frame — never re-parse SVG paths per frame
- [ ] **Standard tier**: full pip layout + full face-card SVG art, per the above
- [ ] **Compact/mobile tier**: single pip + rank character for every card; face cards = top-half-cropped rasterized SVG (`drawImage` with `sy=0, sHeight=fullHeight/2`) + pip + letter (J/Q/K) — per RUST_MIGRATION_PLAN.md §5
- [ ] Tier-selection threshold constant, chosen by rendered card pixel width — test by narrowing a desktop browser window, not just by platform
- [ ] Card flip: manual Canvas horizontal-scale interpolation (`scaleX` 1→0→1, face swap at the midpoint) — not a CSS transform, so it composites correctly with an in-flight flying-card tween
- [ ] Flying-card move/deal/stock-draw tween: position + scale-bump (1.0→1.05→1.0) + rotation-wobble (0→0.02rad→0), flip synced at t=0.5 for stock draws
- [ ] `GameCanvas.tsx`: fixed-timestep accumulator driving the tweens above, re-fetching WASM memory views every frame (never cached)

### 1.9 Theme + settings UI
Reference: `lib/features/settings/models/theme_preset.dart`, `lib/features/settings/services/settings_provider.dart`, `lib/core/utils/overlay_validator.dart`.

- [ ] `theme/presets.ts`: port all 8 `ThemePreset` objects (colors, overlay tint + intensity + blend mode) as flat TS data
- [ ] CSS custom properties for React chrome; fill-color parameters passed into the Canvas renderer
- [ ] `store/uiStore.ts` (Zustand): the ~20-field settings schema (drawMode, autoComplete, themeMode, autoplay, difficulty, scoringMode, cardBack*, sound/music enabled+volume, currentThemeId, per-theme overlay-intensity map, hintMode, victoryPattern, vibrationEnabled, leftHandMode, vegasBankroll, cumulativeVegas, showTimer)
- [ ] Settings screen: 4 tabs (Theme/Cards/Gameplay/Sound) as React components reading/writing `uiStore`
- [ ] `overlayValidator.ts`: port the WCAG contrast logic using real `Math.pow` (not the buggy Dart integer-loop) — manually verify expected values against the correct formula before porting `overlay_validator_test.dart`'s cases, since those may currently assert the buggy output

### 1.10 Persistence — Klondike save/resume + statistics
Reference: `lib/features/game/services/game_state_repository.dart`, `lib/features/statistics/services/statistics_service.dart`.

- [ ] `SaveEnvelope` struct in `tauri-backend/persistence/schema.rs` (schema_version, game_type, piles, move_count, elapsed_ms, saved_at, variant_data)
- [ ] `VariantData::Klondike { stock_recycle_count, draw_mode, max_recycles }` variant
- [ ] Tauri commands: `save_game`, `load_game`, `clear_game` — SQLite or JSON file, behind the capabilities-scoped app-data path from 0.6
- [ ] `webStore.ts`: IndexedDB equivalent of the same `SaveEnvelope` shape
- [ ] Statistics: SQLite table (one row per `GameType`) on the Tauri side; IndexedDB object store on the web side — both storing the same shape (gamesPlayed, gamesWon, gamesLost, currentStreak, bestStreak, bestTime, fewestMoves, vegasCumulativeScore, vegasHighScore)
- [ ] Wire save-on-background/pause (Tauri lifecycle event) and save-on-`visibilitychange` (web) triggers, matching the current app's lifecycle-triggered save behavior
- [ ] Wire load-on-startup: check for a saved game before showing the chooser screen, restore into `GameCanvas` if present
- [ ] Port `test/services/statistics_service_test.dart` cases as acceptance tests against **both** backends

### 1.11 Audio
- [ ] `audio/audioService.ts`: one consolidated module subscribing to a WASM-call-triggered event stream (moveExecuted, cardFlipped, stockDrawn, invalidMove, gameWon) — collapsing the two redundant Dart services into one from the start
- [ ] Load and play the 6 existing audio assets via the Web Audio API
- [ ] Volume/enabled settings wired to `uiStore`

### Phase 1 exit criteria
- [ ] Klondike fully playable via mouse + keyboard on desktop (`tauri dev`)
- [ ] Klondike fully playable via touch on an Android emulator/device (`tauri android dev`)
- [ ] Klondike fully playable via touch/mouse in a browser tab (web target), including the compact tier when the viewport is narrowed
- [ ] Save/resume round-trips correctly across an app restart, on both persistence backends
- [ ] Statistics record correctly (win, loss, best time, move count) on both backends
- [ ] All ported Klondike + core-model Rust unit tests pass
- [ ] Malformed `load_snapshot` input returns an error, never panics (manual check)

---

## Phase 2 — Pyramid + FreeCell (proves the architecture generalizes)

Goal: stress-test whether `GameRules`/`Pile`/`Move`/`History` are genuinely generic or accidentally Klondike-shaped, using the most structurally different game (Pyramid) plus a real algorithmic formula (FreeCell's supermove).

### 2.1 Pyramid (`engine-core`)
Reference: `lib/features/game/games/pyramid/pyramid_game.dart` (712 lines).

- [ ] `games/pyramid.rs`: 28 individual single-card piles (`PileType::Pyramid`), plus stock/waste/discard
- [ ] Port the adjacency/coverage model: `pyramid_covers: Vec<Vec<usize>>`, `pyramid_positions` (row/col), built once in an equivalent of `_buildPyramidStructure()`
- [ ] Port `is_card_uncovered(index)`'s coverage-scan logic
- [ ] Port `is_valid_move`: pairs-summing-to-13 matching, King self-removal, moves always target the discard pile — this is **not** stack-based logic; confirm `GameRules` accommodates it without special-casing elsewhere in shared code
- [ ] `MoveExtra::PyramidPair { second_card: CardId }` variant
- [ ] Port or write test coverage matching `pyramid_game.dart`'s behavior (check whether a dedicated Dart test file exists first)
- [ ] **If `GameRules` needed changes to accommodate Pyramid, document exactly what changed and why** — this is the explicit point of doing Pyramid second rather than eighth

### 2.2 Pyramid layout + rendering
Reference: `lib/features/game/layouts/pyramid_layout_strategy.dart`.

- [ ] `canvas/layout/pyramidLayout.ts`: port the coordinate formula verbatim — `x = centerX + (col - row/2) * cardWidth * 1.1 - cardWidth/2`, `y = topPadding + row * cardHeight * 0.4`
- [ ] Verify the compact tier's 44px touch-target minimum still fits Pyramid's dense 28-card triangular layout at phone width — adjust the card-size floor if the grid formula's clamp is too aggressive here

### 2.3 FreeCell (`engine-core`)
Reference: `lib/features/game/games/freecell/freecell_game.dart` (697 lines).

- [ ] `games/freecell.rs`: 4 free cells (`PileType::Cell`), 4 foundations, 8 tableau, **no** stock/waste
- [ ] Port the deal: all 52 cards face-up, round-robin across 8 piles (4 get 7, 4 get 6)
- [ ] Port the supermove formula: `max_moveable_cards = (empty_cells + 1) * 2^empty_columns`, plus the empty-columns-discounting variant for moves targeting an empty column
- [ ] Unit test: supermove formula against specific empty-cell/empty-column combinations, checked bit-for-bit against the Dart original's expected outputs
- [ ] Port `is_safe_to_auto_move` (opposite-color foundations within 1 of the card's value) — used by both auto-complete and `find_best_auto_move_destination`
- [ ] `MoveExtra::FreecellSupermove { cells_used, columns_used }` variant

### 2.4 FreeCell layout + rendering
- [ ] Confirm the 8-column grid works via the existing `gridLayout.ts` math with no code changes — verify the layout correctly omits stock/waste rendering slots when a game has neither

### 2.5 Persistence
- [ ] `VariantData::Pyramid` and `VariantData::FreeCell` variants — audit whether either needs extra saved state beyond piles/move_count (FreeCell likely needs `None`, given no stock/waste state to track)
- [ ] Save/load + statistics round-trip test for both games, both backends

### Phase 2 exit criteria
- [ ] Both Pyramid and FreeCell fully playable on all three targets
- [ ] No game-specific special-casing leaked into `GameRules`, `History`, or the WASM boundary — confirm by inspecting those files for Pyramid/FreeCell-specific branches
- [ ] Supermove formula unit-tested and matches the Dart original exactly

---

## Phase 3 — Remaining 8 Games

Repeat the per-game checklist below for each of the 8 games, in the batch order given.

### Per-game checklist (apply to each)
- [ ] `games/<name>.rs`: port the dealing logic
- [ ] Port `is_valid_move`/`execute_move` for this game's specific stacking/matching rule
- [ ] Port `check_win`/`is_lost` if the game has custom loss detection (confirm which games do — most inherit the default `false`)
- [ ] Port `get_hint`'s priority heuristic
- [ ] Port `canvas/layout/<name>Layout.ts` (grid-family games: just set `columnCount`/`horizontalPadding`; absolute-position family: port the coordinate formula)
- [ ] Audit for `VariantData` needs — add a typed variant if the game has extra saveable state (don't default to assuming `None`)
- [ ] Port `test/games/<name>_game_test.dart` cases if the file exists (note in this checklist which games currently lack a dedicated test file, since those need new test coverage written from the Dart implementation's behavior instead)
- [ ] Save/load + statistics round-trip test, both backends
- [ ] Play-test end-to-end on all three targets (desktop, Android emulator, web)

### 3.1 Batch A — Klondike-like (stack-based)
- [ ] Yukon (move-any-face-up-group regardless of internal sequence) — `lib/features/game/games/yukon/`
- [ ] Scorpion (move-any-face-up-group variant) — `lib/features/game/games/scorpion/`
- [ ] Forty Thieves (strict single-card-move) — `lib/features/game/games/fortythieves/`
- [ ] Canfield (strict single-card-move, reserve pile — pay particular attention to reserve-pile config as a `VariantData` candidate) — `lib/features/game/games/canfield/`

### 3.2 Batch B — Pyramid-like matching
- [ ] Golf (rank±1 matching, no suit) — `lib/features/game/games/golf/`
- [ ] TriPeaks (rank±1 matching; 3 mini-pyramids + continuous bottom row) — `lib/features/game/games/tripeaks/`; port `tripeaksLayout.ts`'s peak-centers-at-25%/50%/75%-width formula from `tripeaks_layout_strategy.dart`

### 3.3 Batch C — Spider (own mini-phase — genuinely unique mechanics)
Reference: `lib/features/game/games/spider/spider_game.dart` (744 lines, largest of the ten).

- [ ] 2-deck build (104 cards), 1/2/4-suit difficulty modes as a constructor parameter
- [ ] No waste pile — confirm `GameRules`/layout correctly represent "no waste" (already proven possible by FreeCell's no-stock/no-waste case in Phase 2)
- [ ] `tap_stock` deals 1 card to **all 10 tableau piles simultaneously** (distinct from every other game's single-target stock tap) — requires the "no empty tableau piles" precondition
- [ ] Port the same-suit-descending-sequence validity check (distinct from Klondike's alternating-color rule)
- [ ] Port completed-K→A-run auto-detection/extraction into `completedPiles`, triggered after every move and every stock deal (`_checkAndRemoveCompletedSequence`)
- [ ] `check_win`: all 8 completed piles non-empty
- [ ] **Decide and document**: does Spider get solver support in this port, or does it preserve current no-solver parity? Flag for Phase 4 either way
- [ ] Port `test/games/spider_game_test.dart` cases if present

### Phase 3 exit criteria
- [ ] All 10 games playable end-to-end on all three targets
- [ ] Full save/resume + statistics coverage across all 10 games, both persistence backends
- [ ] Every game's ported test-case set passes

---

## Phase 4 — Solver, Autoplay, Polish

### 4.1 Solver generalization
Reference: `lib/features/game/ai/solver_engine.dart`, `lib/features/game/ai/abstract_solver.dart`, per-game `*_solver_state.dart`.

- [ ] `engine-core/solver/mod.rs`: generic best-first search using `BinaryHeap<Reverse<...>>` ordered by `heuristic_score` — replacing the confirmed Dart bug (`openSet.sort()` inside the per-move-expansion loop, `solver_engine.dart:62`)
- [ ] `solver/state.rs`: `SolverState` trait implemented directly by `GameSnapshot` (reuse the undo/redo snapshot type, not a second parallel representation, per RUST_MIGRATION_PLAN.md §2)
- [ ] `signature`: `derive(Hash)` on `GameSnapshot` → `u64`, replacing the current formatted-string signature
- [ ] Wire the solver for every game that had one in Dart
- [ ] Implement (or explicitly defer, per the Phase 3 decision) Spider solver support
- [ ] Regression test: solve time/node-count measurably improves vs. a naive-sort baseline — concrete evidence the `BinaryHeap` fix actually helped, not just an assumption
- [ ] Preserve the 5-second solve timeout from the original design

### 4.2 Autoplay/auto-complete
Reference: `lib/features/game/services/solitaire_bot.dart`.

- [ ] `engine-core`: rule-discovery portion of the bot (repeated `get_hint` calls, oscillation/loop detection via move-signature history, stock-draw fallback after 2 recycles with no progress)
- [ ] TS side: pacing loop (300-400ms between moves) calling the Rust rule-discovery function, driving the flying-card animation per move
- [ ] `auto_complete_step`: simpler loop, 100ms pacing, until it returns false or the game is won

### 4.3 Victory particle system
Reference: `lib/features/game/widgets/victory_card_animation.dart` (461 lines).

- [ ] `canvas/renderParticles.ts`: TS-side SoA — parallel `Float32Array`s for x/y/vx/vy/rotation/life (genuinely warranted SoA use case, per RUST_MIGRATION_PLAN.md §2)
- [ ] Port all 4 patterns: cascade (gravity/bounce), fountain (shoot-up-then-fall), scatter (explosion + friction decay), vortex (spiral, radius/rotation-speed params)
- [ ] Port constants: `gravity=0.5`, `bounceDamping=0.7`, `friction=0.98`, `spawnIntervalMs=100`, `vortexSpeed=2.0`, `vortexRotationSpeed=0.1`, `initialVortexRadius=200.0`
- [ ] Wire the `VictoryPattern` setting (forced pattern vs. random) from `uiStore`

### 4.4 Final consolidation
- [ ] Confirm the single audio module (built in 1.11) is fully wired with no leftover dual-service pattern anywhere
- [ ] Confirm the WCAG fix is live and validated against corrected test expectations
- [ ] Statistics migration tool: a standalone script reading a user's existing Hive box file, emitting the new `Statistics` JSON — scoped to statistics only, not in-progress game state (see RUST_MIGRATION_PLAN.md §4)

### Phase 4 exit criteria
- [ ] Full 10-game parity with the Flutter app: rules, hints, auto-complete, solver where applicable
- [ ] Victory celebration visually matches (or improves on) the Flutter original across all 4 patterns
- [ ] Migration tool successfully imports a real exported Hive statistics box into the new format (test against actual exported data if available)

---

## Phase 5 — Hardening & Release

### 5.1 Fuzzing / reliability
- [ ] Set up `cargo-fuzz` or `proptest` targeting `load_save`/`load_snapshot`
- [ ] Run against malformed/truncated/adversarial byte sequences — confirm zero panics, every path returns `Result::Err` cleanly
- [ ] Repeat against a manually-corrupted IndexedDB record on the web backend

### 5.2 Cross-platform build verification
- [ ] Full build + smoke test on Windows
- [ ] Full build + smoke test on macOS
- [ ] Full build + smoke test on Linux
- [ ] Android build (APK), installed + smoke-tested on a real device, not just an emulator
- [ ] Web PWA: production build, deployed to a static host, installed via "Add to Home Screen" on both Android and desktop Chrome, confirmed fully offline after the first load
- [ ] Decide whether to expand CI beyond its current ubuntu-only scope to cover the platforms actually being shipped

### 5.3 Documentation & compliance
- [ ] Update `PRIVACY.md`: replace "SharedPreferences for settings / Hive database for game state and statistics" with the accurate description (Tauri FS/SQLite on native, IndexedDB on web); keep every substantive commitment (local-only, no telemetry, no network, user-deletable) unchanged
- [ ] Update `CREDITS.md`: carry forward the SVG Playing Cards (David Bellot/Huub de Beer, LGPL 2.1+) and Inter font (SIL OFL) attributions for whichever assets are still in use post-port
- [ ] Update `README.md` to describe the new stack and the three supported platforms, following the WordSearch README's "one codebase, three targets" framing as a model
- [ ] Add an explicit note that iOS is out of scope for this migration (documented decision, not a silent gap)

### 5.4 Final sign-off checklist
- [ ] All 10 games verified playable on all 3 targets via manual play-through (not just automated tests)
- [ ] No network-related capability present in any Tauri capabilities file
- [ ] No telemetry/analytics/crash-reporter dependency introduced anywhere in the new stack
- [ ] Existing Flutter app (`lib/`) archived or clearly marked superseded, not deleted outright — keep it as a reference until confidence in the new stack is high
