use engine_core::factory::GameFactory;
use engine_core::game::GameType;

#[test]
fn test_tripeaks_initialization() {
    let mut game = GameFactory::create_game(GameType::TriPeaks);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 30); // 1 stock + 1 waste + 28 peaks

    // Stock has 23 cards (52 - 28 - 1)
    assert_eq!(piles[0].len(), 23);
    // Waste has 1 card
    assert_eq!(piles[1].len(), 1);

    // Each peak pile has 1 card
    for i in 2..30 {
        assert_eq!(piles[i].len(), 1);
    }
}
