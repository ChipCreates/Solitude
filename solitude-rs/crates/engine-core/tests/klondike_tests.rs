#[cfg(test)]
mod tests {
    use engine_core::card::{Card, CardId, Rank, Suit};
    use engine_core::game::GameRules;
    use engine_core::games::klondike::{DrawMode, KlondikeGame};
    use engine_core::pile::{PileRef, PileType};

    #[test]
    fn test_klondike_initialization_structure() {
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(42);

        // 7 tableau piles created
        assert_eq!(game.piles().len(), 13); // stock, waste, 4 foundations, 7 tableau

        // Check tableau cards count (1..7)
        for i in 0..7 {
            let pile = &game.piles()[6 + i];
            assert_eq!(pile.len(), i + 1);
            // Top card face up
            assert!(pile.top_card().unwrap().face_up);
            // Cards below face down
            for c in 0..i {
                assert!(!pile.card_at(c).unwrap().face_up);
            }
        }

        // Stock gets remaining 24 cards, all face down
        let stock = &game.piles()[0];
        assert_eq!(stock.len(), 24);
        for c in stock.cards() {
            assert!(!c.face_up);
        }

        // Waste and foundations empty
        assert!(game.piles()[1].is_empty());
        for f in 2..6 {
            assert!(game.piles()[f].is_empty());
        }
    }

    #[test]
    fn test_klondike_move_validation() {
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(42);

        let stock_ref = PileRef::new(PileType::Stock, 0);
        let tableau_0 = PileRef::new(PileType::Tableau, 0);

        let card_id = game.piles()[6].top_card().unwrap().id;

        // Cannot move to stock
        assert!(!game.is_valid_move(tableau_0, stock_ref, &[card_id]));

        // Check foundation Ace move validation
        let ace = Card::new(Suit::Hearts, Rank::Ace, CardId(100), true);
        let non_ace = Card::new(Suit::Hearts, Rank::Five, CardId(101), true);

        assert!(ace.can_stack_on_foundation(None));
        assert!(!non_ace.can_stack_on_foundation(None));
    }

    #[test]
    fn test_klondike_is_truly_lost() {
        let mut game = KlondikeGame::new(DrawMode::One, None);
        game.initialize(42);
        assert!(!game.is_lost());
    }
}
