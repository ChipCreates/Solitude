export interface GameProgress {
  level: number;
  xp: number;
}

interface LevelTitleBand {
  minLevel: number;
  title: string;
  description: string;
}

// Early titles arrive quickly; later ones take much longer, since both the
// level gaps here and the per-level XP cost (xpRequiredForLevel) grow.
const LEVEL_TITLE_BANDS: LevelTitleBand[] = [
  { minLevel: 1, title: "Novice", description: "You've shuffled a deck. Some would call that ambition." },
  { minLevel: 3, title: "Apprentice", description: "You can tell a foundation from a tableau. Your family is so proud." },
  { minLevel: 6, title: "Adept", description: "You've mostly stopped undoing your own good moves." },
  { minLevel: 10, title: "Journeyman", description: "You play in public now. There is no shame left to lose." },
  { minLevel: 15, title: "Expert", description: "You see four moves ahead. Your houseplants see zero." },
  { minLevel: 22, title: "Specialist", description: "You have Opinions about draw-one versus draw-three. Nobody asked." },
  { minLevel: 30, title: "Veteran", description: "You've rage-quit and come crawling back more times than you'll admit." },
  { minLevel: 40, title: "Master", description: "The card backs judge you. They still lose." },
  { minLevel: 55, title: "Grandmaster", description: "You dream in suits and ranks. It's a little concerning." },
  { minLevel: 75, title: "Elite", description: "The deck fears you. As it should." },
  { minLevel: 100, title: "Legend", description: "Children are told stories about your win streak. They don't believe them." },
  { minLevel: 150, title: "Immortal", description: "Less a player now, more a force of nature with opposable thumbs." },
];

function getBandForLevel(level: number): LevelTitleBand {
  let band = LEVEL_TITLE_BANDS[0];
  for (const candidate of LEVEL_TITLE_BANDS) {
    if (level >= candidate.minLevel) band = candidate;
    else break;
  }
  return band;
}

export function getLevelTitle(level: number): string {
  return getBandForLevel(level).title;
}

export function getLevelTitleDescription(level: number): string {
  return getBandForLevel(level).description;
}

// XP required to advance from `level` to `level + 1`. Shared by per-game
// leveling (uiStore.addXP) and the aggregate global level below, so both
// stay on the same curve.
export function xpRequiredForLevel(level: number): number {
  return Math.floor(500 * Math.pow(level, 1.5));
}

// Total XP ever earned in one variant: the XP spent reaching its current
// level, plus whatever's left over toward the next one. A variant's own
// `xp` field only holds that leftover remainder, not the full history.
function totalXpEarned(progress: GameProgress): number {
  let total = progress.xp;
  for (let lvl = 1; lvl < progress.level; lvl++) {
    total += xpRequiredForLevel(lvl);
  }
  return total;
}

// A single account-wide level, game-agnostic: pools total XP earned across
// every variant and re-walks it through the same curve used per-game. This
// way playing any variant contributes to one shared progression, rather
// than the player's title just reflecting whichever game they've pushed
// furthest.
export function getGlobalLevel(gameProgress: Record<string, GameProgress>): GameProgress {
  let pooledXp = 0;
  for (const progress of Object.values(gameProgress)) {
    pooledXp += totalXpEarned(progress);
  }

  let level = 1;
  let xpRequired = xpRequiredForLevel(level);
  while (pooledXp >= xpRequired) {
    pooledXp -= xpRequired;
    level++;
    xpRequired = xpRequiredForLevel(level);
  }

  return { level, xp: pooledXp };
}
