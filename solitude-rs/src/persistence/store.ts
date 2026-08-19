import { webStore } from "./webStore";
import { tauriStore } from "./tauriStore";

export interface SaveEnvelope {
  schema_version: number;
  game_type: string;
  piles: unknown[];
  move_count: number;
  elapsed_ms: number;
  saved_at: number;
  variant_data: Record<string, unknown>;
}

export interface Statistics {
  gamesPlayed: number;
  gamesWon: number;
  gamesLost: number;
  currentStreak: number;
  bestStreak: number;
  bestTimeMs: number | null;
  fewestMoves: number | null;
}

export interface Settings {
  drawMode: number; // 1 or 3
  autoComplete: boolean;
  themeId: string;
  themeOverlayIntensities?: Record<string, number>;
  cardBack: string;
  cardBackColor?: string;
  soundEnabled: boolean;
  soundVolume: number;
  musicEnabled?: boolean;
  musicVolume?: number;
  leftHandMode?: boolean;
  victoryPattern?: string;
  showTimer?: boolean;
  autoplay?: boolean;
  scoringMode?: string;
  vegasBankroll?: number;
  golfWrapAround?: boolean;
}

export interface GameProgression {
  level: number;
  xp: number;
}

export interface Progression {
  coins: number;
  unlockedItems: string[];
  unlockedAchievements: string[];
  difficulty: "easy" | "normal" | "hard";
  gameProgress: Record<string, GameProgression>;
}

export interface Profile {
  id: string;
  name: string;
  avatarId: string;
  createdAt: number;
  lastPlayed: number;
}

export interface GameStore {
  // Profiles
  getProfiles(): Promise<Profile[]>;
  saveProfile(profile: Profile): Promise<void>;
  deleteProfile(profileId: string): Promise<void>;
  
  // Scoped Data
  saveGame(profileId: string, state: SaveEnvelope): Promise<void>;
  loadGame(profileId: string): Promise<SaveEnvelope | null>;
  clearGame(profileId: string): Promise<void>;
  
  saveStatistics(profileId: string, gameType: string, stats: Statistics): Promise<void>;
  loadStatistics(profileId: string, gameType: string): Promise<Statistics>;
  
  saveSettings(profileId: string, settings: Settings): Promise<void>;
  loadSettings(profileId: string): Promise<Settings>;
  
  saveProgression(profileId: string, progression: Progression): Promise<void>;
  loadProgression(profileId: string): Promise<Progression>;
}

export function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}

export const store: GameStore = isTauri() ? tauriStore : webStore;
