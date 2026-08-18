import { create } from "zustand";

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
  setDrawMode: (mode: number) => void;
  setThemeId: (id: string) => void;
  setThemeOverlayIntensity: (themeId: string, intensity: number) => void;
  setCardBackPattern: (pattern: string) => void;
  setCardBackColor: (color: string) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setSoundVolume: (vol: number) => void;
  setLeftHandMode: (leftHand: boolean) => void;
  setVictoryPattern: (pattern: "cascade" | "fountain" | "scatter" | "vortex") => void;
}

export const useUIStore = create<SettingsState>((set) => ({
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

  setDrawMode: (drawMode) => set({ drawMode }),
  setThemeId: (themeId) => set({ themeId }),
  setThemeOverlayIntensity: (themeId, intensity) => 
    set((state) => ({ themeOverlayIntensities: { ...state.themeOverlayIntensities, [themeId]: intensity } })),
  setCardBackPattern: (cardBackPattern) => set({ cardBackPattern }),
  setCardBackColor: (cardBackColor) => set({ cardBackColor }),
  setSoundEnabled: (soundEnabled) => set({ soundEnabled }),
  setSoundVolume: (soundVolume) => set({ soundVolume }),
  setLeftHandMode: (leftHandMode) => set({ leftHandMode }),
  setVictoryPattern: (victoryPattern) => set({ victoryPattern }),
}));
