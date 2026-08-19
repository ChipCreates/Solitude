use engine_core::factory::GameFactory;
use engine_core::game::GameType;

#[test]
fn test_canfield_initialization() {
    let mut game = GameFactory::create_game(GameType::Canfield);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 11); // 1 stock + 1 waste + 1 reserve + 4 foundations + 4 tableau

    // Reserve has 13 cards
    assert_eq!(piles[2].len(), 13);
    // Foundation 0 has 1 card
    assert_eq!(piles[3].len(), 1);
    // Each tableau has 1 card
    for i in 7..11 {
        assert_eq!(piles[i].len(), 1);
    }
    // Stock has 52 - 13 - 1 - 4 = 34 cards
    assert_eq!(piles[0].len(), 34);
}
