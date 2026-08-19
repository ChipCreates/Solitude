# Solitude Rust/Tauri/React Migration — Mitigation Plan

**Date:** 2026-08-19  
**Based on:** Architectural Review (docs/MIGRATION_ARCHITECTURE_REVIEW.md)  
**Status:** Ready for implementation sprint planning

---

## Overview

This plan prioritizes the critical architectural and feature-parity issues identified in the migration review, organized by severity and implementation effort. Each item includes:
- **Priority:** Critical / High / Medium / Low
- **Effort:** T-shirt size (XS / S / M / L / XL)
- **Impact:** What users will see/experience
- **Implementation steps:** Concrete file changes and test approach

---

## 🔴 CRITICAL ISSUES (Fix Before Production Release)

### 1. Fix Autoplay Re-Entrancy Bug (Causes Animation Jank)

**Files affected:**
- `src/App.tsx` (lines 611–629, 548–563, 694)
- `src/input/keyboardNav.ts` (line 27–29)

**Problem:**
- Multiple clicks on "Auto Play" button or repeated `A` hotkey spawn duplicate concurrent `setTimeout` chains
- Each chain independently calls `autoPlayStepWasm()` every 120ms
- Cards receive conflicting CSS transform targets mid-animation, causing jank
- Starting a new game mid-autoplay doesn't cancel the old timer, causing unauthorized moves in the new game

**Solution:**
1. Store the timeout ID in a ref instead of relying on closure state
2. Add a cancellation flag that `nextStep` checks before rescheduling
3. Guard the button/hotkey to prevent re-entry while already playing
4. Clear the timer on component unmount and game-state reset

**Implementation steps:**

```typescript
// In App.tsx, replace handleAutoPlay with:
const autoPlayTimeoutRef = useRef<NodeJS.Timeout | null>(null);
const shouldCancelAutoPlayRef = useRef(false);

const handleAutoPlay = useCallback(() => {
  if (isAutoPlaying) return; // Guard against re-entry
  
  shouldCancelAutoPlayRef.current = false;
  
  const nextStep = () => {
    if (shouldCancelAutoPlayRef.current) {
      setIsAutoPlaying(false);
      return;
    }
    
    if (checkWinWasm()) {
      setIsAutoPlaying(false);
      return;
    }
    
    const success = autoPlayStepWasm();
    if (success) {
      setMoveCount((m) => m + 1);
      audioService.playCardMove();
      updateLayout();
      autoPlayTimeoutRef.current = setTimeout(nextStep, 120);
    } else {
      setIsAutoPlaying(false);
      if (!checkWinWasm()) {
        setToastMessage("No moves available.");
      }
    }
  };
  
  setIsAutoPlaying(true);
  nextStep();
}, [isAutoPlaying, updateLayout]);

// Add cleanup on unmount
useEffect(() => {
  return () => {
    if (autoPlayTimeoutRef.current) {
      clearTimeout(autoPlayTimeoutRef.current);
    }
    shouldCancelAutoPlayRef.current = true;
  };
}, []);

// Update startNewGame to cancel autoplay:
const startNewGame = useCallback((typeCode?: number | null) => {
  shouldCancelAutoPlayRef.current = true;
  if (autoPlayTimeoutRef.current) {
    clearTimeout(autoPlayTimeoutRef.current);
    autoPlayTimeoutRef.current = null;
  }
  // ... rest of startNewGame
  setIsAutoPlaying(false);
}, [updateLayout]);

// Guard the button: disabled={isAutoPlaying}
// Or remove the guard if the useCallback re-entry check above is sufficient
```

**Testing:**
- Click "Auto Play", click "Auto Play" again immediately → should not double-speed
- Click "Auto Play", click "New Game" → new game should start cleanly, no orphaned moves
- Autoplay should complete and stop cleanly when game is won
- Timer should clear on component unmount (React dev tools)

