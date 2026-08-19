use crate::card::CardId;
use crate::pile::PileRef;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub enum MoveExtra {
    None,
    PyramidPair { second_card: CardId },
    StockRecycle { recycle_count: u32 },
    FreecellSupermove { cells_used: u8, columns_used: u8 },
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct Move {
    pub from: PileRef,
    pub to: PileRef,
    pub cards: Vec<CardId>,
    pub flipped_card: bool,
    pub drew_from_stock: bool,
    pub extra: MoveExtra,
}

impl Move {
    pub fn new(from: PileRef, to: PileRef, cards: Vec<CardId>) -> Self {
        Self {
            from,
            to,
            cards,
            flipped_card: false,
            drew_from_stock: false,
            extra: MoveExtra::None,
        }
    }

    pub fn with_flipped_card(mut self, flipped: bool) -> Self {
        self.flipped_card = flipped;
        self
    }

    pub fn with_stock_draw(mut self, drew: bool) -> Self {
        self.drew_from_stock = drew;
        self
    }

    pub fn with_extra(mut self, extra: MoveExtra) -> Self {
        self.extra = extra;
        self
    }
}
