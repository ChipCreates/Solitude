use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct TriPeaksGame {
    piles: Vec<Pile>,
    covers: Vec<Vec<usize>>,
    move_count: u32,
    history: History,
}

impl TriPeaksGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        let covers = Self::build_covers();
        Self {
            piles,
            covers,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(30);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        piles.push(Pile::new(PileType::Waste, 0)); // 1
        for i in 0..28 {
            piles.push(Pile::new(PileType::Pyramid, i)); // 2..29
        }
        piles
    }

    fn build_covers() -> Vec<Vec<usize>> {
        let mut covers = vec![vec![]; 28];
        // Row 0: 0, 1, 2
        covers[0] = vec![3, 4];
        covers[1] = vec![5, 6];
        covers[2] = vec![7, 8];
        // Row 1: 3..8
        covers[3] = vec![9, 10];
        covers[4] = vec![10, 11];
        covers[5] = vec![12, 13];
        covers[6] = vec![13, 14];
        covers[7] = vec![15, 16];
        covers[8] = vec![16, 17];
        // Row 2: 9..17
        for i in 0..9 {
            covers[9 + i] = vec![18 + i, 18 + i + 1];
        }
        // Row 3: 18..27 (covers nothing)
        covers
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Pyramid => {
                if r.index < 28 { Some(2 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }

    pub fn is_card_uncovered(&self, p_idx: usize) -> bool {
        if p_idx >= 28 || self.piles[2 + p_idx].is_empty() {
            return false;
        }
        for &c_idx in &self.covers[p_idx] {
            if !self.piles[2 + c_idx].is_empty() {
                return false;
            }
        }
        true
    }

    fn flip_uncovered_cards(&mut self) {
        for i in 0..28 {
            if !self.piles[2 + i].is_empty() && self.is_card_uncovered(i) {
                if let Some(card) = self.piles[2 + i].top_card_mut() {
                    card.face_up = true;
                }
            }
        }
    }
}

impl Default for TriPeaksGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for TriPeaksGame {
    fn snapshot_history(&self) -> History {
        self.history.clone()
    }
    fn restore_history(&mut self, history: History) {
        self.history = history;
    }

    fn heuristic_score(&self) -> i32 {
        let mut score = 1000;
        for pile in self.piles() {
            if pile.kind == crate::pile::PileType::Pyramid {
                score -= (pile.len() as i32) * 50;
                for card in pile.cards() {
                    if card.face_up {
                        score += 10;
                    }
                }
            }
        }
        score
    }
    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, 0)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
    }
    fn game_type(&self) -> GameType {
        GameType::TriPeaks
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

        // Deal 28 cards to peaks (18 face down, 10 face up on bottom row 18..27)
        for i in 0..28 {
            let mut card = deck.draw().unwrap();
            card.face_up = i >= 18;
            self.piles[2 + i].add_card(card);
        }

        // Deal 1 card to waste to start
        if let Some(mut card) = deck.draw() {
            card.face_up = true;
            self.piles[1].add_card(card);
        }

        // Remaining 23 cards to stock
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.len() != 1 || from == to || to.kind != PileType::Waste || from.kind != PileType::Pyramid {
            return false;
        }

        let p_idx = from.index as usize;
        if !self.is_card_uncovered(p_idx) {
            return false;
        }

        let moving_card = match self.piles[2 + p_idx].top_card() {
            Some(c) if c.id == cards[0] => c,
            _ => return false,
        };

        let waste_top = match self.piles[1].top_card() {
            Some(c) => c,
            None => return false,
        };

        let diff = (moving_card.rank.value() as i32 - waste_top.rank.value() as i32).abs();
        diff == 1 || diff == 12
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal TriPeaks move".into()));
        }

        self.history.push(self.snapshot());

        let p_idx = from.index as usize;
        let card = self.piles[2 + p_idx].remove_top().unwrap();
        self.piles[1].add_card(card);

        self.flip_uncovered_cards();
        self.move_count += 1;

        Ok(Move::new(from, to, cards.to_vec()))
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
        (2..30).all(|i| self.piles[i].is_empty())
    }

    fn is_lost(&self) -> bool {
        if !self.piles[0].is_empty() {
            return false;
        }
        let waste_top = match self.piles[1].top_card() {
            Some(c) => c,
            None => return true,
        };
        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let card = self.piles[2 + i].top_card().unwrap();
                let diff = (card.rank.value() as i32 - waste_top.rank.value() as i32).abs();
                if diff == 1 || diff == 12 {
                    return false;
                }
            }
        }
        true
    }

    fn can_tap_stock(&self) -> bool {
        !self.piles[0].is_empty()
    }

    fn get_available_moves(&self) -> Vec<HintMove> {
        let mut moves = Vec::new();
        let discard_ref = PileRef::new(PileType::Discard, 0);

        if let Some(waste_top) = self.piles[1].top_card() {
            for i in 0..28 {
                if self.is_card_uncovered(i) {
                    let card = self.piles[2 + i].top_card().unwrap();
                    let diff = (card.rank.value() as i32 - waste_top.rank.value() as i32).abs();
                    if diff == 1 || diff == 12 {
                        moves.push(HintMove {
                            from: PileRef::new(PileType::Pyramid, i as u8),
                            to: discard_ref,
                            cards: vec![card.id],
                        });
                    }
                }
            }
        }

        if self.can_tap_stock() {
            moves.push(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: PileRef::new(PileType::Waste, 0),
                cards: vec![],
            });
        }

        moves
    }

    fn get_hint(&self) -> Option<HintMove> {
        let waste_top = self.piles[1].top_card()?;
        for i in 0..28 {
            if self.is_card_uncovered(i) {
                let card = self.piles[2 + i].top_card().unwrap();
                let diff = (card.rank.value() as i32 - waste_top.rank.value() as i32).abs();
                if diff == 1 || diff == 12 {
                    return Some(HintMove {
                        from: PileRef::new(PileType::Pyramid, i as u8),
                        to: PileRef::new(PileType::Waste, 0),
                        cards: vec![card.id],
                    });
                }
            }
        }

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
        let waste_ref = PileRef::new(PileType::Waste, 0);
        if self.is_valid_move(from, waste_ref, cards) {
            Some(waste_ref)
        } else {
            None
        }
    }
}
