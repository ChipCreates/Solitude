use crate::game::{GameRules, GameType};
use crate::games::klondike::{DrawMode, KlondikeGame};

pub struct GameFactory;

impl GameFactory {
    pub fn create_game(game_type: GameType) -> Box<dyn GameRules> {
        match game_type {
            GameType::Klondike => Box::new(KlondikeGame::new(DrawMode::One, None)),
            _ => unimplemented!("Game type {:?} not yet implemented", game_type),
        }
    }
}
