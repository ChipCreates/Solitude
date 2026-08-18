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

export class PointerController {
  private downPos: { x: number; y: number } | null = null;
  private dragStartCard: CardBounds | null = null;
  private lastTapTime: number = 0;
  private tapTimer: number | null = null;
  private moved: boolean = false;
  private readonly moveThreshold = 8;
  private readonly doubleTapTimeout = 300;

  constructor(
    private onSingleTap: (bounds: CardBounds) => void,
    private onDoubleTap: (bounds: CardBounds) => void,
    private onDragEnd?: (from: CardBounds, to: CardBounds) => void,
    private onDragMove?: (x: number, y: number) => void
  ) {}

  public handlePointerDown(e: React.PointerEvent, cardBoundsList: CardBounds[]) {
    this.downPos = { x: e.clientX, y: e.clientY };
    this.dragStartCard = this.findHitCard(e.clientX, e.clientY, cardBoundsList);
    this.moved = false;
  }

  public handlePointerMove(e: React.PointerEvent) {
    if (this.downPos) {
      if (!this.moved) {
        const dist = Math.hypot(e.clientX - this.downPos.x, e.clientY - this.downPos.y);
        if (dist > this.moveThreshold) {
          this.moved = true;
        }
      }
      if (this.moved && this.dragStartCard && this.onDragMove) {
        this.onDragMove(e.clientX, e.clientY);
      }
    }
  }

  public handlePointerUp(e: React.PointerEvent, cardBoundsList: CardBounds[]) {
    if (!this.downPos) return;

    const clickX = e.clientX;
    const clickY = e.clientY;
    const hitCard = this.findHitCard(clickX, clickY, cardBoundsList);

    if (this.moved) {
      if (this.dragStartCard && hitCard && this.onDragEnd) {
        if (
          this.dragStartCard.pileKind !== hitCard.pileKind ||
          this.dragStartCard.pileIndex !== hitCard.pileIndex
        ) {
          this.onDragEnd(this.dragStartCard, hitCard);
        }
      }
      this.downPos = null;
      this.dragStartCard = null;
      return;
    }

    if (!hitCard) {
      this.downPos = null;
      this.dragStartCard = null;
      return;
    }

    const now = Date.now();
    if (this.lastTapTime && now - this.lastTapTime <= this.doubleTapTimeout) {
      if (this.tapTimer !== null) {
        clearTimeout(this.tapTimer);
        this.tapTimer = null;
      }
      this.lastTapTime = 0;
      this.onDoubleTap(hitCard);
    } else {
      this.lastTapTime = now;
      if (this.tapTimer !== null) {
        clearTimeout(this.tapTimer);
      }
      this.tapTimer = window.setTimeout(() => {
        this.onSingleTap(hitCard);
        this.lastTapTime = 0;
      }, this.doubleTapTimeout);
    }

    this.downPos = null;
    this.dragStartCard = null;
  }

  private findHitCard(x: number, y: number, list: CardBounds[]): CardBounds | null {
    // Traverse backwards to hit top-most cards first
    for (let i = list.length - 1; i >= 0; i--) {
      const b = list[i];
      if (x >= b.x && x <= b.x + b.width && y >= b.y && y <= b.y + b.height) {
        return b;
      }
    }
    return null;
  }
}
