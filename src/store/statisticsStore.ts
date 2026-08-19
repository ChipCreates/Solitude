import { create } from "zustand";
import { store, Statistics } from "../persistence/store";
import { useProfileStore } from "./profileStore";
import { GAME_TYPE_NAMES } from "../data/gameTypes";

const DEFAULT_STATS: Statistics = {
  gamesPlayed: 0,
  gamesWon: 0,
  gamesLost: 0,
  currentStreak: 0,
  bestStreak: 0,
  bestTimeMs: null,
  fewestMoves: null,
};

export interface AggregateStatistics {
  totalGamesPlayed: number;
  totalGamesWon: number;
  totalGamesLost: number;
  overallWinRate: number; // 0-100, rounded
  bestStreak: number; // max bestStreak across all variants
}

export interface StatisticsState {
  statsByGameType: Record<string, Statistics>;
  getStats: (gameType: string) => Statistics;
  getAggregateStats: () => AggregateStatistics;
  loadStats: (gameType: string) => Promise<Statistics>;
  loadAllStats: () => Promise<void>;
  recordWin: (gameType: string, elapsedMs: number, moveCount: number) => Promise<void>;
  recordLoss: (gameType: string) => Promise<void>;
}

export const useStatisticsStore = create<StatisticsState>((set, get) => ({
  statsByGameType: {},

  getStats: (gameType) => get().statsByGameType[gameType] ?? DEFAULT_STATS,

  getAggregateStats: () => {
    const { statsByGameType } = get();
    let totalGamesPlayed = 0;
    let totalGamesWon = 0;
    let totalGamesLost = 0;
    let bestStreak = 0;
    for (const gameType of GAME_TYPE_NAMES) {
      const s = statsByGameType[gameType] ?? DEFAULT_STATS;
      totalGamesPlayed += s.gamesPlayed;
      totalGamesWon += s.gamesWon;
      totalGamesLost += s.gamesLost;
      bestStreak = Math.max(bestStreak, s.bestStreak);
    }
    const overallWinRate = totalGamesPlayed > 0 ? Math.round((totalGamesWon / totalGamesPlayed) * 100) : 0;
    return { totalGamesPlayed, totalGamesWon, totalGamesLost, overallWinRate, bestStreak };
  },

  loadStats: async (gameType) => {
    const profileId = useProfileStore.getState().activeProfileId;
    const stats = await store.loadStatistics(profileId, gameType);
    set((state) => ({ statsByGameType: { ...state.statsByGameType, [gameType]: stats } }));
    return stats;
  },

  loadAllStats: async () => {
    const profileId = useProfileStore.getState().activeProfileId;
    const entries = await Promise.all(
      GAME_TYPE_NAMES.map(async (gameType) => [gameType, await store.loadStatistics(profileId, gameType)] as const)
    );
    set((state) => ({ statsByGameType: { ...state.statsByGameType, ...Object.fromEntries(entries) } }));
  },

  recordWin: async (gameType, elapsedMs, moveCount) => {
    const profileId = useProfileStore.getState().activeProfileId;
    const current = get().statsByGameType[gameType] ?? (await store.loadStatistics(profileId, gameType));
    const newStreak = current.currentStreak + 1;
    const updated: Statistics = {
      gamesPlayed: current.gamesPlayed + 1,
      gamesWon: current.gamesWon + 1,
      gamesLost: current.gamesLost,
      currentStreak: newStreak,
      bestStreak: Math.max(newStreak, current.bestStreak),
      bestTimeMs: current.bestTimeMs === null ? elapsedMs : Math.min(current.bestTimeMs, elapsedMs),
      fewestMoves: current.fewestMoves === null ? moveCount : Math.min(current.fewestMoves, moveCount),
    };
    set((state) => ({ statsByGameType: { ...state.statsByGameType, [gameType]: updated } }));
    await store.saveStatistics(profileId, gameType, updated);
  },

  recordLoss: async (gameType) => {
    const profileId = useProfileStore.getState().activeProfileId;
    const current = get().statsByGameType[gameType] ?? (await store.loadStatistics(profileId, gameType));
    const updated: Statistics = {
      ...current,
      gamesPlayed: current.gamesPlayed + 1,
      gamesLost: current.gamesLost + 1,
      currentStreak: 0,
    };
    set((state) => ({ statsByGameType: { ...state.statsByGameType, [gameType]: updated } }));
    await store.saveStatistics(profileId, gameType, updated);
  },
}));
