export interface GameProgress {
  level: number;
  xp: number;
}

interface LevelTitleBand {
  minLevel: number;
  title: string;
}

// Highest matching band (by minLevel) wins.
const LEVEL_TITLE_BANDS: LevelTitleBand[] = [
  { minLevel: 1, title: "Novice" },
  { minLevel: 3, title: "Apprentice" },
  { minLevel: 6, title: "Adept" },
  { minLevel: 10, title: "Expert" },
  { minLevel: 15, title: "Master" },
  { minLevel: 20, title: "Grandmaster" },
];

export function getLevelTitle(level: number): string {
  let title = LEVEL_TITLE_BANDS[0].title;
  for (const band of LEVEL_TITLE_BANDS) {
    if (level >= band.minLevel) title = band.title;
    else break;
  }
  return title;
}

// There's no single account-wide level — each variant levels independently
// — so "overall level" is the player's best result across all variants.
export function getOverallLevel(gameProgress: Record<string, GameProgress>): GameProgress {
  let best: GameProgress | null = null;
  for (const progress of Object.values(gameProgress)) {
    if (!best || progress.level > best.level || (progress.level === best.level && progress.xp > best.xp)) {
      best = progress;
    }
  }
  return best ?? { level: 1, xp: 0 };
}
