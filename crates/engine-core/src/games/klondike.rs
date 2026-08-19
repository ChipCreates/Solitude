use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::{Move, MoveExtra};
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DrawMode {
    One = 1,
    Three = 3,
}

#[derive(Debug, Clone)]
pub struct KlondikeGame {
    draw_mode: DrawMode,
    max_stock_recycles: Option<u32>,
    stock_recycle_count: u32,
    piles: Vec<Pile>,
    move_count: u32,
    history: History,
}

impl KlondikeGame {
    pub fn new(draw_mode: DrawMode, max_stock_recycles: Option<u32>) -> Self {
        let piles = Self::create_piles();
        Self {
            draw_mode,
            max_stock_recycles,
            stock_recycle_count: 0,
            piles,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(13);
        piles.push(Pile::new(PileType::Stock, 0));
        piles.push(Pile::new(PileType::Waste, 0));
        for i in 0..4 {
            piles.push(Pile::new(PileType::Foundation, i));
        }
        for i in 0..7 {
            piles.push(Pile::new(PileType::Tableau, i));
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Foundation => {
                if r.index < 4 {
                    Some(2 + r.index as usize)
                } else {
                    None
                }
            }
            PileType::Tableau => {
                if r.index < 7 {
                    Some(6 + r.index as usize)
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    pub fn can_recycle_stock(&self) -> bool {
        if let Some(max) = self.max_stock_recycles {
            self.stock_recycle_count < max
        } else {
            true
        }
    }
}

impl GameRules for KlondikeGame {
    fn snapshot_history(&self) -> History {
        self.history.clone()
    }
    fn restore_history(&mut self, history: History) {
        self.history = history;
    }


    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, self.stock_recycle_count)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
        self.stock_recycle_count = snapshot.stock_recycle_count;
    }
    fn game_type(&self) -> GameType {
        GameType::Klondike
    }

    fn deck_size(&self) -> usize {
        52
    }

    fn piles(&self) -> &[Pile] {
        &self.piles
    }
    fn piles_mut(&mut self) -> &mut Vec<Pile> {
        &mut self.piles
    }

    fn initialize(&mut self, seed: u64) {
        self.piles = Self::create_piles();
        self.move_count = 0;
        self.stock_recycle_count = 0;
        self.history.clear();

        let mut deck = Deck::new(1);
        deck.shuffle(seed);

        // Triangular deal: tableau column i gets i+1 cards
        for i in 0..7 {
            for j in i..7 {
                let mut card = deck.draw().unwrap();
                card.face_up = j == i; // Only top card is face-up
                let pile_idx = 6 + j;
                self.piles[pile_idx].add_card(card);
            }
        }

        // Remaining cards go to stock (face down)
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.is_empty() {
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

        // Find moving card in from_pile
        let first_card_id = cards[0];
        let moving_card = match from_pile.cards().iter().find(|c| c.id == first_card_id) {
            Some(c) => c,
            None => return false,
        };

        if !moving_card.face_up {
            return false;
        }

        if to.kind == PileType::Foundation {
            if cards.len() > 1 {
                return false;
            }
            return moving_card.can_stack_on_foundation(to_pile.top_card());
        }

        if to.kind == PileType::Tableau {
            if to_pile.is_empty() {
                return moving_card.rank == Rank::King;
            }
            if let Some(target) = to_pile.top_card() {
                return moving_card.can_stack_on(target, true, true);
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
            return Err(EngineError::InvalidMove("Illegal move".into()));
        }

        self.history.push(self.snapshot());

        let from_idx = self.get_pile_idx(from).unwrap();
        let to_idx = self.get_pile_idx(to).unwrap();

        let card_pos = self.piles[from_idx]
            .cards()
            .iter()
            .position(|c| c.id == cards[0])
            .unwrap();

        let will_flip = if from.kind == PileType::Tableau && card_pos > 0 {
            !self.piles[from_idx].card_at(card_pos - 1).unwrap().face_up
        } else {
            false
        };

        let moved_cards = self.piles[from_idx].remove_from(card_pos);
        self.piles[to_idx].add_cards(moved_cards);

        if will_flip {
            self.piles[from_idx].flip_top_card();
        }

        self.move_count += 1;

        Ok(Move::new(from, to, cards.to_vec()).with_flipped_card(will_flip))
    }

    fn can_tap_stock(&self) -> bool {
        !self.piles[0].is_empty() || (!self.piles[1].is_empty() && self.can_recycle_stock())
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        self.history.push(self.snapshot());

        if self.piles[0].is_empty() {
            if self.piles[1].is_empty() || !self.can_recycle_stock() {
                return Ok(None);
            }

            let waste_cards = self.piles[1].remove_all();
            for mut card in waste_cards.into_iter().rev() {
                card.face_up = false;
                self.piles[0].add_card(card);
            }

            self.stock_recycle_count += 1;
            self.move_count += 1;

            return Ok(Some(
                Move::new(PileRef::new(PileType::Waste, 0), PileRef::new(PileType::Stock, 0), vec![])
                    .with_stock_draw(true)
                    .with_extra(MoveExtra::StockRecycle {
                        recycle_count: self.stock_recycle_count,
                    }),
            ));
        }

        let draw_count = self.draw_mode as usize;
        let mut drawn_ids = Vec::new();

        for _ in 0..draw_count {
            if let Some(mut card) = self.piles[0].remove_top() {
                card.face_up = true;
                drawn_ids.push(card.id);
                self.piles[1].add_card(card);
            }
        }

        self.move_count += 1;

        Ok(Some(
            Move::new(PileRef::new(PileType::Stock, 0), PileRef::new(PileType::Waste, 0), drawn_ids)
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
        // Win when all 4 foundations have 13 cards each
        (2..6).all(|i| self.piles[i].len() == 13)
    }

    fn is_lost(&self) -> bool {
        if !self.piles[0].is_empty() {
            return false;
        }

        // Check if waste top card can move
        if let Some(waste_card) = self.piles[1].top_card() {
            for i in 2..6 {
                if waste_card.can_stack_on_foundation(self.piles[i].top_card()) {
                    return false;
                }
            }
            for i in 6..13 {
                if self.piles[i].is_empty() {
                    if waste_card.rank == Rank::King {
                        return false;
                    }
                } else if waste_card.can_stack_on(self.piles[i].top_card().unwrap(), true, true) {
                    return false;
                }
            }
        }

        // Check tableau progress moves: can any column's top card advance a
        // foundation? Bug fix: this used to only look at columns with
        // exactly one face-up card (`face_up_cards.len() == 1`), so any
        // column with two or more face-up cards was skipped entirely --
        // its top card was never checked even when it could legally go
        // straight to a foundation. That silently declared a still-winnable
        // board "lost".
        for i in 6..13 {
            if let Some(top) = self.piles[i].top_card() {
                for f in 2..6 {
                    if top.can_stack_on_foundation(self.piles[f].top_card()) {
                        return false;
                    }
                }
            }
        }

        true
    }

    fn get_hint(&self) -> Option<HintMove> {
        // Priority 1: Waste -> Foundation
        if let Some(waste_card) = self.piles[1].top_card() {
            for f in 0..4 {
                if waste_card.can_stack_on_foundation(self.piles[2 + f].top_card()) {
                    return Some(HintMove {
                        from: PileRef::new(PileType::Waste, 0),
                        to: PileRef::new(PileType::Foundation, f as u8),
                        cards: vec![waste_card.id],
                    });
                }
            }
        }

        // Priority 2: Tableau -> Foundation
        for t in 0..7 {
            if let Some(top_card) = self.piles[6 + t].top_card() {
                for f in 0..4 {
                    if top_card.can_stack_on_foundation(self.piles[2 + f].top_card()) {
                        return Some(HintMove {
                            from: PileRef::new(PileType::Tableau, t as u8),
                            to: PileRef::new(PileType::Foundation, f as u8),
                            cards: vec![top_card.id],
                        });
                    }
                }
            }
        }

        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        if cards.is_empty() {
            return None;
        }

        let from_idx = self.get_pile_idx(from)?;
        let card = self.piles[from_idx].cards().iter().find(|c| c.id == cards[0])?;

        // Priority 1: Foundation
        if cards.len() == 1 {
            for f in 0..4 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(from, f_ref, cards) {
                    return Some(f_ref);
                }
            }
        }

        // Priority 2: Non-empty Tableau
        for t in 0..7 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && !self.piles[6 + t as usize].is_empty() && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }

        // Priority 3: Empty Tableau (for Kings)
        if card.rank == Rank::King {
            for t in 0..7 {
                let t_ref = PileRef::new(PileType::Tableau, t);
                if t_ref != from && self.piles[6 + t as usize].is_empty() && self.is_valid_move(from, t_ref, cards) {
                    return Some(t_ref);
                }
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_klondike_initialization() {
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(42);

        // 7 tableau piles have 1, 2, 3, 4, 5, 6, 7 cards (sum = 28)
        let tableau_count: usize = (0..7).map(|i| game.piles()[6 + i].len()).sum();
        assert_eq!(tableau_count, 28);

        // Stock has 24 cards (52 - 28)
        assert_eq!(game.piles()[0].len(), 24);
        assert_eq!(game.piles()[1].len(), 0); // Waste empty
    }

    #[test]
    fn test_klondike_tap_stock() {
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(42);

        let move_res = game.tap_stock().unwrap();
        assert!(move_res.is_some());
        assert_eq!(game.piles()[0].len(), 23);
        assert_eq!(game.piles()[1].len(), 1);
    }

    #[test]
    fn test_is_lost_checks_top_card_of_multi_face_up_columns() {
        use crate::card::{Card, CardId, Rank, Suit};

        // Regression test: is_lost() used to only check a tableau column's
        // top card for a foundation move when that column had EXACTLY one
        // face-up card, silently skipping any column with two or more --
        // so a column whose top card could legally advance a foundation
        // was still declared "lost" as long as anything face-down sat
        // beneath the face-up run.
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(1); // real deal, then overwritten below

        // Stock and Waste empty, all foundations empty -> only the tableau
        // check can report "not lost".
        game.piles[0].clear(); // Stock
        game.piles[1].clear(); // Waste
        for f in 2..6 {
            game.piles[f].clear();
        }
        for t in 6..13 {
            game.piles[t].clear();
        }

        // Tableau column 0: one face-down card, then two face-up cards with
        // an Ace of Hearts on top -- directly playable to the empty Hearts
        // foundation, but only reachable via this column's *top* card, and
        // face_up_cards.len() == 2 here (the exact case the old code
        // skipped).
        game.piles[6].add_card(Card::new(Suit::Spades, Rank::King, CardId(0), false));
        game.piles[6].add_card(Card::new(Suit::Clubs, Rank::Three, CardId(1), true));
        game.piles[6].add_card(Card::new(Suit::Hearts, Rank::Ace, CardId(2), true));

        assert!(
            !game.is_lost(),
            "a column with 2+ face-up cards whose top card can reach an empty foundation must not be reported as lost"
        );
    }
}
