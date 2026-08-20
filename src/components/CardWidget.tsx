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
    case 'celestial': return '100% 100%';
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
    case 'celestial': return 'center';
    case 'dots': return '0 0, 10px 10px';
    case 'crosshatch': return '0 0, 10px 10px';
    default: return '0 0';
  }
};

const CardWidgetComponent: React.FC<CardWidgetProps> = ({
  id, rank, suit, faceUp, width, height, theme, overlayIntensity, cardBackPattern, cardBackColor, isSelected, isHint, hideShadow
}) => {
  const isRed = suit === 0 || suit === 1;
  const suitColor = isRed ? "#cc3333" : "#111111";
  const ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
  const suits = ["♥", "♦", "♣", "♠"];
  const rankStr = ranks[rank - 1];
  const suitStr = suits[suit];
  const compact = width < 60;

  const isFaceCard = rank >= 11;
  let faceAsset = '';
  if (rank === 11) faceAsset = 'jack.svg';
  if (rank === 12) faceAsset = 'queen.svg';
  if (rank === 13) faceAsset = 'king.svg';
  if (rank === 1 && suit === 3) faceAsset = 'spade.svg';

  // Gloss gradient
  const glossGradient = "linear-gradient(135deg, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0.05) 50%, rgba(0,0,0,0.05) 51%, rgba(0,0,0,0.15) 100%)";

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
        willChange: 'transform',
        filter: (isSelected || isHint) ? `drop-shadow(0 0 8px ${theme.accentColor})` : (hideShadow ? 'none' : 'drop-shadow(0 -2px 8px rgba(0,0,0,0.4))')
      }}
    >
      <div 
        style={{
          position: 'relative',
          width: '100%',
          height: '100%',
          transformStyle: 'preserve-3d',
          transition: 'transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275)',
          transform: faceUp ? 'rotateY(0deg)' : 'rotateY(180deg)'
        }}
      >
        {/* FRONT */}
        <div 
          style={{
            position: 'absolute', width: '100%', height: '100%', backfaceVisibility: 'hidden',
            backgroundColor: isSelected ? '#fffde7' : '#ffffff',
            borderRadius: '8px',
            border: (isSelected || isHint) ? `3px solid #ffd700` : `1px solid rgba(0,0,0,0.15)`,
            overflow: 'hidden'
          }}
        >
          {/* Card Content */}
          <div style={{ position: 'absolute', width: '100%', height: '100%', padding: compact && isFaceCard ? 0 : (compact ? '4px' : '8px') }}>
            {compact ? (
              isFaceCard ? (
                // Face cards get the rank/pip in the top corners and the
                // portrait art bled to the card's own edge (no padding),
                // instead of shrinking the illustration to fit inside it.
                <div style={{ position: 'relative', width: '100%', height: '100%', color: suitColor }}>
                  <div style={{ position: 'absolute', top: 3, left: 4, fontWeight: 800, fontFamily: 'Manrope, sans-serif', fontSize: width * 0.28, lineHeight: 1 }}>
                    {rankStr}
                  </div>
                  <div style={{ position: 'absolute', top: 3, right: 4, fontSize: width * 0.24, lineHeight: 1 }}>
                    {suitStr}
                  </div>
                  <div style={{ position: 'absolute', left: 0, bottom: 0, width: '78%', height: '82%' }}>
                    <img src={`/assets/cards/${faceAsset}`} alt={rankStr} style={{ width: '100%', height: '100%', objectFit: 'contain', objectPosition: 'left bottom' }} />
                  </div>
                </div>
              ) : (
                // Scaled to card width (not a fixed size) so the rank/pip
                // fill the card rather than shrinking to an illegible dot
                // at small mobile sizes. Aces get an oversized pip relative
                // to the rank letter, matching the traditional single-big-
                // pip ace design.
                <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', color: suitColor, lineHeight: 1 }}>
                  <div style={{ fontWeight: 800, fontFamily: 'Manrope, sans-serif', fontSize: rank === 1 ? width * 0.24 : width * 0.32 }}>{rankStr}</div>
                  <div style={{ fontSize: rank === 1 ? width * 0.6 : width * 0.44, marginTop: width * 0.02 }}>{suitStr}</div>
                </div>
              )
            ) : (
              <>
                <div style={{ position: 'absolute', top: 8, left: 8, color: suitColor, display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1 }}>
                  <div style={{ fontSize: '18px', fontWeight: 800, fontFamily: 'Manrope, sans-serif' }}>{rankStr}</div>
                  <div style={{ fontSize: '16px' }}>{suitStr}</div>
                </div>
                
                <div style={{ position: 'absolute', bottom: 8, right: 8, color: suitColor, display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1, transform: 'rotate(180deg)' }}>
                  <div style={{ fontSize: '18px', fontWeight: 800, fontFamily: 'Manrope, sans-serif' }}>{rankStr}</div>
                  <div style={{ fontSize: '16px' }}>{suitStr}</div>
                </div>

                <div style={{ position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)', width: '75%', height: '75%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  {(isFaceCard || (rank === 1 && suit === 3)) ? (
                    <img src={`/assets/cards/${faceAsset}`} alt={rankStr} style={{ width: '100%', height: '100%', objectFit: 'contain' }} />
                  ) : (
                    <div style={{ fontSize: `${width * 0.4}px`, color: suitColor }}>{suitStr}</div>
                  )}
                </div>
              </>
            )}
          </div>

          {/* Gloss Overlay */}
          <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', background: glossGradient, pointerEvents: 'none' }} />

          {/* Theme Tint Overlay */}
          {overlayIntensity > 0 && theme.cardFaceOverlay && (
            <div style={{ 
              position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', 
              backgroundColor: theme.cardFaceOverlay, 
              opacity: overlayIntensity, 
              mixBlendMode: 'multiply',
              pointerEvents: 'none' 
            }} />
          )}
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
