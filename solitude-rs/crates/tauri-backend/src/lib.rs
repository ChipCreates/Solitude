use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SaveEnvelope {
    pub schema_version: u32,
    pub game_type: String,
    pub piles: Vec<serde_json::Value>,
    pub move_count: u32,
    pub elapsed_ms: u64,
    pub saved_at: i64,
    pub variant_data: serde_json::Value,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[allow(non_snake_case)]
pub struct Statistics {
    pub gamesPlayed: u32,
    pub gamesWon: u32,
    pub gamesLost: u32,
    pub currentStreak: u32,
    pub bestStreak: u32,
    pub bestTimeMs: Option<u64>,
    pub fewestMoves: Option<u32>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[allow(non_snake_case)]
pub struct Settings {
    pub drawMode: u32,
    pub autoComplete: bool,
    pub themeId: String,
    pub cardBack: String,
    pub soundEnabled: bool,
    pub soundVolume: f32,
    pub leftHandMode: bool,
}

pub mod commands {
    use super::*;

    #[tauri::command]
    pub fn save_game(_state: SaveEnvelope) -> Result<(), String> {
        Ok(())
    }

    #[tauri::command]
    pub fn load_game() -> Result<Option<SaveEnvelope>, String> {
        Ok(None)
    }

    #[tauri::command]
    pub fn clear_game() -> Result<(), String> {
        Ok(())
    }

    #[tauri::command]
    pub fn save_statistics(_game_type: String, _stats: Statistics) -> Result<(), String> {
        Ok(())
    }

    #[tauri::command]
    pub fn load_statistics(_game_type: String) -> Result<Statistics, String> {
        Ok(Statistics {
            gamesPlayed: 0,
            gamesWon: 0,
            gamesLost: 0,
            currentStreak: 0,
            bestStreak: 0,
            bestTimeMs: None,
            fewestMoves: None,
        })
    }

    #[tauri::command]
    pub fn save_settings(_settings: Settings) -> Result<(), String> {
        Ok(())
    }

    #[tauri::command]
    pub fn load_settings() -> Result<Settings, String> {
        Ok(Settings {
            drawMode: 1,
            autoComplete: true,
            themeId: "classic_felt".into(),
            cardBack: "classic_gold".into(),
            soundEnabled: true,
            soundVolume: 0.8,
            leftHandMode: false,
        })
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            commands::save_game,
            commands::load_game,
            commands::clear_game,
            commands::save_statistics,
            commands::load_statistics,
            commands::save_settings,
            commands::load_settings
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
