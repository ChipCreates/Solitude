// Architecture note: Game rule mutations are discrete function calls triggered by input events.
// world.tick(dt) is only used for cosmetic UI animation loops in TypeScript.

use engine_core::card::{CardId, Suit};
use engine_core::factory::{GameFactory, VariantOptions};
use engine_core::game::{GameRules, GameType};
use engine_core::pile::{PileRef, PileType};
use engine_core::solver::{SolverContext, SolverEngine};
use std::sync::Mutex;
use wasm_bindgen::prelude::*;

static CURRENT_GAME: Mutex<Option<Box<dyn GameRules + Send>>> = Mutex::new(None);
static LAYOUT_BUFFER: Mutex<Vec<u8>> = Mutex::new(Vec::new());

#[wasm_bindgen]
pub fn init_panic_hook() {
    #[cfg(feature = "console_error_panic_hook")]
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
pub fn ping() -> u32 {
    42
}

#[wasm_bindgen]
pub fn initialize_game(
    game_type_code: u8,
    seed: u64,
    klondike_draw_mode: u8,
    spider_suit_count: u8,
    golf_wrap_around: bool,
) -> bool {
    let game_type = match game_type_code {
        0 => GameType::Klondike,
        1 => GameType::Spider,
        2 => GameType::FreeCell,
        3 => GameType::Pyramid,
        4 => GameType::Golf,
        5 => GameType::TriPeaks,
        6 => GameType::Yukon,
        7 => GameType::FortyThieves,
        8 => GameType::Canfield,
        9 => GameType::Scorpion,
        _ => return false,
    };

    let options = VariantOptions {
        klondike_draw_mode,
        spider_suit_count,
        golf_wrap_around,
    };

    let mut game = GameFactory::create_game_with_options(game_type, options);
    game.initialize(seed);

    let mut lock = CURRENT_GAME.lock().unwrap();
    *lock = Some(game);
    drop(lock);

    engine_core::solver::clear_solver_cache();
    true
}

#[wasm_bindgen]
pub fn tap_stock() -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        game.tap_stock().is_ok()
    } else {
        false
    }
}

#[wasm_bindgen]
pub fn undo() -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        game.undo()
    } else {
        false
    }
}

#[wasm_bindgen]
pub fn redo() -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        game.redo()
    } else {
        false
    }
}

/// "Lucky Reshuffle" power-up: shuffles Stock+Waste back into Stock without
/// restarting the game. Irreversible — does not go through undo/redo.
#[wasm_bindgen]
pub fn reshuffle_stock_waste_wasm(seed: u64) -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        game.reshuffle_stock_waste(seed)
    } else {
        false
    }
}

/// "Reset Column" power-up: shuffles one Tableau column in place, leaving
/// only the new top card face-up. Irreversible — does not go through
/// undo/redo.
#[wasm_bindgen]
pub fn reset_tableau_column_wasm(index: u8, seed: u64) -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        game.reset_tableau_column(index, seed)
    } else {
        false
    }
}

#[wasm_bindgen]
pub fn check_win() -> bool {
    let lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_ref() {
        game.check_win()
    } else {
        false
    }
}

#[wasm_bindgen]
pub fn is_lost() -> bool {
    let lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_ref() {
        game.is_lost()
    } else {
        false
    }
}

fn pile_type_to_u8(kind: PileType) -> u8 {
    match kind {
        PileType::Stock => 0,
        PileType::Waste => 1,
        PileType::Foundation => 2,
        PileType::Tableau => 3,
        PileType::Cell => 4,
        PileType::Reserve => 5,
        PileType::Pyramid => 6,
        PileType::Discard => 7,
    }
}

fn u8_to_pile_type(kind: u8) -> Option<PileType> {
    match kind {
        0 => Some(PileType::Stock),
        1 => Some(PileType::Waste),
        2 => Some(PileType::Foundation),
        3 => Some(PileType::Tableau),
        4 => Some(PileType::Cell),
        5 => Some(PileType::Reserve),
        6 => Some(PileType::Pyramid),
        7 => Some(PileType::Discard),
        _ => None,
    }
}

