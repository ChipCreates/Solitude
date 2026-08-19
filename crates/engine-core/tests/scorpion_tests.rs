use engine_core::factory::GameFactory;
use engine_core::game::{GameRules, GameType};
use engine_core::pile::PileRef;
use engine_core::pile::PileType;

#[test]
fn test_scorpion_initialization() {
    let mut game = GameFactory::create_game(GameType::Scorpion);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 8); // 1 stock + 7 tableau

    // Stock has 3 cards
    assert_eq!(piles[0].len(), 3);

    // Each tableau column has 7 cards
    for i in 1..=7 {
        assert_eq!(piles[i].len(), 7);
    }
}

#[test]
fn test_scorpion_tap_stock() {
    let mut game = GameFactory::create_game(GameType::Scorpion);
    game.initialize(42);

    // Tap stock deals 1 card to each of the first 3 tableau columns
    let res = game.tap_stock();
    assert!(res.is_ok());

    let piles = game.piles();
    assert_eq!(piles[0].len(), 0); // Stock empty
    assert_eq!(piles[1].len(), 8);
    assert_eq!(piles[2].len(), 8);
    assert_eq!(piles[3].len(), 8);
    assert_eq!(piles[4].len(), 7);
}
