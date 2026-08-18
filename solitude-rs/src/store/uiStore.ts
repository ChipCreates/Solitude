import { create } from "zustand";

export interface SettingsState {
  drawMode: number;
  autoComplete: boolean;
  themeId: string;
  cardBack: string;
  soundEnabled: boolean;
  soundVolume: number;
  leftHandMode: boolean;
  victoryPattern: "cascade" | "fountain" | "scatter" | "vortex";
  setDrawMode: (mode: number) => void;
  setThemeId: (id: string) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setSoundVolume: (vol: number) => void;
  setLeftHandMode: (leftHand: boolean) => void;
  setVictoryPattern: (pattern: "cascade" | "fountain" | "scatter" | "vortex") => void;
}

export const useUIStore = create<SettingsState>((set) => ({
  drawMode: 1,
  autoComplete: true,
  themeId: "classic_felt",
  cardBack: "classic_gold",
  soundEnabled: true,
  soundVolume: 0.8,
  leftHandMode: false,
  victoryPattern: "cascade",

  setDrawMode: (drawMode) => set({ drawMode }),
  setThemeId: (themeId) => set({ themeId }),
  setSoundEnabled: (soundEnabled) => set({ soundEnabled }),
  setSoundVolume: (soundVolume) => set({ soundVolume }),
  setLeftHandMode: (leftHandMode) => set({ leftHandMode }),
  setVictoryPattern: (victoryPattern) => set({ victoryPattern }),
}));
