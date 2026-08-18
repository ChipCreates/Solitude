use crate::game::{GameRules, HintMove};
use crate::history::GameSnapshot;
use crate::pile::PileType;
use std::cmp::Ordering;

#[derive(Debug, Clone)]
pub struct SolverNode {
    pub snapshot: GameSnapshot,
    pub depth: usize,
    pub score: i32,
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

    /// Evaluates if the current state can make immediate progress via auto-move / hint.
    pub fn find_best_move(game: &dyn GameRules) -> Option<HintMove> {
        game.get_hint()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::factory::GameFactory;
    use crate::game::GameType;

    #[test]
    fn test_solver_heuristic_initial_state() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(12345);

        let score = SolverEngine::calculate_heuristic(game.as_ref());
        assert!(score > 0);
    }

    #[test]
    fn test_solver_find_best_move() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(12345);

        let hint = SolverEngine::find_best_move(game.as_ref());
        // Initial Klondike deal with seed 12345 may or may not have a hint, but should not panic
        let _ = hint;
    }
}
