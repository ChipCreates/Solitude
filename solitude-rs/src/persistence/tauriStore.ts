import { GameStore, SaveEnvelope, Settings, Statistics, Profile } from "./store";
import { webStore } from "./webStore";

// Tauri IPC wrapper. When running inside a Tauri container, invoke IPC commands.
// Fallback to webStore if IPC calls are unavailable.
export const tauriStore: GameStore = {
  // --- Profiles ---
  async getProfiles(): Promise<Profile[]> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<Profile[]>("get_profiles");
    } catch {
      return webStore.getProfiles();
    }
  },

  async saveProfile(profile: Profile): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_profile", { profile });
    } catch {
      return webStore.saveProfile(profile);
    }
  },

  async deleteProfile(profileId: string): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("delete_profile", { profileId });
    } catch {
      return webStore.deleteProfile(profileId);
    }
  },

  // --- Scoped Data ---
  async saveGame(profileId: string, state: SaveEnvelope): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_game", { profileId, state });
    } catch {
      return webStore.saveGame(profileId, state);
    }
  },

  async loadGame(profileId: string): Promise<SaveEnvelope | null> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<SaveEnvelope | null>("load_game", { profileId });
    } catch {
      return webStore.loadGame(profileId);
    }
  },

  async clearGame(profileId: string): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("clear_game", { profileId });
    } catch {
      return webStore.clearGame(profileId);
    }
  },

  async saveStatistics(profileId: string, gameType: string, stats: Statistics): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_statistics", { profileId, gameType, stats });
    } catch {
      return webStore.saveStatistics(profileId, gameType, stats);
    }
  },

  async loadStatistics(profileId: string, gameType: string): Promise<Statistics> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<Statistics>("load_statistics", { profileId, gameType });
    } catch {
      return webStore.loadStatistics(profileId, gameType);
    }
  },

  async saveSettings(profileId: string, settings: Settings): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_settings", { profileId, settings });
    } catch {
      return webStore.saveSettings(profileId, settings);
    }
  },

  async loadSettings(profileId: string): Promise<Settings> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<Settings>("load_settings", { profileId });
    } catch {
      return webStore.loadSettings(profileId);
    }
  },

  async saveProgression(profileId: string, progression: import("./store").Progression): Promise<void> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      await invoke("save_progression", { profileId, progression });
    } catch {
      return webStore.saveProgression(profileId, progression);
    }
  },

  async loadProgression(profileId: string): Promise<import("./store").Progression> {
    try {
      const { invoke } = await import("@tauri-apps/api/core");
      return await invoke<import("./store").Progression>("load_progression", { profileId });
    } catch {
      return webStore.loadProgression(profileId);
    }
  },
};
