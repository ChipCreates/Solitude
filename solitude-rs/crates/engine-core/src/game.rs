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
}
