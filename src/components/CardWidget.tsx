import React from 'react';

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
// extension and folder name vary. The deck id used for equip/store matching
// ("gilded_mystery") doesn't always match its asset folder name on disk
// ("the_gilded_mystery"), so that mapping is explicit rather than assumed.
const CARD_DECK_EXTENSION: Record<string, string> = { default: 'png', gilded_mystery: 'webp' };
const CARD_DECK_FOLDER: Record<string, string> = { default: 'default', gilded_mystery: 'the_gilded_mystery' };
const RANK_CODE: Record<number, string> = { 1: 'A', 10: 'T', 11: 'J', 12: 'Q', 13: 'K' };
const SUIT_CODE = ['H', 'D', 'C', 'S']; // matches the engine's suit-index order (0=hearts..3=spades)

function cardImagePath(deckId: string, rank: number, suit: number): string {
  const rankCode = RANK_CODE[rank] ?? String(rank);
  const ext = CARD_DECK_EXTENSION[deckId] ?? 'png';
  const folder = CARD_DECK_FOLDER[deckId] ?? deckId;
  return `/assets/cards/${folder}/${rankCode}${SUIT_CODE[suit]}.${ext}`;
}

// Warms the browser's image cache/decode for a whole deck ahead of time, so
// dealing/animating cards doesn't stutter on first-time image decode. Safe
// to call repeatedly (e.g. on every deck switch) -- already-cached requests
// resolve instantly.
export function preloadCardDeck(deckId: string): void {
  for (let rank = 1; rank <= 13; rank++) {
    for (let suit = 0; suit < 4; suit++) {
      const img = new Image();
      img.src = cardImagePath(deckId, rank, suit);
    }
  }
}

const CardWidgetComponent: React.FC<CardWidgetProps> = ({
  id, rank, suit, faceUp, width, height, theme, cardFaceSet, cardBackPattern, cardBackColor, isSelected, isHint, hideShadow
}) => {
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
          <img
            src={cardImagePath(cardFaceSet, rank, suit)}
            alt=""
            style={{ width: '100%', height: '100%', objectFit: 'contain', display: 'block' }}
          />
        </div>

        {/* BACK */}
        <div
          style={{
            position: 'absolute', width: '100%', height: '100%', backfaceVisibility: 'hidden',
            transform: 'rotateY(180deg)',
            backgroundColor: cardBackColor,
            backgroundImage: getBackPatternCss(cardBackPattern),
            backgroundSize: getBackPatternSize(cardBackPattern),
            backgroundPosition: getBackPatternPosition(cardBackPattern),
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
