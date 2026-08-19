# Solitude

A cross-platform solitaire game supporting 10 solitaire variants, built with a Rust engine (compiled to WASM) and a React + TypeScript frontend, packaged as a Tauri desktop/mobile app and a standalone PWA.

The original Flutter implementation has been fully retired; this is the sole active codebase.

## Architecture

**Rust workspace** (`crates/`):
- `crates/engine-core` — game rules, moves, undo/redo history, and the solver, independent of any UI. `src/games/` has one file per variant (klondike.rs, spider.rs, pyramid.rs, freecell.rs, golf.rs, tripeaks.rs, yukon.rs, forty_thieves.rs, canfield.rs, scorpion.rs), each implementing the shared `GameRules` trait (`src/game.rs`). `src/solver/mod.rs` is the best-first-search hint/autoplay solver, with a fallback MCTS solver in `src/solver/mcts.rs`.
- `crates/engine-wasm` — thin `wasm-bindgen` bridge exposing the engine to JS (`src/lib.rs`): move execution, hint/autoplay, save/resume snapshots, and the power-up primitives (reshuffle stock/waste, reset a tableau column, shelve/unshelve a card).
- `crates/tauri-backend` — desktop/mobile shell. `src/db.rs` is SQLite persistence (profiles, save slot, statistics, settings, progression) via `rusqlite` with the `bundled` feature; `src/lib.rs` registers the Tauri commands.

**Frontend** (`src/`), Vite + React 19 + TypeScript + Zustand:
- `src/App.tsx` — the whole game screen: canvas/DOM hybrid rendering, pointer + keyboard input, autoplay loop, win/loss detection.
- `src/wasm/engine.ts` — typed wrapper around the wasm-bindgen exports.
- `src/store/` — Zustand stores (`uiStore.ts` for settings/progression/coins/power-ups, `statisticsStore.ts`, `profileStore.ts`).
- `src/persistence/` — `store.ts` picks `tauriStore.ts` (invokes Tauri commands, falls back to IndexedDB on error) or `webStore.ts` (pure IndexedDB) via `isTauri()`.
- `src/components/` — UI: `MetaGameHub.tsx` (top-level shell: header, sidebar, Emporium store, Trophy Room), `GameChooserGrid.tsx`, `CardWidget.tsx`, modals.
- `src/achievements/`, `src/powerups/` — achievement-unlock and power-up-effect logic, evaluated from `App.tsx`'s win-detection and power-up-activation paths.
- `src/canvas/` — layout strategies per variant (grid/pyramid) and the victory particle system.
- `src/theme/` — theme presets and WCAG-based card-face-overlay legibility validation.

**Two frontend builds** (both consume the same `src/`):
- `vite.config.ts` — Tauri desktop/mobile build (`npm run build`).
- `vite.web.config.ts` — PWA/GitHub Pages build with `vite-plugin-pwa` (`npm run build:web`, outputs `dist-web/`), IndexedDB-only persistence (no Tauri).

## Supported Variants
Klondike, Spider, Pyramid, Golf, FreeCell, TriPeaks, Yukon, Forty Thieves, Canfield, Scorpion.

## Game-Specific Settings
- **Draw Mode (1/3)** — Klondike, Canfield only
- **Scoring Mode (Standard/Vegas/Vegas Cumulative)** — Klondike only
- **Suit Count (1/2/4)** — Spider (maps to Easy/Medium/Hard difficulty)
- **Wrap-around** — Golf only

## Common Commands
- `npm run dev` — Vite dev server (port 1420) for the Tauri/web frontend, iterate against this rather than a full native build.
- `npm run build:wasm` — rebuild the WASM engine after any Rust change under `crates/`.
- `npm run tauri dev` / `npm run tauri build` — native desktop app (rebuilds wasm + frontend automatically per `tauri.conf.json`).
- `npm run build:web` — PWA build (`dist-web/`).
- `cargo test --workspace` — Rust test suite.
- `cargo llvm-cov --workspace --html` — Rust coverage report (`target/llvm-cov/html/index.html`).
- `npx tsc --noEmit` — TypeScript type-check.
- `npm test` — frontend test suite (Vitest). `npm run test:coverage` for a coverage report.

## Known Issue
`npm run build:web` can fail if any `public/assets/cards/*.svg` exceeds the PWA workbox precache's 2MB-per-file limit — check asset sizes before assuming a build regression.