**Effort:** S (Small) — ~30 lines of code  
**Impact:** Eliminates jank symptom during autoplay; prevents silent unauthorized moves

---

### 2. Implement Cache Invalidation on New Game

**Files affected:**
- `crates/engine-wasm/src/lib.rs` (lines 26–48)
- `crates/engine-core/src/solver/mod.rs` (lines 49–52, 126–127)

**Problem:**
- `initialize_game()` doesn't clear `CACHED_PATH` or `EXPECTED_STATE_HASH`
- Stale cache from game N can theoretically cause game N+1 to return wrong moves
- Latent correctness bug, low probability but high severity if triggered

**Solution:**
Add explicit cache clearing to `initialize_game()`.

**Implementation steps:**

**Rust side** (`crates/engine-core/src/solver/mod.rs`):
```rust
// Add a public function to clear the cache
pub fn clear_solver_cache() {
    CACHED_PATH.with(|p| p.borrow_mut().clear());
    EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = 0);
}
```

**WASM side** (`crates/engine-wasm/src/lib.rs`):
```rust
#[wasm_bindgen]
pub fn initialize_game(game_type_code: u32, seed: u64) -> Result<(), JsValue> {
    // ... existing code ...
    
    // Clear solver cache before starting new game
    crate::solver::clear_solver_cache();
    
    // ... rest of function ...
}
```

**TS wrapper** (`src/wasm/engine.ts`):
- No change needed; the WASM call happens atomically

**Testing:**
- Play game 1, get multiple hint moves, check cache is populated
- Start game 2 → cache should be empty (verify with instrumentation/debug logging)
- Hint in game 2 should work independently

**Effort:** XS (Extra Small) — ~10 lines  
**Impact:** Closes a correctness landmine; minimal but important

---

### 3. Fix Cycle-Detection Bug in Solver

**Files affected:**
- `crates/engine-core/src/pile.rs` (lines 43–49)
- `crates/engine-core/src/solver/mod.rs` (lines 43–47, 158–165)

**Problem:**
- `Pile` derives `Hash` including a `version: u64` counter that increments on every mutation
- `StateSignature` embeds full `Vec<Pile>`, so version is part of state hash
- Two content-identical boards with different mutation counts hash as different states
- Cycle detection never dedupes transpositions; wasted iterations inflate BFS cost
- Contributes significantly to jank on cache misses

**Solution:**
Implement manual `Hash`/`Eq` for `StateSignature` that excludes the version field.

**Implementation steps:**

**Option A (Recommended): Manual Hash impl**

`crates/engine-core/src/solver/mod.rs`:
```rust
use std::hash::{Hash, Hasher};

#[derive(Debug, Clone, PartialEq, Eq)]
struct StateSignature {
    piles: Vec<Pile>,
    stock_recycle_count: u32,
}

impl Hash for StateSignature {
    fn hash<H: Hasher>(&self, state: &mut H) {
        // Hash only pile contents, not version
        for pile in &self.piles {
            pile.kind.hash(state);
            pile.index.hash(state);
            // Hash cards in the pile, not the version counter
            for card in pile.cards() {
                card.rank.hash(state);
                card.suit.hash(state);
                card.is_face_up.hash(state);
            }
        }
        self.stock_recycle_count.hash(state);
    }
}

impl PartialEq for StateSignature {
    fn eq(&self, other: &Self) -> bool {
        self.stock_recycle_count == other.stock_recycle_count &&
        self.piles.len() == other.piles.len() &&
        self.piles.iter().zip(other.piles.iter()).all(|(a, b)| {
            a.kind == b.kind &&
            a.index == b.index &&
            a.cards() == b.cards()
        })
    }
}

impl Eq for StateSignature {}
```

**Option B (Simpler): Use a stripped-down struct**

