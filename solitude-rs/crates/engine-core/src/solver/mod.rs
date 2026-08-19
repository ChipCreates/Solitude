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
use std::cell::RefCell;

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct StateSignature {
    piles: Vec<Pile>,
    stock_recycle_count: u32,
}

thread_local! {
    static CACHED_PATH: RefCell<Vec<HintMove>> = RefCell::new(Vec::new());
    static EXPECTED_STATE_HASH: RefCell<u64> = RefCell::new(0);
}

/// Clears the solver's cached move path and expected-state hash.
///
/// Must be called whenever a new game is initialized: a stale cache from
/// the previous game could otherwise be replayed against the new state if
/// the state hashes happen to collide.
pub fn clear_solver_cache() {
    CACHED_PATH.with(|p| p.borrow_mut().clear());
    EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = 0);
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
    pub fn find_best_move(game: &mut dyn GameRules) -> Option<HintMove> {
        let current_hash = calculate_hash(game);
        
        // Check cache
        let cached_move = EXPECTED_STATE_HASH.with(|expected| {
            if *expected.borrow() == current_hash {
                CACHED_PATH.with(|path| {
                    let mut p = path.borrow_mut();
                    if !p.is_empty() {
                        return Some(p.remove(0));
                    }
                    None
                })
            } else {
                CACHED_PATH.with(|p| p.borrow_mut().clear());
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
                // Update expected hash for the NEXT turn
                let initial_snap = game.snapshot();
                let initial_hist = game.snapshot_history();
                if m.cards.is_empty() && m.from.kind == PileType::Stock {
                    let _ = game.tap_stock();
                } else {
                    let _ = game.execute_move(m.from, m.to, &m.cards);
                }
                EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = calculate_hash(game));
                game.restore(initial_snap);
                game.restore_history(initial_hist);
                
                return Some(m);
            } else {
                CACHED_PATH.with(|p| p.borrow_mut().clear());
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
        } else if let Some(ref m) = best_move_found {
            // Save the remaining path to cache
            CACHED_PATH.with(|p| {
                let mut path = p.borrow_mut();
                path.clear();
                // The first move is returned, the rest are cached
                if let Some(best_path) = best_path_found {
                    if best_path.len() > 1 {
                        path.extend(best_path.into_iter().skip(1));
                    }
                }
            });
            
            // Calculate what the hash WILL be after this move
            if m.cards.is_empty() && m.from.kind == PileType::Stock {
                let _ = game.tap_stock();
            } else {
                let _ = game.execute_move(m.from, m.to, &m.cards);
            }
            EXPECTED_STATE_HASH.with(|e| *e.borrow_mut() = calculate_hash(game));
            
            // Restore again
            game.restore(initial_snapshot);
            game.restore_history(initial_history);
        }

        best_move_found
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::factory::GameFactory;
    use crate::game::GameType;

    #[test]
    fn test_solver_find_best_move() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(12345);

        let initial_history_len = game.snapshot_history().can_undo();
        let hint = SolverEngine::find_best_move(game.as_mut());
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
        let _ = SolverEngine::find_best_move(game.as_mut());
        let had_cached_path = CACHED_PATH.with(|p| !p.borrow().is_empty());
        let had_expected_hash = EXPECTED_STATE_HASH.with(|e| *e.borrow() != 0);
        assert!(
            had_cached_path || had_expected_hash,
            "expected a real search to populate the solver cache"
        );

        clear_solver_cache();

        CACHED_PATH.with(|p| assert!(p.borrow().is_empty(), "CACHED_PATH should be empty"));
        EXPECTED_STATE_HASH.with(|e| assert_eq!(*e.borrow(), 0, "EXPECTED_STATE_HASH should be reset"));
    }

    #[test]
    fn test_stale_cache_does_not_leak_across_games() {
        // Simulates what initialize_game must do: clear the cache before a
        // new game starts, so a cached path from game N can never be
        // replayed against game N+1's state.
        let mut game_a = GameFactory::create_game(GameType::Klondike);
        game_a.initialize(111);
        let _ = SolverEngine::find_best_move(game_a.as_mut());

        // New game starts; without clearing, EXPECTED_STATE_HASH from game_a
        // could coincidentally match game_b's hash and return a stale move.
        clear_solver_cache();

        let mut game_b = GameFactory::create_game(GameType::Klondike);
        game_b.initialize(222);

        EXPECTED_STATE_HASH.with(|e| assert_eq!(*e.borrow(), 0));
        CACHED_PATH.with(|p| assert!(p.borrow().is_empty()));

        // Sanity: solver still works normally on the fresh game.
        let _ = SolverEngine::find_best_move(game_b.as_mut());
        assert_eq!(game_b.snapshot().move_count, 0);
    }
}
