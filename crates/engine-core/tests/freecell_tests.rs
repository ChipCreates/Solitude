use engine_core::factory::GameFactory;
use engine_core::game::{GameRules, GameType};
use engine_core::games::freecell::FreeCellGame;
use engine_core::pile::{PileRef, PileType};

#[test]
fn test_freecell_initialization() {
    let mut game = FreeCellGame::new();
    game.initialize(42);

    assert_eq!(game.game_type(), GameType::FreeCell);
    assert_eq!(game.deck_size(), 52);

    let piles = game.piles();
    assert_eq!(piles.len(), 16);

    // 4 FreeCells empty
    for i in 0..4 {
        assert_eq!(piles[i].len(), 0);
    }

    // 4 Foundations empty
    for i in 4..8 {
        assert_eq!(piles[i].len(), 0);
    }

    // 8 Tableau columns: first 4 have 7 cards, last 4 have 6 cards (total 52)
    for i in 0..4 {
        assert_eq!(piles[8 + i].len(), 7);
    }
    for i in 4..8 {
        assert_eq!(piles[8 + i].len(), 6);
    }

    // All tableau cards must be face up
    for i in 0..8 {
        for card in piles[8 + i].cards() {
            assert!(card.face_up);
        }
    }
}

#[test]
fn test_freecell_supermove_formula() {
    let mut game = FreeCellGame::new();
    game.initialize(42);

    // Initial state: 4 empty cells, 0 empty columns
    // max_moveable = (4 + 1) * 2^0 = 5
    assert_eq!(game.max_moveable_cards(false), 5);
    // max_moveable_to_empty = (4 + 1) * 2^0 = 5
    assert_eq!(game.max_moveable_cards(true), 5);

    // Move 1 card to a freecell
    let card_id = game.piles()[8].top_card().unwrap().id;
    let from_ref = PileRef::new(PileType::Tableau, 0);
    let cell_ref = PileRef::new(PileType::Cell, 0);

    assert!(game.is_valid_move(from_ref, cell_ref, &[card_id]));
    game.execute_move(from_ref, cell_ref, &[card_id]).unwrap();

    // Now 3 empty cells, 0 empty columns
    // max_moveable = (3 + 1) * 2^0 = 4
    assert_eq!(game.max_moveable_cards(false), 4);
}

#[test]
fn test_freecell_undo_redo() {
    let mut game = FreeCellGame::new();
    game.initialize(100);

    let card_id = game.piles()[8].top_card().unwrap().id;
    let from_ref = PileRef::new(PileType::Tableau, 0);
    let cell_ref = PileRef::new(PileType::Cell, 0);

    game.execute_move(from_ref, cell_ref, &[card_id]).unwrap();
    assert_eq!(game.piles()[0].len(), 1);
    assert_eq!(game.piles()[8].len(), 6);

    assert!(game.undo());
    assert_eq!(game.piles()[0].len(), 0);
    assert_eq!(game.piles()[8].len(), 7);

    assert!(game.redo());
    assert_eq!(game.piles()[0].len(), 1);
    assert_eq!(game.piles()[8].len(), 6);
}

#[test]
fn test_factory_freecell() {
    let mut game = GameFactory::create_game(GameType::FreeCell);
    game.initialize(1);
    assert_eq!(game.game_type(), GameType::FreeCell);
}
