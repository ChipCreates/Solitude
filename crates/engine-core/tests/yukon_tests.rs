use engine_core::factory::GameFactory;
use engine_core::game::{GameRules, GameType};
use engine_core::pile::PileType;

#[test]
fn test_yukon_initialization() {
    let mut game = GameFactory::create_game(GameType::Yukon);
    game.initialize(42);

    let piles = game.piles();
    assert_eq!(piles.len(), 11); // 4 foundations + 7 tableau

    // Check tableau card counts (1 + 6 + 7 + 8 + 9 + 10 + 11 = 52)
    assert_eq!(piles[4].len(), 1);
    assert_eq!(piles[5].len(), 6);
    assert_eq!(piles[6].len(), 7);
    assert_eq!(piles[7].len(), 8);
    assert_eq!(piles[8].len(), 9);
    assert_eq!(piles[9].len(), 10);
    assert_eq!(piles[10].len(), 11);
}
