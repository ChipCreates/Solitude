import { create } from "zustand";
import { useProfileStore } from "./profileStore";
import type { Settings, Progression } from "../persistence/store";
import { MUSIC_TRACKS } from "../data/musicTracks";

export interface SettingsState {
  drawMode: number;
  autoComplete: boolean;
  themeId: string;
  themeOverlayIntensities: Record<string, number>;
  cardBackPattern: string;
  cardBackColor: string;
  soundEnabled: boolean;
  soundVolume: number;
  leftHandMode: boolean;
  victoryPattern: "cascade" | "fountain" | "scatter" | "vortex";
  coins: number;
  unlockedItems: string[];
  unlockedAchievements: string[];
  difficulty: "easy" | "normal" | "hard";
  gameProgress: Record<string, { level: number; xp: number }>;
  // Consumable count per power-up id, distinct from unlockedItems (which is
  // a permanent one-time flag used for cosmetics). Buying a power-up adds to
  // its count; using one decrements it.
  powerUpInventory: Record<string, number>;

  showTimer: boolean;
  autoplay: boolean;
  scoringMode: "standard" | "vegas" | "vegas_cumulative";
  vegasBankroll: number;
  golfWrapAround: boolean;
  musicEnabled: boolean;
  musicVolume: number;
  musicTrackId: string;
  // A player-picked local file, not a persisted setting: object URLs die
  // with the page, and there's nothing meaningful to restore across
  // sessions or devices, so this lives only in memory for the session.
  customMusicUrl: string | null;
  customMusicName: string | null;

  setDrawMode: (mode: number) => void;
  setAutoComplete: (enabled: boolean) => void;
  setThemeId: (id: string) => void;
  setThemeOverlayIntensity: (themeId: string, intensity: number) => void;
  setCardBackPattern: (pattern: string) => void;
  setCardBackColor: (color: string) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setSoundVolume: (vol: number) => void;
  setLeftHandMode: (leftHand: boolean) => void;
  setVictoryPattern: (pattern: "cascade" | "fountain" | "scatter" | "vortex") => void;
  
  setShowTimer: (show: boolean) => void;
  setAutoplay: (enabled: boolean) => void;
  setScoringMode: (mode: "standard" | "vegas" | "vegas_cumulative") => void;
  resetVegasBankroll: () => void;
  addToVegasBankroll: (delta: number) => void;
  setGolfWrapAround: (enabled: boolean) => void;
  setMusicEnabled: (enabled: boolean) => void;
  setMusicVolume: (vol: number) => void;
  setMusicTrackId: (id: string) => void;
  setCustomMusicTrack: (url: string | null, name: string | null) => void;

  addCoins: (amount: number) => void;
  subtractCoins: (amount: number) => boolean;
  unlockItem: (itemId: string) => void;
  unlockAchievement: (achievementId: string) => void;
  purchasePowerUp: (powerUpId: string, price: number) => boolean;
  consumePowerUp: (powerUpId: string) => boolean;
  refundPowerUp: (powerUpId: string) => void;
  setDifficulty: (difficulty: "easy" | "normal" | "hard") => void;
  addXP: (gameType: string, amount: number) => { leveledUp: boolean, newLevel: number, newXP: number };
  initializeStore: () => Promise<void>;
}

// Zustand stores actions and data in one flat object. IndexedDB's structured
// clone algorithm can't serialize functions, so persistence payloads must be
// built from an explicit, data-only shape rather than spreading get().
function settingsSnapshot(state: SettingsState): Settings {
  return {
    drawMode: state.drawMode,
    autoComplete: state.autoComplete,
    themeId: state.themeId,
    themeOverlayIntensities: state.themeOverlayIntensities,
    cardBack: state.cardBackPattern,
    cardBackColor: state.cardBackColor,
    soundEnabled: state.soundEnabled,
    soundVolume: state.soundVolume,
    musicEnabled: state.musicEnabled,
    musicVolume: state.musicVolume,
    leftHandMode: state.leftHandMode,
    victoryPattern: state.victoryPattern,
    showTimer: state.showTimer,
    autoplay: state.autoplay,
    scoringMode: state.scoringMode,
    vegasBankroll: state.vegasBankroll,
    golfWrapAround: state.golfWrapAround,
    musicTrackId: state.musicTrackId,
  };
}

