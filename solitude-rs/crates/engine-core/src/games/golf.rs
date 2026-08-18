use crate::card::{CardId, Rank};
use crate::deck::Deck;
use crate::error::EngineError;
use crate::game::{GameRules, GameType, HintMove};
use crate::history::{GameSnapshot, History};
use crate::mv::Move;
use crate::pile::{Pile, PileRef, PileType};

#[derive(Debug, Clone)]
pub struct GolfGame {
    piles: Vec<Pile>,
    allow_wrapping: bool,
    move_count: u32,
    history: History,
}

impl GolfGame {
    pub fn new(allow_wrapping: bool) -> Self {
        let piles = Self::create_piles();
        Self {
            piles,
            allow_wrapping,
            move_count: 0,
            history: History::new(),
        }
    }

    fn create_piles() -> Vec<Pile> {
        let mut piles = Vec::with_capacity(9);
        piles.push(Pile::new(PileType::Stock, 0)); // 0
        piles.push(Pile::new(PileType::Waste, 0)); // 1
        for i in 0..7 {
            piles.push(Pile::new(PileType::Tableau, i)); // 2..8
        }
        piles
    }

    fn get_pile_idx(&self, r: PileRef) -> Option<usize> {
        match r.kind {
            PileType::Stock => Some(0),
            PileType::Waste => Some(1),
            PileType::Tableau => {
                if r.index < 7 { Some(2 + r.index as usize) } else { None }
            }
            _ => None,
        }
    }

    fn can_play_to_waste(&self, rank: Rank, waste_rank: Rank) -> bool {
        let diff = (rank.value() as i32 - waste_rank.value() as i32).abs();
        if self.allow_wrapping {
            diff == 1 || diff == 12
        } else {
            diff == 1
        }
    }
}

impl Default for GolfGame {
    fn default() -> Self {
        Self::new(false)
    }
}

impl GameRules for GolfGame {

    fn snapshot(&self) -> GameSnapshot {
        GameSnapshot::new(self.piles.clone(), self.move_count, 0)
    }

    fn restore(&mut self, snapshot: GameSnapshot) {
        self.piles = snapshot.piles;
        self.move_count = snapshot.move_count;
    }
    fn game_type(&self) -> GameType {
        GameType::Golf
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

        // Deal 5 cards to each of 7 columns (35 cards), all face up
        for col in 0..7 {
            for _ in 0..5 {
                let mut card = deck.draw().unwrap();
                card.face_up = true;
                self.piles[2 + col].add_card(card);
            }
        }

        // 1 card to waste to start
        let mut waste_card = deck.draw().unwrap();
        waste_card.face_up = true;
        self.piles[1].add_card(waste_card);

        // Remaining 16 cards to stock
        while let Some(mut card) = deck.draw() {
            card.face_up = false;
            self.piles[0].add_card(card);
        }
    }

    fn is_valid_move(&self, from: PileRef, to: PileRef, cards: &[CardId]) -> bool {
        if cards.len() != 1 || from == to || to.kind != PileType::Waste || from.kind != PileType::Tableau {
            return false;
        }

        let from_idx = match self.get_pile_idx(from) {
            Some(i) => i,
            None => return false,
        };

        let moving_card = match self.piles[from_idx].top_card() {
            Some(c) if c.id == cards[0] => c,
            _ => return false,
        };

        let waste_top = match self.piles[1].top_card() {
            Some(c) => c,
            None => return false,
        };

        self.can_play_to_waste(moving_card.rank, waste_top.rank)
    }

    fn execute_move(
        &mut self,
        from: PileRef,
        to: PileRef,
        cards: &[CardId],
    ) -> Result<Move, EngineError> {
        if !self.is_valid_move(from, to, cards) {
            return Err(EngineError::InvalidMove("Illegal Golf move".into()));
        }

        self.history.push(self.snapshot());

        let from_idx = self.get_pile_idx(from).unwrap();
        let card = self.piles[from_idx].remove_top().unwrap();
        self.piles[1].add_card(card);

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
        (2..9).all(|i| self.piles[i].is_empty())
    }

    fn is_lost(&self) -> bool {
        if !self.piles[0].is_empty() {
            return false;
        }
        let waste_top = match self.piles[1].top_card() {
            Some(c) => c,
            None => return true,
        };
        for i in 2..9 {
            if let Some(card) = self.piles[i].top_card() {
                if self.can_play_to_waste(card.rank, waste_top.rank) {
                    return false;
                }
            }
        }
        true
    }

    fn get_hint(&self) -> Option<HintMove> {
        let waste_top = self.piles[1].top_card()?;
        for t in 0..7 {
            let t_ref = PileRef::new(PileType::Tableau, t);
            if let Some(card) = self.piles[2 + t as usize].top_card() {
                if self.can_play_to_waste(card.rank, waste_top.rank) {
                    return Some(HintMove {
                        from: t_ref,
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
