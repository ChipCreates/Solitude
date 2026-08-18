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
  _viewportHeight: number,
  columnCount: number = 7
): GridLayoutResult {
  const containerPadding = 24;
  const availableWidth = viewportWidth - containerPadding * 2;

  // cardWidth from column count + 15%-of-width gap, clamped [44, 150]px
  const rawWidth = availableWidth / (columnCount + (columnCount - 1) * 0.15);
  const cardWidth = Math.max(44, Math.min(150, rawWidth));
  const cardHeight = cardWidth * 1.4;

  const gap = cardWidth * 0.15;
  const startX = Math.max(containerPadding, (viewportWidth - (columnCount * cardWidth + (columnCount - 1) * gap)) / 2);
  const topOffset = 80;

  // Stack offset clamped to [0.15, 0.28] * cardHeight
  const stackOffset = Math.max(cardHeight * 0.15, Math.min(cardHeight * 0.28, 32));

  // Compact tier trigger: card width < 70px
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
