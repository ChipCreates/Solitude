import { create } from "zustand";

export interface SettingsState {
  drawMode: number;
  autoComplete: boolean;
  themeId: string;
  cardBack: string;
  soundEnabled: boolean;
  soundVolume: number;
  leftHandMode: boolean;
  setDrawMode: (mode: number) => void;
  setThemeId: (id: string) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setSoundVolume: (vol: number) => void;
  setLeftHandMode: (leftHand: boolean) => void;
}

export const useUIStore = create<SettingsState>((set) => ({
  drawMode: 1,
  autoComplete: true,
  themeId: "classic_felt",
  cardBack: "classic_gold",
  soundEnabled: true,
  soundVolume: 0.8,
  leftHandMode: false,

  setDrawMode: (drawMode) => set({ drawMode }),
  setThemeId: (themeId) => set({ themeId }),
  setSoundEnabled: (soundEnabled) => set({ soundEnabled }),
  setSoundVolume: (soundVolume) => set({ soundVolume }),
  setLeftHandMode: (leftHandMode) => set({ leftHandMode }),
}));
