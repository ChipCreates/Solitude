use crate::card::{Card, CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::{Move, MoveExtra};
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct PyramidGame {
    piles: Vec<Pile>,
    move_count: u32,
    stock_recycle_count: u32,
    history: History,
}

impl PyramidGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            move_count: 0,
            stock_recycle_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(31);
        piles.push(Pile::new(PileType::Stock, 0));  // 0
        piles.push(Pile::new(PileType::Waste, 0));  // 1
        piles.push(Pile::new(PileType::Discard, 0)); // 2
        for i in 0..28 {
            piles.push(Pile::new(PileType::Pyramid, i)); // 3..30
        }
        piles
    }

    pub fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Discard => Some(2),
            PileType::Pyramid => {
                if r.index < 28 {
                    Some(3 + r.index as usize)
                } else {
                    None
                }
            }
            _ => None,
        }
    }

    /// Convert a pyramid index (0..27) to (row, col).
    pub fn pyramid_pos(index: u8) -> Option<(usize, usize)> {
        if index >= 28 {
            return None;
        }
        for r in 0..7 {
            let start = r * (r + 1) / 2;
            let count = r + 1;
            if (index as usize) >= start && (index as usize) < start + count {
                return Some((r, (index as usize) - start));
            }
        }
        None
    }

    /// Check if a pyramid card is uncovered (can be selected/matched).
    /// Row 6 cards are always uncovered if present.
    /// Row r (< 6) card at (r, c) is uncovered if present AND both children (r+1, c) and (r+1, c+1) are empty.
    pub fn is_card_uncovered(&self, index: u8) -> bool {
        if index >= 28 {
            return false;
        }
        let pile_idx = 3 + index as usize;
        if self.piles[pile_idx].is_empty() {
            return false;
        }

        let (r, c) = match Self::pyramid_pos(index) {
            Some(pos) => pos,
            None => return false,
        };

        if r == 6 {
            return true;
        }

        let next_row_start = (r + 1) * (r + 2) / 2;
        let child_left = next_row_start + c;
        let child_right = next_row_start + c + 1;

        self.piles[3 + child_left].is_empty() && self.piles[3 + child_right].is_empty()
    }

    /// Check if a card is accessible for matching (uncovered in pyramid or top of waste).
    pub fn is_card_accessible(&self, pile_ref: PileRef, card_id: CardId) -> bool {
        let idx = match self.get_pile_idx(pile_ref) {
            Some(i) => i,
            None => return false,
        };

        let pile = &self.piles[idx];
        if pile.is_empty() {
            return false;
        }

        match pile_ref.kind {
            PileType::Waste => pile.top_card().map_or(false, |c| c.id == card_id),
            PileType::Pyramid => {
                self.is_card_uncovered(pile_ref.index) && pile.top_card().map_or(false, |c| c.id == card_id)
            }
            _ => false,
        }
    }

    /// Find which pile (Waste or Pyramid) currently holds the given `card_id` at its accessible top.
    fn find_accessible_card_pile(&self, card_id: CardId) -> Option<PileRef> {
        let waste_ref = PileRef::new(PileType::Waste, 0);
        if self.is_card_accessible(waste_ref, card_id) {
            return Some(waste_ref);
        }

        for i in 0..28 {
            let pyr_ref = PileRef::new(PileType::Pyramid, i);
            if self.is_card_accessible(pyr_ref, card_id) {
                return Some(pyr_ref);
            }
        }

        None
    }
}

impl Default for PyramidGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for PyramidGame {
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
        GameType::Pyramid
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
        self.stock_recycle_count = 0;
        self.history.clear();

        let mut deck = Deck::new(1);
        deck.shuffle(seed);

        // Deal 28 cards to pyramid face up
        for i in 0..28 {
            let mut card = deck.draw().unwrap();
            card.face_up = true;
            self.piles[3 + i].add_card(card);
        }

        // Remaining 24 cards go to stock face down
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.is_empty() || to.kind != PileType::Discard {
            return false;
        }

        if cards.len() == 1 {
            let card_id = cards[0];
            if !self.is_card_accessible(from, card_id) {
                return false;
            }
            let from_idx = match self.get_pile_idx(from) {
                Some(i) => i,
                None => return false,
            };
            let card = match self.piles[from_idx].top_card() {
                Some(c) => c,
                None => return false,
            };
            return card.rank == Rank::King;
        }

        if cards.len() == 2 {
            let c1_id = cards[0];
            let c2_id = cards[1];

            if !self.is_card_accessible(from, c1_id) {
                return false;
            }
            let p2_ref = match self.find_accessible_card_pile(c2_id) {
                Some(r) => r,
                None => return false,
            };

            let p1_idx = self.get_pile_idx(from).unwrap();
            let p2_idx = self.get_pile_idx(p2_ref).unwrap();

            let card1 = self.piles[p1_idx].top_card().unwrap();
            let card2 = self.piles[p2_idx].top_card().unwrap();

            return (card1.rank.value() + card2.rank.value()) == 13;
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
            return Err(EngineError::InvalidMove("Illegal Pyramid move".into()));
        }

        self.history.push(self.snapshot());

        if cards.len() == 1 {
            let from_idx = self.get_pile_idx(from).unwrap();
            let mut card = self.piles[from_idx].remove_top().unwrap();
            card.face_up = true;
            self.piles[2].add_card(card);
            self.move_count += 1;
            return Ok(Move::new(from, to, cards.to_vec()));
        }

        let c1_id = cards[0];
        let c2_id = cards[1];

        let p2_ref = self.find_accessible_card_pile(c2_id).unwrap();

        let p1_idx = self.get_pile_idx(from).unwrap();
        let p2_idx = self.get_pile_idx(p2_ref).unwrap();

