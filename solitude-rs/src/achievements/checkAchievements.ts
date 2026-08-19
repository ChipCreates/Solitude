import achievementsData from "../data/achievements.json";
import { useUIStore } from "../store/uiStore";
import { Statistics } from "../persistence/store";

export interface WinAchievementContext {
  elapsedMs: number;
  moveCount: number;
  updatedStats: Statistics;
  usedHintOrUndo: boolean;
}

/**
 * Evaluates the achievement list against the just-completed win and unlocks
 * any newly-earned ones. `updatedStats` must be the stats snapshot taken
 * AFTER recordWin() so gamesWon/currentStreak reflect this round.
 *
 * Returns the titles of newly unlocked achievements, for UI feedback.
 */
export function checkWinAchievements(ctx: WinAchievementContext): string[] {
  const { unlockAchievement, unlockedAchievements } = useUIStore.getState();
  const alreadyUnlocked = new Set(unlockedAchievements);
  const newlyUnlocked: string[] = [];

  for (const ach of achievementsData.achievements) {
    if (alreadyUnlocked.has(ach.id)) continue;

    let earned = false;
    switch (ach.id) {
      case "first_win":
        earned = ctx.updatedStats.gamesWon >= (ach.criteria?.wins ?? 1);
        break;
      case "speed_demon":
        earned = ctx.elapsedMs <= (ach.criteria?.maxTime ?? Infinity) * 1000;
        break;
      case "efficiency_expert":
        earned = ctx.moveCount <= (ach.criteria?.maxMoves ?? Infinity);
        break;
      case "streak_5":
        earned = ctx.updatedStats.currentStreak >= (ach.targetValue ?? 5);
        break;
      case "perfect_game":
        earned = !ctx.usedHintOrUndo;
        break;
    }

    if (earned) {
      unlockAchievement(ach.id);
      newlyUnlocked.push(ach.title);
    }
  }

  return newlyUnlocked;
}
