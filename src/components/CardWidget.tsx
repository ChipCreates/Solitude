import React from 'react';
import { GILDED_MYSTERY_ATLAS_URL, GILDED_MYSTERY_ATLAS_SIZE, GILDED_MYSTERY_ATLAS_CELLS, AtlasCell } from '../data/gildedMysteryAtlas';
import { DEFAULT_ATLAS_URL, DEFAULT_ATLAS_SIZE, DEFAULT_ATLAS_CELLS } from '../data/defaultAtlas';
import { FANTASY_ATLAS_URL, FANTASY_ATLAS_SIZE, FANTASY_ATLAS_CELLS } from '../data/fantasyAtlas';

export interface CardWidgetProps {
  id: number;
  rank: number;
  suit: number;
  faceUp: boolean;
  width: number;
  height: number;
  theme: any;
  overlayIntensity: number;
  cardFaceSet: string;
  cardBackPattern: string;
  cardBackColor: string;
  isSelected: boolean;
  isHint: boolean;
  hideShadow?: boolean;
}

export const getBackPatternCss = (pattern: string) => {
  switch (pattern) {
    case 'bicycle': return `url(/assets/cards/back_bicycle.png)`;
    case 'filigree': return `url(/assets/cards/back_filigree.png)`;
    case 'botanical': return `url(/assets/cards/back_botanical.png)`;
    case 'mystic': return `url(/assets/cards/back_mystic.png)`;
    case 'dragon': return `url(/assets/cards/card_back_dragon_1787130558476.png)`;
    case 'celestial': return `url(/assets/cards/card_back_celestial_1787130567064.png)`;
    case 'gilded_mystery': return `url(/assets/cards/the_gilded_mystery/back.webp)`;
    case 'crosshatch':
      return `linear-gradient(45deg, rgba(255,255,255,0.1) 25%, transparent 25%, transparent 75%, rgba(255,255,255,0.1) 75%, rgba(255,255,255,0.1)), linear-gradient(-45deg, rgba(255,255,255,0.1) 25%, transparent 25%, transparent 75%, rgba(255,255,255,0.1) 75%, rgba(255,255,255,0.1))`;
    case 'dots':
      return `radial-gradient(circle, rgba(255,255,255,0.15) 15%, transparent 16%), radial-gradient(circle, rgba(255,255,255,0.15) 15%, transparent 16%)`;
    case 'waves':
      return `repeating-radial-gradient(circle at 0 0, transparent 0, rgba(255,255,255,0.05) 10px, transparent 11px, rgba(255,255,255,0.05) 12px, transparent 20px)`;
    case 'diamond':
    default:
      return `repeating-linear-gradient(45deg, rgba(255,255,255,0.05) 0px, rgba(255,255,255,0.05) 10px, transparent 10px, transparent 20px), repeating-linear-gradient(-45deg, rgba(255,255,255,0.05) 0px, rgba(255,255,255,0.05) 10px, transparent 10px, transparent 20px)`;
  }
};

export const getBackPatternSize = (pattern: string) => {
  switch (pattern) {
    case 'bicycle':
    case 'filigree':
    case 'botanical':
    case 'mystic':
    case 'dragon':
    case 'celestial':
    case 'gilded_mystery': return '100% 100%';
    case 'crosshatch': return '20px 20px';
    case 'dots': return '20px 20px';
    case 'waves': return '40px 40px';
    case 'diamond':
    default: return 'auto';
  }
};

export const getBackPatternPosition = (pattern: string) => {
  switch (pattern) {
    case 'bicycle':
    case 'filigree':
    case 'botanical':
    case 'mystic':
    case 'dragon':
    case 'celestial':
    case 'gilded_mystery': return 'center';
    case 'dots': return '0 0, 10px 10px';
    case 'crosshatch': return '0 0, 10px 10px';
    default: return '0 0';
  }
};

// Every card face is a pre-rendered image, one file per deck per rank/suit,
// named by the same two-character code across all decks (e.g. "AH", "TC",
// "KS") so a single path formula covers every deck -- only the file
// extension and folder name vary. Every current deck is atlas-backed (see
// DECK_ATLAS_FAMILY below) so both maps are empty today; they exist for the
// next per-file deck, and cardImagePath falls back sanely without an entry.
const CARD_DECK_EXTENSION: Record<string, string> = {};
const CARD_DECK_FOLDER: Record<string, string> = {};
const RANK_CODE: Record<number, string> = { 1: 'A', 10: 'T', 11: 'J', 12: 'Q', 13: 'K' };
const SUIT_CODE = ['H', 'D', 'C', 'S']; // matches the engine's suit-index order (0=hearts..3=spades)

