export interface PyramidLayoutResult {
  cardWidth: number;
  cardHeight: number;
  topPadding: number;
  centerX: number;
  bottomY: number;
  isCompactTier: boolean;
}

export function calculatePyramidLayout(
  viewportWidth: number,
  viewportHeight: number
): PyramidLayoutResult {
  const horizontalPadding = 16;
  const availableWidth = viewportWidth - horizontalPadding * 2;

  // Base needs space for ~8 cards (7 cards with 1.1x spacing)
  const cardWidth = Math.max(40, Math.min(100, availableWidth / 8.0));
  const cardHeight = cardWidth * 1.4;

  const pyramidHeight = 7 * cardHeight * 0.4 + cardHeight;
  const bottomRowHeight = cardHeight + 16;
  const totalContentHeight = pyramidHeight + bottomRowHeight + 20;

  const topPadding = Math.max(8, Math.min(40, (viewportHeight - totalContentHeight) / 3));
  const centerX = viewportWidth / 2;
  const bottomY = viewportHeight - cardHeight - 24;

  const isCompactTier = cardWidth < 60;

  return {
    cardWidth,
    cardHeight,
    topPadding,
    centerX,
    bottomY,
    isCompactTier,
  };
}

export function getPyramidCardPosition(
  row: number,
  col: number,
  layout: PyramidLayoutResult
): { x: number; y: number } {
  const x = layout.centerX + (col - row / 2.0) * layout.cardWidth * 1.1 - layout.cardWidth / 2;
  const y = layout.topPadding + row * layout.cardHeight * 0.4;
  return { x, y };
}
