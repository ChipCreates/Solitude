use engine_core::factory::GameFactory;
use engine_core::game::GameType;

#[test]
fn test_spider_initialization() {
    let mut game = GameFactory::create_game(GameType::Spider);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 19); // 1 stock + 8 foundations + 10 tableau

    // Stock has 50 cards (104 - 54)
    assert_eq!(piles[0].len(), 50);

    // First 4 tableau columns have 6 cards, next 6 have 5 cards
    for i in 0..4 {
        assert_eq!(piles[9 + i].len(), 6);
    }
    for i in 4..10 {
        assert_eq!(piles[9 + i].len(), 5);
    }
}
