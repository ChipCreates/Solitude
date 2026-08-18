use crate::game::{GameRules, GameType};
use crate::games::canfield::CanfieldGame;
use crate::games::forty_thieves::FortyThievesGame;
use crate::games::freecell::FreeCellGame;
use crate::games::golf::GolfGame;
use crate::games::klondike::{DrawMode, KlondikeGame};
use crate::games::pyramid::PyramidGame;
use crate::games::scorpion::ScorpionGame;
use crate::games::spider::SpiderGame;
use crate::games::tripeaks::TriPeaksGame;
use crate::games::yukon::YukonGame;

pub struct GameFactory;

impl GameFactory {
    pub fn create_game(game_type: GameType) -> Box<dyn GameRules> {
        match game_type {
            GameType::Klondike => Box::new(KlondikeGame::new(DrawMode::One, None)),
            GameType::Spider => Box::new(SpiderGame::new(4)),
            GameType::FreeCell => Box::new(FreeCellGame::new()),
            GameType::Pyramid => Box::new(PyramidGame::new()),
            GameType::Golf => Box::new(GolfGame::new(false)),
            GameType::TriPeaks => Box::new(TriPeaksGame::new()),
            GameType::Yukon => Box::new(YukonGame::new()),
            GameType::FortyThieves => Box::new(FortyThievesGame::new()),
            GameType::Canfield => Box::new(CanfieldGame::new()),
            GameType::Scorpion => Box::new(ScorpionGame::new()),
        }
    }
}
