pub mod mcts;

use crate::game::{GameRules, HintMove};
use crate::history::GameSnapshot;
use crate::pile::{Pile, PileType};
use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashSet};

#[derive(Debug, Clone)]
pub struct SolverNode {
    pub snapshot: GameSnapshot,
    pub depth: usize,
    pub score: i32,
    pub path: Vec<HintMove>,
}

impl PartialEq for SolverNode {
    fn eq(&self, other: &Self) -> bool {
        self.score == other.score && self.depth == other.depth
    }
}

impl Eq for SolverNode {}

impl Ord for SolverNode {
    fn cmp(&self, other: &Self) -> Ordering {
        self.score
            .cmp(&other.score)
            .then_with(|| other.depth.cmp(&self.depth))
    }
}

impl PartialOrd for SolverNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

use std::hash::{Hash, Hasher};
use std::collections::hash_map::DefaultHasher;
use std::collections::VecDeque;
use std::cell::RefCell;

// `Pile` derives `Hash`/`Eq` including its internal `version` counter, which
// increments on every mutation. Two content-identical boards reached via a
// different number of pile mutations would otherwise hash/compare unequal,
// so cycle detection never deduped transpositions. Implement Hash/Eq by hand
// here, comparing pile kind/index/cards and skipping `version`.
#[derive(Debug, Clone)]
struct StateSignature {
    piles: Vec<Pile>,
    stock_recycle_count: u32,
}

impl Hash for StateSignature {
    fn hash<H: Hasher>(&self, state: &mut H) {
        for pile in &self.piles {
            pile.kind.hash(state);
            pile.index.hash(state);
            pile.cards().hash(state);
        }
        self.stock_recycle_count.hash(state);
    }
}

impl PartialEq for StateSignature {
    fn eq(&self, other: &Self) -> bool {
        self.stock_recycle_count == other.stock_recycle_count
            && self.piles.len() == other.piles.len()
            && self.piles.iter().zip(other.piles.iter()).all(|(a, b)| {
                a.kind == b.kind && a.index == b.index && a.cards() == b.cards()
            })
    }
}

impl Eq for StateSignature {}

/// Distinguishes which UI feature is driving a solver search. Hint (one-shot,
/// user-triggered) and AutoPlay/AutoComplete (continuous stepping) each get
/// their own cache namespace so interleaving the two — e.g. a hint request
/// arriving mid-autoplay — can't desync the other's cached move path against
/// a state hash it was never computed from.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SolverContext {
    Hint,
    AutoPlay,
}

// Cap on how many recent post-move states AutoPlay remembers when deciding
// whether a candidate move would just backtrack into a state it was
// already in. Small and fixed-size on purpose: this only needs to catch
// short back-and-forth cycles (e.g. shuffling a King/Queen pair between two
// empty tableau columns), not long-range repetition.
const AUTOPLAY_HISTORY_CAPACITY: usize = 12;

thread_local! {
    static HINT_CACHED_PATH: RefCell<Vec<HintMove>> = RefCell::new(Vec::new());
    static HINT_EXPECTED_STATE_HASH: RefCell<u64> = RefCell::new(0);
    static AUTOPLAY_CACHED_PATH: RefCell<Vec<HintMove>> = RefCell::new(Vec::new());
    static AUTOPLAY_EXPECTED_STATE_HASH: RefCell<u64> = RefCell::new(0);
    // Distinct from the BFS's per-call `visited` set (game.rs), which only
    // dedupes states *within* one search and is discarded afterward. This
    // ring buffer persists *across* separate AutoPlay steps, so it can
    // catch a move that looks locally best on every individual call but
    // only ever shuffles between a handful of already-seen states,
    // producing a non-terminating loop no single search would ever see.
    static AUTOPLAY_RECENT_HASHES: RefCell<VecDeque<u64>> = RefCell::new(VecDeque::new());
}

/// Clears both solver caches (Hint and AutoPlay) and AutoPlay's recent-state
/// history.
///
/// Must be called whenever a new game is initialized: a stale cache from
/// the previous game could otherwise be replayed against the new state if
/// the state hashes happen to collide.
pub fn clear_solver_cache() {
    HINT_CACHED_PATH.with(|p| p.borrow_mut().clear());
    HINT_EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = 0);
    AUTOPLAY_CACHED_PATH.with(|p| p.borrow_mut().clear());
    AUTOPLAY_EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = 0);
    AUTOPLAY_RECENT_HASHES.with(|h| h.borrow_mut().clear());
}

