use crate::card::{CardId, Rank, Suit};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct SpiderGame {
    piles: Vec<Pile>,
    number_of_suits: u8, // 1, 2, or 4
    move_count: u32,
    history: History,
}

impl SpiderGame {
    pub fn new(number_of_suits: u8) -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            number_of_suits,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(19);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        for i in 0..8 {
            piles.push(Pile::new(PileType::Foundation, i)); // 1..8
        }
        for i in 0..10 {
            piles.push(Pile::new(PileType::Tableau, i)); // 9..18
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Foundation => {
                if r.index < 8 { Some(1 + r.index as usize) } else { None }
            }
            PileType::Tableau => {
                if r.index < 10 { Some(9 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }

    fn is_valid_same_suit_sequence(cards: &[&crate::card::Card]) -> bool {
        if cards.len() <= 1 {
            return true;
        }
        for i in 1..cards.len() {
            let prev = cards[i - 1];
            let curr = cards[i];
            if !prev.face_up || !curr.face_up || curr.suit != prev.suit || curr.rank.value() + 1 != prev.rank.value() {
                return false;
            }
        }
        true
    }

    fn check_and_remove_completed_sequences(&mut self) {
        for t in 0..10 {
            let t_idx = 9 + t;
            if self.piles[t_idx].len() < 13 {
                continue;
            }
            let len = self.piles[t_idx].len();
            let start = len - 13;
            let cards: Vec<_> = self.piles[t_idx].cards()[start..].iter().collect();

            if cards.first().map(|c| c.rank) == Some(Rank::King)
                && cards.last().map(|c| c.rank) == Some(Rank::Ace)
                && Self::is_valid_same_suit_sequence(&cards)
            {
                // Find empty foundation
                for f in 1..=8 {
                    if self.piles[f].is_empty() {
                        let completed = self.piles[t_idx].remove_from(start);
                        self.piles[f].add_cards(completed);
                        if let Some(top) = self.piles[t_idx].top_card_mut() {
                            top.face_up = true;
                        }
                        break;
                    }
                }
            }
        }
    }
}

impl Default for SpiderGame {
    fn default() -> Self {
        Self::new(4)
    }
}

impl GameRules for SpiderGame {
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
        GameType::Spider
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

        let mut deck = Deck::new(2);
        deck.shuffle(seed);

        // Remap suits based on number_of_suits setting
        let suits_to_use = match self.number_of_suits {
            1 => vec![Suit::Spades],
            2 => vec![Suit::Spades, Suit::Hearts],
            _ => vec![Suit::Spades, Suit::Hearts, Suit::Diamonds, Suit::Clubs],
        };

        let mut card_count = 0;

        // Deal to 10 tableau columns
        // Piles 0..3 get 6 cards, Piles 4..9 get 5 cards
        for col in 0..10 {
            let count = if col < 4 { 6 } else { 5 };
            for j in 0..count {
                let mut card = deck.draw().unwrap();
                card.suit = suits_to_use[card_count % suits_to_use.len()];
                card.face_up = j == count - 1;
                self.piles[9 + col].add_card(card);
                card_count += 1;
            }
        }

        // Remaining 50 cards to stock (face down)
        while let Some(mut card) = deck.draw() {
            card.suit = suits_to_use[card_count % suits_to_use.len()];
            card.face_up = false;
            self.piles[0].add_card(card);
            card_count += 1;
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.is_empty() || from == to || from.kind != PileType::Tableau || to.kind != PileType::Tableau {
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
        let first_id = cards[0];

        let start_pos = match from_pile.cards().iter().position(|c| c.id == first_id) {
            Some(p) => p,
            None => return false,
        };

        let moving_cards: Vec<_> = from_pile.cards()[start_pos..].iter().collect();
        if moving_cards.len() != cards.len() {
            return false;
        }

        if !Self::is_valid_same_suit_sequence(&moving_cards) {
            return false;
        }

        let to_pile = &self.piles[to_idx];
        if to_pile.is_empty() {
            return true;
        } else {
            let top_card = to_pile.top_card().unwrap();
            let first_moving = moving_cards[0];
            return first_moving.rank.value() + 1 == top_card.rank.value();
        }
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal Spider move".into()));
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

        if let Some(top) = self.piles[from_idx].top_card_mut() {
            top.face_up = true;
        }

        self.check_and_remove_completed_sequences();
        self.move_count += 1;

        Ok(Move::new(from, to, cards.to_vec()))
    }
    fn can_tap_stock(&self) -> bool {
        if self.piles[0].is_empty() {
            return false;
        }
        // Spider rule: all tableau columns must be non-empty to deal
        for t in 0..10 {
            if self.piles[9 + t].is_empty() {
                return false;
            }
        }
        true
    }

    fn tap_stock(&mut self) -> Result<Option<Move>, EngineError> {
        if self.piles[0].is_empty() {
            return Ok(None);
        }

        // Spider rule: all tableau columns must be non-empty to deal
        for t in 0..10 {
            if self.piles[9 + t].is_empty() {
                return Err(EngineError::InvalidMove(
                    "Cannot deal from stock while tableau has empty columns".into(),
                ));
            }
        }

        self.history.push(self.snapshot());

        let mut drawn_ids = Vec::new();
        for t in 0..10 {
            if let Some(mut card) = self.piles[0].remove_top() {
                card.face_up = true;
                drawn_ids.push(card.id);
                self.piles[9 + t].add_card(card);
            }
        }

        self.check_and_remove_completed_sequences();
        self.move_count += 1;

        Ok(Some(
            Move::new(PileRef::new(PileType::Stock, 0), PileRef::new(PileType::Tableau, 0), drawn_ids)
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
        (1..=8).all(|f| !self.piles[f].is_empty())
    }

    fn is_lost(&self) -> bool {
        false
    }

    fn get_hint(&self) -> Option<HintMove> {
        for from_t in 0..10 {
            let from_ref = PileRef::new(PileType::Tableau, from_t);
            let pile = &self.piles[9 + from_t as usize];
            if pile.is_empty() {
                continue;
            }

            for start_pos in 0..pile.len() {
                if !pile.cards()[start_pos].face_up {
                    continue;
                }
                let cards_ref: Vec<_> = pile.cards()[start_pos..].iter().collect();
                if !Self::is_valid_same_suit_sequence(&cards_ref) {
                    continue;
                }

                let card_ids: Vec<_> = cards_ref.iter().map(|c| c.id).collect();

                for to_t in 0..10 {
                    if from_t == to_t {
                        continue;
                    }
                    let to_ref = PileRef::new(PileType::Tableau, to_t);
                    if self.is_valid_move(from_ref, to_ref, &card_ids) {
                        return Some(HintMove {
                            from: from_ref,
                            to: to_ref,
                            cards: card_ids,
                        });
                    }
                }
            }
        }

        if !self.piles[0].is_empty() && (0..10).all(|t| !self.piles[9 + t].is_empty()) {
            return Some(HintMove {
                from: PileRef::new(PileType::Stock, 0),
                to: PileRef::new(PileType::Tableau, 0),
                cards: vec![],
            });
        }

        None
    }

    fn find_best_auto_move_destination(&self, from: PileRef, cards: &[CardId]) -> Option<PileRef> {
        for t in 0..10 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if t_ref != from && self.is_valid_move(from, t_ref, cards) {
                return Some(t_ref);
            }
        }
        None
    }
}