fn suit_to_u8(suit: Suit) -> u8 {
    match suit {
        Suit::Hearts => 0,
        Suit::Diamonds => 1,
        Suit::Clubs => 2,
        Suit::Spades => 3,
    }
}

#[wasm_bindgen]
pub fn get_layout_buffer_ptr() -> *const u8 {
    let lock = CURRENT_GAME.lock().unwrap();
    let mut buf = LAYOUT_BUFFER.lock().unwrap();
    buf.clear();

    if let Some(game) = lock.as_ref() {
        let piles = game.piles();
        buf.push(piles.len() as u8);

        for pile in piles {
            buf.push(pile_type_to_u8(pile.kind));
            buf.push(pile.index);
            let cards = pile.cards();
            buf.push(cards.len() as u8);

            for card in cards {
                buf.push(card.id.0);
                buf.push(suit_to_u8(card.suit));
                buf.push(card.rank.value());
                buf.push(if card.face_up { 1 } else { 0 });
            }
        }
    }

    buf.as_ptr()
}

#[wasm_bindgen]
pub fn get_layout_buffer_len() -> usize {
    let buf = LAYOUT_BUFFER.lock().unwrap();
    buf.len()
}

#[wasm_bindgen]
pub fn execute_move_wasm(from_kind: u8, from_idx: u8, to_kind: u8, to_idx: u8, card_id: u8) -> bool {
    execute_pair_move_wasm(from_kind, from_idx, to_kind, to_idx, card_id, 255)
}

#[wasm_bindgen]
pub fn execute_pair_move_wasm(
    from_kind: u8,
    from_idx: u8,
    to_kind: u8,
    to_idx: u8,
    card_id: u8,
    second_card_id: u8,
) -> bool {
    let from_type = match u8_to_pile_type(from_kind) {
        Some(t) => t,
        None => return false,
    };
    let to_type = match u8_to_pile_type(to_kind) {
        Some(t) => t,
        None => return false,
    };

    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        let from_ref = PileRef::new(from_type, from_idx);
        let to_ref = PileRef::new(to_type, to_idx);
        let cards = if second_card_id != 255 {
            vec![CardId(card_id), CardId(second_card_id)]
        } else {
            vec![CardId(card_id)]
        };
        game.execute_move(from_ref, to_ref, &cards).is_ok()
    } else {
        false
    }
}

#[wasm_bindgen]
pub fn get_hint_json() -> String {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        if let Some(hint) = SolverEngine::find_best_move(&mut **game, SolverContext::Hint) {
            return serde_json::to_string(&hint).unwrap_or_default();
        }
    }
    String::new()
}

#[wasm_bindgen]
pub fn auto_play_step_wasm() -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        if let Some(hint) = SolverEngine::find_best_move(&mut **game, SolverContext::AutoPlay) {
            if hint.cards.is_empty() && hint.from.kind == PileType::Stock {
                return game.tap_stock().is_ok();
            } else {
                let card_ids: Vec<CardId> = hint.cards;
                return game.execute_move(hint.from, hint.to, &card_ids).is_ok();
            }
        }
    }
    false
}

#[wasm_bindgen]
pub fn auto_complete_step_wasm() -> bool {
    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        if game.check_win() {
            return false;
        }
        if let Some(hint) = SolverEngine::find_best_move(&mut **game, SolverContext::AutoPlay) {
            if hint.cards.is_empty() && hint.from.kind == PileType::Stock {
                return game.tap_stock().is_ok();
            } else {
                let card_ids: Vec<CardId> = hint.cards;
                return game.execute_move(hint.from, hint.to, &card_ids).is_ok();
            }
        }
    }
    false
}

