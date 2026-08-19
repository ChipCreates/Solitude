//! SQLite-backed persistence for the Tauri desktop/mobile app.
//!
//! Every domain (profiles, save slot, statistics, settings, progression) is
//! keyed by profile id (and game type, for statistics) with the payload
//! stored as a JSON blob column. The frontend's shapes for these payloads
//! (Settings, Progression, SaveEnvelope, Statistics) have already changed
//! several times this session; normalizing every field into its own column
//! would mean a schema migration for every frontend field addition. A JSON
//! column keeps the schema stable while still giving us real transactions,
//! atomic writes, and indexed lookups by profile/game type — the actual
//! value SQLite adds over flat files.

use rusqlite::{params, Connection, OptionalExtension};
use serde_json::Value;
use std::path::Path;

const CURRENT_SCHEMA_VERSION: i64 = 1;

pub fn open(db_path: &Path) -> Result<Connection, String> {
    if let Some(parent) = db_path.parent() {
        std::fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create {parent:?}: {e}"))?;
    }
    let conn = Connection::open(db_path)
        .map_err(|e| format!("Failed to open database at {db_path:?}: {e}"))?;
    conn.pragma_update(None, "foreign_keys", true)
        .map_err(|e| format!("Failed to enable foreign keys: {e}"))?;
    migrate(&conn)?;
    Ok(conn)
}