function progressionSnapshot(state: SettingsState): Progression {
  return {
    coins: state.coins,
    unlockedItems: state.unlockedItems,
    unlockedAchievements: state.unlockedAchievements,
    difficulty: state.difficulty,
    gameProgress: state.gameProgress,
    powerUpInventory: state.powerUpInventory,
  };
}

export const useUIStore = create<SettingsState>((set, get) => ({
  drawMode: 1,
  autoComplete: true,
  themeId: "classic_felt",
  themeOverlayIntensities: {},
  cardBackPattern: "diamond",
  cardBackColor: "#1e3a2b",
  soundEnabled: true,
  soundVolume: 0.8,
  leftHandMode: false,
  victoryPattern: "cascade",
  coins: 0,
  unlockedItems: [],
  unlockedAchievements: [],
  difficulty: "normal",
  gameProgress: {},
  powerUpInventory: {},

  showTimer: true,
  autoplay: false,
  scoringMode: "standard",
  vegasBankroll: 0,
  golfWrapAround: false,
  musicEnabled: false,
  musicVolume: 0.5,
  musicTrackId: MUSIC_TRACKS[0]?.id ?? "",
  customMusicUrl: null,
  customMusicName: null,

  setDrawMode: (drawMode) => { set({ drawMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setAutoComplete: (autoComplete) => { set({ autoComplete }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setThemeId: (themeId) => { set({ themeId }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setThemeOverlayIntensity: (themeId, intensity) => {
    set((state) => ({ themeOverlayIntensities: { ...state.themeOverlayIntensities, [themeId]: intensity } }));
    import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get())));
  },
  setCardBackPattern: (cardBackPattern) => { set({ cardBackPattern }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setCardBackColor: (cardBackColor) => { set({ cardBackColor }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setSoundEnabled: (soundEnabled) => { set({ soundEnabled }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setSoundVolume: (soundVolume) => { set({ soundVolume }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setLeftHandMode: (leftHandMode) => { set({ leftHandMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setVictoryPattern: (victoryPattern) => { set({ victoryPattern }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  
  setShowTimer: (showTimer) => { set({ showTimer }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setAutoplay: (autoplay) => { set({ autoplay }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setScoringMode: (scoringMode) => { set({ scoringMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  resetVegasBankroll: () => { set({ vegasBankroll: 0 }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  addToVegasBankroll: (delta) => { set((state) => ({ vegasBankroll: state.vegasBankroll + delta })); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setGolfWrapAround: (golfWrapAround) => { set({ golfWrapAround }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setMusicEnabled: (musicEnabled) => { set({ musicEnabled }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setMusicVolume: (musicVolume) => { set({ musicVolume }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setMusicTrackId: (musicTrackId) => { set({ musicTrackId }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, settingsSnapshot(get()))); },
  setCustomMusicTrack: (customMusicUrl, customMusicName) => { set({ customMusicUrl, customMusicName }); },

  addCoins: (amount) => {
    set((state) => ({ coins: state.coins + amount }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
  },
  subtractCoins: (amount) => {
    const { coins } = get();
    if (coins >= amount) {
      set({ coins: coins - amount });
      import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
      return true;
    }
    return false;
  },
  unlockItem: (itemId) => {
    set((state) => ({ 
      unlockedItems: state.unlockedItems.includes(itemId) ? state.unlockedItems : [...state.unlockedItems, itemId] 
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
  },
  unlockAchievement: (achievementId) => {
    set((state) => ({
      unlockedAchievements: state.unlockedAchievements.includes(achievementId) ? state.unlockedAchievements : [...state.unlockedAchievements, achievementId]
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
  },
  purchasePowerUp: (powerUpId, price) => {
    const { coins } = get();
    if (coins < price) return false;
    set((state) => ({
      coins: state.coins - price,
      powerUpInventory: { ...state.powerUpInventory, [powerUpId]: (state.powerUpInventory[powerUpId] ?? 0) + 1 },
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
    return true;
  },
  consumePowerUp: (powerUpId) => {
    const { powerUpInventory } = get();
    if ((powerUpInventory[powerUpId] ?? 0) <= 0) return false;
    set((state) => ({
      powerUpInventory: { ...state.powerUpInventory, [powerUpId]: state.powerUpInventory[powerUpId] - 1 },
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
    return true;
  },
  // Returns a consumed power-up's charge to inventory without touching
  // coins, for when the underlying effect turned out to have no legal
  // target (e.g. Undo Token with empty history) — the player shouldn't
  // lose the item for something that had no effect.
  refundPowerUp: (powerUpId) => {
    set((state) => ({
      powerUpInventory: { ...state.powerUpInventory, [powerUpId]: (state.powerUpInventory[powerUpId] ?? 0) + 1 },
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
  },
  setDifficulty: (difficulty) => {
    set({ difficulty });
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
  },
  
  addXP: (gameType, amount) => {
    const state = get();
    const progress = state.gameProgress[gameType] || { level: 1, xp: 0 };
    let newXP = progress.xp + amount;
    let newLevel = progress.level;
    let leveledUp = false;
    
    // Calculate required XP for next level: Base * (Level ^ 1.5)
    // Let's use 500 as the base for level 2, scaling up.
    let xpRequired = Math.floor(500 * Math.pow(newLevel, 1.5));
    
    while (newXP >= xpRequired) {
      newXP -= xpRequired;
      newLevel++;
      leveledUp = true;
      xpRequired = Math.floor(500 * Math.pow(newLevel, 1.5));
    }
    
    set({
      gameProgress: {
        ...state.gameProgress,
        [gameType]: { level: newLevel, xp: newXP }
      }
    });
    
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, progressionSnapshot(get())));
    
    return { leveledUp, newLevel, newXP };
  },

  initializeStore: async () => {
    try {
      const { store } = await import("../persistence/store");
      const settings = await store.loadSettings(useProfileStore.getState().activeProfileId);
      const progression = await store.loadProgression(useProfileStore.getState().activeProfileId);
      
      set({
        drawMode: settings.drawMode,
        autoComplete: settings.autoComplete,
        themeId: settings.themeId,
        themeOverlayIntensities: settings.themeOverlayIntensities ?? {},
        cardBackPattern: settings.cardBack,
        cardBackColor: settings.cardBackColor ?? "#1e3a2b",
        soundEnabled: settings.soundEnabled,
        soundVolume: settings.soundVolume,
        musicEnabled: settings.musicEnabled ?? false,
        musicVolume: settings.musicVolume ?? 0.5,
        leftHandMode: settings.leftHandMode,
        victoryPattern: (settings.victoryPattern as SettingsState["victoryPattern"]) ?? "cascade",
        showTimer: settings.showTimer ?? true,
        autoplay: settings.autoplay ?? false,
        scoringMode: (settings.scoringMode as SettingsState["scoringMode"]) ?? "standard",
        vegasBankroll: settings.vegasBankroll ?? 0,
        golfWrapAround: settings.golfWrapAround ?? false,
        musicTrackId: settings.musicTrackId ?? MUSIC_TRACKS[0]?.id ?? "",

        coins: progression.coins,
        unlockedItems: progression.unlockedItems,
        unlockedAchievements: progression.unlockedAchievements,
        difficulty: progression.difficulty,
        gameProgress: progression.gameProgress || {},
        powerUpInventory: progression.powerUpInventory || {},
      });
    } catch (e) {
      console.error("Failed to initialize store", e);
    }
  }
}));