Create a separate `StateContent` struct without version:
```rust
#[derive(Hash, PartialEq, Eq, Clone)]
struct StateContent {
    // Same fields as StateSignature, but without version
    cards_by_pile: Vec<Vec<(Rank, Suit)>>, // Cheaper representation
    stock_recycle_count: u32,
}
```

**Recommendation:** Option A is cleaner; Option B would require duplicating/converting data.

**Testing:**
- Unit test: Create two identical boards via different move sequences, verify they hash the same
- Integration test: Run BFS on a complex position, verify iteration count is lower (fewer redundant states)
- Regression test: Existing solver tests should still pass

**Effort:** M (Medium) — ~40 lines of code + testing  
**Impact:** Reduces wasted BFS iterations; measurably improves performance on complex positions

---

### 4. Wire Variant-Specific Settings to WASM Engine

**Files affected:**
- `crates/engine-core/src/factory.rs` (lines 16–29)
- `crates/engine-wasm/src/lib.rs` (lines 26–48)
- `src/App.tsx` (line 552)
- `src/store/uiStore.ts` (variant-settings state)
- `src/persistence/store.ts` (variant-settings types)

**Problem:**
- React UI allows users to set Klondike Draw Mode, Spider suit count, Golf wrap-around, etc.
- These settings are stored in Zustand and persisted
- But `initialize_game()` doesn't accept any parameters for them
- `GameFactory::create_game()` hardcodes all variant options
- Changing settings has zero gameplay effect

**Solution:**
Extend the WASM API to accept variant options as a JSON object.

**Implementation steps:**

**Rust side** (`crates/engine-core/src/factory.rs`):
```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct VariantOptions {
    pub klondike_draw_mode: Option<u32>,  // 1 or 3
    pub klondike_scoring_mode: Option<String>,  // "Standard" or "Vegas"
    pub spider_suit_count: Option<u32>,  // 1, 2, or 4
    pub golf_wrap_around: Option<bool>,
}

impl Default for VariantOptions {
    fn default() -> Self {
        Self {
            klondike_draw_mode: Some(1),
            klondike_scoring_mode: Some("Standard".to_string()),
            spider_suit_count: Some(4),
            golf_wrap_around: Some(false),
        }
    }
}

pub fn create_game_with_options(game_type: GameType, options: &VariantOptions) -> Box<dyn GameRules> {
    match game_type {
        GameType::Klondike => {
            let draw_mode = match options.klondike_draw_mode.unwrap_or(1) {
                3 => DrawMode::Three,
                _ => DrawMode::One,
            };
            let scoring = match options.klondike_scoring_mode.as_deref().unwrap_or("Standard") {
                "Vegas" => Some("Vegas".to_string()),
                _ => None,
            };
            Box::new(KlondikeGame::new(draw_mode, scoring))
        },
        GameType::Spider => {
            let suit_count = options.spider_suit_count.unwrap_or(4);
            Box::new(SpiderGame::new(suit_count))
        },
        GameType::Golf => {
            let wrap = options.golf_wrap_around.unwrap_or(false);
            Box::new(GolfGame::new(wrap))
        },
        // ... other variants ...
    }
}
```

**WASM side** (`crates/engine-wasm/src/lib.rs`):
```rust
#[wasm_bindgen]
pub fn initialize_game(game_type_code: u32, seed: u64, options_json: &str) -> Result<(), JsValue> {
    let game_type = GameType::from_code(game_type_code)
        .ok_or_else(|| JsValue::from_str("Invalid game type"))?;
    
    let options: VariantOptions = serde_json::from_str(options_json)
        .unwrap_or_default();
    
    let mut game = factory::create_game_with_options(game_type, &options);
    game.initialize(seed);
    
    CURRENT_GAME.with(|g| *g.borrow_mut() = Some(game));
    clear_solver_cache();
    
    Ok(())
}
```