// Decks with an alternate, simplified rendering (flat rank + single large
// pip instead of a full illustration) for when a card is drawn too small
// for the illustrated artwork's detail to read. Swapped in automatically by
// rendered pixel width -- not a separately equippable/purchasable deck.
const COMPACT_DECK_VARIANT: Record<string, string> = { gilded_mystery: 'gilded_mystery_mini', default: 'default_mini', fantasy: 'fantasy_mini' };
// Matches the "compact tier" threshold gridLayout.ts already uses for
// cardWidth-driven layout decisions, so both kick in at the same size.
const COMPACT_WIDTH_THRESHOLD = 70;

function resolveDeckId(deckId: string, width: number): string {
  const compactId = COMPACT_DECK_VARIANT[deckId];
  return compactId && width < COMPACT_WIDTH_THRESHOLD ? compactId : deckId;
}

interface AtlasManifest {
  url: string;
  size: { width: number; height: number };
  cells: Record<string, AtlasCell>;
}

// One sprite sheet per illustrated deck, each holding both its desktop and
// compact face sets (plus backs/jokers where available) -- see
// gildedMysteryAtlas.ts / defaultAtlas.ts. Every deck id that's atlas-backed
// (desktop and mini alike) maps to the family containing its cells; drawn
// via CSS background-position rather than an <img src> per card. Any deck
// id absent from this map falls back to individual files via cardImagePath.
const ATLASES: Record<string, AtlasManifest> = {
  gilded_mystery: { url: GILDED_MYSTERY_ATLAS_URL, size: GILDED_MYSTERY_ATLAS_SIZE, cells: GILDED_MYSTERY_ATLAS_CELLS },
  default: { url: DEFAULT_ATLAS_URL, size: DEFAULT_ATLAS_SIZE, cells: DEFAULT_ATLAS_CELLS },
  fantasy: { url: FANTASY_ATLAS_URL, size: FANTASY_ATLAS_SIZE, cells: FANTASY_ATLAS_CELLS },
};
const DECK_ATLAS_FAMILY: Record<string, string> = {
  gilded_mystery: 'gilded_mystery',
  gilded_mystery_mini: 'gilded_mystery',
  default: 'default',
  default_mini: 'default',
  fantasy: 'fantasy',
  fantasy_mini: 'fantasy',
};
// Decks whose atlas also has a "back" cell -- keyed by cardBackPattern id
// (a separately-chosen setting from cardFaceSet, but happens to share the
// same id for these two decks).
const ATLAS_BACK_FAMILY: Record<string, string> = { gilded_mystery: 'gilded_mystery', fantasy: 'fantasy' };

function rankSuitCode(rank: number, suit: number): string {
  const rankCode = RANK_CODE[rank] ?? String(rank);
  return `${rankCode}${SUIT_CODE[suit]}`;
}

interface AtlasSprite {
  backgroundImage: string;
  backgroundSize: string;
  backgroundPosition: string;
  backgroundRepeat: 'no-repeat';
}

// Cells and the on-screen card are both a fixed 5:7 ratio, so one scale
// factor (derived from width alone) correctly maps the cell on both axes.
export function atlasSprite(deckId: string, code: string, displayWidth: number): AtlasSprite | null {
  const family = DECK_ATLAS_FAMILY[deckId];
  if (!family) return null;
  const atlas = ATLASES[family];
  const cell = atlas.cells[`${deckId}:${code}`];
  if (!cell) return null;
  const scale = displayWidth / cell.w;
  return {
    backgroundImage: `url(${atlas.url})`,
    backgroundSize: `${atlas.size.width * scale}px ${atlas.size.height * scale}px`,
    backgroundPosition: `-${cell.x * scale}px -${cell.y * scale}px`,
    backgroundRepeat: 'no-repeat',
  };
}

export function cardImagePath(deckId: string, rank: number, suit: number, width = Infinity): string {
  const resolvedDeckId = resolveDeckId(deckId, width);
  const rankCode = RANK_CODE[rank] ?? String(rank);
  const ext = CARD_DECK_EXTENSION[resolvedDeckId] ?? 'png';
  const folder = CARD_DECK_FOLDER[resolvedDeckId] ?? resolvedDeckId;
  return `/assets/cards/${folder}/${rankCode}${SUIT_CODE[suit]}.${ext}`;
}

// Warms the browser's image cache/decode for a whole deck ahead of time, so
// dealing/animating cards doesn't stutter on first-time image decode. Safe
// to call repeatedly (e.g. on every deck switch) -- already-cached requests
// resolve instantly. Actual card width isn't known this early (it depends on
// the variant's layout), so decks with a compact variant preload both --
// whichever one CardWidget ends up choosing per-card is already warm.
export function preloadCardDeck(deckId: string): void {
  const family = DECK_ATLAS_FAMILY[deckId];
  if (family) {
    // Every face (both size variants) plus backs/jokers where available
    // live in one sprite sheet -- a single fetch warms the whole deck.
    const img = new Image();
    img.src = ATLASES[family].url;
    return;
  }
  const deckIds = [deckId, COMPACT_DECK_VARIANT[deckId]].filter((id): id is string => !!id);
  for (const id of deckIds) {
    for (let rank = 1; rank <= 13; rank++) {
      for (let suit = 0; suit < 4; suit++) {
        const img = new Image();
        img.src = cardImagePath(id, rank, suit);
      }
    }
  }
}

