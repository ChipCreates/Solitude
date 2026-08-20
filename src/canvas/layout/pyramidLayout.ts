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
  const isLandscape = viewportWidth > viewportHeight;
  const horizontalPadding = isLandscape ? 12 : 16;
  const availableWidth = viewportWidth - horizontalPadding * 2;

  const rawWidth = availableWidth / 8.0;

  const topPadding = isLandscape ? (viewportHeight < 500 ? 44 : 56) : 80;
  const availableHeight = viewportHeight - topPadding - (isLandscape ? 12 : 24);

  // Pyramid height factor = 7 rows * 0.4 * cardHeight + 2 * cardHeight + padding = ~4.8 * cardHeight
  const heightConstrainedCardWidth = (availableHeight / 4.8) / 1.4;

  let cardWidth = Math.min(rawWidth, heightConstrainedCardWidth);
  if (isLandscape) {
    cardWidth = Math.min(cardWidth, viewportHeight * 0.14);
  }

  cardWidth = Math.max(44, Math.min(100, cardWidth));
  const cardHeight = cardWidth * 1.4;

  const pyramidHeight = 7 * cardHeight * 0.4 + cardHeight;
  const centerX = viewportWidth / 2;
  const bottomY = Math.min(viewportHeight - cardHeight - (isLandscape ? 8 : 24), topPadding + pyramidHeight + 12);

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
