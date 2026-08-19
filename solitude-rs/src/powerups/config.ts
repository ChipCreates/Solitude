// GameType codes match GAME_TYPE_NAMES / engine GameType ordering:
// 0 Klondike, 1 Spider, 2 FreeCell, 3 Pyramid, 4 Golf, 5 TriPeaks,
// 6 Yukon, 7 Forty Thieves, 8 Canfield, 9 Scorpion.

export type PowerUpTargeting = "none" | "card" | "column";

export interface PowerUpEntry {
  targeting: PowerUpTargeting;
  // Omitted = usable in every game type.
  compatibleGameTypes?: number[];
}

const GAMES_WITH_STOCK = [0, 1, 3, 4, 5, 7, 8, 9]; // all except FreeCell(2), Yukon(6)
const GAMES_WITH_TABLEAU = [0, 1, 2, 4, 6, 7, 8, 9]; // all except Pyramid(3), TriPeaks(5)
const GAMES_WITH_WASTE = [0, 3, 4, 5, 7, 8]; // Klondike, Pyramid, Golf, TriPeaks, Forty Thieves, Canfield

export const POWER_UP_CONFIG: Record<string, PowerUpEntry> = {
  unstick_wand: { targeting: "none" },
  peek_charm: { targeting: "card" },
  deck_whisper: { targeting: "none", compatibleGameTypes: GAMES_WITH_STOCK },
  lucky_reshuffle: { targeting: "none", compatibleGameTypes: GAMES_WITH_STOCK },
  undo_token: { targeting: "none" },
  column_breather: { targeting: "column", compatibleGameTypes: GAMES_WITH_TABLEAU },
  extra_hint: { targeting: "none" },
  second_look: { targeting: "none", compatibleGameTypes: GAMES_WITH_WASTE },
  foundation_nudge: { targeting: "none" },
  time_ease: { targeting: "none" },
  free_slot: { targeting: "card" },
  reset_column: { targeting: "column", compatibleGameTypes: GAMES_WITH_TABLEAU },
};