**React side** (`src/App.tsx`):
```typescript
// In startNewGame or initializeGame:
const startNewGame = useCallback((typeCode?: number | null) => {
  const type = typeCode !== undefined ? typeCode : gameTypeRef.current;
  if (type === null) return;
  
  // Get variant options from store
  const options = {
    klondike_draw_mode: uiStore.getState().klondikeDrawMode,
    klondike_scoring_mode: uiStore.getState().klondikeScoringMode,
    spider_suit_count: uiStore.getState().spiderSuitCount,
    golf_wrap_around: uiStore.getState().golfWrapAround,
  };
  
  initializeGame(type, BigInt(Date.now()), JSON.stringify(options));
  // ... rest of function
}, []);
```

**Testing:**
- Klondike: Set Draw 3, start game, verify stock pile cycles every 3 cards
- Klondike: Set Vegas scoring, verify score calculations are different
- Spider: Set 1-suit (Easy), verify only spades are dealt
- Spider: Set 2-suit (Medium), verify spades + hearts
- Golf: Toggle wrap-around, verify end-of-row logic changes

**Effort:** M (Medium) — ~60 lines across Rust + TS + React  
**Impact:** Settings UI actually works; users can customize gameplay as intended

---

## 🟠 HIGH PRIORITY (Fix Before Next Release)

### 5. Implement Tauri Backend Persistence

**Files affected:**
- `crates/tauri-backend/src/lib.rs` (lines 38–91)
- `crates/Cargo.toml` (add database/fs dependencies)

**Problem:**
- All 7 backend commands are no-op stubs
- App silently falls back to browser IndexedDB everywhere
- Native desktop build has no persistence advantage
- Defeats the purpose of shipping a Tauri app

**Solution:**
Implement real filesystem or SQLite persistence.

**Implementation options:**

**Option A: Filesystem (Simpler, less featured)**
- Use `std::fs` + `serde_json` to write/read JSON files to app data directory
- Store in `~/.local/share/solitude/` (Linux), `~/Library/Application Support/Solitude/` (macOS), `%APPDATA%/Solitude/` (Windows)
- File per entity: `save-game.json`, `settings.json`, `statistics/{game_type}.json`

**Option B: SQLite (More robust)**
- Add `rusqlite` or `sqlx` crate
- Create schema with tables: `SaveGames`, `Settings`, `Statistics`
- Handle migrations, schema versioning

**Recommendation:** Start with Option A (simpler, no new deps), migrate to B if needed.

**Implementation steps (Option A):**

`crates/tauri-backend/src/lib.rs`:
```rust
use std::path::{Path, PathBuf};
use std::fs;

fn get_app_data_dir() -> PathBuf {
    let base = if cfg!(target_os = "windows") {
        std::env::var("APPDATA").unwrap_or_else(|_| ".".to_string())
    } else if cfg!(target_os = "macos") {
        format!("{}{}Library/Application Support", std::env::var("HOME").unwrap_or_else(|_| ".".to_string()), std::path::MAIN_SEPARATOR)
    } else {
        format!("{}{}local/share", std::env::var("HOME").unwrap_or_else(|_| ".".to_string()), std::path::MAIN_SEPARATOR)
    };
    
    let app_dir = PathBuf::from(base).join("Solitude");
    let _ = fs::create_dir_all(&app_dir);
    app_dir
}

#[tauri::command]
pub fn save_game(state: SaveEnvelope) -> Result<(), String> {
    let dir = get_app_data_dir();
    let path = dir.join("save-game.json");
    let json = serde_json::to_string_pretty(&state)
        .map_err(|e| format!("Serialization error: {}", e))?;
    fs::write(path, json)
        .map_err(|e| format!("Write error: {}", e))
}

#[tauri::command]
pub fn load_game() -> Result<Option<SaveEnvelope>, String> {
    let dir = get_app_data_dir();
    let path = dir.join("save-game.json");
    
    if !path.exists() {
        return Ok(None);
    }
    
    let json = fs::read_to_string(path)
        .map_err(|e| format!("Read error: {}", e))?;
    let save = serde_json::from_str(&json)
        .map_err(|e| format!("Deserialization error: {}", e))?;
    Ok(Some(save))
}

// Similar for statistics, settings, etc.
```

