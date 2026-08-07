# Solitude: Flutter → Rust/WASM/Tauri/React Migration Plan

## 0. Context

Solitude is a complete, tested, 10-variant Flutter solitaire collection (~20,000 lines under `lib/features/game/`) with a genuinely strong, already-published privacy story (`PRIVACY.md`: zero telemetry, confirmed by exhaustive grep — the only network-capable call in the whole app is an explicit, user-initiated `url_launcher` open to a GitHub-hosted privacy policy). This migration isn't chasing a missing feature; it's changing the technical foundation: a Rust engine gives one memory-safe, fuzzable, property-testable source of truth for game rules that can be compiled to WASM and shared, byte-for-byte, across every deployment target — desktop, Android, and web — instead of Flutter's single-runtime model.

**Scope decision (from discussion): this targets three platforms from one codebase — desktop (Windows/macOS/Linux via Tauri), Android (via Tauri v2 mobile), and an installable web PWA (plain static build, no Tauri runtime).** This mirrors the architecture already proven in the user's own `~/Projects/WordSearch` project ("one codebase, three targets" — see §2). iOS is out of scope for now, matching that same precedent (no Apple developer/signing story currently in place).

**Repo layout (from discussion): the new stack lives in a sibling directory in this same repository** (e.g. `solitude-rs/`), not a new repo. `lib/` (Flutter) stays untouched and serves as the living reference/spec during the port, archived once the new stack reaches parity.

### What must be preserved
- **Data sovereignty commitments**: everything `PRIVACY.md` promises — local-only storage, no network calls, no telemetry, user-deletable data — must remain true on all three targets, including the web build (see §5 for how "local-only" is satisfied without a filesystem).
- **10-game feature parity**: Klondike, Spider, Pyramid, Golf, FreeCell, TriPeaks, Yukon, Forty Thieves, Canfield, Scorpion — same rules, difficulty modes (draw-1/draw-3, Vegas scoring, Spider's suit-count variants), win/loss semantics (notably Klondike's `isTrulyLost`).
- **Keyboard accessibility** on desktop/web: Tab/Shift-Tab pile cycling, Enter/Space activation, full shortcut set (U/Ctrl+Z, N, H, A, Esc).
- **Existing user statistics data, where feasible** (see §5 migration story) — the in-progress single-slot game save is not worth migrating (ephemeral by nature); statistics (win/loss history, best times) are.

