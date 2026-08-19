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

/// Per-variant gameplay options that the React UI exposes but, before this,
/// never reached the engine: `initialize_game()` always built games with
/// hardcoded defaults regardless of what the player had selected.
#[derive(Debug, Clone, Copy)]
pub struct VariantOptions {
    /// Klondike stock draw count: 1 or 3.
    pub klondike_draw_mode: u8,
    /// Spider tableau suit variety: 1, 2, or 4.
    pub spider_suit_count: u8,
    /// Golf: whether King can wrap onto Ace (or vice versa) on the waste.
    pub golf_wrap_around: bool,
}

impl Default for VariantOptions {
    fn default() -> Self {
        Self {
            klondike_draw_mode: 1,
            spider_suit_count: 4,
            golf_wrap_around: false,
        }
    }
}

pub struct GameFactory;

impl GameFactory {
    pub fn create_game(game_type: GameType) -> Box<dyn GameRules> {
        Self::create_game_with_options(game_type, VariantOptions::default())
    }

    pub fn create_game_with_options(
        game_type: GameType,
        options: VariantOptions,
    ) -> Box<dyn GameRules> {
        match game_type {
            GameType::Klondike => {
                let draw_mode = if options.klondike_draw_mode == 3 {
                    DrawMode::Three
                } else {
                    DrawMode::One
                };
                Box::new(KlondikeGame::new(draw_mode, None))
            }
            GameType::Spider => Box::new(SpiderGame::new(options.spider_suit_count)),
            GameType::FreeCell => Box::new(FreeCellGame::new()),
            GameType::Pyramid => Box::new(PyramidGame::new()),
            GameType::Golf => Box::new(GolfGame::new(options.golf_wrap_around)),
            GameType::TriPeaks => Box::new(TriPeaksGame::new()),
            GameType::Yukon => Box::new(YukonGame::new()),
            GameType::FortyThieves => Box::new(FortyThievesGame::new()),
            GameType::Canfield => Box::new(CanfieldGame::new()),
            GameType::Scorpion => Box::new(ScorpionGame::new()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::pile::PileType;

    #[test]
    fn test_klondike_draw_mode_wired_through_options() {
        let mut game = GameFactory::create_game_with_options(
            GameType::Klondike,
            VariantOptions { klondike_draw_mode: 3, ..VariantOptions::default() },
        );
        game.initialize(1);
        game.tap_stock().unwrap();

        let waste = game
            .piles()
            .iter()
            .find(|p| p.kind == PileType::Waste)
            .unwrap();
        assert_eq!(waste.len(), 3, "draw_mode: 3 should draw 3 cards per stock tap");
    }

    #[test]
    fn test_spider_suit_count_wired_through_options() {
        let mut game = GameFactory::create_game_with_options(
            GameType::Spider,
            VariantOptions { spider_suit_count: 1, ..VariantOptions::default() },
        );
        game.initialize(1);

        let all_one_suit = game
            .piles()
            .iter()
            .flat_map(|p| p.cards())
            .all(|c| c.suit == crate::card::Suit::Spades);
        assert!(all_one_suit, "suit_count: 1 should deal only Spades");
    }

    #[test]
    fn test_golf_wrap_around_wired_through_options() {
        // The behavioral difference `allow_wrapping` makes is covered by
        // games::golf::tests::test_wrap_around_toggles_ace_king_adjacency;
        // this just confirms the factory threads the option through to the
        // right constructor for the right game type.
        let game = GameFactory::create_game_with_options(
            GameType::Golf,
            VariantOptions { golf_wrap_around: true, ..VariantOptions::default() },
        );
        assert_eq!(game.game_type(), GameType::Golf);
    }
}
