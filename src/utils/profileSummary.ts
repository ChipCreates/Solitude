import { store } from "../persistence/store";
import { GAME_TYPE_NAMES } from "../data/gameTypes";
import { getGlobalLevel } from "./levelTitles";

export interface ProfileSummary {
  coins: number;
  gamesPlayed: number;
  gamesWon: number;
  level: number;
}

export async function loadProfileSummary(profileId: string): Promise<ProfileSummary> {
  const [progression, statsEntries] = await Promise.all([
    store.loadProgression(profileId),
    Promise.all(GAME_TYPE_NAMES.map((gameType) => store.loadStatistics(profileId, gameType))),
  ]);
  const gamesPlayed = statsEntries.reduce((sum, s) => sum + s.gamesPlayed, 0);
  const gamesWon = statsEntries.reduce((sum, s) => sum + s.gamesWon, 0);
  const { level } = getGlobalLevel(progression.gameProgress);
  return { coins: progression.coins, gamesPlayed, gamesWon, level };
}