fn calculate_hash(game: &dyn GameRules) -> u64 {
    let mut hasher = DefaultHasher::new();
    let snap = game.snapshot();
    snap.piles.hash(&mut hasher);
    snap.stock_recycle_count.hash(&mut hasher);
    hasher.finish()
}

pub struct SolverEngine;

impl SolverEngine {
    /// Calculates a heuristic score (higher is better) for the current game state.
    pub fn calculate_heuristic(game: &dyn GameRules) -> i32 {
        if game.check_win() {
            return 10_000;
        }
        game.heuristic_score()
    }

    /// Explores the game tree to find the best immediate move using Best-First Search.
    pub fn find_best_move(game: &mut dyn GameRules, context: SolverContext) -> Option<HintMove> {
        let (cached_path, expected_state_hash) = match context {
            SolverContext::Hint => (&HINT_CACHED_PATH, &HINT_EXPECTED_STATE_HASH),
            SolverContext::AutoPlay => (&AUTOPLAY_CACHED_PATH, &AUTOPLAY_EXPECTED_STATE_HASH),
        };

        let current_hash = calculate_hash(game);

        // Check cache
        let cached_move = expected_state_hash.with(|expected| {
            if *expected.borrow() == current_hash {
                cached_path.with(|path| {
                    let mut p = path.borrow_mut();
                    if !p.is_empty() {
                        return Some(p.remove(0));
                    }
                    None
                })
            } else {
                cached_path.with(|p| p.borrow_mut().clear());
                None
            }
        });

        if let Some(m) = cached_move {
            // Verify it's actually valid before returning
            let mut valid = false;
            if m.cards.is_empty() && m.from.kind == PileType::Stock {
                valid = game.can_tap_stock();
            } else {
                valid = game.is_valid_move(m.from, m.to, &m.cards);
            }

            if valid {
                let initial_snap = game.snapshot();
                let initial_hist = game.snapshot_history();
                if m.cards.is_empty() && m.from.kind == PileType::Stock {
                    let _ = game.tap_stock();
                } else {
                    let _ = game.execute_move(m.from, m.to, &m.cards);
                }
                let resulting_hash = calculate_hash(game);
                game.restore(initial_snap);
                game.restore_history(initial_hist);

                if Self::is_autoplay_repeat(context, resulting_hash) {
                    // This cached step would just backtrack into a state
                    // AutoPlay has already been in recently -- drop the
                    // whole plan and fall through to a fresh search instead
                    // of blindly replaying a path that's proven to cycle.
                    cached_path.with(|p| p.borrow_mut().clear());
                } else {
                    // Update expected hash for the NEXT turn
                    expected_state_hash.with(|e| *e.borrow_mut() = resulting_hash);
                    Self::record_autoplay_state(context, resulting_hash);
                    return Some(m);
                }
            } else {
                cached_path.with(|p| p.borrow_mut().clear());
            }
        }

        let initial_snapshot = game.snapshot();
        let initial_history = game.snapshot_history();
        let initial_score = Self::calculate_heuristic(game);

        let mut open_set = BinaryHeap::new();
        let mut visited = HashSet::new();

        open_set.push(SolverNode {
            snapshot: initial_snapshot.clone(),
            depth: 0,
            score: initial_score,
            path: Vec::new(),
        });

        // Limit the search to ensure it stays fast enough for 60FPS UI rendering
        let max_iterations = 25000;
        let mut iterations = 0;
        let mut best_score_seen = initial_score;
        let mut best_move_found = None;
        let mut best_path_found = None;

        while let Some(node) = open_set.pop() {
            if iterations >= max_iterations {
                break;
            }
            iterations += 1;

            game.restore(node.snapshot.clone());

            if game.check_win() {
                best_move_found = node.path.first().cloned();
                best_path_found = Some(node.path.clone());
                break;
            }

            // Cycle detection using pile configuration and recycle/completed count (ignoring move_count)
            let current_snap = game.snapshot();
            let state_sig = StateSignature {
                piles: current_snap.piles,
                stock_recycle_count: current_snap.stock_recycle_count,
            };
            if visited.contains(&state_sig) {
                continue;
            }
            visited.insert(state_sig);

            if node.depth >= 30 {
                continue;
            }

            let available_moves = game.get_available_moves();
            for m in available_moves {
                let mut valid = false;
                if m.cards.is_empty() && m.from.kind == PileType::Stock {
                    if game.tap_stock().is_ok() {
                        valid = true;
                    }
                } else if game.execute_move(m.from, m.to, &m.cards).is_ok() {
                    valid = true;
                }

                if valid {
                    let mut new_path = node.path.clone();
                    new_path.push(m.clone());
                    
                    let new_score = Self::calculate_heuristic(game);
                    
                    // Track the best immediate move based on the highest heuristic discovered
                    if new_score > best_score_seen {
                        best_score_seen = new_score;
                        best_move_found = new_path.first().cloned();
                        best_path_found = Some(new_path.clone());
                    }
                    
                    open_set.push(SolverNode {
                        snapshot: game.snapshot(),
                        depth: node.depth + 1,
                        score: new_score - (node.depth as i32), // Penalize longer paths slightly
                        path: new_path,
                    });
                    
                    // Re-restore the parent snapshot to try the next move cleanly
                    game.restore(node.snapshot.clone());
                }
            }
        }

        // Restore exact initial board state and undo history
        game.restore(initial_snapshot.clone());
        game.restore_history(initial_history.clone());

        if best_move_found.is_none() {
            best_move_found = mcts::MctsSolver::find_best_move(game, 10_000);

            if best_move_found.is_none() {
                best_move_found = game.get_hint();
            }

            // Neither fallback draws from best_path_found, so there's no
            // path to cache -- just apply the same repeat check + hash
            // bookkeeping the cached-path and fresh-search branches use.
            if let Some(ref m) = best_move_found {
                if let Some(resulting_hash) =
                    Self::simulate_move_hash(game, m, initial_snapshot.clone(), initial_history.clone())
                {
                    if Self::is_autoplay_repeat(context, resulting_hash) {
                        best_move_found = None;
                    } else {
                        Self::record_autoplay_state(context, resulting_hash);
                    }
                } else {
                    best_move_found = None;
                }
            }
        } else if let Some(ref m) = best_move_found {
            let resulting_hash =
                Self::simulate_move_hash(game, m, initial_snapshot.clone(), initial_history.clone());

            match resulting_hash {
                Some(hash) if Self::is_autoplay_repeat(context, hash) => {
                    // The single best-scoring move BFS found would just
                    // backtrack into a recently-seen state. Reject it
                    // rather than commit AutoPlay to a step it already
                    // knows leads nowhere new.
                    best_move_found = None;
                }
                Some(hash) => {
                    // Save the remaining path to cache
                    cached_path.with(|p| {
                        let mut path = p.borrow_mut();
                        path.clear();
                        // The first move is returned, the rest are cached
                        if let Some(best_path) = best_path_found {
                            if best_path.len() > 1 {
                                path.extend(best_path.into_iter().skip(1));
                            }
                        }
                    });
                    expected_state_hash.with(|e| *e.borrow_mut() = hash);
                    Self::record_autoplay_state(context, hash);
                }
                None => {
                    best_move_found = None;
                }
            }
        }

        best_move_found
    }

