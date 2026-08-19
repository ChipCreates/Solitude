use crate::card::CardId;
use crate::error::EngineError;
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum GameType {
    Klondike,
    Spider,
    FreeCell,
    Pyramid,
    Golf,
    TriPeaks,
    Yukon,
    FortyThieves,
    Canfield,
    Scorpion,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HintMove {
    pub from: PileRef,
    pub to: PileRef,
    pub cards: Vec<CardId>,
}

pub trait GameRules: Send {
    fn game_type(&self) -> GameType;
    fn deck_size(&self) -> usize;
    fn piles(&self) -> &[Pile];
    fn piles_mut(&mut self) -> &mut Vec<Pile>;
    fn initialize(&mut self, seed: u64);
    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool;
    fn execute_move(&mut self, from: PileRef, to: PileRef, cards: &[CardId]) -> Result<Move, EngineError>;
    fn undo(&mut self) -> bool;
    fn redo(&mut self) -> bool;
    fn check_win(&self) -> bool;
    fn is_lost(&self) -> bool {
        false
    }
    fn snapshot(&self) -> crate::history::GameSnapshot;
    fn restore(&mut self, snapshot: crate::history::GameSnapshot);
    fn snapshot_history(&self) -> crate::history::History {
        crate::history::History::new()
    }
    fn restore_history(&mut self, _history: crate::history::History) {}
    
    fn heuristic_score(&self) -> i32 {
        let mut score = 0;

        for pile in self.piles() {
            match pile.kind {
                crate::pile::PileType::Foundation => {
                    score += (pile.len() as i32) * 50;
                }
                crate::pile::PileType::Discard => {
                    // Do not artificially inflate discard pile score
                }
                crate::pile::PileType::Tableau => {
                    let mut has_face_down = false;
                    let mut prev_card: Option<&crate::card::Card> = None;
                    for card in pile.cards() {
                        if card.face_up {
                            score += 10;
                            if has_face_down {
                                score -= 1; // Encourage moving cards off face-down cards
                            }
                            if let Some(prev) = prev_card {
                                if prev.rank.value() == card.rank.value() + 1 {
                                    if prev.suit == card.suit {
                                        score += 2; // Same suit sequence (Spider/Scorpion)
                                    } else if prev.is_red() != card.is_red() {
                                        score += 1; // Alternating color sequence (Klondike)
                                    }
                                }
                            }
                        } else {
                            has_face_down = true;
                        }
                        prev_card = Some(card);
                    }
                    if pile.is_empty() {
                        score += 5;
                    }
                }
                crate::pile::PileType::Cell => {
                    if pile.is_empty() {
                        score += 5;
                    }
                }
                crate::pile::PileType::Pyramid => {
                    // Lower cards in pyramid cleared means higher score
                    score += 1;
                }
                _ => {}
            }
        }
        score
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError>;
    fn can_tap_stock(&self) -> bool {
        false
    }
    fn get_available_moves(&self) -> Vec<HintMove> {
        let mut moves = Vec::new();
        let piles = self.piles();
        
        // Default rule: iterate all piles and test face-up card suffixes
        for from_pile in piles {
            if from_pile.is_empty() {
                continue;
            }
            let from_ref = PileRef::new(from_pile.kind, from_pile.index);
            
            let face_up_cards = from_pile.face_up_cards();
            for i in 0..face_up_cards.len() {
                let cards: Vec<CardId> = face_up_cards[i..].iter().map(|c| c.id).collect();
                for to_pile in piles {
                    let to_ref = PileRef::new(to_pile.kind, to_pile.index);
                    if from_ref != to_ref {
                        if self.is_valid_move(from_ref, to_ref, &cards) {
                            moves.push(HintMove {
                                from: from_ref,
                                to: to_ref,
                                cards: cards.clone(),
                            });
                        }
                    }
                }
            }
        }
        
        // Add stock tap if possible
        if self.can_tap_stock() {
            moves.push(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: PileRef::new(PileType::Waste, 0), // Placeholder to indicate stock tap
                cards: vec![],
            });
        }
        
        moves
    }
    fn get_hint(&self) -> Option<HintMove>;
    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef>;

    /// Power-up primitive ("Lucky Reshuffle"): gathers every card currently
    /// in the Stock and Waste piles, shuffles them together, and redeals
    /// them face-down into Stock (Waste ends up empty). Returns `false` if
    /// the game has no Stock pile at all, or if Stock+Waste hold no cards.
    /// Bypasses the undo/redo history by design — this is a paid,
    /// irreversible reset, not a normal move.
    fn reshuffle_stock_waste(&mut self, seed: u64) -> bool {
        use rand::seq::SliceRandom;
        use rand::SeedableRng;
        use rand_chacha::ChaCha8Rng;

        let has_stock = self.piles().iter().any(|p| p.kind == PileType::Stock);
        if !has_stock {
            return false;
        }

        let mut cards = Vec::new();
        for pile in self.piles_mut().iter_mut() {
            if pile.kind == PileType::Stock || pile.kind == PileType::Waste {
                cards.extend(pile.remove_all());
            }
        }
        if cards.is_empty() {
            return false;
        }

        for card in cards.iter_mut() {
            card.face_up = false;
        }
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        cards.shuffle(&mut rng);

        match self.piles_mut().iter_mut().find(|p| p.kind == PileType::Stock) {
            Some(stock) => {
                stock.add_cards(cards);
                true
            }
            None => false,
        }
    }

    /// Power-up primitive ("Reset Column"): pulls every card out of one
    /// Tableau pile, shuffles them, and restacks them with only the new top
    /// card face-up (matching how a freshly-dealt column looks). Returns
    /// `false` if no Tableau pile exists at that index or it's already
    /// empty. Bypasses undo/redo history, same as `reshuffle_stock_waste`.
    fn reset_tableau_column(&mut self, index: u8, seed: u64) -> bool {
        use rand::seq::SliceRandom;
        use rand::SeedableRng;
        use rand_chacha::ChaCha8Rng;

        let mut cards = match self
            .piles_mut()
            .iter_mut()
            .find(|p| p.kind == PileType::Tableau && p.index == index)
        {
            Some(pile) if !pile.is_empty() => pile.remove_all(),
            _ => return false,
        };

        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        cards.shuffle(&mut rng);
        let last = cards.len() - 1;
        for (i, card) in cards.iter_mut().enumerate() {
            card.face_up = i == last;
        }

        match self
            .piles_mut()
            .iter_mut()
            .find(|p| p.kind == PileType::Tableau && p.index == index)
        {
            Some(pile) => {
                pile.add_cards(cards);
                true
            }
            None => false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::factory::GameFactory;
    use crate::pile::PileType;

    #[test]
    fn test_reshuffle_stock_waste_preserves_total_card_count_and_faces_down() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(42);
        let _ = game.tap_stock(); // populate Waste with at least one card

        let total_before: usize = game
            .piles()
            .iter()
            .filter(|p| p.kind == PileType::Stock || p.kind == PileType::Waste)
            .map(|p| p.len())
            .sum();
        assert!(total_before > 0, "expected stock+waste to hold cards before reshuffling");

        let ok = game.reshuffle_stock_waste(999);
        assert!(ok);

        let total_after: usize = game
            .piles()
            .iter()
            .filter(|p| p.kind == PileType::Stock || p.kind == PileType::Waste)
            .map(|p| p.len())
            .sum();
        assert_eq!(total_before, total_after, "reshuffle must not create or destroy cards");

        let waste = game.piles().iter().find(|p| p.kind == PileType::Waste).unwrap();
        assert!(waste.is_empty(), "waste should be empty after reshuffling back into stock");

        let stock = game.piles().iter().find(|p| p.kind == PileType::Stock).unwrap();
        assert!(stock.cards().iter().all(|c| !c.face_up), "all reshuffled cards must be face-down");
    }

    #[test]
    fn test_reshuffle_stock_waste_is_deterministic_for_same_seed() {
        let mut game_a = GameFactory::create_game(GameType::Klondike);
        game_a.initialize(42);
        let _ = game_a.tap_stock();
        game_a.reshuffle_stock_waste(555);

        let mut game_b = GameFactory::create_game(GameType::Klondike);
        game_b.initialize(42);
        let _ = game_b.tap_stock();
        game_b.reshuffle_stock_waste(555);

        let stock_a = game_a.piles().iter().find(|p| p.kind == PileType::Stock).unwrap();
        let stock_b = game_b.piles().iter().find(|p| p.kind == PileType::Stock).unwrap();
        assert_eq!(stock_a.cards(), stock_b.cards(), "same seed must produce the same reshuffled order");
    }

    #[test]
    fn test_reset_tableau_column_preserves_card_count_and_flips_only_top() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(42);

        let column_len_before = game
            .piles()
            .iter()
            .find(|p| p.kind == PileType::Tableau && p.index == 6)
            .unwrap()
            .len();
        assert!(column_len_before > 0);

        let ok = game.reset_tableau_column(6, 777);
        assert!(ok);

        let column = game.piles().iter().find(|p| p.kind == PileType::Tableau && p.index == 6).unwrap();
        assert_eq!(column.len(), column_len_before, "reset must not create or destroy cards");

        let face_up_count = column.cards().iter().filter(|c| c.face_up).count();
        assert_eq!(face_up_count, 1, "exactly the new top card should be face-up after a reset");
        assert!(column.top_card().unwrap().face_up);
    }

    #[test]
    fn test_reset_tableau_column_rejects_out_of_range_index() {
        let mut game = GameFactory::create_game(GameType::Klondike);
        game.initialize(42);
        assert!(!game.reset_tableau_column(99, 1));
    }

    #[test]
    fn test_reshuffle_stock_waste_returns_false_when_game_has_no_stock() {
        // FreeCell deals every card to the tableau at start and has no
        // Stock pile at all.
        let mut game = GameFactory::create_game(GameType::FreeCell);
        game.initialize(42);
        assert!(!game.reshuffle_stock_waste(1));
    }
}
