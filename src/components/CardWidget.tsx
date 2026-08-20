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

const getDesktopPipSize = (rank: number, height: number): number => {
  if (rank === 1) return Math.max(34, height * 0.46);
  if (rank <= 3) return Math.max(20, Math.min(36, height * 0.28));
  if (rank <= 6) return Math.max(17, Math.min(28, height * 0.23));
  return Math.max(14, Math.min(22, height * 0.19));
};

const getDesktopPipPositions = (rank: number): { x: number; y: number; invert?: boolean }[] => {
  switch (rank) {
    case 1:
      return [{ x: 50, y: 50 }];
    case 2:
      return [
        { x: 50, y: 18 },
        { x: 50, y: 82, invert: true },
      ];
    case 3:
      return [
        { x: 50, y: 18 },
        { x: 50, y: 50 },
        { x: 50, y: 82, invert: true },
      ];
    case 4:
      return [
        { x: 25, y: 18 },
        { x: 75, y: 18 },
        { x: 25, y: 82, invert: true },
        { x: 75, y: 82, invert: true },
      ];
    case 5:
      return [
        { x: 25, y: 18 },
        { x: 75, y: 18 },
        { x: 50, y: 50 },
        { x: 25, y: 82, invert: true },
        { x: 75, y: 82, invert: true },
      ];
    case 6:
      return [
        { x: 25, y: 18 },
        { x: 75, y: 18 },
        { x: 25, y: 50 },
        { x: 75, y: 50 },
        { x: 25, y: 82, invert: true },
        { x: 75, y: 82, invert: true },
      ];
    case 7:
      return [
        { x: 25, y: 18 },
        { x: 75, y: 18 },
        { x: 50, y: 34 },
        { x: 25, y: 50 },
        { x: 75, y: 50 },
        { x: 25, y: 82, invert: true },
        { x: 75, y: 82, invert: true },
      ];
    case 8:
      return [
        { x: 25, y: 18 },
        { x: 75, y: 18 },
        { x: 50, y: 34 },
        { x: 25, y: 50 },
        { x: 75, y: 50 },
        { x: 50, y: 66, invert: true },
        { x: 25, y: 82, invert: true },
        { x: 75, y: 82, invert: true },
      ];
    case 9:
      return [
        { x: 22, y: 18 },
        { x: 50, y: 18 },
        { x: 78, y: 18 },
        { x: 22, y: 50 },
        { x: 50, y: 50 },
        { x: 78, y: 50 },
        { x: 22, y: 82, invert: true },
        { x: 50, y: 82, invert: true },
        { x: 78, y: 82, invert: true },
      ];
    case 10:
      return [
        { x: 22, y: 16 },
        { x: 78, y: 16 },
        { x: 50, y: 28 },
        { x: 22, y: 40 },
        { x: 78, y: 40 },
        { x: 22, y: 64, invert: true },
        { x: 78, y: 64, invert: true },
        { x: 50, y: 76, invert: true },
        { x: 22, y: 88, invert: true },
        { x: 78, y: 88, invert: true },
      ];
    default:
      return [];
  }
};