    /// Applies `m` to `game` just to compute the resulting state hash, then
    /// restores `game` to `snapshot`/`history` unconditionally. Returns
    /// `None` if `m` turns out not to be executable (shouldn't normally
    /// happen for a move the caller just found, but the underlying engine
    /// calls are fallible).
    fn simulate_move_hash(
        game: &mut dyn GameRules,
        m: &HintMove,
        snapshot: crate::history::GameSnapshot,
        history: crate::history::History,
    ) -> Option<u64> {
        let ok = if m.cards.is_empty() && m.from.kind == PileType::Stock {
            game.tap_stock().is_ok()
        } else {
            game.execute_move(m.from, m.to, &m.cards).is_ok()
        };
        let hash = if ok { Some(calculate_hash(game)) } else { None };
        game.restore(snapshot);
        game.restore_history(history);
        hash
    }

    fn is_autoplay_repeat(context: SolverContext, hash: u64) -> bool {
        matches!(context, SolverContext::AutoPlay)
            && AUTOPLAY_RECENT_HASHES.with(|h| h.borrow().contains(&hash))
    }

    fn record_autoplay_state(context: SolverContext, hash: u64) {
        if !matches!(context, SolverContext::AutoPlay) {
            return;
        }
        AUTOPLAY_RECENT_HASHES.with(|h| {
            let mut buf = h.borrow_mut();
            buf.push_back(hash);
            while buf.len() > AUTOPLAY_HISTORY_CAPACITY {
                buf.pop_front();
            }
        });
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::card::{Card, CardId, Rank, Suit};
    use crate::factory::GameFactory;
    use crate::game::GameType;
    use crate::pile::PileType;

    #[test]
    fn test_state_signature_ignores_pile_version() {
        // Two piles with identical content but different mutation counts
        // (reached via a different number of add/remove calls) should be
        // treated as the same state for cycle detection.
        let card = Card::new(Suit::Hearts, Rank::Ace, CardId(0), true);

        let mut pile_a = Pile::new(PileType::Tableau, 0);
        pile_a.add_card(card.clone()); // version 1

        let mut pile_b = Pile::new(PileType::Tableau, 0);
        pile_b.add_card(card.clone());
        let _ = pile_b.remove_top();
        pile_b.add_card(card.clone()); // version 3, same final content

        assert_ne!(pile_a.version(), pile_b.version());
        assert_eq!(pile_a.cards(), pile_b.cards());

        let sig_a = StateSignature { piles: vec![pile_a], stock_recycle_count: 0 };
        let sig_b = StateSignature { piles: vec![pile_b], stock_recycle_count: 0 };

        assert_eq!(sig_a, sig_b, "content-identical states must compare equal regardless of version");

        let mut visited: HashSet<StateSignature> = HashSet::new();
        visited.insert(sig_a);
        assert!(
            visited.contains(&sig_b),
            "content-identical states must hash the same for cycle-detection dedup"
        );
    }

    #[test]
    fn test_solver_find_best_move() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(12345);

        let initial_history_len = game.snapshot_history().can_undo();
        let hint = SolverEngine::find_best_move(game.as_mut(), SolverContext::Hint);
        let _ = hint;

        // Should not panic and should restore the exact initial state & history
        assert_eq!(game.snapshot().move_count, 0);
        assert_eq!(game.snapshot_history().can_undo(), initial_history_len);
    }

