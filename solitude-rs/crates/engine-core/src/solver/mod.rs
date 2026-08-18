use crate::game::{GameRules, HintMove};
use crate::history::GameSnapshot;
use crate::pile::PileType;
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
        self.score == other.score
    }
}

impl Eq for SolverNode {}

impl Ord for SolverNode {
    fn cmp(&self, other: &Self) -> Ordering {
        self.score.cmp(&other.score)
    }
}

impl PartialOrd for SolverNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

pub struct SolverEngine;

impl SolverEngine {
    /// Calculates a heuristic score (higher is better) for the current game state.
    pub fn calculate_heuristic(game: &dyn GameRules) -> i32 {
        if game.check_win() {
            return 10_000;
        }

        let mut score = 0;
        for pile in game.piles() {
            match pile.kind {
                PileType::Foundation | PileType::Discard => {
                    score += (pile.len() as i32) * 15;
                }
                PileType::Tableau => {
                    for card in pile.cards() {
                        if card.face_up {
                            score += 2;
                        }
                    }
                    if pile.is_empty() {
                        score += 5; // Empty tableau spots are valuable
                    }
                }
                PileType::Cell => {
                    if pile.is_empty() {
                        score += 5; // Empty cells are valuable in FreeCell
                    }
                }
                PileType::Pyramid => {
                    // Lower cards in pyramid cleared means higher score
                    score += 1;
                }
                _ => {}
            }
        }
        score
    }

    /// Explores the game tree to find the best immediate move using Best-First Search.
    pub fn find_best_move(game: &mut dyn GameRules) -> Option<HintMove> {
        let initial_snapshot = game.snapshot();
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
        let max_iterations = 200;
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

            // Create a simple state signature string by serializing the snapshot length/moves
            let state_signature = format!("{:?}", game.snapshot());
            if visited.contains(&state_signature) {
                continue;
            }
            visited.insert(state_signature);

            if node.depth >= 15 {
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

        game.restore(initial_snapshot);
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

        let hint = SolverEngine::find_best_move(game.as_mut());
        // Should not panic and should restore the exact initial state
        assert_eq!(game.snapshot().move_count, 0);
    }
}
