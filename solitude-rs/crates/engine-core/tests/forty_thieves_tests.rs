use engine_core::factory::GameFactory;
use engine_core::game::GameType;

#[test]
fn test_forty_thieves_initialization() {
    let mut game = GameFactory::create_game(GameType::FortyThieves);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 20); // 1 stock + 1 waste + 8 foundations + 10 tableau

    // Stock has 64 cards (104 - 40)
    assert_eq!(piles[0].len(), 64);
    assert_eq!(piles[1].len(), 0);

    // Each tableau column has 4 cards
    for i in 10..20 {
        assert_eq!(piles[i].len(), 4);
    }
}