        let mut card1 = self.piles[p1_idx].remove_top().unwrap();
        let mut card2 = self.piles[p2_idx].remove_top().unwrap();
        card1.face_up = true;
        card2.face_up = true;

        self.piles[2].add_card(card1);
        self.piles[2].add_card(card2);
        self.move_count += 1;

        Ok(Move::new(from, to, vec![c1_id]).with_extra(MoveExtra::PyramidPair { second_card: c2_id }))
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        self.history.push(self.snapshot());

        if self.piles[0].is_empty() {
            if self.piles[1].is_empty() {
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
        (3..31).all(|i| self.piles[i].is_empty())
    }

    fn is_lost(&self) -> bool {
        if self.check_win() {
            return false;
        }

        if !self.piles[0].is_empty() {
            return false;
        }

        // Collect all accessible cards
        let mut accessible_cards: Vec<(PileRef, &Card)> = Vec::new();
        let waste_ref = PileRef::new(PileType::Waste, 0);
        if let Some(top) = self.piles[1].top_card() {
            accessible_cards.push((waste_ref, top));
        }

        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let pyr_ref = PileRef::new(PileType::Pyramid, i);
                if let Some(top) = self.piles[3 + i as usize].top_card() {
                    accessible_cards.push((pyr_ref, top));
                }
            }
        }

        // Check if any King is accessible
        if accessible_cards.iter().any(|(_, c)| c.rank == Rank::King) {
            return false;
        }

        // Check if any two accessible cards sum to 13
        for i in 0..accessible_cards.len() {
            for j in (i + 1)..accessible_cards.len() {
                if accessible_cards[i].1.rank.value() + accessible_cards[j].1.rank.value() == 13 {
                    return false;
                }
            }
        }

        true
    }

    fn can_tap_stock(&self) -> bool {
        !self.piles[0].is_empty() || (!self.piles[1].is_empty() && self.stock_recycle_count < 2)
    }

    fn get_available_moves(&self) -> Vec<HintMove> {
        let mut moves = Vec::new();
        let discard_ref = PileRef::new(PileType::Discard, 0);

        // Gather all accessible cards (Waste + uncovered Pyramid)
        let mut accessible = Vec::new();
        
        let waste_ref = PileRef::new(PileType::Waste, 0);
        if let Some(w_top) = self.piles[1].top_card() {
            accessible.push((waste_ref, w_top));
        }

        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let pyr_ref = PileRef::new(PileType::Pyramid, i);
                if let Some(top) = self.piles[3 + i as usize].top_card() {
                    accessible.push((pyr_ref, top));
                }
            }
        }

        // Single King moves
        for (pref, card) in &accessible {
            if card.rank == Rank::King {
                moves.push(HintMove {
                    from: *pref,
                    to: discard_ref,
                    cards: vec![card.id],
                });
            }
        }

        // Pair moves
        for i in 0..accessible.len() {
            for j in (i + 1)..accessible.len() {
                if accessible[i].1.rank.value() + accessible[j].1.rank.value() == 13 {
                    moves.push(HintMove {
                        from: accessible[i].0,
                        to: discard_ref,
                        cards: vec![accessible[i].1.id, accessible[j].1.id],
                    });
                }
            }
        }

        if self.can_tap_stock() {
            moves.push(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: waste_ref,
                cards: vec![],
            });
        }

        moves
    }

    fn get_hint(&self) -> Option<HintMove> {
        let discard_ref = PileRef::new(PileType::Discard, 0);

        // Priority 1: Remove Kings from Pyramid
        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let pyr_ref = PileRef::new(PileType::Pyramid, i);
                let top = self.piles[3 + i as usize].top_card().unwrap();
                if top.rank == Rank::King {
                    return Some(HintMove {
                        from: pyr_ref,
                        to: discard_ref,
                        cards: vec![top.id],
                    });
                }
            }
        }

        // Priority 2: Remove King from Waste
        let waste_ref = PileRef::new(PileType::Waste, 0);
        if let Some(w_top) = self.piles[1].top_card() {
            if w_top.rank == Rank::King {
                return Some(HintMove {
                    from: waste_ref,
                    to: discard_ref,
                    cards: vec![w_top.id],
                });
            }
        }

        // Priority 3: Match pairs within Pyramid
        let mut uncovered: Vec<(u8, CardId, u8)> = Vec::new();
        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let top = self.piles[3 + i as usize].top_card().unwrap();
                uncovered.push((i, top.id, top.rank.value()));
            }
        }

        for i in 0..uncovered.len() {
            for j in (i + 1)..uncovered.len() {
                if uncovered[i].2 + uncovered[j].2 == 13 {
                    return Some(HintMove {
                        from: PileRef::new(PileType::Pyramid, uncovered[i].0),
                        to: discard_ref,
                        cards: vec![uncovered[i].1, uncovered[j].1],
                    });
                }
            }
        }

        // Priority 4: Match Waste card with Pyramid
        if let Some(w_top) = self.piles[1].top_card() {
            let w_val = w_top.rank.value();
            for u in &uncovered {
                if w_val + u.2 == 13 {
                    return Some(HintMove {
                        from: waste_ref,
                        to: discard_ref,
                        cards: vec![w_top.id, u.1],
                    });
                }
            }
        }

        // Priority 5: Draw from stock
        if !self.piles[0].is_empty() {
            return Some(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: waste_ref,
                cards: vec![],
            });
        }

        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        let discard_ref = PileRef::new(PileType::Discard, 0);
        if self.is_valid_move(from, discard_ref, cards) {
            Some(discard_ref)
        } else {
            None
        }
    }
}
