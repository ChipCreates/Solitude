# Copilot instructions for Solitude (brief)

This file gives targeted, actionable guidance to AI coding agents working on Solitude — a Rust (engine, compiled to WASM) + React/TypeScript solitaire game, packaged as a Tauri desktop/mobile app and a standalone PWA. See `CLAUDE.md` at the repo root for the full architecture rundown.

High-level architecture
- Rust workspace under `crates/`: `engine-core` (game rules + solver, no UI dependency), `engine-wasm` (wasm-bindgen bridge), `tauri-backend` (SQLite persistence + Tauri commands).
- Frontend under `src/`: `App.tsx` is the whole game screen; `store/` holds Zustand stores; `persistence/` picks Tauri-backed or IndexedDB-backed storage at runtime; `components/` is the UI.
- Two Vite configs consume the same `src/`: `vite.config.ts` (Tauri) and `vite.web.config.ts` (PWA/GitHub Pages).

Key conventions and patterns (project-specific)
- Game rules, move validation, and undo/redo live in `crates/engine-core/src/games/*.rs`, one file per variant, each implementing the shared `GameRules` trait — keep UI code free of game rules.
- The solver (`crates/engine-core/src/solver/mod.rs`) is used by both the Hint button and AutoPlay, via separate cache namespaces per `SolverContext` (Hint vs AutoPlay) so interleaving the two can't desync either one's cached plan.
- Persistence: `src/persistence/store.ts` exports a `GameStore` interface implemented by `tauriStore.ts` and `webStore.ts`; add new persisted fields to both, plus the shared `SaveEnvelope`/`Settings`/`Progression` types.
- After any change under `crates/`, rebuild the WASM package with `npm run build:wasm` before testing the frontend.

Build, run, and debug commands
- Frontend dev server (iterate here, not full native builds): `npm run dev`
- Rebuild WASM after Rust changes: `npm run build:wasm`
- Native desktop app: `npm run tauri dev` / `npm run tauri build`
- PWA build: `npm run build:web`
- Rust tests: `cargo test --workspace`
- TypeScript check: `npx tsc --noEmit`

Change guidance for AI agents
- Small, focused PRs: change one file or one small feature at a time. Keep public APIs (WASM exports, Zustand store shapes) stable.
- Tests: Rust tests live alongside their modules (`#[cfg(test)] mod tests`); there is no frontend test runner configured, verify UI changes by running the dev server and testing manually (or via Playwright if available).

What NOT to do (quick list)
- Do not add remote telemetry or network calls — the project is offline-first and privacy-respecting.
- Do not assume an asset exists in both the Tauri and PWA builds — check `public/assets/` and both Vite configs.
- Avoid touching `crates/engine-wasm`'s exported function signatures without updating `src/wasm/engine.ts`'s wrappers in the same change.

If anything is unclear, ask the maintainer which platform targets to prioritize or where to place new tests.

— End of instructions —
