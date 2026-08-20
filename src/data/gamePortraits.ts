import { GAME_TYPE_NAMES } from "./gameTypes";

// Indexed to match GAME_TYPE_NAMES / engine gameTypeCode ordering.
const PORTRAIT_FILES = [
  "king.webp", "spider-king.webp", "wizard.webp", "pyramid.webp", "jester.webp",
  "tripeaks.webp", "knight.webp", "thief.webp", "fortune-teller.webp", "rogue.webp",
];

export const GAME_PORTRAITS: string[] = PORTRAIT_FILES.map((f) => `/assets/tiles/webp/${f}`);

export function getGamePortrait(gameTypeCode: number): string | undefined {
  return GAME_PORTRAITS[gameTypeCode];
}

export function getGamePortraitByName(name: string): string | undefined {
  const idx = GAME_TYPE_NAMES.indexOf(name);
  return idx >= 0 ? GAME_PORTRAITS[idx] : undefined;
}
