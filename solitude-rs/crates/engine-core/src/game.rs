use crate::card::{Card, CardId};
use crate::error::EngineError;
use crate::mv::Move;
use crate::pile::{Pile, PileRef};
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

#[derive(Debug, Clone)]
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
    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError>;
    fn get_hint(&self) -> Option<HintMove>;
    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef>;
}
