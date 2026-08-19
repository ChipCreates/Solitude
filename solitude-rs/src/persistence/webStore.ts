import { GameStore, SaveEnvelope, Settings, Statistics, Profile } from "./store";

const DB_NAME = "SolitudeDB";
const DB_VERSION = 3;

const STORES = {
  PROFILES: "profiles",
  SAVE_SLOT: "save_slot",
  STATISTICS: "statistics",
  SETTINGS: "settings",
  PROGRESSION: "progression",
};

function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORES.PROFILES)) {
        db.createObjectStore(STORES.PROFILES, { keyPath: "id" });
      }
      if (!db.objectStoreNames.contains(STORES.SAVE_SLOT)) {
        db.createObjectStore(STORES.SAVE_SLOT);
      }
      if (!db.objectStoreNames.contains(STORES.STATISTICS)) {
        db.createObjectStore(STORES.STATISTICS);
      }
      if (!db.objectStoreNames.contains(STORES.SETTINGS)) {
        db.createObjectStore(STORES.SETTINGS);
      }
      if (!db.objectStoreNames.contains(STORES.PROGRESSION)) {
        db.createObjectStore(STORES.PROGRESSION);
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export const webStore: GameStore = {
  // --- Profiles ---
  async getProfiles(): Promise<Profile[]> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.PROFILES, "readonly");
      const store = tx.objectStore(STORES.PROFILES);
      const req = store.getAll();
      req.onsuccess = () => resolve(req.result || []);
      req.onerror = () => reject(req.error);
    });
  },

  async saveProfile(profile: Profile): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.PROFILES, "readwrite");
      const store = tx.objectStore(STORES.PROFILES);
      const req = store.put(profile);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async deleteProfile(profileId: string): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.PROFILES, "readwrite");
      const store = tx.objectStore(STORES.PROFILES);
      const req = store.delete(profileId);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  // --- Scoped Data ---
  async saveGame(profileId: string, state: SaveEnvelope): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readwrite");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.put(state, `${profileId}_current_save`);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadGame(profileId: string): Promise<SaveEnvelope | null> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readonly");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.get(`${profileId}_current_save`);
      req.onsuccess = () => resolve(req.result || null);
      req.onerror = () => reject(req.error);
    });
  },

  async clearGame(profileId: string): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SAVE_SLOT, "readwrite");
      const store = tx.objectStore(STORES.SAVE_SLOT);
      const req = store.delete(`${profileId}_current_save`);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async saveStatistics(profileId: string, gameType: string, stats: Statistics): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.STATISTICS, "readwrite");
      const store = tx.objectStore(STORES.STATISTICS);
      const req = store.put(stats, `${profileId}_${gameType}`);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadStatistics(profileId: string, gameType: string): Promise<Statistics> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.STATISTICS, "readonly");
      const store = tx.objectStore(STORES.STATISTICS);
      const req = store.get(`${profileId}_${gameType}`);
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

  async saveSettings(profileId: string, settings: Settings): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SETTINGS, "readwrite");
      const store = tx.objectStore(STORES.SETTINGS);
      const req = store.put(settings, `${profileId}_app_settings`);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadSettings(profileId: string): Promise<Settings> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.SETTINGS, "readonly");
      const store = tx.objectStore(STORES.SETTINGS);
      const req = store.get(`${profileId}_app_settings`);
      req.onsuccess = () => {
        const defaultSettings: Settings = {
          drawMode: 1,
          autoComplete: true,
          themeId: "classic_felt",
          cardBack: "diamond",
          soundEnabled: true,
          soundVolume: 0.8,
          leftHandMode: false,
        };
        resolve(req.result || defaultSettings);
      };
      req.onerror = () => reject(req.error);
    });
  },

  async saveProgression(profileId: string, progression: import("./store").Progression): Promise<void> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.PROGRESSION, "readwrite");
      const store = tx.objectStore(STORES.PROGRESSION);
      const req = store.put(progression, `${profileId}_app_progression`);
      req.onsuccess = () => resolve();
      req.onerror = () => reject(req.error);
    });
  },

  async loadProgression(profileId: string): Promise<import("./store").Progression> {
    const db = await openDB();
    return new Promise((resolve, reject) => {
      const tx = db.transaction(STORES.PROGRESSION, "readonly");
      const store = tx.objectStore(STORES.PROGRESSION);
      const req = store.get(`${profileId}_app_progression`);
      req.onsuccess = () => {
        const defaultProgression: import("./store").Progression = {
          coins: 0,
          unlockedItems: ["classic_felt", "diamond"],
          unlockedAchievements: [],
          difficulty: "normal",
          gameProgress: {}
        };
        resolve(req.result || defaultProgression);
      };
      req.onerror = () => reject(req.error);
    });
  },
};
