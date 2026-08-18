import { GameStore, SaveEnvelope, Settings, Statistics } from "./store";
import { webStore } from "./webStore";

// Tauri IPC wrapper. When running inside a Tauri container, invoke IPC commands.
// Fallback to webStore if IPC calls are unavailable.
export const tauriStore: GameStore = {
  async saveGame(state: SaveEnvelope): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_game", { state });
    } catch {
      return webStore.saveGame(state);
    }
  },

  async loadGame(): Promise<SaveEnvelope | null> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<SaveEnvelope | null>("load_game");
    } catch {
      return webStore.loadGame();
    }
  },

  async clearGame(): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("clear_game");
    } catch {
      return webStore.clearGame();
    }
  },

  async saveStatistics(gameType: string, stats: Statistics): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_statistics", { gameType, stats });
    } catch {
      return webStore.saveStatistics(gameType, stats);
    }
  },

  async loadStatistics(gameType: string): Promise<Statistics> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<Statistics>("load_statistics", { gameType });
    } catch {
      return webStore.loadStatistics(gameType);
    }
  },

  async saveSettings(settings: Settings): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_settings", { settings });
    } catch {
      return webStore.saveSettings(settings);
    }
  },

  async loadSettings(): Promise<Settings> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<Settings>("load_settings");
    } catch {
      return webStore.loadSettings();
    }
  },
};
