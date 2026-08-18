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

#[derive(Debug, Clone, PartialEq, Eq, Hash)]
struct StateSignature {
    piles: Vec<Pile>,
    stock_recycle_count: u32,
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
        let max_iterations = 5000;
        let mut iterations = 0;
        let mut best_score_seen = initial_score;
        let mut best_move_found = None;

        while let Some(node) = open_set.pop() {
            if iterations >= max_iterations {
                break;
            }
            iterations += 1;

            game.restore(node.snapshot.clone());

            if game.check_win() {
                best_move_found = node.path.into_iter().next();
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
        game.restore(initial_snapshot);
        game.restore_history(initial_history);

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
}
