import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  initEngine, initializeGame, getPilesLayout, tapStockWasm,
  undoWasm, redoWasm, executeMoveWasm, executePairMoveWasm,
  getHintWasm, autoPlayStepWasm, checkWinWasm,
} from "./wasm/engine";
import { calculateGridLayout } from "./canvas/layout/gridLayout";
import { calculatePyramidLayout, getPyramidCardPosition } from "./canvas/layout/pyramidLayout";
import { CardBounds } from "./input/pointerController";
import { setupKeyboardNav } from "./input/keyboardNav";
import { THEME_PRESETS } from "./theme/presets";
import { useUIStore } from "./store/uiStore";
import { SettingsModal } from "./components/SettingsModal";
import { audioService } from "./audio/audioService";
import { ParticleSystem } from "./canvas/renderParticles";
import { RotateCcw, Play, Settings as SettingsIcon, Lightbulb, Sparkles } from "lucide-react";

interface AnimatedCard { x: number; y: number; vx: number; vy: number; }

export const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  // Use a ref for gameTypeCode so async callbacks always read the live value
  const gameTypeRef = useRef<number>(0);
  const [gameTypeCode, setGameTypeCodeState] = useState<number>(0);
  const setGameTypeCode = (n: number) => { gameTypeRef.current = n; setGameTypeCodeState(n); };

  const [moveCount, setMoveCount] = useState(0);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Pyramid selection stored in ref so tap handler always reads live value
  const selectedPyramidCardRef = useRef<CardBounds | null>(null);
  const [, setSelectedPyramidCardDisplay] = useState<CardBounds | null>(null);
  const setSelectedPyramidCard = (c: CardBounds | null) => {
    selectedPyramidCardRef.current = c;
    setSelectedPyramidCardDisplay(c);
  };

  const cardBoundsListRef = useRef<CardBounds[]>([]);
  const animatedCardsRef = useRef(new Map<number, AnimatedCard>());
  const dragStateRef = useRef<{ cardId: number; ptrX: number; ptrY: number; offsetX: number; offsetY: number } | null>(null);
  const pointerDownRef = useRef<{ x: number; y: number } | null>(null);
  const movedRef = useRef(false);
  const dragStartCardRef = useRef<CardBounds | null>(null);

  const particleSystemRef = useRef(new ParticleSystem());
  const hintCardIdRef = useRef<number | null>(null);
  const [isAutoPlaying, setIsAutoPlaying] = useState(false);
  const isWonRef = useRef(false);

  const { themeId, soundEnabled, soundVolume, victoryPattern } = useUIStore();
  const currentTheme = THEME_PRESETS[themeId] || THEME_PRESETS.classic_felt;

  useEffect(() => { audioService.setConfig(soundEnabled, soundVolume); }, [soundEnabled, soundVolume]);
  useEffect(() => {
    const timer = setInterval(() => setTimerSeconds((s) => s + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  // ─── Layout (type-agnostic) ───────────────────────────────────────────────
  const updateLayout = useCallback((typeCode?: number) => {
    const type = typeCode !== undefined ? typeCode : gameTypeRef.current;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    if (rect.width === 0 || rect.height === 0) {
      requestAnimationFrame(() => updateLayout(type));
      return;
    }
    const piles = getPilesLayout();
    const boundsList: CardBounds[] = [];

    const pushSlot = (pileKind: number, pileIndex: number, x: number, y: number, w: number, h: number) =>
      boundsList.push({ pileKind, pileIndex, cardIndex: -1, cardId: -1, x, y, width: w, height: h, faceUp: true, rank: 0, suit: 0 });

    if (type === 3) {
      // PYRAMID
      const pl = calculatePyramidLayout(rect.width, rect.height);
      let pIdx = 0;
      for (let row = 0; row < 7; row++)
        for (let col = 0; col <= row; col++) {
          const pos = getPyramidCardPosition(row, col, pl);
          pushSlot(6, pIdx++, pos.x, pos.y, pl.cardWidth, pl.cardHeight);
        }
      const bY = pl.bottomY, sX = 24, wX = 24 + pl.cardWidth + 12, dX = rect.width - 24 - pl.cardWidth;
      pushSlot(0, 0, sX, bY, pl.cardWidth, pl.cardHeight);
      pushSlot(1, 0, wX, bY, pl.cardWidth, pl.cardHeight);
      pushSlot(7, 0, dX, bY, pl.cardWidth, pl.cardHeight);

      piles.forEach((pile) => {
        let bx = 0, by = 0;
        if (pile.kind === 6) {
          let idx = pile.index, row = 0;
          while (idx > row) { idx -= row + 1; row++; }
          const pos = getPyramidCardPosition(row, idx, pl);
          bx = pos.x; by = pos.y;
        } else if (pile.kind === 0) { bx = sX; by = bY; }
        else if (pile.kind === 1) { bx = wX; by = bY; }
        else if (pile.kind === 7) { bx = dX; by = bY; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by, width: pl.cardWidth, height: pl.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 2) {
      // FREECELL
      const layout = calculateGridLayout(rect.width, rect.height, 8);
      for (let c = 0; c < 4; c++) pushSlot(4, c, layout.startX + c * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let f = 0; f < 4; f++) pushSlot(2, f, layout.startX + (4 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 8; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 4) bx = layout.startX + pile.index * (layout.cardWidth + layout.gap);
        else if (pile.kind === 2) bx = layout.startX + (4 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 6) {
      // YUKON
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      for (let f = 0; f < 4; f++) pushSlot(2, f, layout.startX + (3 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 7; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 2) bx = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 7) {
      // FORTY THIEVES
      const layout = calculateGridLayout(rect.width, rect.height, 10);
      pushSlot(0, 0, layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      pushSlot(1, 0, layout.startX + layout.cardWidth + layout.gap, layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let f = 0; f < 8; f++) pushSlot(2, f, layout.startX + (2 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 10; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 0) bx = layout.startX;
        else if (pile.kind === 1) bx = layout.startX + layout.cardWidth + layout.gap;
        else if (pile.kind === 2) bx = layout.startX + (2 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 8) {
      // CANFIELD
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      pushSlot(0, 0, layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      pushSlot(1, 0, layout.startX + layout.cardWidth + layout.gap, layout.topOffset, layout.cardWidth, layout.cardHeight);
      pushSlot(5, 0, layout.startX + 2 * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let f = 0; f < 4; f++) pushSlot(2, f, layout.startX + (3 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 4; t++) pushSlot(3, t, layout.startX + (3 + t) * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 0) bx = layout.startX;
        else if (pile.kind === 1) bx = layout.startX + layout.cardWidth + layout.gap;
        else if (pile.kind === 5) bx = layout.startX + 2 * (layout.cardWidth + layout.gap);
        else if (pile.kind === 2) bx = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : (pile.kind === 5 ? ci * 4 : 0)), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 1) {
      // SPIDER
      const layout = calculateGridLayout(rect.width, rect.height, 10);
      pushSlot(0, 0, layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let f = 0; f < 8; f++) pushSlot(2, f, layout.startX + (2 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 10; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 0) bx = layout.startX;
        else if (pile.kind === 2) bx = layout.startX + (2 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 4) {
      // GOLF: 7 tableau columns, stock + waste on the right
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      const totalW = 7 * layout.cardWidth + 6 * layout.gap;
      const tStartX = (rect.width - totalW) / 2;
      const rightX = tStartX + totalW - layout.cardWidth;
      const rightX2 = rightX - layout.cardWidth - layout.gap;
      // Stock and Waste sit above the tableau on the right
      pushSlot(0, 0, rightX2, layout.topOffset, layout.cardWidth, layout.cardHeight);
      pushSlot(1, 0, rightX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 7; t++) pushSlot(3, t, tStartX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = tStartX, by = layout.topOffset;
        if (pile.kind === 0) { bx = rightX2; }
        else if (pile.kind === 1) { bx = rightX; }
        else if (pile.kind === 3) { bx = tStartX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 5) {
      // TRIPEAKS
      const layout = calculateGridLayout(rect.width, rect.height, 10);
      const topY = layout.topOffset;
      // rowGap = 60% of card height: each row overlaps the one above, but
      // enough of each card is visible to read rank/suit
      const rowGap = layout.cardHeight * 0.6;

      const peakPos = (idx: number) => {
        if (idx === 0) return { x: layout.startX + 1.5 * (layout.cardWidth + layout.gap), y: topY };
        if (idx === 1) return { x: layout.startX + 4.5 * (layout.cardWidth + layout.gap), y: topY };
        if (idx === 2) return { x: layout.startX + 7.5 * (layout.cardWidth + layout.gap), y: topY };
        if (idx >= 3 && idx <= 8) {
          const offsets = [1, 2, 4, 5, 7, 8];
          return { x: layout.startX + offsets[idx - 3] * (layout.cardWidth + layout.gap), y: topY + rowGap };
        }
        if (idx >= 9 && idx <= 17) {
          return { x: layout.startX + (idx - 9) * (layout.cardWidth + layout.gap) + 0.5 * (layout.cardWidth + layout.gap), y: topY + 2 * rowGap };
        }
        // Base row (idx 18-27): 10 cards across all columns
        return { x: layout.startX + (idx - 18) * (layout.cardWidth + layout.gap), y: topY + 3 * rowGap };
      };

      for (let p = 0; p < 28; p++) {
        const pos = peakPos(p);
        pushSlot(6, p, pos.x, pos.y, layout.cardWidth, layout.cardHeight);
      }
      // Stock and waste sit below the BOTTOM EDGE of the base row cards + padding
      const bY = topY + 3 * rowGap + layout.cardHeight + 20;
      pushSlot(0, 0, layout.startX, bY, layout.cardWidth, layout.cardHeight);
      pushSlot(1, 0, layout.startX + layout.cardWidth + layout.gap, bY, layout.cardWidth, layout.cardHeight);

      piles.forEach((pile) => {
        let bx = 0, by = 0;
        if (pile.kind === 6) {
          const pos = peakPos(pile.index);
          bx = pos.x; by = pos.y;
        } else if (pile.kind === 0) { bx = layout.startX; by = bY; }
        else if (pile.kind === 1) { bx = layout.startX + layout.cardWidth + layout.gap; by = bY; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by, width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else if (type === 9) {
      // SCORPION
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      pushSlot(0, 0, layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 7; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 0) bx = layout.startX;
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    } else {
      // KLONDIKE
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      pushSlot(0, 0, layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight);
      pushSlot(1, 0, layout.startX + layout.cardWidth + layout.gap, layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let f = 0; f < 4; f++) pushSlot(2, f, layout.startX + (3 + f) * (layout.cardWidth + layout.gap), layout.topOffset, layout.cardWidth, layout.cardHeight);
      for (let t = 0; t < 7; t++) pushSlot(3, t, layout.startX + t * (layout.cardWidth + layout.gap), layout.topOffset + layout.cardHeight + 24, layout.cardWidth, layout.cardHeight);
      piles.forEach((pile) => {
        let bx = layout.startX, by = layout.topOffset;
        if (pile.kind === 0) bx = layout.startX;
        else if (pile.kind === 1) bx = layout.startX + layout.cardWidth + layout.gap;
        else if (pile.kind === 2) bx = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { bx = layout.startX + pile.index * (layout.cardWidth + layout.gap); by = layout.topOffset + layout.cardHeight + 24; }
        pile.cards.forEach((card, ci) => {
          boundsList.push({ pileKind: pile.kind, pileIndex: pile.index, cardIndex: ci, cardId: card.id, x: bx, y: by + (pile.kind === 3 ? ci * layout.stackOffset : 0), width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit });
        });
      });
    }
    cardBoundsListRef.current = boundsList;
  }, []);

  // ─── Render Loop ──────────────────────────────────────────────────────────
  useEffect(() => {
    let rafId: number;
    let lastTime = performance.now();
    const render = (time: number) => {
      const dt = Math.min((time - lastTime) / 1000, 0.05);
      lastTime = time;
      const canvas = canvasRef.current;
      const ctx = canvas?.getContext("2d");
      if (!canvas || !ctx) { rafId = requestAnimationFrame(render); return; }
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      if (canvas.width !== Math.floor(rect.width * dpr) || canvas.height !== Math.floor(rect.height * dpr)) {
        canvas.width = Math.floor(rect.width * dpr);
        canvas.height = Math.floor(rect.height * dpr);
        updateLayout();
      }
      ctx.save();
      ctx.scale(dpr, dpr);
      const g = ctx.createRadialGradient(rect.width / 2, rect.height / 2, 100, rect.width / 2, rect.height / 2, Math.max(rect.width, rect.height));
      g.addColorStop(0, currentTheme.tableColor);
      g.addColorStop(1, currentTheme.tableGradientEnd);
      ctx.fillStyle = g;
      ctx.fillRect(0, 0, rect.width, rect.height);
      ctx.lineWidth = 1.5;
      ctx.strokeStyle = "rgba(255,255,255,0.15)";
      ctx.fillStyle = "rgba(255,255,255,0.03)";

      const cardsToDraw: CardBounds[] = [];
      const ds = dragStateRef.current;
      cardBoundsListRef.current.forEach((b) => {
        if (b.cardId === -1) {
          ctx.beginPath(); ctx.roundRect(b.x, b.y, b.width, b.height, 8); ctx.fill(); ctx.stroke();
        } else {
          cardsToDraw.push(b);
          if (!animatedCardsRef.current.has(b.cardId))
            animatedCardsRef.current.set(b.cardId, { x: b.x, y: b.y, vx: 0, vy: 0 });
          const anim = animatedCardsRef.current.get(b.cardId)!;
          if (ds && ds.cardId === b.cardId) {
            anim.x = ds.ptrX - ds.offsetX; anim.y = ds.ptrY - ds.offsetY; anim.vx = 0; anim.vy = 0;
          } else {
            const spring = 400, damp = 30;
            anim.vx += ((b.x - anim.x) * spring - anim.vx * damp) * dt;
            anim.vy += ((b.y - anim.y) * spring - anim.vy * damp) * dt;
            anim.x += anim.vx * dt; anim.y += anim.vy * dt;
          }
        }
      });

      cardsToDraw.sort((a, b) => ds ? (a.cardId === ds.cardId ? 1 : b.cardId === ds.cardId ? -1 : 0) : 0);
      cardsToDraw.forEach((b) => {
        const anim = animatedCardsRef.current.get(b.cardId)!;
        const isSel = selectedPyramidCardRef.current?.cardId === b.cardId;
        const isHint = hintCardIdRef.current === b.cardId;
        drawCard(ctx, b, anim.x, anim.y, b.width, b.height, b.width < 60, currentTheme.accentColor, isSel || isHint);
      });

      if (checkWinWasm()) {
        if (!isWonRef.current) {
          isWonRef.current = true;
          audioService.playWin();
          particleSystemRef.current.spawnVictoryPattern(victoryPattern, rect.width, rect.height);
        }
        particleSystemRef.current.updateAndRender(ctx, rect.width, rect.height, victoryPattern);
      }

      ctx.restore();
      rafId = requestAnimationFrame(render);
    };
    rafId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(rafId);
  }, [currentTheme, updateLayout]);

  // ─── Hit Test ────────────────────────────────────────────────────────────
  const findHit = (x: number, y: number): CardBounds | null => {
    const list = cardBoundsListRef.current;
    for (let i = list.length - 1; i >= 0; i--) {
      const b = list[i];
      if (x >= b.x && x <= b.x + b.width && y >= b.y && y <= b.y + b.height) return b;
    }
    return null;
  };

  // ─── Input Handlers ───────────────────────────────────────────────────────
  const handleTap = useCallback((card: CardBounds) => {
    const type = gameTypeRef.current;

    // Stock tap (empty slot or card)
    if (card.pileKind === 0) {
      tapStockWasm(); setMoveCount((m) => m + 1); audioService.playCardMove();
      setSelectedPyramidCard(null); updateLayout(); return;
    }

    if (card.cardId === -1) return; // empty non-stock slot

    if (type === 3) {
      // PYRAMID: immediate tap-to-select/match, no double-tap needed
      const prev = selectedPyramidCardRef.current;

      // Try King self-removal first
      if (prev === null || prev.cardId === card.cardId) {
        if (executeMoveWasm(card.pileKind, card.pileIndex, 7, 0, card.cardId)) {
          setMoveCount((m) => m + 1); audioService.playCardMove();
          setSelectedPyramidCard(null); updateLayout(); return;
        }
        // Not a king or move failed — toggle selection
        if (prev?.cardId === card.cardId) { setSelectedPyramidCard(null); return; }
        setSelectedPyramidCard(card); return;
      }

      // Try pair match with previously selected card
      const success = executePairMoveWasm(prev.pileKind, prev.pileIndex, 7, 0, prev.cardId, card.cardId);
      if (success) {
        setMoveCount((m) => m + 1); audioService.playCardMove();
        setSelectedPyramidCard(null); updateLayout();
      } else {
        // Start fresh selection on this card
        setSelectedPyramidCard(card);
      }
      return;
    }

    if (type === 4 || type === 5) {
      // GOLF (4) & TRIPEAKS (5): single tap moves card to Waste (kind 1, index 0)
      if (executeMoveWasm(card.pileKind, card.pileIndex, 1, 0, card.cardId)) {
        setMoveCount((m) => m + 1); audioService.playCardMove();
        updateLayout(); return;
      }
    }
  }, [updateLayout]);

  const handleDoubleTap = useCallback((card: CardBounds) => {
    if (card.cardId === -1) return;
    const type = gameTypeRef.current;
    const foundationCount = (type === 7) ? 8 : 4;
    if (type === 0 || type === 2 || type === 6 || type === 7 || type === 8) {
      for (let f = 0; f < foundationCount; f++) {
        if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
          setMoveCount((m) => m + 1); audioService.playCardMove(); updateLayout(); return;
        }
      }
      if (type === 2) {
        for (let c = 0; c < 4; c++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 4, c, card.cardId)) {
            setMoveCount((m) => m + 1); audioService.playCardMove(); updateLayout(); return;
          }
        }
      }
    }
  }, [updateLayout]);

  // ─── Pointer Events ───────────────────────────────────────────────────────
  const lastTapTimeRef = useRef(0);
  const tapTimerRef = useRef<number | null>(null);
  const DOUBLE_TAP_MS = 280;

  const onPointerDown = useCallback((e: React.PointerEvent) => {
    pointerDownRef.current = { x: e.clientX, y: e.clientY };
    movedRef.current = false;
    const hit = findHit(e.clientX, e.clientY);
    dragStartCardRef.current = hit;
    if (hit && hit.cardId !== -1) {
      const anim = animatedCardsRef.current.get(hit.cardId);
      dragStateRef.current = {
        cardId: hit.cardId, ptrX: e.clientX, ptrY: e.clientY,
        offsetX: e.clientX - (anim?.x ?? hit.x), offsetY: e.clientY - (anim?.y ?? hit.y),
      };
    }
  }, []);

  const onPointerMove = useCallback((e: React.PointerEvent) => {
    if (pointerDownRef.current && !movedRef.current) {
      const dist = Math.hypot(e.clientX - pointerDownRef.current.x, e.clientY - pointerDownRef.current.y);
      if (dist > 8) movedRef.current = true;
    }
    if (dragStateRef.current) {
      dragStateRef.current.ptrX = e.clientX;
      dragStateRef.current.ptrY = e.clientY;
    }
  }, []);

  const onPointerUp = useCallback((e: React.PointerEvent) => {
    if (!pointerDownRef.current) return;
    const wasDrag = movedRef.current;
    const hit = findHit(e.clientX, e.clientY);

    if (wasDrag) {
      // Drag-and-drop
      const from = dragStartCardRef.current;
      if (from && from.cardId !== -1 && hit && gameTypeRef.current !== 3) {
        if (from.pileKind !== hit.pileKind || from.pileIndex !== hit.pileIndex) {
          if (executeMoveWasm(from.pileKind, from.pileIndex, hit.pileKind, hit.pileIndex, from.cardId)) {
            setMoveCount((m) => m + 1); audioService.playCardMove(); updateLayout();
          }
        }
      }
      dragStateRef.current = null;
      pointerDownRef.current = null;
      dragStartCardRef.current = null;
      return;
    }

    dragStateRef.current = null;
    pointerDownRef.current = null;
    dragStartCardRef.current = null;
    if (!hit) return;

    // For Pyramid: fire tap immediately, no double-tap
    if (gameTypeRef.current === 3) { handleTap(hit); return; }

    // For others: detect double-tap with 280ms window
    const now = Date.now();
    if (now - lastTapTimeRef.current < DOUBLE_TAP_MS) {
      if (tapTimerRef.current !== null) { clearTimeout(tapTimerRef.current); tapTimerRef.current = null; }
      lastTapTimeRef.current = 0;
      handleDoubleTap(hit);
    } else {
      lastTapTimeRef.current = now;
      if (tapTimerRef.current !== null) clearTimeout(tapTimerRef.current);
      tapTimerRef.current = window.setTimeout(() => {
        handleTap(hit); lastTapTimeRef.current = 0; tapTimerRef.current = null;
      }, DOUBLE_TAP_MS);
    }
  }, [handleTap, handleDoubleTap, updateLayout]);

  // ─── Game Management ──────────────────────────────────────────────────────
  const startNewGame = useCallback((typeCode?: number) => {
    const type = typeCode !== undefined ? typeCode : gameTypeRef.current;
    setGameTypeCode(type);
    initializeGame(type, BigInt(Date.now()));
    animatedCardsRef.current.clear();
    setSelectedPyramidCard(null);
    hintCardIdRef.current = null;
    isWonRef.current = false;
    particleSystemRef.current.clear();
    setIsAutoPlaying(false);
    setMoveCount(0); setTimerSeconds(0);
    setToastMessage(null);
    updateLayout(type);
    requestAnimationFrame(() => updateLayout(type));
  }, [updateLayout]);

  const handleHint = useCallback(() => {
    const hint = getHintWasm();
    if (hint && hint.cards && hint.cards.length > 0) {
      hintCardIdRef.current = hint.cards[0];
      setTimeout(() => { hintCardIdRef.current = null; }, 2500);
    }
  }, []);

  const handleAutoPlay = useCallback(() => {
    const nextStep = () => {
      if (checkWinWasm()) return;
      const success = autoPlayStepWasm();
      if (success) {
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        updateLayout();
        setTimeout(nextStep, 350);
      } else {
        setIsAutoPlaying(false);
        if (!checkWinWasm()) {
          setToastMessage("No moves available.");
        }
      }
    };
    setIsAutoPlaying(true);
    nextStep();
  }, [updateLayout]);

  useEffect(() => {
    initEngine().then(() => startNewGame(0));
  }, []);

  const handleGameSelect = useCallback((typeCode: number) => {
    setGameTypeCode(typeCode);
    startNewGame(typeCode);
  }, [startNewGame]);

  useEffect(() => {
    return setupKeyboardNav({
      onUndo: () => { undoWasm(); updateLayout(); },
      onRedo: () => { redoWasm(); updateLayout(); },
      onNewGame: () => startNewGame(),
      onHint: handleHint,
      onAutoPlay: handleAutoPlay,
      onSettings: () => setIsSettingsOpen((o) => !o),
    });
  }, [updateLayout, startNewGame, handleHint, handleAutoPlay]);

  const formatTime = (s: number) => `${Math.floor(s / 60).toString().padStart(2, "0")}:${(s % 60).toString().padStart(2, "0")}`;

  return (
    <div
      style={{ width: "100vw", height: "100vh", position: "relative", overflow: "hidden", backgroundColor: currentTheme.tableColor }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerLeave={onPointerUp}
    >
      <div style={{ position: "absolute", top: 16, left: 24, right: 24, display: "flex", justifyContent: "space-between", alignItems: "center", background: "rgba(19,19,19,0.65)", backdropFilter: "blur(16px)", borderRadius: "16px", padding: "12px 24px", border: "1px solid rgba(255,255,255,0.12)", zIndex: 10, color: "#e5e2e1" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <h1 style={{ fontFamily: "Manrope,sans-serif", fontSize: "20px", fontWeight: 800, color: currentTheme.accentColor }}>Solitude</h1>
          <select value={gameTypeCode} onChange={(e) => handleGameSelect(Number(e.target.value))}
            style={{ background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", color: "#e5e2e1", padding: "6px 12px", fontFamily: "Inter,sans-serif", fontSize: "14px", fontWeight: 600, cursor: "pointer", outline: "none" }}>
            <option value={0} style={{ background: "#1e1e1e" }}>Klondike</option>
            <option value={1} style={{ background: "#1e1e1e" }}>Spider</option>
            <option value={2} style={{ background: "#1e1e1e" }}>FreeCell</option>
            <option value={3} style={{ background: "#1e1e1e" }}>Pyramid</option>
            <option value={4} style={{ background: "#1e1e1e" }}>Golf</option>
            <option value={5} style={{ background: "#1e1e1e" }}>TriPeaks</option>
            <option value={6} style={{ background: "#1e1e1e" }}>Yukon</option>
            <option value={7} style={{ background: "#1e1e1e" }}>Forty Thieves</option>
            <option value={8} style={{ background: "#1e1e1e" }}>Canfield</option>
            <option value={9} style={{ background: "#1e1e1e" }}>Scorpion</option>
          </select>
        </div>
        <div style={{ display: "flex", gap: 24, fontFamily: "JetBrains Mono,monospace", fontSize: "14px" }}>
          <div><span style={{ opacity: 0.6 }}>TIME: </span>{formatTime(timerSeconds)}</div>
          <div><span style={{ opacity: 0.6 }}>MOVES: </span>{moveCount}</div>
        </div>
        <div style={{ display: "flex", gap: 12 }}>
          <button onClick={handleHint} title="Hint (H)" style={HUD_BTN}><Lightbulb size={18} /></button>
          <button onClick={handleAutoPlay} title="Auto Play (A)" style={{ ...HUD_BTN, color: isAutoPlaying ? currentTheme.accentColor : "#e5e2e1" }}><Sparkles size={18} /></button>
          <button onClick={() => { undoWasm(); updateLayout(); }} title="Undo (U)" style={HUD_BTN}><RotateCcw size={18} /></button>
          <button onClick={() => startNewGame()} title="New Game (N)" style={HUD_BTN}><Play size={18} /></button>
          <button onClick={() => setIsSettingsOpen(true)} title="Settings (Esc)" style={HUD_BTN}><SettingsIcon size={18} /></button>
        </div>
      </div>
      <canvas ref={canvasRef} style={{ width: "100%", height: "100%", display: "block", touchAction: "none" }} />
      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
      
      {toastMessage && (
        <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -50%)", background: "rgba(19,19,19,0.9)", backdropFilter: "blur(16px)", padding: "24px", borderRadius: "16px", border: "1px solid rgba(255,255,255,0.2)", zIndex: 100, display: "flex", flexDirection: "column", alignItems: "center", gap: 16 }}>
          <div style={{ color: "#e5e2e1", fontFamily: "Manrope,sans-serif", fontSize: "18px", fontWeight: 600 }}>{toastMessage}</div>
          <div style={{ display: "flex", gap: 12 }}>
            <button onClick={() => { setToastMessage(null); startNewGame(); }} style={{ background: currentTheme.accentColor, color: "#111", border: "none", borderRadius: "8px", padding: "10px 20px", fontWeight: 700, cursor: "pointer", fontFamily: "Inter,sans-serif" }}>New Game</button>
            <button onClick={() => setToastMessage(null)} style={{ background: "transparent", color: "#e5e2e1", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "10px 20px", fontWeight: 600, cursor: "pointer", fontFamily: "Inter,sans-serif" }}>Dismiss</button>
          </div>
        </div>
      )}
    </div>
  );
};

function drawCard(ctx: CanvasRenderingContext2D, card: CardBounds, x: number, y: number, w: number, h: number, compact: boolean, accent: string, selected: boolean) {
  ctx.save();
  ctx.beginPath(); ctx.roundRect(x, y, w, h, 8);
  if (!card.faceUp) {
    ctx.fillStyle = "#1e3a2b"; ctx.fill();
    ctx.strokeStyle = selected ? "#ffd700" : accent; ctx.lineWidth = selected ? 2.5 : 1; ctx.stroke();
  } else {
    ctx.fillStyle = selected ? "#fffde7" : "#ffffff"; ctx.fill();
    ctx.strokeStyle = selected ? "#ffd700" : "rgba(0,0,0,0.15)"; ctx.lineWidth = selected ? 3 : 1; ctx.stroke();
    const red = card.suit === 0 || card.suit === 1;
    ctx.fillStyle = red ? "#cc3333" : "#111111";
    const rank = ["A","2","3","4","5","6","7","8","9","10","J","Q","K"][card.rank - 1];
    const suit = ["♥","♦","♣","♠"][card.suit];
    if (compact) {
      ctx.font = "bold 14px Inter,sans-serif"; ctx.fillText(`${rank}${suit}`, x + 6, y + 18);
    } else {
      ctx.font = "bold 16px Manrope,sans-serif"; ctx.fillText(rank, x + 8, y + 20);
      ctx.font = "14px Inter,sans-serif"; ctx.fillText(suit, x + 8, y + 36);
      ctx.font = "28px Inter,sans-serif"; ctx.textAlign = "center"; ctx.textBaseline = "middle";
      ctx.fillText(suit, x + w / 2, y + h / 2);
      ctx.textAlign = "start"; ctx.textBaseline = "alphabetic";
    }
  }
  ctx.restore();
}

const HUD_BTN: React.CSSProperties = { background: "rgba(255,255,255,0.08)", border: "1px solid rgba(255,255,255,0.15)", borderRadius: "8px", color: "#e5e2e1", padding: "8px 12px", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" };
export default App;