**Testing:**
- Save a game state, restart app, verify it loads
- Statistics persist across sessions
- Settings survive app restart
- Verify JSON files are created in correct OS-specific paths

**Effort:** L (Large) — ~150 lines of Rust + testing  
**Impact:** Native builds now have real persistence; justifies desktop app

---

### 6. Wire Statistics Tracking

**Files affected:**
- `src/App.tsx` (game-end logic, lines 613–625, victory detection)
- `src/components/VictoryModal.tsx` (on win)
- `src/store/profileStore.ts` or new `statisticsStore.ts`
- `src/persistence/store.ts` (already has interface)

**Problem:**
- Statistics interface fully defined and persisted
- But `saveStatistics()` is never called from game logic
- Nothing increments `gamesPlayed`, `gamesWon`, `currentStreak`
- Trophy Room shows 0% completion

**Solution:**
Add calls to `saveStatistics()` on game win/loss/undo.

**Implementation steps:**

**Create statistics store** (`src/store/statisticsStore.ts`):
```typescript
import { create } from 'zustand';
import { store } from '../persistence/store';

interface GameStats {
  gamesPlayed: number;
  gamesWon: number;
  gamesLost: number;
  currentStreak: number;
  bestStreak: number;
  bestTimeMs?: number;
  fewestMoves?: number;
}

interface StatisticsStore {
  stats: Map<string, GameStats>; // Map<gameType, stats>
  addWin: (gameType: string, timeMs: number, moveCount: number) => Promise<void>;
  addLoss: (gameType: string) => Promise<void>;
  getStats: (gameType: string) => GameStats;
}

export const useStatisticsStore = create<StatisticsStore>((set, get) => ({
  stats: new Map(),
  
  addWin: async (gameType: string, timeMs: number, moveCount: number) => {
    const current = get().stats.get(gameType) || {
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
    };
    
    const updated = {
      ...current,
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + 1,
      currentStreak: current.currentStreak + 1,
      bestStreak: Math.max(current.currentStreak + 1, current.bestStreak),
      bestTimeMs: current.bestTimeMs === undefined ? timeMs : Math.min(current.bestTimeMs, timeMs),
      fewestMoves: current.fewestMoves === undefined ? moveCount : Math.min(current.fewestMoves, moveCount),
    };
    
    get().stats.set(gameType, updated);
    await store.saveStatistics(gameType, updated);
  },
  
  addLoss: async (gameType: string) => {
    const current = get().stats.get(gameType) || {
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
    };
    
    const updated = {
      ...current,
      gamesPlayed: current.gamesPlayed + 1,
      gamesLost: current.gamesLost + 1,
      currentStreak: 0, // Streak broken
    };
    
    get().stats.set(gameType, updated);
    await store.saveStatistics(gameType, updated);
  },
  
  getStats: (gameType: string) => {
    return get().stats.get(gameType) || {
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
    };
  },
}));
```

**Wire to game logic** (`src/App.tsx`):
```typescript
// In victory handler (when checkWinWasm() returns true):
if (checkWinWasm()) {
  const elapsedMs = timerSeconds * 1000;
  const moveCount = moveCountRef.current;
  const gameTypeName = GAME_TYPES[gameTypeRef.current]?.name || "Unknown";
  
  await useStatisticsStore.getState().addWin(gameTypeName, elapsedMs, moveCount);
  // ... show victory modal, etc.
}

// On "Give Up" or when autoplay fails with no moves:
if (noMovesAvailable) {
  const gameTypeName = GAME_TYPES[gameTypeRef.current]?.name || "Unknown";
  await useStatisticsStore.getState().addLoss(gameTypeName);
  setToastMessage("Game over.");
}
```