fn migrate(conn: &Connection) -> Result<(), String> {
    let version: i64 = conn
        .query_row("PRAGMA user_version", [], |row| row.get(0))
        .map_err(|e| format!("Failed to read schema version: {e}"))?;

    if version < 1 {
        conn.execute_batch(
            "
            CREATE TABLE IF NOT EXISTS profiles (
                id   TEXT PRIMARY KEY,
                data TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS save_games (
                profile_id TEXT PRIMARY KEY,
                data       TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS statistics (
                profile_id TEXT NOT NULL,
                game_type  TEXT NOT NULL,
                data       TEXT NOT NULL,
                PRIMARY KEY (profile_id, game_type)
            );
            CREATE TABLE IF NOT EXISTS settings (
                profile_id TEXT PRIMARY KEY,
                data       TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS progression (
                profile_id TEXT PRIMARY KEY,
                data       TEXT NOT NULL
            );
            ",
        )
        .map_err(|e| format!("Failed to run schema migration: {e}"))?;
    }

    if version < CURRENT_SCHEMA_VERSION {
        conn.pragma_update(None, "user_version", CURRENT_SCHEMA_VERSION)
            .map_err(|e| format!("Failed to set schema version: {e}"))?;
    }

    Ok(())
}

fn to_text(value: &Value) -> Result<String, String> {
    serde_json::to_string(value).map_err(|e| format!("Failed to serialize JSON: {e}"))
}

fn from_text(text: String) -> Result<Value, String> {
    serde_json::from_str(&text).map_err(|e| format!("Failed to parse stored JSON: {e}"))
}

// ---- Profiles ----

pub fn get_profiles(conn: &Connection) -> Result<Vec<Value>, String> {
    let mut stmt = conn
        .prepare("SELECT data FROM profiles ORDER BY rowid")
        .map_err(|e| e.to_string())?;
    let rows = stmt
        .query_map([], |row| row.get::<_, String>(0))
        .map_err(|e| e.to_string())?;
    let mut profiles = Vec::new();
    for row in rows {
        profiles.push(from_text(row.map_err(|e| e.to_string())?)?);
    }
    Ok(profiles)
}

pub fn save_profile(conn: &Connection, profile: &Value) -> Result<(), String> {
    let id = profile
        .get("id")
        .and_then(|v| v.as_str())
        .ok_or_else(|| "profile.id is required".to_string())?;
    conn.execute(
        "INSERT INTO profiles (id, data) VALUES (?1, ?2)
         ON CONFLICT(id) DO UPDATE SET data = excluded.data",
        params![id, to_text(profile)?],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn delete_profile(conn: &Connection, profile_id: &str) -> Result<(), String> {
    conn.execute("DELETE FROM profiles WHERE id = ?1", params![profile_id])
        .map_err(|e| e.to_string())?;
    // A deleted profile's other data has no purpose left; clean it up too
    // rather than leaking rows keyed to an id nothing references anymore.
    for table in ["save_games", "settings", "progression"] {
        conn.execute(
            &format!("DELETE FROM {table} WHERE profile_id = ?1"),
            params![profile_id],
        )
        .map_err(|e| e.to_string())?;
    }
    conn.execute(
        "DELETE FROM statistics WHERE profile_id = ?1",
        params![profile_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

// ---- Save slot ----

pub fn save_game(conn: &Connection, profile_id: &str, state: &Value) -> Result<(), String> {
    conn.execute(
        "INSERT INTO save_games (profile_id, data) VALUES (?1, ?2)
         ON CONFLICT(profile_id) DO UPDATE SET data = excluded.data",
        params![profile_id, to_text(state)?],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn load_game(conn: &Connection, profile_id: &str) -> Result<Option<Value>, String> {
    let data: Option<String> = conn
        .query_row(
            "SELECT data FROM save_games WHERE profile_id = ?1",
            params![profile_id],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    data.map(from_text).transpose()
}

pub fn clear_game(conn: &Connection, profile_id: &str) -> Result<(), String> {
    conn.execute(
        "DELETE FROM save_games WHERE profile_id = ?1",
        params![profile_id],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

// ---- Statistics ----

pub fn save_statistics(
    conn: &Connection,
    profile_id: &str,
    game_type: &str,
    stats: &Value,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO statistics (profile_id, game_type, data) VALUES (?1, ?2, ?3)
         ON CONFLICT(profile_id, game_type) DO UPDATE SET data = excluded.data",
        params![profile_id, game_type, to_text(stats)?],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn load_statistics(
    conn: &Connection,
    profile_id: &str,
    game_type: &str,
) -> Result<Option<Value>, String> {
    let data: Option<String> = conn
        .query_row(
            "SELECT data FROM statistics WHERE profile_id = ?1 AND game_type = ?2",
            params![profile_id, game_type],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    data.map(from_text).transpose()
}

// ---- Settings ----

pub fn save_settings(conn: &Connection, profile_id: &str, settings: &Value) -> Result<(), String> {
    conn.execute(
        "INSERT INTO settings (profile_id, data) VALUES (?1, ?2)
         ON CONFLICT(profile_id) DO UPDATE SET data = excluded.data",
        params![profile_id, to_text(settings)?],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn load_settings(conn: &Connection, profile_id: &str) -> Result<Option<Value>, String> {
    let data: Option<String> = conn
        .query_row(
            "SELECT data FROM settings WHERE profile_id = ?1",
            params![profile_id],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    data.map(from_text).transpose()
}

// ---- Progression ----

pub fn save_progression(
    conn: &Connection,
    profile_id: &str,
    progression: &Value,
) -> Result<(), String> {
    conn.execute(
        "INSERT INTO progression (profile_id, data) VALUES (?1, ?2)
         ON CONFLICT(profile_id) DO UPDATE SET data = excluded.data",
        params![profile_id, to_text(progression)?],
    )
    .map_err(|e| e.to_string())?;
    Ok(())
}

pub fn load_progression(conn: &Connection, profile_id: &str) -> Result<Option<Value>, String> {
    let data: Option<String> = conn
        .query_row(
            "SELECT data FROM progression WHERE profile_id = ?1",
            params![profile_id],
            |row| row.get(0),
        )
        .optional()
        .map_err(|e| e.to_string())?;
    data.map(from_text).transpose()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn test_conn() -> Connection {
        let conn = Connection::open_in_memory().unwrap();
        migrate(&conn).unwrap();
        conn
    }

    #[test]
    fn test_migrate_is_idempotent() {
        let conn = test_conn();
        migrate(&conn).unwrap();
        migrate(&conn).unwrap();
        let version: i64 = conn
            .query_row("PRAGMA user_version", [], |row| row.get(0))
            .unwrap();
        assert_eq!(version, CURRENT_SCHEMA_VERSION);
    }

    #[test]
    fn test_profile_round_trip_and_upsert() {
        let conn = test_conn();
        assert_eq!(get_profiles(&conn).unwrap(), Vec::<Value>::new());

        let p1 = json!({"id": "abc", "name": "Chip", "avatarId": "a1", "createdAt": 1, "lastPlayed": 1});
        save_profile(&conn, &p1).unwrap();
        assert_eq!(get_profiles(&conn).unwrap(), vec![p1.clone()]);

        // Saving the same id again updates in place rather than duplicating.
        let p1_updated = json!({"id": "abc", "name": "Chip Renamed", "avatarId": "a1", "createdAt": 1, "lastPlayed": 2});
        save_profile(&conn, &p1_updated).unwrap();
        assert_eq!(get_profiles(&conn).unwrap(), vec![p1_updated]);

        let p2 = json!({"id": "def", "name": "Guest", "avatarId": "a2", "createdAt": 2, "lastPlayed": 2});
        save_profile(&conn, &p2).unwrap();
        assert_eq!(get_profiles(&conn).unwrap().len(), 2);

        delete_profile(&conn, "abc").unwrap();
        let remaining = get_profiles(&conn).unwrap();
        assert_eq!(remaining.len(), 1);
        assert_eq!(remaining[0]["id"], "def");
    }

    #[test]
    fn test_delete_profile_cascades_owned_data() {
        let conn = test_conn();
        save_profile(&conn, &json!({"id": "p1", "name": "X"})).unwrap();
        save_game(&conn, "p1", &json!({"move_count": 3})).unwrap();
        save_settings(&conn, "p1", &json!({"drawMode": 3})).unwrap();
        save_progression(&conn, "p1", &json!({"coins": 10})).unwrap();
        save_statistics(&conn, "p1", "Klondike", &json!({"gamesPlayed": 1})).unwrap();

        delete_profile(&conn, "p1").unwrap();

        assert_eq!(load_game(&conn, "p1").unwrap(), None);
        assert_eq!(load_settings(&conn, "p1").unwrap(), None);
        assert_eq!(load_progression(&conn, "p1").unwrap(), None);
        assert_eq!(load_statistics(&conn, "p1", "Klondike").unwrap(), None);
    }

    #[test]
    fn test_save_game_round_trip_and_clear() {
        let conn = test_conn();
        assert_eq!(load_game(&conn, "p1").unwrap(), None);

        let envelope = json!({"schema_version": 1, "game_type": "Klondike", "piles": [], "move_count": 5, "elapsed_ms": 1000, "saved_at": 123, "variant_data": {}});
        save_game(&conn, "p1", &envelope).unwrap();
        assert_eq!(load_game(&conn, "p1").unwrap(), Some(envelope.clone()));

        // Re-saving overwrites rather than erroring on the PRIMARY KEY.
        let envelope2 = json!({"schema_version": 1, "game_type": "Klondike", "piles": [], "move_count": 8, "elapsed_ms": 2000, "saved_at": 456, "variant_data": {}});
        save_game(&conn, "p1", &envelope2).unwrap();
        assert_eq!(load_game(&conn, "p1").unwrap(), Some(envelope2));

        clear_game(&conn, "p1").unwrap();
        assert_eq!(load_game(&conn, "p1").unwrap(), None);
    }

    #[test]
    fn test_statistics_scoped_by_game_type() {
        let conn = test_conn();
        save_statistics(&conn, "p1", "Klondike", &json!({"gamesWon": 2})).unwrap();
        save_statistics(&conn, "p1", "Spider", &json!({"gamesWon": 5})).unwrap();

        assert_eq!(
            load_statistics(&conn, "p1", "Klondike").unwrap(),
            Some(json!({"gamesWon": 2}))
        );
        assert_eq!(
            load_statistics(&conn, "p1", "Spider").unwrap(),
            Some(json!({"gamesWon": 5}))
        );
        assert_eq!(load_statistics(&conn, "p2", "Klondike").unwrap(), None);
    }

    #[test]
    fn test_settings_and_progression_round_trip() {
        let conn = test_conn();
        let settings = json!({"drawMode": 3, "scoringMode": "vegas_cumulative", "vegasBankroll": -12});
        save_settings(&conn, "p1", &settings).unwrap();
        assert_eq!(load_settings(&conn, "p1").unwrap(), Some(settings));

        let progression = json!({"coins": 250, "difficulty": "hard", "gameProgress": {"0": {"level": 3, "xp": 40}}});
        save_progression(&conn, "p1", &progression).unwrap();
        assert_eq!(load_progression(&conn, "p1").unwrap(), Some(progression));
    }

    #[test]
    fn test_open_creates_parent_directory_and_persists() {
        let dir = tempfile::tempdir().unwrap();
        let db_path = dir.path().join("nested").join("solitude.db");
        {
            let conn = open(&db_path).unwrap();
            save_settings(&conn, "p1", &json!({"drawMode": 1})).unwrap();
        }
        // Reopen to confirm data survived the connection being dropped.
        let conn = open(&db_path).unwrap();
        assert_eq!(
            load_settings(&conn, "p1").unwrap(),
            Some(json!({"drawMode": 1}))
        );
    }
}
