use crate::game::{GameRules, GameType};
use crate::games::freecell::FreeCellGame;
use crate::games::klondike::{DrawMode, KlondikeGame};
use crate::games::pyramid::PyramidGame;

pub struct GameFactory;

impl GameFactory {
    pub fn create_game(game_type: GameType) -> Box<dyn GameRules> {
        match game_type {
            GameType::Klondike => Box::new(KlondikeGame::new(DrawMode::One, None)),
            GameType::Pyramid => Box::new(PyramidGame::new()),
            GameType::FreeCell => Box::new(FreeCellGame::new()),
            _ => unimplemented!("Game type {:?} not yet implemented", game_type),
        }
    }
}