**Create Statistics display screen** (`src/components/StatisticsScreen.tsx`):
```typescript
// Table showing: wins, losses, streak, best time, fewest moves per variant
// Integrates into MetaGameHub or a dedicated tab
```

**Testing:**
- Play and win a game → statistics should increment
- Play and lose → gamesLost and streak should reset
- Verify persisted stats survive app restart
- Statistics screen displays correct values

**Effort:** M (Medium) — ~100 lines across new store + UI + integration  
**Impact:** Users can track their performance; adds engagement/replayability

---

### 7. Fix Overlay Legibility Validator

**Files affected:**
- `src/theme/overlayValidator.ts` (exists, unused)
- `src/components/SettingsModal.tsx` (lines 150–158)
- `src/theme/presets.ts` (overlay application)

**Problem:**
- `OverlayValidator.isLegible()` is fully implemented but never called
- User can set overlay intensity that makes card suits indistinguishable
- No UI feedback/validation

**Solution:**
Call the validator when overlay intensity changes and either warn or auto-adjust.

**Implementation steps:**

`src/components/SettingsModal.tsx`:
```typescript
import { OverlayValidator } from '../theme/overlayValidator';

// In the intensity slider handler:
const handleIntensityChange = (intensity: number) => {
  const theme = THEME_PRESETS[selectedTheme];
  if (theme && theme.overlayColor) {
    const isLegible = OverlayValidator.isLegible(
      theme.overlayColor,
      intensity,
      theme.tableBackgroundColor
    );
    
    if (!isLegible) {
      setIntensityWarning(true);
      // Auto-clamp to max safe intensity:
      const maxSafeIntensity = OverlayValidator.findMaxIntensity(
        theme.overlayColor,
        theme.tableBackgroundColor
      );
      setOverlayIntensity(maxSafeIntensity);
    } else {
      setIntensityWarning(false);
      setOverlayIntensity(intensity);
    }
  }
};

// In JSX:
<input 
  type="range" 
  value={overlayIntensity}
  onChange={(e) => handleIntensityChange(parseFloat(e.target.value))}
/>
{intensityWarning && (
  <p style={{ color: 'orange' }}>⚠️ Overlay intensity clamped to maintain legibility</p>
)}
```

**Testing:**
- Change overlay intensity for each theme
- Try to set an illegible intensity → should either warn or auto-clamp
- Verify card suits remain readable at all allowed intensities

**Effort:** S (Small) — ~30 lines  
**Impact:** Prevents user-facing legibility problems; adds polish

---

### 8. Implement Background Music Playback (or Remove Dead UI)

**Files affected:**
- `src/audio/audioService.ts`
- `src/components/SettingsModal.tsx` (lines 426–452)
- `src/store/uiStore.ts`
- `assets/` (audio files, if adding music)

**Problem:**
- Music Enabled toggle and Volume slider exist in Settings
- No backing audio implementation or asset files
- Dead UI control that does nothing

**Solution Option A: Remove the dead control (quickest)**

Delete from SettingsModal.tsx (lines 426–452) and uiStore.ts.

**Solution Option B: Implement Web Audio music playback**

Add simple looping synthesizer music or load an audio file.

**Recommendation:** Option A (remove dead control) is faster to ship. Option B (actual music) is better UX but requires audio assets.

**Implementation (Option A):**
- Remove lines 426–452 from SettingsModal.tsx
- Remove `musicEnabled`, `musicVolume` from uiStore.ts
- Remove from persistence store.ts
- Done

