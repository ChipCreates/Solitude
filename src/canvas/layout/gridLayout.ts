// Helper calculating responsive card layout dimensions
export interface GridLayoutResult {
  cardWidth: number;
  cardHeight: number;
  gap: number;
  startX: number;
  topOffset: number;
  stackOffset: number;
  isCompactTier: boolean;
}

export function calculateGridLayout(
  viewportWidth: number,
  viewportHeight: number = 800,
  columnCount: number = 7
): GridLayoutResult {
  const isLandscape = viewportWidth > viewportHeight;
  const containerPadding = isLandscape || columnCount >= 10 ? 8 : 16;
  const availableWidth = viewportWidth - containerPadding * 2;

  // 1. Horizontal cardWidth constraint
  const gapRatio = columnCount >= 10 ? 0.10 : 0.14;
  const rawWidth = availableWidth / (columnCount + (columnCount - 1) * gapRatio);

  // 2. Vertical height & landscape constraint
  const topOffset = isLandscape ? (viewportHeight < 500 ? 36 : 48) : (columnCount >= 10 ? 52 : 72);
  const availableHeight = viewportHeight - topOffset - (isLandscape ? 12 : 20);

  // Multiplier for max vertical space needed (top row + gap + stack depth)
  const verticalMultiplier = columnCount >= 10 ? 3.6 : (isLandscape ? 3.2 : 2.7);
  const heightConstrainedCardHeight = availableHeight / verticalMultiplier;

  let cardWidth = Math.min(rawWidth, heightConstrainedCardHeight / 1.4);

  // Scale down for landscape orientation & 10-column layouts
  if (isLandscape) {
    const landscapeMaxFactor = columnCount >= 10 ? 0.12 : 0.16;
    cardWidth = Math.min(cardWidth, viewportHeight * landscapeMaxFactor);
  } else if (columnCount >= 10) {
    cardWidth = Math.min(cardWidth, viewportHeight * 0.11);
  }

  // Clamping: minimum card width 30px, maximum 140px
  cardWidth = Math.max(30, Math.min(140, cardWidth));
  const cardHeight = cardWidth * 1.4;

  const gap = Math.max(2, cardWidth * gapRatio);
  const startX = Math.max(containerPadding, (viewportWidth - (columnCount * cardWidth + (columnCount - 1) * gap)) / 2);

  const stackOffset = isLandscape
    ? Math.max(cardHeight * 0.12, Math.min(cardHeight * 0.18, 16))
    : Math.max(cardHeight * 0.14, Math.min(cardHeight * 0.24, 28));

  const isCompactTier = cardWidth < 70;

  return {
    cardWidth,
    cardHeight,
    gap,
    startX,
    topOffset,
    stackOffset,
    isCompactTier,
  };
}