export function isAtlasBackedDeck(deckId: string): boolean {
  return !!DECK_ATLAS_FAMILY[deckId];
}

// Same warming as preloadCardDeck, but resolves once the assets are actually
// ready (or after a safety timeout, so a slow/broken network can't hang the
// caller forever) -- for gating the splash screen on an atlas fetch actually
// finishing, unlike per-file decks where individual images trickle in and
// there's nothing worth blocking on.
export function preloadCardDeckAsync(deckId: string, timeoutMs = 8000): Promise<void> {
  const family = DECK_ATLAS_FAMILY[deckId];
  if (!family) {
    preloadCardDeck(deckId);
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    const img = new Image();
    let settled = false;
    const done = () => { if (!settled) { settled = true; resolve(); } };
    img.onload = done;
    img.onerror = done;
    img.src = ATLASES[family].url;
    setTimeout(done, timeoutMs);
  });
}

const CardWidgetComponent: React.FC<CardWidgetProps> = ({
  id, rank, suit, faceUp, width, height, theme, cardFaceSet, cardBackPattern, cardBackColor, isSelected, isHint, hideShadow
}) => {
  const resolvedFaceDeck = resolveDeckId(cardFaceSet, width);
  const faceSprite = atlasSprite(resolvedFaceDeck, rankSuitCode(rank, suit), width);
  // The back has no compact variant (no text/pips to shrink) so it always
  // draws from the desktop-sized "back" cell, scaled to whatever size this
  // card is rendered at.
  const backFamily = ATLAS_BACK_FAMILY[cardBackPattern];
  const backSprite = backFamily ? atlasSprite(backFamily, 'back', width) : null;

  return (
    <div
      id={`card-wrapper-${id}`}
      style={{
        position: 'absolute',
        width,
        height,
        left: 0,
        top: 0,
        pointerEvents: 'none',
        willChange: 'transform'
      }}
    >
      <div
        style={{
          position: 'relative',
          width: '100%',
          height: '100%',
          transformStyle: 'preserve-3d',
          transition: 'transform 0.25s cubic-bezier(0.2, 0.8, 0.2, 1)',
          transform: faceUp ? 'rotateY(0deg)' : 'rotateY(180deg)'
        }}
      >
        {/* FRONT */}
        <div
          style={{
            position: 'absolute', width: '100%', height: '100%', backfaceVisibility: 'hidden',
            borderRadius: '8px',
            border: (isSelected || isHint) ? `3px solid #ffd700` : `1px solid rgba(0,0,0,0.15)`,
            boxShadow: (isSelected || isHint) ? `0 0 12px ${theme.accentColor || '#ffd700'}` : (hideShadow ? 'none' : '0 2px 8px rgba(0,0,0,0.3)'),
            overflow: 'hidden'
          }}
        >
          {faceSprite ? (
            <div style={{ width: '100%', height: '100%', ...faceSprite }} />
          ) : (
            <img
              src={cardImagePath(cardFaceSet, rank, suit, width)}
              alt=""
              style={{ width: '100%', height: '100%', objectFit: 'contain', display: 'block' }}
            />
          )}
        </div>

        {/* BACK */}
        <div
          style={{
            position: 'absolute', width: '100%', height: '100%', backfaceVisibility: 'hidden',
            transform: 'rotateY(180deg)',
            backgroundColor: cardBackColor,
            ...(backSprite ?? {
              backgroundImage: getBackPatternCss(cardBackPattern),
              backgroundSize: getBackPatternSize(cardBackPattern),
              backgroundPosition: getBackPatternPosition(cardBackPattern),
            }),
            borderRadius: '8px',
            border: (isSelected || isHint) ? `2.5px solid #ffd700` : `1px solid ${theme.accentColor || 'rgba(255,255,255,0.2)'}`,
            boxShadow: (isSelected || isHint) ? `0 0 12px ${theme.accentColor || '#ffd700'}` : (hideShadow ? 'none' : '0 2px 8px rgba(0,0,0,0.3)'),
            overflow: 'hidden'
          }}
        >
        </div>
      </div>
    </div>
  );
};

// All props are primitives except `theme`, which is always one of the
// module-level THEME_PRESETS entries (a stable reference per themeId, not a
// fresh object per render) — so React.memo's default shallow comparison is
// exactly the right check, correctly skipping re-render for the ~50 cards
// that didn't change on any given move instead of re-running each card's
// full front/back JSX tree.
export const CardWidget = React.memo(CardWidgetComponent);
