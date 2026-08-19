use crate::card::{Card, CardId, Rank, Suit};
use rand::seq::SliceRandom;
use rand::SeedableRng;
use rand_chacha::ChaCha8Rng;

#[derive(Debug, Clone)]
pub struct Deck {
    cards: Vec<Card>,
}

impl Deck {
    pub fn new(deck_count: u8) -> Self {
        let mut cards = Vec::with_capacity(52 * deck_count as usize);
        let mut id_counter: u8 = 0;

        for _deck in 0..deck_count {
            for suit in Suit::ALL {
                for rank in Rank::ALL {
                    cards.add_card_internal(Card::new(suit, rank, CardId(id_counter), false));
                    id_counter = id_counter.wrapping_add(1);
                }
            }
        }

        Self { cards }
    }

    pub fn shuffle(&mut self, seed: u64) {
        let mut rng = ChaCha8Rng::seed_from_u64(seed);
        self.cards.shuffle(&mut rng);
    }

    pub fn draw(&mut self) -> Option<Card> {
        self.cards.pop()
    }

    pub fn draw_multiple(&mut self, count: usize) -> Vec<Card> {
        let mut drawn = Vec::with_capacity(count.min(self.cards.len()));
        for _ in 0..count {
            if let Some(card) = self.cards.pop() {
                drawn.push(card);
            } else {
                break;
            }
        }
        drawn
    }

    pub fn is_empty(&self) -> bool {
        self.cards.is_empty()
    }

    pub fn len(&self) -> usize {
        self.cards.len()
    }

    pub fn cards(&self) -> &[Card] {
        &self.cards
    }
}

trait VecAddHelper {
    fn add_card_internal(&mut self, card: Card);
}

impl VecAddHelper for Vec<Card> {
    fn add_card_internal(&mut self, card: Card) {
        self.push(card);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_deck_creation() {
        let deck = Deck::new(1);
        assert_eq!(deck.len(), 52);

        let double_deck = Deck::new(2);
        assert_eq!(double_deck.len(), 104);
    }

    #[test]
    fn test_shuffle_determinism() {
        let mut deck1 = Deck::new(1);
        let mut deck2 = Deck::new(1);

        deck1.shuffle(12345);
        deck2.shuffle(12345);

        assert_eq!(deck1.cards(), deck2.cards());
    }

    #[test]
    fn test_draw() {
        let mut deck = Deck::new(1);
        let card = deck.draw();
        assert!(card.is_some());
        assert_eq!(deck.len(), 51);
    }
}
