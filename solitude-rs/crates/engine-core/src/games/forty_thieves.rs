use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct FortyThievesGame {
    piles: Vec<Pile>,
    move_count: u32,
    history: History,
}

impl FortyThievesGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(20);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        piles.push(Pile::new(PileType::Waste, 0)); // 1
        for i in 0..8 {
            piles.push(Pile::new(PileType::Foundation, i)); // 2..9
        }
        for i in 0..10 {
            piles.push(Pile::new(PileType::Tableau, i)); // 10..19
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Foundation => {
                if r.index < 8 { Some(2 + r.index as usize) } else { None }
            }
            PileType::Tableau => {
                if r.index < 10 { Some(10 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }
}

impl Default for FortyThievesGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for FortyThievesGame {
    fn snapshot_history(&self) -> History {
        self.history.clone()
    }
    fn restore_history(&mut self, history: History) {
        self.history = history;
    }


    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, 0)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
    }
    fn game_type(&self) -> GameType {
        GameType::FortyThieves
    }

    fn deck_size(&self) -> usize {
        104
    }

    fn piles(&self) -> &[Pile] {
        &self.piles
    }

    fn initialize(&mut self, seed: u64) {
        self.piles = Self::create_piles();
        self.move_count = 0;
        self.history.clear();

        let mut deck = Deck::new(2); // 2 decks (104 cards)
        deck.shuffle(seed);

        // Deal 4 cards to each of 10 tableau columns, all face up
        for col in 0..10 {
            for _ in 0..4 {
                let mut card = deck.draw().unwrap();
                card.face_up = true;
                self.piles[10 + col].add_card(card);
            }
        }

        // Remaining 64 cards to stock (face down)
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.len() != 1 || from == to {
            return false;
        }

        let from_idx = match self.get_pile_idx(from) {
            Some(i) => i,
            None => return false,
        };
        let to_idx = match self.get_pile_idx(to) {
            Some(i) => i,
            None => return false,
        };

        if to.kind == PileType::Stock || to.kind == PileType::Waste {
            return false;
        }

        let from_pile = &self.piles[from_idx];
        let to_pile = &self.piles[to_idx];

        let moving_card = match from_pile.top_card() {
            Some(c) if c.id == cards[0] => c,
            _ => return false,
        };

        if to.kind == PileType::Foundation {
            if let Some(top) = to_pile.top_card() {
                return moving_card.suit == top.suit && moving_card.rank.value() == top.rank.value() + 1;
            } else {
                return moving_card.rank == Rank::Ace;
            }
        }

        if to.kind == PileType::Tableau {
            if to_pile.is_empty() {
                return true; // Any single card can fill empty column
            } else {
                let top = to_pile.top_card().unwrap();
                return moving_card.suit == top.suit && moving_card.rank.value() + 1 == top.rank.value();
            }
        }

        false
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal Forty Thieves move".into()));
        }

        self.history.push(self.snapshot());

        let from_idx = self.get_pile_idx(from).unwrap();
        let to_idx = self.get_pile_idx(to).unwrap();

        let card = self.piles[from_idx].remove_top().unwrap();
        self.piles[to_idx].add_card(card);

        self.move_count += 1;
        Ok(Move::new(from, to, cards.to_vec()))
    }
    fn can_tap_stock(&self) -> bool {
        !self.piles[0].is_empty()
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        if self.piles[0].is_empty() {
            return Ok(None);
        }

        self.history.push(self.snapshot());

        let mut card = self.piles[0].remove_top().unwrap();
        card.face_up = true;
        let card_id = card.id;
        self.piles[1].add_card(card);

        self.move_count += 1;

        Ok(Some(
            Move::new(PileRef::new(PileType::Stock, 0), PileRef::new(PileType::Waste, 0), vec![card_id])
                .with_stock_draw(true),
        ))
    }

    fn undo(&mut self) -> bool {
        let current = self.snapshot();
        if let Some(prev) = self.history.undo(current) {
            self.restore(prev);
            true
        } else {
            false
        }
    }

    fn redo(&mut self) -> bool {
        let current = self.snapshot();
        if let Some(next) = self.history.redo(current) {
            self.restore(next);
            true
        } else {
            false
        }
    }

    fn check_win(&self) -> bool {
        (2..10).all(|i| self.piles[i].len() == 13)
    }

    fn is_lost(&self) -> bool {
        false
    }

    fn get_hint(&self) -> Option<HintMove> {
        // Priority 1: Waste to Foundation
        if let Some(card) = self.piles[1].top_card() {
            for f in 0..8 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(PileRef::new(PileType::Waste, 0), f_ref, &[card.id]) {
                    return Some(HintMove {
                        from: PileRef::new(PileType::Waste, 0),
                        to: f_ref,
                        cards: vec![card.id],
                    });
                }
            }
        }

        // Priority 2: Tableau to Foundation
        for t in 0..10 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if let Some(card) = self.piles[10 + t as usize].top_card() {
                for f in 0..8 {
                    let f_ref = PileRef::new(PileType::Foundation, f);
                    if self.is_valid_move(t_ref, f_ref, &[card.id]) {
                        return Some(HintMove {
                            from: t_ref,
                            to: f_ref,
                            cards: vec![card.id],
                        });
                    }
                }
            }
        }

        // Priority 3: Stock tap
        if !self.piles[0].is_empty() {
            return Some(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: PileRef::new(PileType::Waste, 0),
                cards: vec![],
            });
        }

        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        if cards.len() != 1 {
            return None;
        }

        for f in 0..8 {
            let f_ref = PileRef::new(PileType::Foundation, f);
            if self.is_valid_move(from, f_ref, cards) {
                return Some(f_ref);
            }
        }

        for t in 0..10 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }

        None
    }
}
