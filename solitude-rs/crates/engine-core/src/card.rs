use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum Suit {
    Hearts,
    Diamonds,
    Clubs,
    Spades,
}

impl Suit {
    pub const ALL: [Suit; 4] = [Suit::Hearts, Suit::Diamonds, Suit::Clubs, Suit::Spades];

    pub fn is_red(&self) -> bool {
        matches!(self, Suit::Hearts | Suit::Diamonds)
    }

    pub fn is_black(&self) -> bool {
        !self.is_red()
    }

    pub fn name(&self) -> &'static str {
        match self {
            Suit::Hearts => "heart",
            Suit::Diamonds => "diamond",
            Suit::Clubs => "club",
            Suit::Spades => "spade",
        }
    }

    pub fn symbol(&self) -> &'static str {
        match self {
            Suit::Hearts => "♥",
            Suit::Diamonds => "♦",
            Suit::Clubs => "♣",
            Suit::Spades => "♠",
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
#[repr(u8)]
pub enum Rank {
    Ace = 1,
    Two = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    Eight = 8,
    Nine = 9,
    Ten = 10,
    Jack = 11,
    Queen = 12,
    King = 13,
}

impl Rank {
    pub const ALL: [Rank; 13] = [
        Rank::Ace,
        Rank::Two,
        Rank::Three,
        Rank::Four,
        Rank::Five,
        Rank::Six,
        Rank::Seven,
        Rank::Eight,
        Rank::Nine,
        Rank::Ten,
        Rank::Jack,
        Rank::Queen,
        Rank::King,
    ];

    pub fn value(&self) -> u8 {
        *self as u8
    }

    pub fn name(&self) -> &'static str {
        match self {
            Rank::Ace => "1",
            Rank::Jack => "jack",
            Rank::Queen => "queen",
            Rank::King => "king",
            Rank::Two => "2",
            Rank::Three => "3",
            Rank::Four => "4",
            Rank::Five => "5",
            Rank::Six => "6",
            Rank::Seven => "7",
            Rank::Eight => "8",
            Rank::Nine => "9",
            Rank::Ten => "10",
        }
    }

    pub fn display(&self) -> &'static str {
        match self {
            Rank::Ace => "A",
            Rank::Jack => "J",
            Rank::Queen => "Q",
            Rank::King => "K",
            Rank::Two => "2",
            Rank::Three => "3",
            Rank::Four => "4",
            Rank::Five => "5",
            Rank::Six => "6",
            Rank::Seven => "7",
            Rank::Eight => "8",
            Rank::Nine => "9",
            Rank::Ten => "10",
        }
    }
}

/// Unique deterministic identifier for cards across 1 or multiple decks.
/// Formed as `deck_index * 52 + suit_index * 13 + (rank - 1)`.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct CardId(pub u8);

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct Card {
    pub suit: Suit,
    pub rank: Rank,
    pub id: CardId,
    pub face_up: bool,
}

impl Card {
    pub fn new(suit: Suit, rank: Rank, id: CardId, face_up: bool) -> Self {
        Self {
            suit,
            rank,
            id,
            face_up,
        }
    }

    pub fn is_red(&self) -> bool {
        self.suit.is_red()
    }

    pub fn is_black(&self) -> bool {
        self.suit.is_black()
    }

    pub fn value(&self) -> u8 {
        self.rank.value()
    }

    pub fn svg_id(&self) -> String {
        format!("{}_{}", self.suit.name(), self.rank.name())
    }

    pub fn can_stack_on(&self, other: &Card, alternating_colors: bool, descending: bool) -> bool {
        if alternating_colors && self.is_red() == other.is_red() {
            return false;
        }
        if descending && self.value() + 1 != other.value() {
            return false;
        }
        if !descending && self.value() != other.value() + 1 {
            return false;
        }
        true
    }

    pub fn can_stack_on_foundation(&self, top_card: Option<&Card>) -> bool {
        match top_card {
            None => self.rank == Rank::Ace,
            Some(top) => self.suit == top.suit && self.value() == top.value() + 1,
        }
    }

    pub fn is_same_face(&self, other: &Card) -> bool {
        self.suit == other.suit && self.rank == other.rank
    }
}

impl fmt::Display for Card {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}{}", self.rank.display(), self.suit.symbol())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_card_values_and_display() {
        let card = Card::new(Suit::Hearts, Rank::Ace, CardId(0), true);
        assert_eq!(card.value(), 1);
        assert!(card.is_red());
        assert_eq!(card.to_string(), "A♥");
        assert_eq!(card.svg_id(), "heart_1");
    }

    #[test]
    fn test_stacking_rules() {
        let red_five = Card::new(Suit::Hearts, Rank::Five, CardId(4), true);
        let black_six = Card::new(Suit::Spades, Rank::Six, CardId(18), true);
        let red_six = Card::new(Suit::Diamonds, Rank::Six, CardId(31), true);

        // Red 5 can stack on Black 6 (alternating colors, descending)
        assert!(red_five.can_stack_on(&black_six, true, true));
        // Red 5 cannot stack on Red 6 (same color)
        assert!(!red_five.can_stack_on(&red_six, true, true));
    }

    #[test]
    fn test_foundation_rules() {
        let ace_spades = Card::new(Suit::Spades, Rank::Ace, CardId(0), true);
        let two_spades = Card::new(Suit::Spades, Rank::Two, CardId(1), true);
        let two_hearts = Card::new(Suit::Hearts, Rank::Two, CardId(14), true);

        assert!(ace_spades.can_stack_on_foundation(None));
        assert!(!two_spades.can_stack_on_foundation(None));

        assert!(two_spades.can_stack_on_foundation(Some(&ace_spades)));
        assert!(!two_hearts.can_stack_on_foundation(Some(&ace_spades)));
    }
}
