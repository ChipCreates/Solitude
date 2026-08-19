import { create } from "zustand";
import { useProfileStore } from "./profileStore";

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
  
  showTimer: boolean;
  autoplay: boolean;
  scoringMode: "standard" | "vegas" | "vegas_cumulative";
  vegasBankroll: number;
  musicEnabled: boolean;
  musicVolume: number;
  
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
  setMusicEnabled: (enabled: boolean) => void;
  setMusicVolume: (vol: number) => void;
  
  addCoins: (amount: number) => void;
  subtractCoins: (amount: number) => boolean;
  unlockItem: (itemId: string) => void;
  unlockAchievement: (achievementId: string) => void;
  setDifficulty: (difficulty: "easy" | "normal" | "hard") => void;
  addXP: (gameType: string, amount: number) => { leveledUp: boolean, newLevel: number, newXP: number };
  initializeStore: () => Promise<void>;
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
  
  showTimer: true,
  autoplay: false,
  scoringMode: "standard",
  vegasBankroll: 0,
  musicEnabled: false,
  musicVolume: 0.5,

  setDrawMode: (drawMode) => { set({ drawMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setAutoComplete: (autoComplete) => { set({ autoComplete }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setThemeId: (themeId) => { set({ themeId }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setThemeOverlayIntensity: (themeId, intensity) => {
    set((state) => ({ themeOverlayIntensities: { ...state.themeOverlayIntensities, [themeId]: intensity } }));
    import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern }));
  },
  setCardBackPattern: (cardBackPattern) => { set({ cardBackPattern }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setCardBackColor: (cardBackColor) => { set({ cardBackColor }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setSoundEnabled: (soundEnabled) => { set({ soundEnabled }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setSoundVolume: (soundVolume) => { set({ soundVolume }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setLeftHandMode: (leftHandMode) => { set({ leftHandMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setVictoryPattern: (victoryPattern) => { set({ victoryPattern }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  
  setShowTimer: (showTimer) => { set({ showTimer }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setAutoplay: (autoplay) => { set({ autoplay }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setScoringMode: (scoringMode) => { set({ scoringMode }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  resetVegasBankroll: () => { set({ vegasBankroll: 0 }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setMusicEnabled: (musicEnabled) => { set({ musicEnabled }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },
  setMusicVolume: (musicVolume) => { set({ musicVolume }); import("../persistence/store").then(({ store }) => store.saveSettings(useProfileStore.getState().activeProfileId, { ...get(), cardBack: get().cardBackPattern })); },

  addCoins: (amount) => {
    set((state) => ({ coins: state.coins + amount }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
  },
  subtractCoins: (amount) => {
    const { coins } = get();
    if (coins >= amount) {
      set({ coins: coins - amount });
      import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
      return true;
    }
    return false;
  },
  unlockItem: (itemId) => {
    set((state) => ({ 
      unlockedItems: state.unlockedItems.includes(itemId) ? state.unlockedItems : [...state.unlockedItems, itemId] 
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
  },
  unlockAchievement: (achievementId) => {
    set((state) => ({
      unlockedAchievements: state.unlockedAchievements.includes(achievementId) ? state.unlockedAchievements : [...state.unlockedAchievements, achievementId]
    }));
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
  },
  setDifficulty: (difficulty) => {
    set({ difficulty });
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
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
    
    import("../persistence/store").then(({ store }) => store.saveProgression(useProfileStore.getState().activeProfileId, get()));
    
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
        cardBackPattern: settings.cardBack,
        soundEnabled: settings.soundEnabled,
        soundVolume: settings.soundVolume,
        leftHandMode: settings.leftHandMode,
        
        coins: progression.coins,
        unlockedItems: progression.unlockedItems,
        unlockedAchievements: progression.unlockedAchievements,
        difficulty: progression.difficulty,
        gameProgress: progression.gameProgress || {},
      });
    } catch (e) {
      console.error("Failed to initialize store", e);
    }
  }
}));
