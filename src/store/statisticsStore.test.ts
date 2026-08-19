import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../persistence/store", () => ({
  store: {
    loadStatistics: vi.fn().mockResolvedValue({
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
      bestTimeMs: null,
      fewestMoves: null,
    }),
    saveStatistics: vi.fn().mockResolvedValue(undefined),
  },
}));

import { useStatisticsStore } from "./statisticsStore";

describe("statisticsStore", () => {
  beforeEach(() => {
    useStatisticsStore.setState({ statsByGameType: {} });
  });

  it("getStats returns defaults for an unseen game type", () => {
    expect(useStatisticsStore.getState().getStats("klondike")).toEqual({
      gamesPlayed: 0,
      gamesWon: 0,
      gamesLost: 0,
      currentStreak: 0,
      bestStreak: 0,
      bestTimeMs: null,
      fewestMoves: null,
    });
  });

  it("recordWin increments played/won, extends streak, and tracks bests", async () => {
    await useStatisticsStore.getState().recordWin("klondike", 5000, 40);
    await useStatisticsStore.getState().recordWin("klondike", 3000, 30);

    const stats = useStatisticsStore.getState().getStats("klondike");
    expect(stats.gamesPlayed).toBe(2);
    expect(stats.gamesWon).toBe(2);
    expect(stats.currentStreak).toBe(2);
    expect(stats.bestStreak).toBe(2);
    expect(stats.bestTimeMs).toBe(3000);
    expect(stats.fewestMoves).toBe(30);
  });

  it("recordLoss increments played/lost and resets the current streak", async () => {
    await useStatisticsStore.getState().recordWin("spider", 1000, 10);
    await useStatisticsStore.getState().recordLoss("spider");

    const stats = useStatisticsStore.getState().getStats("spider");
    expect(stats.gamesPlayed).toBe(2);
    expect(stats.gamesLost).toBe(1);
    expect(stats.currentStreak).toBe(0);
    expect(stats.bestStreak).toBe(1);
  });

  it("getAggregateStats sums across all game types and takes the max best streak", async () => {
    await useStatisticsStore.getState().recordWin("Klondike", 1000, 10);
    await useStatisticsStore.getState().recordWin("Klondike", 1000, 10);
    await useStatisticsStore.getState().recordWin("Klondike", 1000, 10);
    await useStatisticsStore.getState().recordWin("Spider", 1000, 10);
    await useStatisticsStore.getState().recordLoss("Spider");

    const aggregate = useStatisticsStore.getState().getAggregateStats();
    expect(aggregate.totalGamesPlayed).toBe(5);
    expect(aggregate.totalGamesWon).toBe(4);
    expect(aggregate.totalGamesLost).toBe(1);
    expect(aggregate.overallWinRate).toBe(80);
    expect(aggregate.bestStreak).toBe(3);
  });

  it("getAggregateStats returns zeros when no games have been played", () => {
    expect(useStatisticsStore.getState().getAggregateStats()).toEqual({
      totalGamesPlayed: 0,
      totalGamesWon: 0,
      totalGamesLost: 0,
      overallWinRate: 0,
      bestStreak: 0,
    });
  });
});
