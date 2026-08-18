import { GameStore, SaveEnvelope, Settings, Statistics } from "./store";

const DB_NAME = "SolitudeDB";
const DB_VERSION = 1;

const STORES = {
  SAVE_SLOT: "save_slot",
  STATISTICS: "statistics",
  SETTINGS: "settings",
};

function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORES.SAVE_SLOT)) {
        db.createObjectStore(STORES.SAVE_SLOT);
      }
      if (!db.objectStoreNames.contains(STORES.STATISTICS)) {
        db.createObjectStore(STORES.STATISTICS);
      }
      if (!db.objectStoreNames.contains(STORES.SETTINGS)) {
        db.createObjectStore(STORES.SETTINGS);
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export const webStore: GameStore = {
  async saveGame(state: SaveEnvelope): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readwrite");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.put(state, "current_save");
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadGame(): Promise<SaveEnvelope | null> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readonly");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.get("current_save");
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
  },

  async clearGame(): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readwrite");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.delete("current_save");
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async saveStatistics(gameType: string, stats: Statistics): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.STATISTICS, "readwrite");
      const store = tx.objectStore(STORES.STATISTICS);
      const req = store.put(stats, gameType);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadStatistics(gameType: string): Promise<Statistics> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.STATISTICS, "readonly");
      const store = tx.objectStore(STORES.STATISTICS);
      const req = store.get(gameType);
      req.onsuccess = () => {
        const defaultStats: Statistics = {
          gamesPlayed: 0,
          gamesWon: 0,
          gamesLost: 0,
          currentStreak: 0,
          bestStreak: 0,
          bestTimeMs: null,
          fewestMoves: null,
        };
        resolve(req.result || defaultStats);
      };
      req.onerror = () => reject(req.error);
    });
  },

  async saveSettings(settings: Settings): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SETTINGS, "readwrite");
      const store = tx.objectStore(STORES.SETTINGS);
      const req = store.put(settings, "app_settings");
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadSettings(): Promise<Settings> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SETTINGS, "readonly");
      const store = tx.objectStore(STORES.SETTINGS);
      const req = store.get("app_settings");
      req.onsuccess = () => {
        const defaultSettings: Settings = {
          drawMode: 1,
          autoComplete: true,
          themeId: "classic_felt",
          cardBack: "classic_gold",
          soundEnabled: true,
          soundVolume: 0.8,
          leftHandMode: false,
        };
        resolve(req.result || defaultSettings);
      };
      req.onerror = () => reject(req.error);
    });
  },
};
