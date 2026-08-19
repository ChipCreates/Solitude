use crate::card::Card;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum PileType {
    Stock,
    Waste,
    Foundation,
    Tableau,
    Cell,
    Reserve,
    Pyramid,
    Discard,
}

impl PileType {
    pub fn name(&self) -> &'static str {
        match self {
            PileType::Stock => "stock",
            PileType::Waste => "waste",
            PileType::Foundation => "foundation",
            PileType::Tableau => "tableau",
            PileType::Cell => "cell",
            PileType::Reserve => "reserve",
            PileType::Pyramid => "pyramid",
            PileType::Discard => "discard",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct PileRef {
    pub kind: PileType,
    pub index: u8,
}

impl PileRef {
    pub fn new(kind: PileType, index: u8) -> Self {
        Self { kind, index }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Pile {
    pub kind: PileType,
    pub index: u8,
    cards: Vec<Card>,
    version: u64,
}

impl Pile {
    pub fn new(kind: PileType, index: u8) -> Self {
        Self {
            kind,
            index,
            cards: Vec::new(),
            version: 0,
        }
    }

    pub fn id(&self) -> String {
        format!("{}_{}", self.kind.name(), self.index)
    }

    pub fn version(&self) -> u64 {
        self.version
    }

    pub fn cards(&self) -> &[Card] {
        &self.cards
    }

    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    pub fn len(&self) -> usize {
        self.cards.len()
    }

    pub fn top_card(&self) -> Option<&Card> {
        self.cards.last()
    }

    pub fn top_card_mut(&mut self) -> Option<&mut Card> {
        self.cards.last_mut()
    }

    pub fn face_up_cards(&self) -> Vec<&Card> {
        self.cards.iter().filter(|c| c.face_up).collect()
    }

    pub fn face_up_count(&self) -> usize {
        self.cards.iter().filter(|c| c.face_up).count()
    }

    pub fn add_card(&mut self, card: Card) {
        self.cards.push(card);
        self.version += 1;
    }

    pub fn add_cards(&mut self, mut cards: Vec<Card>) {
        self.cards.append(&mut cards);
        self.version += 1;
    }

    pub fn remove_top(&mut self) -> Option<Card> {
        if let Some(card) = self.cards.pop() {
            self.version += 1;
            Some(card)
        } else {
            None
        }
    }

    pub fn remove_from(&mut self, index: usize) -> Vec<Card> {
        if index >= self.cards.len() {
            return Vec::new();
        }
        self.version += 1;
        self.cards.drain(index..).collect()
    }

    pub fn remove_all(&mut self) -> Vec<Card> {
        self.version += 1;
        std::mem::take(&mut self.cards)
    }

    pub fn clear(&mut self) {
        self.cards.clear();
        self.version += 1;
    }

    pub fn card_at(&self, index: usize) -> Option<&Card> {
        self.cards.get(index)
    }

    pub fn flip_top_card(&mut self) -> bool {
        if let Some(card) = self.cards.last_mut() {
            if !card.face_up {
                card.face_up = true;
                self.version += 1;
                return true;
            }
        }
        false
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::card::{CardId, Rank, Suit};

    #[test]
    fn test_pile_mutations_and_versioning() {
        let mut pile = Pile::new(PileType::Tableau, 0);
        assert_eq!(pile.version(), 0);

        let card = Card::new(Suit::Hearts, Rank::Ace, CardId(0), true);
        pile.add_card(card.clone());
        assert_eq!(pile.version(), 1);
        assert_eq!(pile.len(), 1);
        assert_eq!(pile.top_card(), Some(&card));

        let popped = pile.remove_top();
        assert_eq!(popped, Some(card));
        assert_eq!(pile.version(), 2);
        assert!(pile.is_empty());
    }

    #[test]
    fn test_remove_from() {
        let mut pile = Pile::new(PileType::Tableau, 1);
        let c1 = Card::new(Suit::Spades, Rank::Ten, CardId(1), true);
        let c2 = Card::new(Suit::Hearts, Rank::Nine, CardId(2), true);
        let c3 = Card::new(Suit::Clubs, Rank::Eight, CardId(3), true);

        pile.add_cards(vec![c1.clone(), c2.clone(), c3.clone()]);
        assert_eq!(pile.len(), 3);

        let removed = pile.remove_from(1);
        assert_eq!(removed, vec![c2, c3]);
        assert_eq!(pile.len(), 1);
        assert_eq!(pile.top_card(), Some(&c1));
    }
}
