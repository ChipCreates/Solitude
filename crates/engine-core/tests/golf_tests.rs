use engine_core::factory::GameFactory;
use engine_core::game::GameType;

#[test]
fn test_golf_initialization() {
    let mut game = GameFactory::create_game(GameType::Golf);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 9); // 1 stock + 1 waste + 7 tableau

    // Stock has 16 cards (52 - 35 - 1)
    assert_eq!(piles[0].len(), 16);
    // Waste has 1 card
    assert_eq!(piles[1].len(), 1);

    // Each tableau has 5 cards
    for i in 2..9 {
        assert_eq!(piles[i].len(), 5);
    }
}