**Implementation (Option B):**
```typescript
// src/audio/audioService.ts
class AudioService {
  private audioContext: AudioContext | null = null;
  private musicOscillator: OscillatorNode | null = null;
  private musicGain: GainNode | null = null;
  
  playBackgroundMusic() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    }
    
    const ctx = this.audioContext;
    
    // Create a simple harmonic background (e.g., C-E-G chord played continuously)
    this.musicOscillator = ctx.createOscillator();
    this.musicGain = ctx.createGain();
    
    this.musicOscillator.type = 'sine';
    this.musicOscillator.frequency.value = 261.63; // Middle C
    
    this.musicGain.gain.value = 0.1; // Quiet background
    this.musicOscillator.connect(this.musicGain);
    this.musicGain.connect(ctx.destination);
    
    this.musicOscillator.start();
  }
  
  stopBackgroundMusic() {
    if (this.musicOscillator) {
      this.musicOscillator.stop();
      this.musicOscillator = null;
    }
  }
  
  setMusicVolume(volume: number) {
    if (this.musicGain) {
      this.musicGain.gain.value = Math.max(0, Math.min(1, volume / 100));
    }
  }
}
```

**Effort:**
- Option A: XS (delete ~30 lines)
- Option B: M (add ~80 lines + optional audio assets)

**Impact:**
- Option A: Cleaner codebase, removes confusing dead UI
- Option B: Adds atmospheric music, uses the UI controls

**Recommendation for this sprint:** Do Option A (remove), add music playback as a future feature with proper audio asset.

---

## 🟡 MEDIUM PRIORITY (Should Complete This Release)

### 9. Remove Dead Code

**Files to delete:**
- `src/canvas/GameCanvas.tsx` (111 lines, unused)
- `src/input/pointerController.ts` (full class, never used)

**Files to clean:**
- `src/App.tsx` lines 306–393 (invisible canvas RAF loop)
- `src/App.tsx` lines 639–641 (dead useEffect)

**Effort:** XS (Extra Small) — ~200 lines deleted  
**Impact:** Cleaner codebase, ~5% CPU savings (canvas loop gone)

---

### 10. Memoize CardWidget to Reduce Re-renders

**Files affected:**
- `src/components/CardWidget.tsx` (wrap in React.memo)
- `src/App.tsx` (card rendering loop, lines 735–770)

**Implementation:**

`src/components/CardWidget.tsx`:
```typescript
export default React.memo(CardWidget, (prev, next) => {
  // Custom comparison: only re-render if visual properties changed
  return (
    prev.x === next.x &&
    prev.y === next.y &&
    prev.width === next.width &&
    prev.height === next.height &&
    prev.rank === next.rank &&
    prev.suit === next.suit &&
    prev.isSelected === next.isSelected &&
    prev.isHint === next.isHint &&
    prev.isDragging === next.isDragging &&
    prev.isAutoPlaying === next.isAutoPlaying
  );
});
```

**Testing:**
- Autoplay should feel smoother (fewer render cycles)
- Cards should animate the same visually (correctness unchanged)

**Effort:** S (Small) — ~15 lines  
**Impact:** ~15–20% reduction in render overhead during autoplay

---

### 11. Isolate Hint/Autoplay Solver Caches

**Files affected:**
- `crates/engine-core/src/solver/mod.rs` (lines 49–52, 74–119)
- `crates/engine-wasm/src/lib.rs` (lines 209–233)

**Problem:**
- `CACHED_PATH` and `EXPECTED_STATE_HASH` are shared thread-local
- Interleaving `getHintWasm()` and `autoPlayStepWasm()` causes cache desync
- Currently not exercised in UI (hint is one-shot, autoplay continuous), but could happen

**Solution:**
Create separate cache namespaces for Hint vs. Autoplay, or add a context parameter.

**Implementation:**

`crates/engine-core/src/solver/mod.rs`:
```rust
#[derive(Clone, Copy)]
pub enum SolverContext {
    Hint,
    AutoPlay,
}

thread_local! {
    static HINT_CACHE: RefCell<Vec<HintMove>> = RefCell::new(Vec::new());
    static HINT_HASH: RefCell<u64> = RefCell::new(0);
    static AUTOPLAY_CACHE: RefCell<Vec<HintMove>> = RefCell::new(Vec::new());
    static AUTOPLAY_HASH: RefCell<u64> = RefCell::new(0);
}

pub fn find_best_move(game: &mut dyn GameRules, context: SolverContext) -> Option<HintMove> {
    let (cache_path, cache_hash) = match context {
        SolverContext::Hint => (&HINT_CACHE, &HINT_HASH),
        SolverContext::AutoPlay => (&AUTOPLAY_CACHE, &AUTOPLAY_HASH),
    };
    
    // ... rest of function using cache_path, cache_hash
}
```

