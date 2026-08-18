# Project "Bugatti Chiron": Solitude Engine V2 Architecture Plan

## Executive Summary
The current Rust WASM solver is a highly capable "script" utilizing Best-First Search (BFS) bounded by a strict 25,000-iteration limit to maintain 60 FPS in the main browser thread. While blazing fast, its greedy heuristic approach makes it susceptible to local maxima traps, particularly in complex variants like Spider or Scorpion where necessary sacrifices (like tapping the stock and burying sequences) result in temporary score drops.

To elevate this engine into an algorithmic "hypercar" capable of a >90% win rate across all variants, we must migrate the architecture from a greedy, single-thread heuristic search to an asynchronous, deep-learning-capable tree search.

---

## Phase 1: Asynchronous Engine & Unbound Iterations (The Powertrain)

The fundamental barrier to deep AI search is the UI thread limit. We cannot search a million futures if we have to render a frame in 16 milliseconds.

### 1.1 Web Worker Migration
*   **Implementation:** Spin up a dedicated `solitaire_worker.ts` that instantiates its own copy of the WASM engine.
*   **Data Serialization:** The main thread `App.tsx` will serialize the current board state into a compact binary format (or JSON) and send it via `postMessage`.
*   **Unbound Compute:** The worker is completely detached from the render loop. We increase `max_iterations` from `25,000` to `5,000,000`.
*   **Progressive Yielding:** The engine will periodically yield partial results (e.g., "I'm currently at depth 15, evaluating X nodes") so the UI can display a subtle "thinking..." indicator.

### 1.2 Transposition Tables (Memoization)
*   **Implementation:** Introduce a `HashMap<u64, BestKnownState>` to cache board evaluations across search paths.
*   **Zobrist Hashing:** Implement ultra-fast Zobrist hashing for the `StateSignature` to make hash lookups nearly instantaneous.
*   **Memory Management:** The cache will be cleared when a move is actually executed by the user, but will persist across the AI's internal pathfinding, completely eliminating duplicate branch calculations.

---

## Phase 2: Algorithm Overhaul (The Navigation System)

Best-First Search (BFS) is too greedy. We need algorithms designed specifically for asymmetric zero-sum games.

### 2.1 Iterative Deepening A* (IDA*)
*   **Implementation:** Replace BFS with IDA*. IDA* explores the tree using a depth-first approach, iteratively increasing the "allowable cost" bound.
*   **Why it's better:** It has the memory footprint of Depth-First Search but the optimal pathfinding guarantees of Breadth-First Search. Combined with Transposition Tables, it completely solves the "Spider Empty Column" problem because it guarantees exploration of deep score-valleys if no better alternatives exist at the current depth limit.

### 2.2 Monte Carlo Tree Search (MCTS) [Optional / Advanced]
*   **Implementation:** Instead of explicitly scoring the board, MCTS selects a move, plays thousands of random, lightning-fast "rollouts" to the end of the game, and tracks the percentage of random rollouts that resulted in a win.
*   **Why it's better:** MCTS requires *zero human heuristics*. It discovers its own strategies by mathematically verifying which moves statistically lead to victory.

---

## Phase 3: Macro-Moves & Sub-Goals (The Transmission)

Currently, the engine thinks in terms of dragging a single card. Human players think in terms of goals. We must teach the engine to generate "Macro-Moves."

### 3.1 Sequence Compression
*   Instead of generating 4 separate moves to shift a sequence of 4 cards, the engine's move generator will identify valid sequence blocks and treat them as a single atomic operation. This dramatically reduces the branching factor of the search tree.

### 3.2 Goal-Oriented Branching
*   The AI will dynamically prioritize branches that achieve sub-goals:
    1.  *Target:* "Uncover the face-down card in Column 3."
    2.  *Target:* "Empty Column 5."
    3.  *Target:* "Build a Spades sequence on Column 2."
*   By focusing on these targets, the AI skips thousands of useless "shuffling" branches.

---

## Phase 4: Machine Learning Heuristic Tuning (The Aerodynamics)

Our current heuristics (`+10` for face up, `+50` for Foundation) are human guesses. They are good, but not mathematically perfect.

### 4.1 Headless Rust Gym
*   **Implementation:** Build a standalone Rust binary (`cargo run --bin gym`) that strips out WASM and UI, allowing it to play 10,000 games per second in terminal.

### 4.2 Genetic Algorithm Tuning
*   We define the heuristics as floating-point variables (e.g., `weight_foundation`, `weight_face_down`, `weight_sequence`).
*   The Gym spawns 100 different "AI agents", each with slightly different randomized weights. They play 1,000 games. The agents with the highest win rates "breed", combining their weights, and the process repeats.
*   After 50 generations overnight, the Gym will spit out the mathematically perfect heuristic values for all 10 Solitaire variants. We hardcode these derived values into the final WASM build.

---

## Conclusion
Executing this plan will transform the Solitude engine from a competent assistant into an autonomous, hyper-optimized intelligence capable of seeing 100+ moves ahead, discovering novel strategies, and solving virtually any deal that is mathematically winnable.
