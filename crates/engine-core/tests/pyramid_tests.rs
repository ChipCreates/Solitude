use engine_core::card::Rank;
use engine_core::factory::GameFactory;
use engine_core::game::{GameRules, GameType};
use engine_core::games::pyramid::PyramidGame;
use engine_core::pile::{PileRef, PileType};

#[test]
fn test_pyramid_initialization() {
    let mut game = PyramidGame::new();
    game.initialize(42);

    assert_eq!(game.game_type(), GameType::Pyramid);
    assert_eq!(game.deck_size(), 52);

    let piles = game.piles();
    assert_eq!(piles.len(), 31);

    // Stock: 24 cards
    assert_eq!(piles[0].len(), 24);
    // Waste: 0
    assert_eq!(piles[1].len(), 0);
    // Discard: 0
    assert_eq!(piles[2].len(), 0);

    // Pyramid: 28 cards (1 in each pile)
    for i in 0..28 {
        assert_eq!(piles[3 + i].len(), 1);
        assert!(piles[3 + i].top_card().unwrap().face_up);
    }
}

#[test]
fn test_pyramid_coverage_and_uncovered() {
    let mut game = PyramidGame::new();
    game.initialize(12345);

    // Bottom row (21..27) must all be uncovered
    for i in 21..28 {
        assert!(game.is_card_uncovered(i as u8));
    }

    // Top row (0) must be covered initially since rows 1..6 exist
    assert!(!game.is_card_uncovered(0));

    // Middle row card (e.g. 15) must be covered initially
    assert!(!game.is_card_uncovered(15));
}

#[test]
fn test_pyramid_king_removal_and_undo() {
    let mut game = PyramidGame::new();
    game.initialize(42);

    let discard_ref = PileRef::new(PileType::Discard, 0);

    // Find an uncovered King in the bottom row
    let mut found_king_idx = None;
    for i in 21..28 {
        let pile = &game.piles()[3 + i];
        if let Some(card) = pile.top_card() {
            if card.rank == Rank::King {
                found_king_idx = Some(i as u8);
                break;
            }
        }
    }

    if let Some(king_idx) = found_king_idx {
        let from_ref = PileRef::new(PileType::Pyramid, king_idx);
        let card_id = game.piles()[3 + king_idx as usize].top_card().unwrap().id;

        assert!(game.is_valid_move(from_ref, discard_ref, &[card_id]));

        let mv = game.execute_move(from_ref, discard_ref, &[card_id]).unwrap();
        assert_eq!(mv.cards, vec![card_id]);
        assert_eq!(game.piles()[3 + king_idx as usize].len(), 0);
        assert_eq!(game.piles()[2].len(), 1); // Discard has King

        // Test Undo
        assert!(game.undo());
        assert_eq!(game.piles()[3 + king_idx as usize].len(), 1);
        assert_eq!(game.piles()[2].len(), 0);

        // Test Redo
        assert!(game.redo());
        assert_eq!(game.piles()[3 + king_idx as usize].len(), 0);
        assert_eq!(game.piles()[2].len(), 1);
    }
}

#[test]
fn test_pyramid_stock_tap_and_recycle() {
    let mut game = PyramidGame::new();
    game.initialize(99);

    assert_eq!(game.piles()[0].len(), 24);
    assert_eq!(game.piles()[1].len(), 0);

    // Tap stock 24 times
    for i in 0..24 {
        let res = game.tap_stock().unwrap();
        assert!(res.is_some());
        assert_eq!(game.piles()[0].len(), 24 - (i + 1));
        assert_eq!(game.piles()[1].len(), i + 1);
    }

    assert_eq!(game.piles()[0].len(), 0);
    assert_eq!(game.piles()[1].len(), 24);

    // Tap stock to recycle waste
    let recycle_res = game.tap_stock().unwrap();
    assert!(recycle_res.is_some());
    assert_eq!(game.piles()[0].len(), 24);
    assert_eq!(game.piles()[1].len(), 0);
}

#[test]
fn test_factory_pyramid() {
    let mut game = GameFactory::create_game(GameType::Pyramid);
    game.initialize(1);
    assert_eq!(game.game_type(), GameType::Pyramid);
    assert_eq!(game.deck_size(), 52);
}