### What gets reimagined, not ported verbatim
- **Undo/redo generalization**: today hand-rolled per game (10 independent "invert the last move" implementations, Klondike's is 40+ lines). Generalize once via full-state snapshotting (§3).
- **Seeded RNG / replay**: `initialize({Random? random})` already accepts a seed, but nothing today ever records one (zero grep hits for "seed" in `lib/`) — there is no existing replay feature and nothing to migrate; this is purely additive new scope if you choose to expose it.
- **Single consolidated audio module**: today there are two redundant, differently-shaped Dart audio services (254 vs. 70 lines) — collapse to one, driven by a game-event stream.
- **WCAG contrast bug fix**: `overlay_validator.dart`'s hand-rolled `pow()` doesn't handle the fractional 2.4 gamma exponent (effectively computes `x^3`). Fix with a real `powf`/`Math.pow` in the port; verify the existing Dart test's expected values before porting them, in case they encode the bug as "correct."
- **Save schema versioning**: add a `schema_version` field that doesn't exist in `SavedGameState` today.
- **`gameSpecificData` typing**: replace the current dynamic duck-typing bag (`final dynamic dynamicGame = game; if (dynamicGame.stockRecycleCount != null) ...`, confirmed at `lib/features/game/services/game_state_repository.dart:256-303`, and today only wired up for 2 of 10 games) with a typed enum, audited per-game.
- **Card rendering strategy**: reimagined per platform tier, not a straight port — see §6.

---

## 1. Target architecture

### One codebase, three targets — the WordSearch precedent, and why it's even simpler here

`~/Projects/WordSearch` establishes the pattern this plan follows:
- A single Tauri v2 project with Android configured alongside desktop (`src-tauri/gen/android/`, `tauri.conf.json`'s `bundle.android` block) — same Rust backend, same webview technology, Tauri's command/capability model unified across desktop and mobile.
- A **second, separate Vite config** (`vite.web.config.ts`) building a plain static PWA (`vite-plugin-pwa`: service worker, manifest, offline asset precaching) to a different output directory (`dist-web/`), deployed independently (GitHub Pages in that project's case) — completely decoupled from the Tauri build, which is unaffected by its existence.
- A runtime `isTauri()` check (`typeof window !== "undefined" && "__TAURI_INTERNALS__" in window`) that lets shared frontend code branch between "call the Tauri backend via IPC" and "do the equivalent thing in plain JS," transparently to the caller.

**Solitude's situation is actually simpler than WordSearch's on the core-logic axis.** WordSearch had to *duplicate* its puzzle-generation/word-validation logic — real Rust for the Tauri IPC path, a hand-written JS reimplementation for the web path — because that logic lived on the Tauri backend, reached only via IPC, and IPC doesn't exist without Tauri. Solitude's game-rules engine, per the mandated architecture, compiles to **WASM**, and WASM has no dependency on Tauri at all — it runs identically in a Tauri webview or a plain browser tab. This means **the exact same `engine.wasm` binary loads on all three targets** (desktop, Android, web PWA) with zero logic duplication. Only the *persistence* layer (§5) needs the WordSearch-style `isTauri()` branch, because filesystem access genuinely doesn't exist on the web.

### Repository layout

```
solitude-rs/
├── Cargo.toml                        # workspace root
├── crates/
│   ├── engine-core/                  # pure game-rules crate, no wasm-bindgen deps, `cargo test`-able
│   │   ├── src/
│   │   │   ├── card.rs               # Card, Suit, Rank, CardId
│   │   │   ├── pile.rs               # Pile, PileType
│   │   │   ├── deck.rs               # Deck + seeded shuffle
│   │   │   ├── mv.rs                 # Move, MoveExtra enum
│   │   │   ├── history.rs            # generalized undo/redo (snapshot-based)
│   │   │   ├── game.rs               # GameRules trait (GameInterface equivalent, split not copied)
│   │   │   ├── games/                # klondike.rs, spider.rs, pyramid.rs, freecell.rs, golf.rs,
│   │   │   │                         # tripeaks.rs, yukon.rs, forty_thieves.rs, canfield.rs, scorpion.rs
│   │   │   ├── factory.rs            # GameType enum + match-based constructor
│   │   │   ├── solver/               # generic best-first search (BinaryHeap, not sort-per-insert)
│   │   │   └── error.rs              # Result<T, EngineError> — no panics on untrusted input
│   │   └── Cargo.toml
│   ├── engine-wasm/                  # thin wasm-bindgen shim, depends on engine-core
│   │   ├── src/lib.rs                # #[wasm_bindgen] exports, memory-view accessors, panic hook
│   │   └── Cargo.toml
│   └── tauri-backend/                # Tauri v2 app crate — desktop AND Android targets
│       ├── src/
│       │   ├── main.rs
│       │   ├── commands/             # save_game.rs, load_game.rs, statistics.rs, settings.rs
│       │   └── persistence/          # schema.rs (versioned), store.rs (SQLite, atomic writes)
│       ├── capabilities/
│       │   ├── desktop.json          # scoped fs permission, desktop-only
│       │   └── mobile.json           # scoped fs permission, Android-specific paths
│       ├── gen/android/              # Tauri Android project (generated + committed, per WordSearch precedent)
│       ├── tauri.conf.json
│       └── Cargo.toml
├── src/                               # React app (Vite + TS) — shared by Tauri and web builds
│   ├── main.tsx
│   ├── wasm/engine.ts                 # loads engine-wasm, memory-view re-fetch helpers
│   ├── persistence/
│   │   ├── store.ts                   # isTauri()-branching facade — see §5
│   │   ├── tauriStore.ts              # Tauri IPC-backed implementation
│   │   └── webStore.ts                # IndexedDB-backed implementation
│   ├── store/                         # Zustand: uiStore.ts (menus/settings/HUD), gameViewStore.ts (throttled read-only mirror)
│   ├── canvas/
│   │   ├── GameCanvas.tsx             # single useEffect + rAF loop
│   │   ├── renderCard.ts              # responsive-tier card rendering — see §6
│   │   ├── renderBoard.ts
│   │   ├── renderParticles.ts         # victory animation, TS-side SoA
│   │   └── layout/                    # gridLayout.ts, pyramidLayout.ts, tripeaksLayout.ts
│   ├── input/
│   │   ├── pointerController.ts       # tap/double-tap/drag disambiguation (touch + mouse)
│   │   └── keyboardNav.ts             # desktop/web only, no-op on touch-primary devices
│   ├── components/                    # React overlay: menus, HUD, settings, dialogs
│   └── theme/presets.ts               # 8 theme presets as data
├── vite.config.ts                     # Tauri-targeted build (desktop + Android)
├── vite.web.config.ts                 # plain static PWA build, vite-plugin-pwa, separate dist-web/
└── tests/
    ├── engine-core/                   # cargo test, ported from Dart test/games, test/models
    └── e2e/                           # playwright, optional, later phase
```

### Resolving the turn-based-vs-tick-loop tension

Solitaire has no continuous simulation — no physics, no per-frame rules mutation. The mandated `world.tick(dt)` fixed-timestep architecture exists for real-time games and must be *adapted*:

- **Rule mutations are RPC-style, not tick-driven.** `engine.execute_move(...)`, `engine.tap_stock()`, `engine.undo()` are discrete WASM function calls triggered directly by input (pointer-up, key-down), exactly like today's `GameController` → `GameInterface` calls. They never happen inside a tick callback.
- **`world.tick(dt)` (if it exists at all) only advances cosmetic/animation state** — and since §6 recommends keeping the victory particle system and flying-card tweens in TS (not Rust), there may be no meaningful Rust-side `tick()` for this app at all. The fixed-timestep accumulator lives in `GameCanvas.tsx`'s own rAF loop, for animation-timing purposes only.
- **Input is not batched into a per-frame bitflag buffer.** That model exists to let continuous simulation sample "what's currently held" once per tick — it doesn't fit a domain where every input is a discrete, complete action. Input handlers call WASM functions directly and synchronously on the triggering event. This still honors the *spirit* of the rule (React captures input, Rust never polls devices, Rust only receives already-decoded move requests as explicit arguments) while deviating from its literal per-frame-buffer mechanism, which would add complexity with no benefit here.
- Document this decision explicitly as a short comment at the top of `engine-wasm/src/lib.rs` and `GameCanvas.tsx` so it isn't silently re-litigated mid-port.

### Layer responsibilities

| Concern | Current Dart location | New home | Notes |
|---|---|---|---|
| Card/pile/move data model | `models/card.dart`, `pile.dart`, `move.dart` | `engine-core::card/pile/mv` | Array-of-Structs, not SoA — see §3 |
| Per-variant rules (10 games) | `games/*/` | `engine-core::games::*` | 1:1 module mapping |
| Undo/redo | duplicated per-game | `engine-core::history` (generalized once) | |
| Solver | `ai/*` | `engine-core::solver` | fix `openSet.sort()`-in-inner-loop bug with `BinaryHeap` |
| Autoplay/auto-complete driver | `services/solitaire_bot.dart` | rule-discovery in `engine-core`, pacing/animation in TS | split: `Future.delayed` pacing is UI timing, not rules |
| Vegas scoring formula | `game_controller.dart` (portable part) | `engine-core` (pure fn of deck size + foundation counts) | |
| Animation sequencing | `game_controller.dart` (~half the file) | React/Canvas entirely | zero Rust equivalent needed |
| Layout math (grid formula, Pyramid/TriPeaks positions) | `layouts/*` | TS `canvas/layout/*` | pure viewport-pixel arithmetic, zero gameplay content — explicit exception to the React/Rust/Canvas routing table, justified below |
| Card rendering | `widgets/card_widget.dart`, `card_gloss_painter.dart` | TS `canvas/renderCard.ts` | responsive tiers, see §6 |
| Theme presets | `theme/theme_preset.dart` | TS `theme/presets.ts` + CSS custom properties | |
| WCAG validator | `core/utils/overlay_validator.dart` | TS (`Math.pow`) | fix the bug; presentation-layer only |
| Settings/statistics/save | `SettingsProvider`, `statistics_service.dart`, `game_state_repository.dart` | `persistence/store.ts` facade over Tauri or IndexedDB | see §5 |
| Audio | 2 redundant Dart services | 1 TS module subscribing to a game-event stream | |
| Input capture | Flutter `Draggable`/`DragTarget` + raw pointer disambiguator + focus system | React `input/*`, touch+mouse unified via Pointer Events | see §7 |

**Layout math stays in TS, not Rust**: confirmed by reading `layout_strategy.dart` — it only touches viewport width/height and clamp constants, never card/pile state. It needs to react instantly to window resize (a UI concern), and routing it through the WASM boundary adds memory-view overhead for zero rules-integrity benefit. This is the one place the literal "React/Rust/Canvas" routing table gets a reasoned exception.

---

## 2. Data model design

### Card/Pile: Array-of-Structs, not SoA — a reasoned call, not a cargo-culted rule

The SoA mandate exists for hundreds/thousands of entities mutated every frame (particle swarms, bullet-hell). Solitude has **at most 104 cards** (Spider), mutated only on discrete move events, never in a hot per-frame loop. SoA here would trade clarity for zero measurable benefit:

```rust
struct Card { suit: Suit, rank: Rank, id: CardId, face_up: bool }
struct Pile { kind: PileType, index: u8, cards: Vec<Card> }  // ≤24 cards even worst-case tableau
```

This mirrors the current Dart shape (`Pile._cards: List<PlayingCard>`) almost exactly — easy to test against the ported Dart test suite. **Where SoA genuinely is warranted**: the victory particle system (potentially hundreds of particles at 60Hz) — but per §6, that stays entirely in TS/Canvas as parallel `Float32Array`s, since it's cosmetic-only and never touches game-rule state. Apply SoA there specifically, not to the card model.

### Deterministic card IDs

Replace `PlayingCard._idCounter` (a process-global mutable static counter — a real footgun for determinism) with:

```rust
struct CardId(u8);  // 0..104 = deck_index * 52 + suit*13 + rank, unique across Spider's 2 decks
```

A pure function of "which physical card in which deck" — required for reproducible replay and stable solver state-signatures, neither of which today's assignment-order-dependent `uniqueId` guarantees (it happens to work today only because nothing currently replays a session).

### Move & generalized undo/redo

Replace `Move.extraData: Map<String, dynamic>?` with a tagged enum audited per-game:

```rust
enum MoveExtra {
    None,
    PyramidPair { second_card: CardId },
    StockRecycle { recycle_count: u32 },
    FreecellSupermove { cells_used: u8, columns_used: u8 },
    // one variant per game that actually needs extra data
}
struct Move { from: PileRef, to: PileRef, cards: Vec<CardId>, flipped_card: bool, drew_from_stock: bool, extra: MoveExtra }
```

**Undo/redo: full-state snapshotting, not command-inversion.** At ≤104 cards, a full `GameState` snapshot is a few hundred bytes; a 200-move undo stack is under 100KB — trivial. This replaces the exact duplication problem flagged above (10 hand-rolled inversion implementations) with one generic mechanism:

```rust
struct History { past: Vec<GameSnapshot>, future: Vec<GameSnapshot> }  // future cleared on new move
impl History {
    fn push(&mut self, snapshot: GameSnapshot);
    fn undo(&mut self, current: GameSnapshot) -> Option<GameSnapshot>;
    fn redo(&mut self, current: GameSnapshot) -> Option<GameSnapshot>;
}
```

Trade-off to note: this loses the human-readable move-history log used for UI display today. If that's worth keeping, maintain a small parallel `Vec<MoveDescriptor>` alongside the snapshot stack, purely for display, decoupled from the undo mechanism itself.

### `GameRules` trait — split, not copied

`GameInterface` today mixes pure rules (`isValidMove`, `executeMove`, `checkWin`) with UI-adjacent concerns (`getNextFocus`, `layoutConfig`) and Flutter-coupled config (`configure(SettingsProvider)`). The Rust trait keeps only the rules:

```rust
trait GameRules {
    fn game_type(&self) -> GameType;
    fn deck_size(&self) -> usize;
    fn piles(&self) -> &PileSet;
    fn initialize(&mut self, seed: u64);
    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool;
    fn execute_move(&mut self, from: PileRef, to: PileRef, cards: &[CardId]) -> Result<Move, EngineError>;
    fn undo(&mut self) -> bool;
    fn redo(&mut self) -> bool;
    fn check_win(&self) -> bool;
    fn is_lost(&self) -> bool;   // default false; Klondike overrides with isTrulyLost logic
    fn tap_stock(&mut self) -> Result<Move, EngineError>;
    fn get_hint(&self) -> Option<HintMove>;
    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef>;
}
```

Deliberately excluded (moved to TS as data/derived logic): `layoutConfig`, `getNextFocus`/`focusablePiles` (keyboard focus order — expressible as a per-game-type ordered pile-ref table in TS), `configure(SettingsProvider)` (replaced by plain constructor parameters at `initialize()` time).

### Solver: reuse the live snapshot representation

Today the solver keeps a *separate* compact immutable state repr per game (card strings like `"5H"`), distinct from the live mutable model — two parallel representations of the same thing. Make `GameSnapshot` (from `History` above) double as the solver's state input directly: already immutable-by-value, already has everything `is_won`/`available_moves` needs, and `signature` can be a cheap `u64` hash (`derive(Hash)`) instead of a formatted string. Fix the confirmed perf bug precisely: `solver_engine.dart:62` calls `openSet.sort()` **inside the per-move-expansion loop** (O(n log n) per edge, not per node) — replace with a `BinaryHeap<Reverse<...>>` in Rust, O(log n) per insertion.

### WASM ↔ JS boundary

Function-call boundary (discrete, called on user action, never per-frame):
```
initialize(game_type: u8, seed: u64) -> ()
execute_move(from_pile, from_idx, to_pile, to_idx, card_ids_ptr, card_ids_len) -> i32   // 0 = ok
tap_stock() -> i32
undo() -> bool
redo() -> bool
get_hint() -> HintResult   // packed struct/pointer, not JSON
save_snapshot_ptr() -> *const u8, save_snapshot_len() -> usize   // for the persistence layer to read
load_snapshot(ptr, len) -> i32   // error code, never panics on malformed input
```

Memory-view boundary (re-fetched fresh on every Canvas render call, never cached across frames — WASM memory growth from any allocating call silently detaches previously-created views):
```
piles_layout_ptr() -> *const u8   // packed: [pile_kind, pile_index, card_count, (suit,rank,face_up)×card_count]
```

Wire `console_error_panic_hook` in `engine-wasm`'s debug feature; every public function taking untrusted input (save bytes, malformed move indices) returns an error code, never panics — the one place a corrupted save file could otherwise crash the whole WASM instance.

---

## 3. Phased rollout plan

Prove the architecture on two structurally divergent games and all three platform targets before mass-porting the rest.

**Phase 0 — Workspace & skeleton, all three targets wired (no gameplay yet)**
- Cargo workspace (`engine-core`, `engine-wasm`, `tauri-backend`); Vite+React+TS app; Tauri v2 project with Android target added (`tauri android init`, mirroring WordSearch's `src-tauri/gen/android/`); second Vite config (`vite.web.config.ts`) with `vite-plugin-pwa`.
- WASM build pipeline (`wasm-pack`/`wasm-bindgen` + Vite plugin), trivial "hello world" export, confirm React can call it and read a memory view — **and confirm this works identically under `tauri dev`, `tauri android dev`, and the plain `vite` web dev server**, proving the single-WASM-artifact claim in §1 before building anything on top of it.
- `GameCanvas.tsx` with the single `useEffect`+rAF loop, `devicePixelRatio` scaling, static placeholder render.
- `persistence/store.ts` facade (§5) with both backends stubbed to a trivial round-trip (write/read one file via Tauri; write/read one record via IndexedDB), proven on all three targets.
- Exit criteria: WASM call + memory-view render + one persisted round-trip, all working on desktop, Android emulator, and a browser tab. No game rules yet.

**Phase 1 — Klondike vertical slice**
- Port `Card`/`Pile`/`Move`/`Deck`/`History` core types — shared by all games, amortizes across the project.
- Port Klondike rules (draw-1/draw-3, Vegas scoring/recycle limits, alternating-color stacking, `isTrulyLost`, 4-tier hint heuristic). Use `test/games/klondike*` and relevant `test/models/*` cases as the acceptance spec (§4).
- Implement generalized undo/redo (§2) against Klondike first — the most complex existing implementation; if it handles Klondike's edge cases (stock recycle count, flip-reveal tracking) cleanly, the rest are trivial by comparison.
- Build the input layer once: drag-and-drop, tap/double-tap disambiguation (touch + mouse via Pointer Events), full keyboard nav on desktop/web. Klondike exercises every pile type except the specialized ones (cell, pyramid).
- Build Canvas rendering for both responsive tiers (§6): desktop/tablet full pip layout + full face-card SVG, and mobile pip+number tier.
- Implement save/resume and statistics for Klondike end-to-end through **both** persistence backends (Tauri FS/SQLite and IndexedDB), including the versioned schema — prove the schema design here since it must generalize to all 10 games' variant data next.
- Exit criteria: Klondike fully playable, keyboard-accessible on desktop/web, touch-playable on Android, saves/resumes/records stats correctly across an app restart on all three targets, passes ported test cases.

**Phase 2 — Second, structurally-divergent game**
- **Pyramid**: most structurally different (28 individual piles, adjacency/coverage model, pairs-summing-to-13 matching instead of stack rules) — stress-tests whether `GameRules` and the pile/move model are genuinely generic or accidentally Klondike-shaped. If Pyramid slots in without loosening the trait, that's strong evidence the abstraction holds.
- Also port **FreeCell** if time allows, specifically to validate the supermove formula `(emptyCells+1) * 2^emptyColumns` ports exactly, and to validate a no-stock/no-waste game fits `LayoutConfig`.
- Exit criteria: two structurally different games working through the same trait/pile/move/history/save machinery, no game-specific special-casing leaking into shared code.

**Phase 3 — Remaining 8 games, batched by similarity**
- Batch A (Klondike-like, stack-based): Yukon, Scorpion, Forty Thieves, Canfield.
- Batch B (Pyramid-like matching): Golf, TriPeaks.
- Batch C (Spider — genuinely unique, its own mini-phase): no waste, stock deals to all 10 tableau piles at once, K→A run auto-extraction, no existing solver to lean on.
- Per batch: port rules module, verify layout module (grid vs. absolute-position family), wire the game's `VariantData` enum case, port the corresponding Dart test file's cases.

**Phase 4 — Solver, autoplay, polish**
- Generalize the solver across games that had one (Spider had none — decide whether to add it now).
- Port `SolitaireBot`'s greedy autoplay driver, split rule-discovery (Rust) from pacing/animation (TS).
- Victory particle system, theme system, consolidated audio, WCAG fix.
- Statistics migration tool for existing Flutter-era users (§5).

**Phase 5 — Hardening & release**
- Fuzz/property-test the WASM boundary with malformed save files (confirm no panics) on all backends.
- Cross-platform build verification: Windows/macOS/Linux, Android (device + emulator), and the PWA (offline install-and-play test — see §4).
- Update `PRIVACY.md` to reflect the new storage backends (Tauri FS/SQLite on native, IndexedDB on web) — the *substance* of the commitments stays true, only the named technology changes.
- Explicit note that iOS remains out of scope (documented, not silently dropped).

---

## 4. Persistence design

### The core problem this section resolves

The architecture's hard rule — "never use localStorage/IndexedDB for critical game saves, route all saves through Tauri to the local filesystem" — implicitly assumes Tauri is always available. **It isn't on the web PWA target**: a browser tab has no filesystem access and no Tauri runtime at all. `~/Projects/WordSearch` sidesteps this by using plain `localStorage` uniformly across *all* its targets, including its Tauri desktop/Android builds — a pragmatic simplification that works for its small save shape (level number, star count, a few booleans) but is a real deviation from Solitude's own stricter data-sovereignty framing, and Solitude's save blobs (full pile/card state, potentially >5KB per save) are a poorer fit for `localStorage`'s synchronous, string-only, ~5-10MB-quota API regardless.

**Recommendation, resolving the rule for a genuinely Tauri-less target**: honor the *spirit* of the rule (durable, structured, local-first storage — never the ad-hoc, size-constrained, synchronous `localStorage`) rather than its letter, via a small facade:

```typescript
// persistence/store.ts
interface GameStore {
    saveGame(state: SaveEnvelope): Promise<void>;
    loadGame(): Promise<SaveEnvelope | null>;
    clearGame(): Promise<void>;
    saveStatistics(stats: Statistics): Promise<void>;
    loadStatistics(): Promise<Statistics>;
    saveSettings(settings: Settings): Promise<void>;
    loadSettings(): Promise<Settings>;
}
export const store: GameStore = isTauri() ? tauriStore : webStore;
```

- **`tauriStore.ts`** (desktop + Android): Tauri commands → `tauri-backend::persistence`, backed by SQLite (`rusqlite`) for statistics (naturally relational, one row per `GameType`, atomic writes for free) and versioned JSON files for settings and the single save-slot blob.
- **`webStore.ts`** (PWA): **IndexedDB**, not `localStorage` — it's the correct browser-native analog to a local database (structured, asynchronous, effectively-unbounded-for-this-use-case quota, works with `vite-plugin-pwa`'s offline story), and keeps the web build honestly local-first without needing Tauri. Same `SaveEnvelope`/`Statistics`/`Settings` shapes serialize into it as they do into SQLite/JSON.
- Both backends implement the identical interface, so `GameCanvas.tsx` and the settings UI never know or care which platform they're running on — exactly the `isTauri()`-branch pattern from `WordSearch/src/backend.ts`, applied to persistence instead of puzzle data.

### Tauri capabilities/permissions scoping

Per Tauri v2's capability model: scope `capabilities/desktop.json` and `capabilities/mobile.json` to exactly one app-data subdirectory each (via `path::app_data_dir()`), granting only the specific `fs:allow-*`/SQL-plugin permissions needed for that one path. No broad `fs:default` or wildcard scopes. No network-related capability (no `http` plugin permission) on either — the concrete enforcement mechanism for "no silent network calls," not just a policy statement.

### Save file schema + versioning

```rust
struct SaveEnvelope {
    schema_version: u32,       // starts at 1
    game_type: GameType,
    piles: Vec<SerializedPile>,
    move_count: u32,
    elapsed_ms: u64,
    saved_at: i64,
    variant_data: VariantData, // typed enum, replaces gameSpecificData Map
}
```

`load_save(bytes) -> Result<SaveEnvelope, LoadError>` matches on `schema_version` and runs a migration chain (`v1 -> v2 -> ...`) if older than current — establish this pattern in Phase 1 even with only one version today, so it's proven before it's needed. Malformed/corrupt bytes return `LoadError`, never panic — the single most likely source of untrusted input in this app (a save file edited or truncated externally, or an IndexedDB record from a future schema version on an older app build).

`VariantData` replaces the current duck-typed bag, which today only covers Klondike and Spider despite other games (Canfield's reserve config, Vegas bankroll carry-over) plausibly needing saved extra state — audit each game during its Phase 3 port slot, not just copy the 2 existing cases.

### Migration story for existing Flutter-era users

Existing data lives in Hive boxes (binary) and `shared_preferences` (platform-specific), on platforms (`android/`, `linux/`, `macos/`, `windows/`) that may not map 1:1 to the new targets. Scope this as a **separate, optional, one-time import tool**, not core-port-blocking work: a small script/CLI reading a user's Hive box file and emitting the new format. Given the current save is single-slot and mid-game state is inherently ephemeral, the highest-value data to actually migrate is **statistics** (win/loss history, best times), not an in-progress board. Phase 4/5 work.

---

## 5. Rendering design — responsive tiers (per user direction)

Card art uses **SVG assets only for face cards** (J/Q/K) — everything else (pips, suit glyphs, number-card layout, card backs, gloss) is drawn procedurally via Canvas2D primitives, matching what the current Flutter app already does for everything except face cards (and confirming the bundled-but-unused full `svg-cards.svg` 52-card sheet should be dropped from the new asset set entirely, not revived).

**Two explicit rendering tiers, selected by rendered card size** (not by platform/user-agent — a desktop browser window narrowed to phone width should get the same compact rendering a phone gets):

- **Standard tier** (desktop, tablet, wide mobile landscape): full per-rank pip layout (port `_getPipPositions`'s offset table verbatim to `pipPositions.ts`, drawn via Canvas path/arc primitives), full face-card SVG art for J/Q/K (pre-rasterized once to an offscreen canvas per rank/suit/theme combination at startup — this *is* the "pre-render static content to offscreen canvas" performance rule applied correctly — then `drawImage`d each frame, never re-parsing SVG paths per frame).
- **Compact/mobile tier** (small rendered card size, primarily phone-portrait Android and narrow web viewports): every card — number and face alike — renders as **a single pip (suit glyph) + a rank character**, for legibility at small size. **Face cards specifically render the top half only of the pre-rasterized face-card SVG** (`drawImage` with a source rect of `sy=0, sHeight=fullHeight/2`, cropping to the bust/portrait portion of the art which is the visually distinctive part) **composited with the pip + letter (J/Q/K)** below or beside it — giving a recognizable face card without needing separate compact artwork.
- Implementation: `renderCard.ts` picks the tier from the card's on-screen pixel width against a single threshold constant (tune once against real device testing in Phase 1), so the same rendering code path serves desktop-window-resized-small and actual-phone-screen identically.

Theme system, WCAG validator, victory particle system, and flying-card/flip animation follow the Plan agent's original recommendations (unchanged by the multi-platform decision): theme presets as flat TS/JSON data + CSS custom properties; WCAG fix via real `Math.pow`; victory particles as TS-side parallel-typed-array SoA (genuinely warranted there, per §2) rather than crossing into WASM, since they never read/write game-rule state; card flip via manual Canvas horizontal-scale interpolation (not CSS transform) so it composites correctly with an in-flight flying-card tween on the same element.

### PWA offline-asset completeness

Following `vite.web.config.ts`'s precedent: `vite-plugin-pwa`'s default `globPatterns` misses non-standard asset types. Solitude's web build must explicitly precache the face-card SVGs, the 6 audio files (mp3), the Inter font files actually in use (only the 4 weights currently declared in `pubspec.yaml`, not the ~38 bundled-but-unregistered files — drop the unused ones in the port rather than precaching dead weight), and `achievements.json`, with `maximumFileSizeToCacheInBytes` raised if needed. Test true install-and-play-fully-offline as an explicit Phase 5 exit criterion, exactly as WordSearch's README claims ("works fully offline after the first visit").

---

## 6. Input/interaction design

### Unified pointer handling (mouse + touch)

Reimplement using the Pointer Events API (`onPointerDown/Move/Up`) directly on the Canvas element — this single API already unifies mouse and touch input, which matters now that Android is a real target (the current Flutter app's raw-pointer tap/double-tap disambiguator — 300ms window, 8px move threshold, built because `Draggable` swallows taps — ports as *logic*, re-hosted in React pointer handlers). On pointer-up completing a drag over a valid target pile, call `engine.execute_move(...)` directly.

**Touch-specific additions beyond the Flutter original** (new, since touch-primary devices weren't a target before): minimum tap-target sizing for piles/cards on the compact rendering tier (44×44px per standard mobile accessibility guidance, likely larger than the pip-only card art itself — pad the hit-region, not just the visible art); no hover-state-dependent UI (the current app has none that matters here, but audit `pile_widget.dart`'s drop-target highlighting, which currently activates via `DragTarget.onWillAcceptWithDetails` during an active drag — that's touch-compatible as-is, just confirm during Phase 1); Android hardware/gesture back-button mapped to "open pause/settings" or "confirm exit," not silently backing out of a game.

### Keyboard navigation

Full system ports as-is for desktop and web: Tab/Shift-Tab pile cycling, Enter/Space activate, U/Ctrl+Z undo, N/H/A/Esc. `getNextFocus`/`focusablePiles` per-game ordering moves out of the Rust trait (§2) into a small per-game-type TS data table. This subsystem is simply inactive/unreachable on Android (no hardware keyboard in the common case) — no porting work needed there beyond not crashing if a Bluetooth keyboard is connected, which Pointer/Keyboard event handling naturally tolerates.

### Discrete moves vs. `world.tick(dt)`

As resolved in §1: input handlers call WASM functions directly and synchronously on the triggering event, not through a per-frame buffer — the buffer model exists for continuous simulation sampling "what's held," which doesn't fit turn-based card moves. The one place a queue is genuinely useful: deciding whether to queue or drop rapid subsequent input while a flying-card animation is in flight for a previous move — a simple TS-side "animation is blocking new input" flag, not the mandated bitflag buffer.

---

## 7. Testing/acceptance strategy

Use the existing 40 Dart test files (170+ tests across 5 newer model-test files alone, per `TEST_COVERAGE_SUMMARY.md`) as the **behavioral specification**, re-expressed as Rust/TS tests in each language's own idiom, not transliterated line-by-line:
- Priority order: card/pile/stacking-rule tests (foundational, every game depends on them) → Klondike's `isTrulyLost` test specifically (the best existing spec for a genuinely subtle piece of logic) → per-game rule tests → solver tests → persistence-service tests.
- Layout calculator tests: port as pure-function TS unit tests (Vitest) against `gridLayout.ts`.
- **New coverage the Dart suite doesn't have, required by the hard reliability rule**: WASM-boundary fuzzing/property tests for `load_snapshot`/`load_save` against malformed/truncated/adversarial bytes, confirming `Result` returns and never a panic — run this against both persistence backends (a corrupted Tauri-FS file and a manually-tampered IndexedDB record).
- Solver: port existing test cases once the `BinaryHeap` fix lands, plus a regression test asserting solve time/node-count measurably improves post-fix.
- **New coverage for the multi-platform scope**: an explicit PWA offline-install-and-play test (Phase 5 exit criterion, §5); Android touch-interaction pass per game (drag-and-drop, tap/double-tap, compact-tier rendering legibility) — can't be verified by unit tests, needs manual device/emulator pass per the project's existing "test the golden path in a browser before reporting UI work complete" practice, extended here to "and on an Android emulator, and in a narrowed desktop browser window for the compact tier."
- Do not port Flutter widget/animation-sequencing tests — that UI no longer exists in this form; validate Canvas rendering via targeted TS unit tests on pure functions (layout math, pip positions, tier-selection threshold) plus manual visual review, not pixel-snapshot testing.

---

## 8. Risk register

| # | Risk | Why it matters | Mitigation |
|---|---|---|---|
| 1 | Per-game undo/redo duplication carries over if each game's existing logic is ported 1:1 instead of generalized. | Perpetuates a 10x maintenance surface for one conceptual mechanism. | Build the generalized snapshot-based `History` against Klondike (hardest case) in Phase 1 before any other game. |
| 2 | Solver's `openSet.sort()` runs **inside** the per-move-expansion inner loop (`solver_engine.dart:62`) — O(n log n) per edge, not per node. | Ported literally, perf regresses further as branching factor grows (Spider/Forty Thieves branch more than Klondike). | Replace with `BinaryHeap` from the start; do not port the sort-in-loop pattern even as a placeholder. |
| 3 | **Persistence backend split (Tauri FS/SQLite vs. IndexedDB) is new architecture, not a straight port** — the hard rule's "route through Tauri" assumption breaks on the web target if not resolved deliberately. | Left unresolved, a coding agent might default to `localStorage` everywhere (WordSearch's precedent) for expediency, quietly reintroducing the exact anti-pattern the architecture rules warn against for a save blob this app's size. | §4 resolves this explicitly via the `GameStore` facade; bake the `isTauri()` branch in at Phase 0, prove both backends before any game logic depends on either. |
| 4 | Card rendering's two responsive tiers (§6) could get built as platform checks (`if Android`) instead of size-based, breaking the "same code narrows correctly" property. | A desktop window resized small should get the compact tier too; a platform check wouldn't do that, and would diverge behavior between "small Chrome window" and "small Android screen" for no reason. | Select tier by rendered card pixel width, a single threshold constant, tested in both a narrowed desktop browser and a real/emulated phone. |
| 5 | Dead SVG card sheet (`svg-cards.svg`) — an asset/product decision already made here (drop it, face-card SVGs only), but easy to accidentally re-introduce mid-port if not flagged. | Wiring it "helpfully" mid-port would cause rendering-approach churn against the explicit face-cards-only decision in §6. | Don't carry the asset into the new repo at all; only port `jack.svg`/`queen.svg`/`king.svg`. |
| 6 | Two redundant Dart audio services (254 vs. 70 lines, genuinely different shapes) — naive porting could recreate the duplication if each is translated independently. | Confusing sound ownership going forward; much harder to fix once two new TS modules both exist with callers. | Design one consolidated TS audio module, driven off the game-event stream, before porting either Dart file. |
| 7 | WCAG `pow()` bug — and its existing test file may assert the *buggy* values as expected. | Porting `overlay_validator_test.dart`'s cases verbatim would faithfully reproduce the bug and "confirm" it correct with a passing test. | Manually verify each expected value against the real WCAG formula (gamma 2.4) before porting the test cases; update expected values where they encode the bug. |
| 8 | iOS is explicitly out of scope, but "all platforms" could be mis-read later as including it. | Silent scope creep or, conversely, a contributor assuming iOS was silently dropped by accident rather than decided. | Documented here and in Phase 5 exit criteria: desktop (Win/Mac/Linux) + Android + web PWA is the full scope, matching the WordSearch precedent; iOS deferred, not forgotten, pending a signing/dev-account story. |
| 9 | `PRIVACY.md` currently states specific, soon-to-be-false claims ("SharedPreferences for settings," "Hive database for game state"). | A real published commitment (GPL-3.0, GitHub-linked) — shipping without updating it is a factually incorrect privacy claim, a trust issue for a project whose whole pitch is data sovereignty. | Literal Phase 5 exit criterion: update the storage-mechanism section to describe Tauri FS/SQLite (native) + IndexedDB (web), keeping the substantive commitments (local-only, no network, no telemetry) unchanged. |
| 10 | Fragile `gameSpecificData` duck-typing today only covers 2 of 10 games; a naive "typed" port might just copy those 2 cases into `VariantData` and silently reproduce the same coverage gap for the other 8. | Looks fixed (proper enum, no more `dynamic`) while still missing save-worthy state for Canfield/others. | Audit each game's rules module for save-worthy extra state during its own Phase 3 port slot — a checklist item per game, not assumed complete after 2. |
| 11 | Touch-target sizing and Android back-button behavior have no Flutter-app precedent to port (the current app is desktop/keyboard-and-mouse-first in practice). | Easy to ship a Canvas UI that's pixel-perfect on desktop and unusable via touch on a real phone. | Explicit Phase 1 exit criterion: Klondike must be played end-to-end on an Android emulator, not just visually reviewed; treat 44px minimum tap targets and back-button mapping as requirements, not polish. |

---

### Critical files referenced during this planning pass

- `/home/chip/Projects/Solitude/lib/features/game/games/game_interface.dart` — `GameInterface` contract, `GameType` enum, `LayoutConfig`
- `/home/chip/Projects/Solitude/lib/features/game/models/card.dart`, `pile.dart`, `move.dart`, `deck.dart`
- `/home/chip/Projects/Solitude/lib/features/game/services/game_state_repository.dart` — current save format, `gameSpecificData` duck-typing
- `/home/chip/Projects/Solitude/lib/features/statistics/services/statistics_service.dart`
- `/home/chip/Projects/Solitude/lib/features/game/ai/solver_engine.dart` — solver perf bug location
- `/home/chip/Projects/Solitude/lib/features/game/layouts/layout_strategy.dart` — grid formula
- `/home/chip/Projects/Solitude/lib/core/utils/overlay_validator.dart` — WCAG `pow()` bug
- `/home/chip/Projects/Solitude/PRIVACY.md` — data-sovereignty commitments to preserve
- `~/Projects/WordSearch/src/backend.ts`, `vite.web.config.ts`, `README.md` — the "one codebase, three targets" precedent this plan follows for platform architecture and persistence branching

### Verification approach once implementation begins

- `cargo test` in `engine-core` against ported Dart test cases, per game, as each is completed.
- `tauri dev` (desktop) and `tauri android dev` (emulator/device) manual play-through per phase exit criterion.
- `npm run dev` / `vite.web.config.ts` preview build, tested in a narrowed browser window (compact tier) and via Chrome DevTools device emulation, then a real Android device install via the PWA "Add to Home Screen" flow to confirm true offline play.
- `wasm-pack test` or a small fuzz harness (e.g. `cargo fuzz` or `proptest`) against `load_save`/`load_snapshot` for the untrusted-input reliability requirement.