**Effort:** M (Medium) — ~40 lines  
**Impact:** Prevents cross-feature cache contamination

---

## 🔵 LOW PRIORITY (Nice to Have)

### 12. Implement Achievements Unlock System

Wire `unlockAchievement()` calls when achievement conditions are met.

**Effort:** M — ~100 lines  
**Impact:** Trophy Room becomes functional

---

### 13. Implement Basic Power-up System

Start with a few power-ups (Undo Token, Extra Hint, Reset Column).

**Effort:** L — ~150 lines per feature  
**Impact:** Store has real gameplay effect

---

### 14. Implement Save/Resume Game

Wire `saveGame()` / `loadGame()` calls; add "Resume Game" button.

**Effort:** M — ~80 lines  
**Impact:** Users can resume mid-game

---

### 15. Add About Screen Button & Implement Missing Keyboard Shortcuts

**Effort:** S — ~20 lines  
**Impact:** UI completeness

---

## Implementation Roadmap

### Sprint 1 (Week 1) — Critical Fixes
1. Fix autoplay re-entrancy bug
2. Implement cache invalidation
3. Fix cycle detection bug
4. Wire variant-specific settings
5. Wire statistics tracking

**Estimated effort:** 3–4 days for experienced dev

### Sprint 2 (Week 2) — High Priority
6. Implement Tauri persistence (Option A: filesystem)
7. Fix overlay legibility validator
8. Remove dead audio UI (Option A) OR implement music (Option B)
9. Remove dead code (GameCanvas, PointerController, invisible canvas)
10. Memoize CardWidget

**Estimated effort:** 2–3 days

### Sprint 3 (Week 3) — Medium Priority
11. Isolate solver caches
12. Implement achievements
13. Polish/testing

**Estimated effort:** 2–3 days

### Future (Post-Release)
- Power-up system
- Save/Resume game
- Advanced music/audio
- Full test suite

---

## Testing Checklist

- [ ] Autoplay no longer double-speeds on rapid clicks
- [ ] New game cleanly stops old autoplay timers
- [ ] All 10 variants selectable and playable
- [ ] Draw Mode, Vegas Scoring, Spider suit count, Golf wrap actually affect gameplay
- [ ] Tauri app saves/loads settings, statistics, game state on desktop
- [ ] Statistics persist across sessions
- [ ] Overlay intensity clamped to maintain legibility
- [ ] Music disabled or removed from UI
- [ ] No dead GameCanvas or PointerController code
- [ ] Autoplay visibly smoother (reduced re-renders)
- [ ] Solver cache cleared on new game
- [ ] Cycle detection prevents redundant state exploration
- [ ] All 10 game variants have >2 unit tests each

---

## Success Criteria

**Post-implementation, the app should:**
1. ✅ Autoplay runs smoothly without jank
2. ✅ All variant-specific settings actually work
3. ✅ Native builds have persistence (Tauri layer functional)
4. ✅ Statistics tracked and displayed
5. ✅ No dead UI controls
6. ✅ Codebase cleaner (dead code removed)
7. ✅ Performance measurably improved (fewer clones, re-renders)

---

## References

- Full architectural review: `docs/MIGRATION_ARCHITECTURE_REVIEW.md`
- Solver implementation: `crates/engine-core/src/solver/mod.rs`
- React frontend: `src/App.tsx`, `src/components/`
- Tauri backend: `crates/tauri-backend/src/lib.rs`
