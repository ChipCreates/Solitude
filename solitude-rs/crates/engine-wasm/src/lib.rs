// Architecture note: Game rule mutations are discrete function calls triggered by input events.
// world.tick(dt) is only used for cosmetic UI animation loops in TypeScript.

use engine_core::card::{CardId, Rank, Suit};
use engine_core::factory::GameFactory;
use engine_core::game::{GameRules, GameType};
use engine_core::pile::{PileRef, PileType};
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
pub fn initialize_game(game_type_code: u8, seed: u64) -> bool {
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

    let mut game = GameFactory::create_game(game_type);
    game.initialize(seed);

    let mut lock = CURRENT_GAME.lock().unwrap();
    *lock = Some(game);
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
    let from_type = match from_kind {
        0 => PileType::Stock,
        1 => PileType::Waste,
        2 => PileType::Foundation,
        3 => PileType::Tableau,
        _ => return false,
    };

    let to_type = match to_kind {
        0 => PileType::Stock,
        1 => PileType::Waste,
        2 => PileType::Foundation,
        3 => PileType::Tableau,
        _ => return false,
    };

    let mut lock = CURRENT_GAME.lock().unwrap();
    if let Some(game) = lock.as_mut() {
        let from_ref = PileRef::new(from_type, from_idx);
        let to_ref = PileRef::new(to_type, to_idx);
        game.execute_move(from_ref, to_ref, &[CardId(card_id)]).is_ok()
    } else {
        false
    }
}
