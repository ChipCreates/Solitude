use crate::card::{Card, CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::{Move, MoveExtra};
use crate::pile::{Pile, PileRef, PileType};
use std::cmp::max;

#[derive(Debug, Clone)]
pub struct FreeCellGame {
    piles: Vec<Pile>,
    move_count: u32,
    history: History,
}

impl FreeCellGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(16);
        for i in 0..4 {
            piles.push(Pile::new(PileType::Cell, i)); // 0..3
        }
        for i in 0..4 {
            piles.push(Pile::new(PileType::Foundation, i)); // 4..7
        }
        for i in 0..8 {
            piles.push(Pile::new(PileType::Tableau, i)); // 8..15
        }
        piles
    }

    pub fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Cell => {
                if r.index < 4 {
                    Some(r.index as usize)
                } else {
                    None
                }
            }
            PileType::Foundation => {
                if r.index < 4 {
                    Some(4 + r.index as usize)
                } else {
                    None
                }
            }
            PileType::Tableau => {
                if r.index < 8 {
                    Some(8 + r.index as usize)
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    /// Calculate the maximum number of cards that can be moved as a group (Supermove formula).
    /// Formula: (empty_cells + 1) * 2^(empty_cols)
    pub fn max_moveable_cards(&self, moving_to_empty_col: bool) -> usize {
        let empty_cells = (0..4).filter(|&i| self.piles[i].is_empty()).count();
        let mut empty_cols = (8..16).filter(|&i| self.piles[i].is_empty()).count();

        if moving_to_empty_col && empty_cols > 0 {
            empty_cols -= 1;
        }

        (empty_cells + 1) * (1 << empty_cols)
    }

    /// Verify if a sequence of cards forms a valid descending alternating-color sequence.
    fn is_valid_sequence(cards: &[&Card]) -> bool {
        if cards.len() <= 1 {
            return true;
        }
        for i in 1..cards.len() {
            let prev = cards[i - 1];
            let curr = cards[i];
            if curr.suit.is_red() == prev.suit.is_red() || curr.rank.value() != prev.rank.value() - 1 {
                return false;
            }
        }
        true
    }

    /// Check if a card can safely be auto-moved to foundation without destroying potential tableau stacks.
    fn is_safe_to_auto_move(&self, card: &Card) -> bool {
        if card.rank.value() <= 2 {
            return true;
        }

        let mut min_red_foundation = 0;
        let mut min_black_foundation = 0;

        for f in 4..8 {
            if let Some(top) = self.piles[f].top_card() {
                if top.suit.is_red() {
                    min_red_foundation = max(min_red_foundation, top.rank.value());
                } else {
                    min_black_foundation = max(min_black_foundation, top.rank.value());
                }
            }
        }

        if card.suit.is_red() {
            min_black_foundation >= card.rank.value() - 1
        } else {
            min_red_foundation >= card.rank.value() - 1
        }
    }
}

impl Default for FreeCellGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for FreeCellGame {
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
        GameType::FreeCell
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
        self.history.clear();

        let mut deck = Deck::new(1);
        deck.shuffle(seed);

        // Deal 52 cards to 8 tableau columns (all face up)
        // First 4 piles get 7 cards, last 4 piles get 6 cards
        let mut col = 0;
        while let Some(mut card) = deck.draw() {
            card.face_up = true;
            self.piles[8 + col].add_card(card);
            col = (col + 1) % 8;
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

        let from_pile = &self.piles[from_idx];
        let to_pile = &self.piles[to_idx];

        let start_pos = match from_pile.cards().iter().position(|c| c.id == cards[0]) {
            Some(p) => p,
            None => return false,
        };

        let moving_cards: Vec<&Card> = from_pile.cards()[start_pos..].iter().collect();
        if moving_cards.len() != cards.len() {
            return false;
        }

        let moving_first = moving_cards[0];

        match to.kind {
            PileType::Cell => {
                cards.len() == 1 && to_pile.is_empty()
            }
            PileType::Foundation => {
                cards.len() == 1 && moving_first.can_stack_on_foundation(to_pile.top_card())
            }
            PileType::Tableau => {
                if !Self::is_valid_sequence(&moving_cards) {
                    return false;
                }

                let max_moveable = self.max_moveable_cards(to_pile.is_empty());
                if cards.len() > max_moveable {
                    return false;
                }

                if to_pile.is_empty() {
                    true
                } else if let Some(target) = to_pile.top_card() {
                    moving_first.can_stack_on(target, true, true)
                } else {
                    false
                }
            }
            _ => false,
        }
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal FreeCell move".into()));
        }

        self.history.push(self.snapshot());

        let from_idx = self.get_pile_idx(from).unwrap();
        let to_idx = self.get_pile_idx(to).unwrap();

        let start_pos = self.piles[from_idx]
            .cards()
            .iter()
            .position(|c| c.id == cards[0])
            .unwrap();

        let removed = self.piles[from_idx].remove_from(start_pos);
        self.piles[to_idx].add_cards(removed);

        self.move_count += 1;

        let extra = if cards.len() > 1 && to.kind == PileType::Tableau {
            MoveExtra::FreecellSupermove {
                cells_used: 0,
                columns_used: 0,
            }
        } else {
            MoveExtra::None
        };

        Ok(Move::new(from, to, cards.to_vec()).with_extra(extra))
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        Ok(None) // No stock in FreeCell
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
        (4..8).all(|i| self.piles[i].len() == 13)
    }

    fn is_lost(&self) -> bool {
        if self.check_win() {
            return false;
        }

        // Check if any freecell card can move to foundation or tableau
        for c in 0..4 {
            if let Some(top) = self.piles[c].top_card() {
                let cell_ref = PileRef::new(PileType::Cell, c as u8);
                // Foundation check
                for f in 0..4 {
                    let f_ref = PileRef::new(PileType::Foundation, f);
                    if self.is_valid_move(cell_ref, f_ref, &[top.id]) {
                        return false;
                    }
                }
                // Tableau check
                for t in 0..8 {
                    let t_ref = PileRef::new(PileType::Tableau, t);
                    if self.is_valid_move(cell_ref, t_ref, &[top.id]) {
                        return false;
                    }
                }
            }
        }

        // Check if any tableau card sequence can move
        for t in 0..8 {
            let from_ref = PileRef::new(PileType::Tableau, t as u8);
            let pile = &self.piles[8 + t];
            if pile.is_empty() {
                continue;
            }

            for pos in 0..pile.len() {
                let cards_to_move: Vec<CardId> = pile.cards()[pos..].iter().map(|c| c.id).collect();

                // FreeCell move (single card)
                if cards_to_move.len() == 1 {
                    for cell in 0..4 {
                        let cell_ref = PileRef::new(PileType::Cell, cell);
                        if self.is_valid_move(from_ref, cell_ref, &cards_to_move) {
                            return false;
                        }
                    }
                    for f in 0..4 {
                        let f_ref = PileRef::new(PileType::Foundation, f);
                        if self.is_valid_move(from_ref, f_ref, &cards_to_move) {
                            return false;
                        }
                    }
                }

                // Tableau move
                for t_dest in 0..8 {
                    if t_dest != t {
                        let dest_ref = PileRef::new(PileType::Tableau, t_dest as u8);
                        if self.is_valid_move(from_ref, dest_ref, &cards_to_move) {
                            return false;
                        }
                    }
                }
            }
        }

        true
    }

    fn get_hint(&self) -> Option<HintMove> {
        // Priority 1: FreeCell to Foundation
        for c in 0..4 {
            if let Some(top) = self.piles[c].top_card() {
                let cell_ref = PileRef::new(PileType::Cell, c as u8);
                for f in 0..4 {
                    let f_ref = PileRef::new(PileType::Foundation, f);
                    if self.is_valid_move(cell_ref, f_ref, &[top.id]) {
                        return Some(HintMove {
                            from: cell_ref,
                            to: f_ref,
                            cards: vec![top.id],
                        });
                    }
                }
            }
        }

        // Priority 2: Tableau to Foundation
        for t in 0..8 {
            if let Some(top) = self.piles[8 + t].top_card() {
                let t_ref = PileRef::new(PileType::Tableau, t as u8);
                for f in 0..4 {
                    let f_ref = PileRef::new(PileType::Foundation, f);
                    if self.is_valid_move(t_ref, f_ref, &[top.id]) {
                        return Some(HintMove {
                            from: t_ref,
                            to: f_ref,
                            cards: vec![top.id],
                        });
                    }
                }
            }
        }

        // Priority 3: Tableau to non-empty Tableau
        for t_src in 0..8 {
            let src_ref = PileRef::new(PileType::Tableau, t_src as u8);
            let pile = &self.piles[8 + t_src];
            if pile.is_empty() {
                continue;
            }

            for pos in 0..pile.len() {
                let cards_to_move: Vec<CardId> = pile.cards()[pos..].iter().map(|c| c.id).collect();
                for t_dest in 0..8 {
                    if t_dest != t_src && !self.piles[8 + t_dest].is_empty() {
                        let dest_ref = PileRef::new(PileType::Tableau, t_dest as u8);
                        if self.is_valid_move(src_ref, dest_ref, &cards_to_move) {
                            return Some(HintMove {
                                from: src_ref,
                                to: dest_ref,
                                cards: cards_to_move,
                            });
                        }
                    }
                }
            }
        }

        // Priority 4: FreeCell to Tableau
        for c in 0..4 {
            if let Some(top) = self.piles[c].top_card() {
                let cell_ref = PileRef::new(PileType::Cell, c as u8);
                for t in 0..8 {
                    let t_ref = PileRef::new(PileType::Tableau, t as u8);
                    if self.is_valid_move(cell_ref, t_ref, &[top.id]) {
                        return Some(HintMove {
                            from: cell_ref,
                            to: t_ref,
                            cards: vec![top.id],
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

        // Priority 1: Ace to empty foundation
        if card.rank == Rank::Ace {
            for f in 0..4 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(from, f_ref, cards) {
                    return Some(f_ref);
                }
            }
        }

        // Priority 2: Safe foundation move
        if cards.len() == 1 && self.is_safe_to_auto_move(card) {
            for f in 0..4 {
                let f_ref = PileRef::new(PileType::Foundation, f);
                if self.is_valid_move(from, f_ref, cards) {
                    return Some(f_ref);
                }
            }
        }

        // Priority 3: Non-empty tableau
        for t in 0..8 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && !self.piles[8 + t as usize].is_empty() && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }

        // Priority 4: Empty tableau
        for t in 0..8 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && self.piles[8 + t as usize].is_empty() && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }

        // Priority 5: Empty FreeCell (single cards)
        if cards.len() == 1 {
            for c in 0..4 {
                let cell_ref = PileRef::new(PileType::Cell, c);
                if self.is_valid_move(from, cell_ref, cards) {
                    return Some(cell_ref);
                }
            }
        }

        None
    }
}
