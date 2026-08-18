use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct CanfieldGame {
    piles: Vec<Pile>,
    base_rank: Option<Rank>,
    move_count: u32,
    history: History,
}

impl CanfieldGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            base_rank: None,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(11);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        piles.push(Pile::new(PileType::Waste, 0)); // 1
        piles.push(Pile::new(PileType::Reserve, 0)); // 2
        for i in 0..4 {
            piles.push(Pile::new(PileType::Foundation, i)); // 3..6
        }
        for i in 0..4 {
            piles.push(Pile::new(PileType::Tableau, i)); // 7..10
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Reserve => Some(2),
            PileType::Foundation => {
                if r.index < 4 { Some(3 + r.index as usize) } else { None }
            }
            PileType::Tableau => {
                if r.index < 4 { Some(7 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }

    fn auto_fill_tableau(&mut self) {
        if self.piles[2].is_empty() {
            return;
        }
        for t in 7..=10 {
            if self.piles[t].is_empty() && !self.piles[2].is_empty() {
                if let Some(mut card) = self.piles[2].remove_top() {
                    card.face_up = true;
                    self.piles[t].add_card(card);
                    if let Some(top_res) = self.piles[2].top_card_mut() {
                        top_res.face_up = true;
                    }
                }
            }
        }
    }
}

impl Default for CanfieldGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for CanfieldGame {

    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, 0)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
    }
    fn game_type(&self) -> GameType {
        GameType::Canfield
    }

    fn deck_size(&self) -> usize {
        52
    }

    fn piles(&self) -> &[Pile] {
        &self.piles
    }

    fn initialize(&mut self, seed: u64) {
        self.piles = Self::create_piles();
        self.move_count = 0;
        self.history.clear();

        let mut deck = Deck::new(1);
        deck.shuffle(seed);

        // 13 cards to reserve (only top card face up)
        for i in 0..13 {
            let mut card = deck.draw().unwrap();
            card.face_up = i == 12;
            self.piles[2].add_card(card);
        }

        // 1 card to Foundation 0 (sets base_rank)
        let mut foundation_card = deck.draw().unwrap();
        foundation_card.face_up = true;
        self.base_rank = Some(foundation_card.rank);
        self.piles[3].add_card(foundation_card);

        // 1 card to each tableau pile
        for t in 0..4 {
            let mut card = deck.draw().unwrap();
            card.face_up = true;
            self.piles[7 + t].add_card(card);
        }

        // Remaining cards to stock
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.is_empty() || from == to {
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

        if to.kind == PileType::Stock || to.kind == PileType::Waste || to.kind == PileType::Reserve {
            return false;
        }

        let from_pile = &self.piles[from_idx];
        let to_pile = &self.piles[to_idx];

        let first_id = cards[0];
        let start_pos = match from_pile.cards().iter().position(|c| c.id == first_id) {
            Some(p) => p,
            None => return false,
        };

        let moving_card = &from_pile.cards()[start_pos];
        if !moving_card.face_up {
            return false;
        }

        // Foundation target
        if to.kind == PileType::Foundation {
            if cards.len() > 1 {
                return false;
            }
            if let Some(top) = to_pile.top_card() {
                if moving_card.suit != top.suit {
                    return false;
                }
                let expected = if top.rank.value() == 13 { 1 } else { top.rank.value() + 1 };
                return moving_card.rank.value() == expected;
            } else {
                return Some(moving_card.rank) == self.base_rank;
            }
        }

        // Tableau target
        if to.kind == PileType::Tableau {
            if to_pile.is_empty() {
                return true;
            } else {
                let top = to_pile.top_card().unwrap();
                if moving_card.suit.is_red() == top.suit.is_red() {
                    return false;
                }
                let expected = if top.rank.value() == 1 { 13 } else { top.rank.value() - 1 };
                return moving_card.rank.value() == expected;
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
            return Err(EngineError::InvalidMove("Illegal Canfield move".into()));
        }

        self.history.push(self.snapshot());

        let from_idx = self.get_pile_idx(from).unwrap();
        let to_idx = self.get_pile_idx(to).unwrap();

        let first_id = cards[0];
        let start_pos = self.piles[from_idx]
            .cards()
            .iter()
            .position(|c| c.id == first_id)
            .unwrap();

        let moved_cards = self.piles[from_idx].remove_from(start_pos);
        self.piles[to_idx].add_cards(moved_cards);

        if from.kind == PileType::Reserve {
            if let Some(top_res) = self.piles[2].top_card_mut() {
                top_res.face_up = true;
            }
        }

        self.move_count += 1;
        self.auto_fill_tableau();

        Ok(Move::new(from, to, cards.to_vec()))
    }
    fn can_tap_stock(&self) -> bool {
        !self.piles[0].is_empty() || !self.piles[1].is_empty()
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        if self.piles[0].is_empty() {
            if self.piles[1].is_empty() {
                return Ok(None);
            }
            // Recycle waste to stock
            self.history.push(self.snapshot());
            let waste_cards = self.piles[1].remove_all();
            let mut ids = Vec::new();
            for mut card in waste_cards.into_iter().rev() {
                card.face_up = false;
                ids.push(card.id);
                self.piles[0].add_card(card);
            }
            self.move_count += 1;
            return Ok(Some(
                Move::new(PileRef::new(PileType::Waste, 0), PileRef::new(PileType::Stock, 0), ids)
                    .with_stock_draw(true),
            ));
        }

        self.history.push(self.snapshot());

        let mut drawn = Vec::new();
        for _ in 0..3 {
            if let Some(mut card) = self.piles[0].remove_top() {
                card.face_up = true;
                drawn.push(card.id);
                self.piles[1].add_card(card);
            }
        }

        self.move_count += 1;

        Ok(Some(
            Move::new(PileRef::new(PileType::Stock, 0), PileRef::new(PileType::Waste, 0), drawn)
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
        (3..7).all(|i| self.piles[i].len() == 13)
    }

    fn is_lost(&self) -> bool {
        false
    }

    fn get_hint(&self) -> Option<HintMove> {
        // Reserve top card to Foundation
        if let Some(card) = self.piles[2].top_card() {
            for f in 0..4 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(PileRef::new(PileType::Reserve, 0), f_ref, &[card.id]) {
                    return Some(HintMove {
                        from: PileRef::new(PileType::Reserve, 0),
                        to: f_ref,
                        cards: vec![card.id],
                    });
                }
            }
        }
        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        if cards.len() == 1 {
            for f in 0..4 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(from, f_ref, cards) {
                    return Some(f_ref);
                }
            }
        }
        for t in 0..4 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }
        None
    }
}