const CardWidgetComponent: React.FC<CardWidgetProps> = ({
  id, rank, suit, faceUp, width, height, theme, overlayIntensity, cardBackPattern, cardBackColor, isSelected, isHint, hideShadow
}) => {
  const isRed = suit === 0 || suit === 1;
  const suitColor = isRed ? "#e00000" : "#000000";
  const ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
  const suits = ["♥", "♦", "♣", "♠"];
  const rankStr = ranks[rank - 1];
  const suitStr = suits[suit];
  const compact = width < 80;

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
            backgroundColor: isSelected ? '#fffde7' : '#ffffff',
            borderRadius: '8px',
            border: (isSelected || isHint) ? `3px solid #ffd700` : `1px solid rgba(0,0,0,0.15)`,
            boxShadow: (isSelected || isHint) ? `0 0 12px ${theme.accentColor || '#ffd700'}` : (hideShadow ? 'none' : '0 2px 8px rgba(0,0,0,0.3)'),
            overflow: 'hidden'
          }}
        >
          {/* Card Content */}
          <div style={{ position: 'absolute', width: '100%', height: '100%', padding: compact ? 0 : '2px' }}>
            {compact ? (
              // Mobile / compact layout matching reference:
              // Rank on top-left, Suit on top-right, and a large centered pip or face art below (or overflowing lower-right pip for Aces).
              <div style={{ position: 'relative', width: '100%', height: '100%', color: suitColor }}>
                <div style={{
                  position: 'absolute',
                  top: Math.max(1, height * 0.01),
                  left: Math.max(3, width * 0.04),
                  fontWeight: 900,
                  fontFamily: 'Manrope, sans-serif',
                  fontSize: Math.max(16, height * 0.28),
                  lineHeight: 1
                }}>
                  {rankStr}
                </div>
                <div style={{
                  position: 'absolute',
                  top: Math.max(1, height * 0.01),
                  right: Math.max(3, width * 0.04),
                  fontSize: Math.max(16, height * 0.28),
                  lineHeight: 1
                }}>
                  {suitStr}
                </div>

                {rank === 1 ? (
                  <div style={{ position: 'absolute', right: '-22%', bottom: '-15%', width: '110%', height: '100%', display: 'flex', alignItems: 'flex-end', justifyContent: 'flex-end', overflow: 'hidden' }}>
                    <span style={{ fontSize: height * 1.35, lineHeight: 0.8, transform: 'translate(22%, 10%)', userSelect: 'none' }}>{suitStr}</span>
                  </div>
                ) : isFaceCard ? (
                  <div style={{ position: 'absolute', left: 0, bottom: 0, width: '92%', height: '82%' }}>
                    {/* Source art faces left; mirrored so it faces into the card. */}
                    <img src={`/assets/cards/${faceAsset}`} alt={rankStr} style={{ width: '100%', height: '100%', objectFit: 'contain', objectPosition: 'left bottom', transform: 'scaleX(-1)' }} />
                  </div>
                ) : (
                  <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, top: '15%', display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden' }}>
                    <span style={{ fontSize: height * 0.85, lineHeight: 1, userSelect: 'none' }}>{suitStr}</span>
                  </div>
                )}
              </div>
            ) : (
              // Full Desktop Cards Suite:
              // Smaller corner ranks + authentic multi-pip grid layouts (e.g. 3x3 for 9, 1 column of 2 for 2, etc.)
              <div style={{ position: 'relative', width: '100%', height: '100%', color: suitColor }}>
                {/* Top-left corner index */}
                <div style={{ position: 'absolute', top: 4, left: 5, color: suitColor, display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1 }}>
                  <div style={{ fontSize: `${Math.max(11, Math.min(16, height * 0.14))}px`, fontWeight: 800, fontFamily: 'Manrope, sans-serif' }}>{rankStr}</div>
                  <div style={{ fontSize: `${Math.max(10, Math.min(14, height * 0.12))}px` }}>{suitStr}</div>
                </div>

                {/* Bottom-right corner index (inverted) */}
                <div style={{ position: 'absolute', bottom: 4, right: 5, color: suitColor, display: 'flex', flexDirection: 'column', alignItems: 'center', lineHeight: 1, transform: 'rotate(180deg)' }}>
                  <div style={{ fontSize: `${Math.max(11, Math.min(16, height * 0.14))}px`, fontWeight: 800, fontFamily: 'Manrope, sans-serif' }}>{rankStr}</div>
                  <div style={{ fontSize: `${Math.max(10, Math.min(14, height * 0.12))}px` }}>{suitStr}</div>
                </div>

                {/* Center area for pips or court illustration */}
                <div style={{ position: 'absolute', top: '7%', bottom: '7%', left: '12%', right: '12%' }}>
                  {(isFaceCard || (rank === 1 && suit === 3)) ? (
                    <div style={{ width: '100%', height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                      <img src={`/assets/cards/${faceAsset}`} alt={rankStr} style={{ width: '100%', height: '100%', objectFit: 'contain', transform: 'scaleX(-1)' }} />
                    </div>
                  ) : rank === 1 ? (
                    <div style={{ width: '100%', height: '100%', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                      <span style={{ fontSize: `${getDesktopPipSize(1, height)}px`, color: suitColor, userSelect: 'none' }}>{suitStr}</span>
                    </div>
                  ) : (
                    <div style={{ position: 'relative', width: '100%', height: '100%' }}>
                      {getDesktopPipPositions(rank).map((pos, idx) => (
                        <span
                          key={idx}
                          style={{
                            position: 'absolute',
                            left: `${pos.x}%`,
                            top: `${pos.y}%`,
                            transform: `translate(-50%, -50%) ${pos.invert ? 'rotate(180deg)' : ''}`,
                            fontSize: `${getDesktopPipSize(rank, height)}px`,
                            color: suitColor,
                            lineHeight: 1,
                            userSelect: 'none',
                          }}
                        >
                          {suitStr}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
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
