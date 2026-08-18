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
  cardBack: string;
  soundEnabled: boolean;
  soundVolume: number;
  leftHandMode: boolean;
}

export interface GameStore {
  saveGame(state: SaveEnvelope): Promise<void>;
  loadGame(): Promise<SaveEnvelope | null>;
  clearGame(): Promise<void>;
  saveStatistics(gameType: string, stats: Statistics): Promise<void>;
  loadStatistics(gameType: string): Promise<Statistics>;
  saveSettings(settings: Settings): Promise<void>;
  loadSettings(): Promise<Settings>;
}

export function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}

export const store: GameStore = isTauri() ? tauriStore : webStore;
