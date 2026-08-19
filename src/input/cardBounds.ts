export interface CardBounds {
  pileKind: number; // 0: Stock, 1: Waste, 2: Foundation, 3: Tableau, 4: Cell, 5: Reserve, 6: Pyramid, 7: Discard
  pileIndex: number;
  cardIndex: number;
  cardId: number; // -1 for empty slots
  x: number;
  y: number;
  width: number;
  height: number;
  faceUp: boolean;
  rank: number;
  suit: number;
}
