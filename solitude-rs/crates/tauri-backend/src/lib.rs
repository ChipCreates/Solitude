mod db;

use serde_json::Value;
use std::path::PathBuf;
use tauri::{AppHandle, Manager};

fn db_path(app: &AppHandle) -> Result<PathBuf, String> {
    let dir = app
        .path()
        .app_data_dir()
        .map_err(|e| format!("Failed to resolve app data directory: {e}"))?;
    Ok(dir.join("solitude.db"))
}

fn open(app: &AppHandle) -> Result<rusqlite::Connection, String> {
    db::open(&db_path(app)?)
}

pub mod commands {
    use super::*;

    // ---- Profiles ----

    #[tauri::command]
    pub fn get_profiles(app: AppHandle) -> Result<Vec<Value>, String> {
        db::get_profiles(&open(&app)?)
    }

    #[tauri::command]
    pub fn save_profile(app: AppHandle, profile: Value) -> Result<(), String> {
        db::save_profile(&open(&app)?, &profile)
    }

    #[tauri::command]
    pub fn delete_profile(app: AppHandle, profile_id: String) -> Result<(), String> {
        db::delete_profile(&open(&app)?, &profile_id)
    }

    // ---- Save slot ----

    #[tauri::command]
    pub fn save_game(app: AppHandle, profile_id: String, state: Value) -> Result<(), String> {
        db::save_game(&open(&app)?, &profile_id, &state)
    }

    #[tauri::command]
    pub fn load_game(app: AppHandle, profile_id: String) -> Result<Option<Value>, String> {
        db::load_game(&open(&app)?, &profile_id)
    }

    #[tauri::command]
    pub fn clear_game(app: AppHandle, profile_id: String) -> Result<(), String> {
        db::clear_game(&open(&app)?, &profile_id)
    }

    // ---- Statistics ----

    #[tauri::command]
    pub fn save_statistics(
        app: AppHandle,
        profile_id: String,
        game_type: String,
        stats: Value,
    ) -> Result<(), String> {
        db::save_statistics(&open(&app)?, &profile_id, &game_type, &stats)
    }

    #[tauri::command]
    pub fn load_statistics(
        app: AppHandle,
        profile_id: String,
        game_type: String,
    ) -> Result<Value, String> {
        Ok(db::load_statistics(&open(&app)?, &profile_id, &game_type)?.unwrap_or_else(|| {
            serde_json::json!({
                "gamesPlayed": 0,
                "gamesWon": 0,
                "gamesLost": 0,
                "currentStreak": 0,
                "bestStreak": 0,
                "bestTimeMs": null,
                "fewestMoves": null,
            })
        }))
    }

    // ---- Settings ----

    #[tauri::command]
    pub fn save_settings(app: AppHandle, profile_id: String, settings: Value) -> Result<(), String> {
        db::save_settings(&open(&app)?, &profile_id, &settings)
    }

    #[tauri::command]
    pub fn load_settings(app: AppHandle, profile_id: String) -> Result<Value, String> {
        Ok(db::load_settings(&open(&app)?, &profile_id)?.unwrap_or_else(|| {
            serde_json::json!({
                "drawMode": 1,
                "autoComplete": true,
                "themeId": "classic_felt",
                "cardBack": "diamond",
                "soundEnabled": true,
                "soundVolume": 0.8,
                "leftHandMode": false,
            })
        }))
    }

    // ---- Progression ----

    #[tauri::command]
    pub fn save_progression(
        app: AppHandle,
        profile_id: String,
        progression: Value,
    ) -> Result<(), String> {
        db::save_progression(&open(&app)?, &profile_id, &progression)
    }

    #[tauri::command]
    pub fn load_progression(app: AppHandle, profile_id: String) -> Result<Value, String> {
        Ok(db::load_progression(&open(&app)?, &profile_id)?.unwrap_or_else(|| {
            serde_json::json!({
                "coins": 0,
                "unlockedItems": ["classic_felt", "diamond"],
                "unlockedAchievements": [],
                "difficulty": "normal",
                "gameProgress": {},
                "powerUpInventory": {},
            })
        }))
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            commands::get_profiles,
            commands::save_profile,
            commands::delete_profile,
            commands::save_game,
            commands::load_game,
            commands::clear_game,
            commands::save_statistics,
            commands::load_statistics,
            commands::save_settings,
            commands::load_settings,
            commands::save_progression,
            commands::load_progression,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