    #[test]
    fn test_clear_solver_cache_resets_state() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(12345);

        // Populate the cache with a real search.
        let _ = SolverEngine::find_best_move(game.as_mut(), SolverContext::Hint);
        let had_cached_path = HINT_CACHED_PATH.with(|p| !p.borrow().is_empty());
        let had_expected_hash = HINT_EXPECTED_STATE_HASH.with(|e| *e.borrow() != 0);
        assert!(
            had_cached_path || had_expected_hash,
            "expected a real search to populate the solver cache"
        );

        clear_solver_cache();

        HINT_CACHED_PATH.with(|p| assert!(p.borrow().is_empty(), "HINT_CACHED_PATH should be empty"));
        HINT_EXPECTED_STATE_HASH.with(|e| assert_eq!(*e.borrow(), 0, "HINT_EXPECTED_STATE_HASH should be reset"));
        AUTOPLAY_CACHED_PATH.with(|p| assert!(p.borrow().is_empty(), "AUTOPLAY_CACHED_PATH should be empty"));
        AUTOPLAY_EXPECTED_STATE_HASH.with(|e| assert_eq!(*e.borrow(), 0, "AUTOPLAY_EXPECTED_STATE_HASH should be reset"));
    }

    #[test]
    fn test_stale_cache_does_not_leak_across_games() {
        // Simulates what initialize_game must do: clear the cache before a
        // new game starts, so a cached path from game N can never be
        // replayed against game N+1's state.
        let mut game_a = GameFactory::create_game(GameType::Klondike);
        game_a.initialize(111);
        let _ = SolverEngine::find_best_move(game_a.as_mut(), SolverContext::Hint);

        // New game starts; without clearing, EXPECTED_STATE_HASH from game_a
        // could coincidentally match game_b's hash and return a stale move.
        clear_solver_cache();

        let mut game_b = GameFactory::create_game(GameType::Klondike);
        game_b.initialize(222);

        HINT_EXPECTED_STATE_HASH.with(|e| assert_eq!(*e.borrow(), 0));
        HINT_CACHED_PATH.with(|p| assert!(p.borrow().is_empty()));

        // Sanity: solver still works normally on the fresh game.
        let _ = SolverEngine::find_best_move(game_b.as_mut(), SolverContext::Hint);
        assert_eq!(game_b.snapshot().move_count, 0);
    }

    #[test]
    fn test_hint_and_autoplay_caches_are_isolated() {
        // Interleave Hint and AutoPlay searches on the same game state and
        // verify each context's cache only ever contains moves computed
        // under that context's own expected-state hash — i.e. a hint
        // request mid-autoplay can't desync the autoplay cache or vice
        // versa.
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(999);

        let hint_move = SolverEngine::find_best_move(game.as_mut(), SolverContext::Hint);
        let autoplay_move = SolverEngine::find_best_move(game.as_mut(), SolverContext::AutoPlay);

        // Both contexts searched from the same identical state, so they
        // must agree on the best move.
        assert_eq!(
            hint_move.map(|m| (m.from, m.to, m.cards)),
            autoplay_move.clone().map(|m| (m.from, m.to, m.cards)),
            "hint and autoplay should find the same best move from the same state"
        );

        // Actually advance the game via the autoplay move, then take a
        // second autoplay step. If the caches were shared, the first
        // find_best_move(Hint) call above would have already populated a
        // cache keyed to a state hash that autoplay's second call could
        // mistakenly reuse; verifying it still returns a legal move after a
        // real state change confirms no cross-contamination occurred.
        if let Some(m) = autoplay_move {
            if m.cards.is_empty() && m.from.kind == PileType::Stock {
                let _ = game.tap_stock();
            } else {
                let _ = game.execute_move(m.from, m.to, &m.cards);
            }
        }
        let next_autoplay_move = SolverEngine::find_best_move(game.as_mut(), SolverContext::AutoPlay);
        if let Some(ref m) = next_autoplay_move {
            let mut valid = false;
            if m.cards.is_empty() && m.from.kind == PileType::Stock {
                valid = game.can_tap_stock();
            } else {
                valid = game.is_valid_move(m.from, m.to, &m.cards);
            }
            assert!(valid, "autoplay's next move must be valid against the actual post-move state");
        }
    }

    #[test]
    fn test_autoplay_recent_hashes_detects_repeat_and_evicts_old_entries() {
        clear_solver_cache();

        assert!(!SolverEngine::is_autoplay_repeat(SolverContext::AutoPlay, 42));
        SolverEngine::record_autoplay_state(SolverContext::AutoPlay, 42);
        assert!(SolverEngine::is_autoplay_repeat(SolverContext::AutoPlay, 42));

        // Hint's own repeated states must never be flagged -- only AutoPlay
        // accumulates this history at all.
        assert!(!SolverEngine::is_autoplay_repeat(SolverContext::Hint, 42));

        // Push past capacity and confirm the oldest entry (42) ages out.
        for h in 1..=AUTOPLAY_HISTORY_CAPACITY as u64 {
            SolverEngine::record_autoplay_state(SolverContext::AutoPlay, 1000 + h);
        }
        assert!(!SolverEngine::is_autoplay_repeat(SolverContext::AutoPlay, 42));
        assert!(SolverEngine::is_autoplay_repeat(
            SolverContext::AutoPlay,
            1000 + AUTOPLAY_HISTORY_CAPACITY as u64
        ));

        clear_solver_cache();
        assert!(!SolverEngine::is_autoplay_repeat(
            SolverContext::AutoPlay,
            1000 + AUTOPLAY_HISTORY_CAPACITY as u64
        ));
    }

    #[test]
    fn test_autoplay_does_not_loop_forever_on_previously_stuck_deal() {
        // Seed 1_700_000_000_000 is the exact deal from the reported bug: a
        // fresh best-first search on every AutoPlay step kept picking the
        // single highest-scoring immediate move even though it only ever
        // shuffled a King/Queen pair between two open tableau columns,
        // so the game never reached check_win()/is_lost() and AutoPlay
        // (and, downstream, the Hint button gated behind isAutoPlaying)
        // never stopped. Confirms find_best_move now bails out with None
        // once AutoPlay would just be revisiting a recent state, instead of
        // returning a "valid" move forever.
        clear_solver_cache();
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(1_700_000_000_000);

        const MAX_STEPS: usize = 2000;
        let mut terminated = false;
        for _ in 0..MAX_STEPS {
            if game.check_win() || game.is_lost() {
                terminated = true;
                break;
            }
            let mv = match SolverEngine::find_best_move(game.as_mut(), SolverContext::AutoPlay) {
                Some(m) => m,
                None => {
                    terminated = true;
                    break;
                }
            };
            if mv.cards.is_empty() && mv.from.kind == PileType::Stock {
                let _ = game.tap_stock();
            } else {
                let _ = game.execute_move(mv.from, mv.to, &mv.cards);
            }
        }

        assert!(
            terminated,
            "AutoPlay must eventually stop (win, lose, or run out of non-repeating moves) \
             instead of finding a 'valid' move forever on a deal it can't make progress on"
        );
    }
}
