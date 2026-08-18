use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct ScorpionGame {
    piles: Vec<Pile>,
    move_count: u32,
    completed_suits: u32,
    history: History,
}

impl ScorpionGame {
    pub fn new() -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            move_count: 0,
            completed_suits: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(8);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        for i in 0..7 {
            piles.push(Pile::new(PileType::Tableau, i)); // 1..7
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Tableau => {
                if r.index < 7 { Some(1 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }

    fn check_and_remove_complete_suits(&mut self) {
        for t in 1..=7 {
            let len = self.piles[t].len();
            if len < 13 {
                continue;
            }
            let start = len - 13;
            let cards = self.piles[t].cards();

            if cards[start].rank != Rank::King {
                continue;
            }

            let suit = cards[start].suit;
            let mut is_complete = true;
            for i in 0..13 {
                let card = &cards[start + i];
                if card.suit != suit || card.rank.value() != 13 - (i as u8) {
                    is_complete = false;
                    break;
                }
            }

            if is_complete {
                self.piles[t].remove_from(start);
                self.completed_suits += 1;
            }
        }
    }
}

impl Default for ScorpionGame {
    fn default() -> Self {
        Self::new()
    }
}

impl GameRules for ScorpionGame {
    fn snapshot_history(&self) -> History {
        self.history.clone()
    }
    fn restore_history(&mut self, history: History) {
        self.history = history;
    }

    fn heuristic_score(&self) -> i32 {
        let mut score = (self.completed_suits as i32) * 1300; // Large reward for completing a suit (13 * 100)
        
        for pile in self.piles() {
            if pile.kind == crate::pile::PileType::Tableau {
                for card in pile.cards() {
                    if card.face_up {
                        score += 10;
                    }
                }
                if pile.is_empty() {
                    score += 5;
                }
            }
        }
        score
    }

    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, self.completed_suits)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
        self.completed_suits = snapshot.stock_recycle_count;
    }
    fn game_type(&self) -> GameType {
        GameType::Scorpion
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
        self.completed_suits = 0;
        self.history.clear();

        let mut deck = Deck::new(1);
        deck.shuffle(seed);

        // 49 cards to tableau (7x7)
        for row in 0..7 {
            for col in 0..7 {
                let mut card = deck.draw().unwrap();
                card.face_up = col >= 4 || row >= 3;
                self.piles[1 + col].add_card(card);
            }
        }

        // 3 cards to stock face-down
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.is_empty() || from == to || to.kind != PileType::Tableau {
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

        let first_id = cards[0];
        let start_pos = match from_pile.cards().iter().position(|c| c.id == first_id) {
            Some(p) => p,
            None => return false,
        };

        let moving_card = &from_pile.cards()[start_pos];
        if !moving_card.face_up {
            return false;
        }

        if to_pile.is_empty() {
            return moving_card.rank == Rank::King;
        } else {
            let top = to_pile.top_card().unwrap();
            return moving_card.suit == top.suit && moving_card.rank.value() + 1 == top.rank.value();
        }
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal Scorpion move".into()));
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

        let mut will_flip = false;
        if start_pos > 0 {
            if let Some(c_below) = self.piles[from_idx].card_at(start_pos - 1) {
                if !c_below.face_up {
                    will_flip = true;
                }
            }
        }

        let moved_cards = self.piles[from_idx].remove_from(start_pos);
        self.piles[to_idx].add_cards(moved_cards);

        if will_flip {
            self.piles[from_idx].flip_top_card();
        }

        self.move_count += 1;
        self.check_and_remove_complete_suits();

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

        let mut dealt = Vec::new();
        for col in 0..3 {
            if let Some(mut card) = self.piles[0].remove_top() {
                card.face_up = true;
                dealt.push(card.id);
                self.piles[1 + col].add_card(card);
            }
        }

        self.move_count += 1;
        self.check_and_remove_complete_suits();

        Ok(Some(
            Move::new(PileRef::new(PileType::Stock, 0), PileRef::new(PileType::Tableau, 0), dealt)
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
        self.completed_suits == 4
    }

    fn is_lost(&self) -> bool {
        false
    }

    fn get_hint(&self) -> Option<HintMove> {
        // Priority 1: Expose face-down cards
        for t_idx in 0..7 {
            let pile = &self.piles[1 + t_idx];
            if pile.is_empty() {
                continue;
            }
            if let Some(first_fu) = pile.cards().iter().position(|c| c.face_up) {
                if first_fu > 0 {
                    let p_ref = PileRef::new(PileType::Tableau, t_idx as u8);
                    let cards_to_move: Vec<CardId> =
                        pile.cards()[first_fu..].iter().map(|c| c.id).collect();
                    for to_idx in 0..7 {
                        if to_idx == t_idx {
                            continue;
                        }
                        let to_ref = PileRef::new(PileType::Tableau, to_idx as u8);
                        if self.is_valid_move(p_ref, to_ref, &cards_to_move) {
                            return Some(HintMove {
                                from: p_ref,
                                to: to_ref,
                                cards: cards_to_move,
                            });
                        }
                    }
                }
            }
        }

        // Priority 2: Deal stock
        if !self.piles[0].is_empty() {
            return Some(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: PileRef::new(PileType::Tableau, 0),
                cards: vec![],
            });
        }

        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        for t in 0..7 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }
        None
    }
}
