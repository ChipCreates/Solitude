import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  initEngine,
  initializeGame,
  getPilesLayout,
  tapStockWasm,
  undoWasm,
  redoWasm,
  executeMoveWasm,
  executePairMoveWasm,
} from "./wasm/engine";
import { calculateGridLayout } from "./canvas/layout/gridLayout";
import { calculatePyramidLayout, getPyramidCardPosition } from "./canvas/layout/pyramidLayout";
import { PointerController, CardBounds } from "./input/pointerController";
import { setupKeyboardNav } from "./input/keyboardNav";
import { THEME_PRESETS } from "./theme/presets";
import { useUIStore } from "./store/uiStore";
import { SettingsModal } from "./components/SettingsModal";
import { audioService } from "./audio/audioService";
import { RotateCcw, Play, Settings as SettingsIcon } from "lucide-react";

interface AnimatedCard {
  x: number;
  y: number;
  vx: number;
  vy: number;
}

export const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [gameTypeCode, setGameTypeCode] = useState<number>(0);
  const [moveCount, setMoveCount] = useState(0);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  const [selectedPyramidCard, setSelectedPyramidCard] = useState<CardBounds | null>(null);

  const cardBoundsListRef = useRef<CardBounds[]>([]);
  const animatedCardsRef = useRef(new Map<number, AnimatedCard>());
  const dragStateRef = useRef<{ cardId: number; ptrX: number; ptrY: number; offsetX: number; offsetY: number } | null>(null);

  const { themeId, soundEnabled, soundVolume } = useUIStore();
  const currentTheme = THEME_PRESETS[themeId] || THEME_PRESETS.classic_felt;

  useEffect(() => {
    audioService.setConfig(soundEnabled, soundVolume);
  }, [soundEnabled, soundVolume]);

  useEffect(() => {
    const timer = setInterval(() => setTimerSeconds((s) => s + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  const updateLayout = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const rect = canvas.getBoundingClientRect();
    const piles = getPilesLayout();
    const boundsList: CardBounds[] = [];

    if (gameTypeCode === 3) {
      const pyrLayout = calculatePyramidLayout(rect.width, rect.height);
      let pIdx = 0;
      for (let row = 0; row < 7; row++) {
        for (let col = 0; col <= row; col++) {
          const pos = getPyramidCardPosition(row, col, pyrLayout);
          boundsList.push({ pileKind: 6, pileIndex: pIdx, cardIndex: -1, cardId: -1, x: pos.x, y: pos.y, width: pyrLayout.cardWidth, height: pyrLayout.cardHeight, faceUp: true, rank: 0, suit: 0 });
          pIdx++;
        }
      }

      const bottomY = pyrLayout.bottomY;
      const stockX = 24;
      const wasteX = 24 + pyrLayout.cardWidth + 12;
      const discardX = rect.width - 24 - pyrLayout.cardWidth;

      boundsList.push({ pileKind: 0, pileIndex: 0, cardIndex: -1, cardId: -1, x: stockX, y: bottomY, width: pyrLayout.cardWidth, height: pyrLayout.cardHeight, faceUp: false, rank: 0, suit: 0 });
      boundsList.push({ pileKind: 1, pileIndex: 0, cardIndex: -1, cardId: -1, x: wasteX, y: bottomY, width: pyrLayout.cardWidth, height: pyrLayout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      boundsList.push({ pileKind: 7, pileIndex: 0, cardIndex: -1, cardId: -1, x: discardX, y: bottomY, width: pyrLayout.cardWidth, height: pyrLayout.cardHeight, faceUp: true, rank: 0, suit: 0 });

      piles.forEach((pile) => {
        let baseX = 0, baseY = 0;
        if (pile.kind === 6) {
          let idx = pile.index, row = 0;
          while (idx > row) { idx -= row + 1; row++; }
          const pos = getPyramidCardPosition(row, idx, pyrLayout);
          baseX = pos.x; baseY = pos.y;
        } else if (pile.kind === 0) { baseX = stockX; baseY = bottomY; }
        else if (pile.kind === 1) { baseX = wasteX; baseY = bottomY; }
        else if (pile.kind === 7) { baseX = discardX; baseY = bottomY; }

        pile.cards.forEach((card, cardIdx) => {
          boundsList.push({
            pileKind: pile.kind, pileIndex: pile.index, cardIndex: cardIdx, cardId: card.id,
            x: baseX, y: baseY, width: pyrLayout.cardWidth, height: pyrLayout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit
          });
        });
      });
    } else if (gameTypeCode === 2) {
      const layout = calculateGridLayout(rect.width, rect.height, 8);
      for (let c = 0; c < 4; c++) {
        const x = layout.startX + c * (layout.cardWidth + layout.gap);
        boundsList.push({ pileKind: 4, pileIndex: c, cardIndex: -1, cardId: -1, x, y: layout.topOffset, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      }
      for (let f = 0; f < 4; f++) {
        const x = layout.startX + (4 + f) * (layout.cardWidth + layout.gap);
        boundsList.push({ pileKind: 2, pileIndex: f, cardIndex: -1, cardId: -1, x, y: layout.topOffset, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      }
      for (let t = 0; t < 8; t++) {
        const x = layout.startX + t * (layout.cardWidth + layout.gap);
        boundsList.push({ pileKind: 3, pileIndex: t, cardIndex: -1, cardId: -1, x, y: layout.topOffset + layout.cardHeight + 24, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      }

      piles.forEach((pile) => {
        let baseX = layout.startX, baseY = layout.topOffset;
        if (pile.kind === 4) baseX = layout.startX + pile.index * (layout.cardWidth + layout.gap);
        else if (pile.kind === 2) baseX = layout.startX + (4 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { baseX = layout.startX + pile.index * (layout.cardWidth + layout.gap); baseY = layout.topOffset + layout.cardHeight + 24; }

        pile.cards.forEach((card, cardIdx) => {
          let cardY = baseY + (pile.kind === 3 ? cardIdx * layout.stackOffset : 0);
          boundsList.push({
            pileKind: pile.kind, pileIndex: pile.index, cardIndex: cardIdx, cardId: card.id,
            x: baseX, y: cardY, width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit
          });
        });
      });
    } else {
      const layout = calculateGridLayout(rect.width, rect.height, 7);
      boundsList.push({ pileKind: 0, pileIndex: 0, cardIndex: -1, cardId: -1, x: layout.startX, y: layout.topOffset, width: layout.cardWidth, height: layout.cardHeight, faceUp: false, rank: 0, suit: 0 });
      boundsList.push({ pileKind: 1, pileIndex: 0, cardIndex: -1, cardId: -1, x: layout.startX + layout.cardWidth + layout.gap, y: layout.topOffset, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });

      for (let f = 0; f < 4; f++) {
        const x = layout.startX + (3 + f) * (layout.cardWidth + layout.gap);
        boundsList.push({ pileKind: 2, pileIndex: f, cardIndex: -1, cardId: -1, x, y: layout.topOffset, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      }
      for (let t = 0; t < 7; t++) {
        const x = layout.startX + t * (layout.cardWidth + layout.gap);
        boundsList.push({ pileKind: 3, pileIndex: t, cardIndex: -1, cardId: -1, x, y: layout.topOffset + layout.cardHeight + 24, width: layout.cardWidth, height: layout.cardHeight, faceUp: true, rank: 0, suit: 0 });
      }

      piles.forEach((pile) => {
        let baseX = layout.startX, baseY = layout.topOffset;
        if (pile.kind === 0) baseX = layout.startX;
        else if (pile.kind === 1) baseX = layout.startX + layout.cardWidth + layout.gap;
        else if (pile.kind === 2) baseX = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap);
        else if (pile.kind === 3) { baseX = layout.startX + pile.index * (layout.cardWidth + layout.gap); baseY = layout.topOffset + layout.cardHeight + 24; }

        pile.cards.forEach((card, cardIdx) => {
          let cardY = baseY + (pile.kind === 3 ? cardIdx * layout.stackOffset : 0);
          boundsList.push({
            pileKind: pile.kind, pileIndex: pile.index, cardIndex: cardIdx, cardId: card.id,
            x: baseX, y: cardY, width: layout.cardWidth, height: layout.cardHeight, faceUp: card.faceUp, rank: card.rank, suit: card.suit
          });
        });
      });
    }

    cardBoundsListRef.current = boundsList;
  }, [gameTypeCode]);

  // Animation Loop
  useEffect(() => {
    let animationFrameId: number;
    let lastTime = performance.now();

    const render = (time: number) => {
      const dt = Math.min((time - lastTime) / 1000, 0.05);
      lastTime = time;

      const canvas = canvasRef.current;
      if (!canvas) {
        animationFrameId = requestAnimationFrame(render);
        return;
      }

      const ctx = canvas.getContext("2d");
      if (!ctx) {
        animationFrameId = requestAnimationFrame(render);
        return;
      }

      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();
      if (canvas.width !== Math.floor(rect.width * dpr) || canvas.height !== Math.floor(rect.height * dpr)) {
        canvas.width = Math.floor(rect.width * dpr);
        canvas.height = Math.floor(rect.height * dpr);
        updateLayout();
      }

      ctx.save();
      ctx.scale(dpr, dpr);

      // Background
      const gradient = ctx.createRadialGradient(rect.width / 2, rect.height / 2, 100, rect.width / 2, rect.height / 2, Math.max(rect.width, rect.height));
      gradient.addColorStop(0, currentTheme.tableColor);
      gradient.addColorStop(1, currentTheme.tableGradientEnd);
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, rect.width, rect.height);

      ctx.lineWidth = 1.5;
      ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
      ctx.fillStyle = "rgba(255, 255, 255, 0.03)";

      const cardsToDraw: CardBounds[] = [];
      const dragState = dragStateRef.current;

      // Update Physics & Draw Slots
      cardBoundsListRef.current.forEach((b) => {
        if (b.cardId === -1) {
          ctx.beginPath();
          ctx.roundRect(b.x, b.y, b.width, b.height, 8);
          ctx.fill();
          ctx.stroke();
        } else {
          cardsToDraw.push(b);

          if (!animatedCardsRef.current.has(b.cardId)) {
            animatedCardsRef.current.set(b.cardId, { x: b.x, y: b.y, vx: 0, vy: 0 });
          }

          const anim = animatedCardsRef.current.get(b.cardId)!;

          if (dragState && dragState.cardId === b.cardId) {
            anim.x = dragState.ptrX - dragState.offsetX;
            anim.y = dragState.ptrY - dragState.offsetY;
            anim.vx = 0; anim.vy = 0;
          } else {
            // Spring physics
            const spring = 400;
            const damp = 30;
            const ax = (b.x - anim.x) * spring - anim.vx * damp;
            const ay = (b.y - anim.y) * spring - anim.vy * damp;
            anim.vx += ax * dt;
            anim.vy += ay * dt;
            anim.x += anim.vx * dt;
            anim.y += anim.vy * dt;
          }
        }
      });

      // Render Cards (bottom to top)
      cardsToDraw.sort((a, b) => {
        if (dragState) {
          if (a.cardId === dragState.cardId) return 1;
          if (b.cardId === dragState.cardId) return -1;
        }
        return 0;
      });

      cardsToDraw.forEach((b) => {
        const anim = animatedCardsRef.current.get(b.cardId)!;
        const isSelected = selectedPyramidCard !== null && selectedPyramidCard.cardId === b.cardId;
        const isCompact = b.width < 60;
        
        drawCard(ctx, b, anim.x, anim.y, b.width, b.height, isCompact, currentTheme.accentColor, isSelected);
      });

      ctx.restore();
      animationFrameId = requestAnimationFrame(render);
    };

    animationFrameId = requestAnimationFrame(render);
    return () => cancelAnimationFrame(animationFrameId);
  }, [currentTheme, selectedPyramidCard, updateLayout]);

  const handleSingleTap = useCallback(
    (card: CardBounds) => {
      if (card.cardId === -1 && card.pileKind === 0) {
        tapStockWasm();
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        setSelectedPyramidCard(null);
        updateLayout();
        return;
      }
      if (card.cardId === -1) return;

      if (card.pileKind === 0) {
        tapStockWasm();
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        setSelectedPyramidCard(null);
        updateLayout();
        return;
      }

      if (gameTypeCode === 3) {
        if (selectedPyramidCard === null) {
          setSelectedPyramidCard(card);
          if (executeMoveWasm(card.pileKind, card.pileIndex, 7, 0, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            setSelectedPyramidCard(null);
            updateLayout();
          }
        } else {
          if (selectedPyramidCard.cardId === card.cardId) {
            setSelectedPyramidCard(null);
          } else {
            const success = executePairMoveWasm(
              selectedPyramidCard.pileKind, selectedPyramidCard.pileIndex, 7, 0,
              selectedPyramidCard.cardId, card.cardId
            );
            if (success) {
              setMoveCount((m) => m + 1);
              audioService.playCardMove();
              setSelectedPyramidCard(null);
              updateLayout();
            } else {
              setSelectedPyramidCard(card);
            }
          }
        }
      }
    },
    [gameTypeCode, selectedPyramidCard, updateLayout]
  );

  const handleDoubleTap = useCallback(
    (card: CardBounds) => {
      if (card.cardId === -1) return;

      if (gameTypeCode === 0) {
        for (let f = 0; f < 4; f++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            updateLayout();
            break;
          }
        }
      } else if (gameTypeCode === 2) {
        for (let f = 0; f < 4; f++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            updateLayout();
            return;
          }
        }
        for (let c = 0; c < 4; c++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 4, c, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            updateLayout();
            return;
          }
        }
      }
    },
    [gameTypeCode, updateLayout]
  );

  const handleDragMove = useCallback((x: number, y: number) => {
    if (dragStateRef.current) {
      dragStateRef.current.ptrX = x;
      dragStateRef.current.ptrY = y;
    }
  }, []);

  const handleDragEnd = useCallback(
    (from: CardBounds, to: CardBounds) => {
      dragStateRef.current = null;
      if (gameTypeCode === 3) return;
      if (from.cardId === -1) return;

      if (executeMoveWasm(from.pileKind, from.pileIndex, to.pileKind, to.pileIndex, from.cardId)) {
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        updateLayout();
      }
    },
    [gameTypeCode, updateLayout]
  );

  const callbacksRef = useRef({ handleSingleTap, handleDoubleTap, handleDragEnd, handleDragMove });
  useEffect(() => {
    callbacksRef.current = { handleSingleTap, handleDoubleTap, handleDragEnd, handleDragMove };
  }, [handleSingleTap, handleDoubleTap, handleDragEnd, handleDragMove]);

  const pointerControllerRef = useRef(
    new PointerController(
      (c) => callbacksRef.current.handleSingleTap(c),
      (c) => callbacksRef.current.handleDoubleTap(c),
      (from, to) => callbacksRef.current.handleDragEnd(from, to),
      (x, y) => callbacksRef.current.handleDragMove(x, y)
    )
  );

  const startNewGame = useCallback(
    (typeCode?: number) => {
      const targetType = typeCode !== undefined ? typeCode : gameTypeCode;
      initializeGame(targetType, BigInt(Date.now()));
      animatedCardsRef.current.clear();
      setSelectedPyramidCard(null);
      setMoveCount(0);
      setTimerSeconds(0);
      updateLayout();
    },
    [gameTypeCode, updateLayout]
  );

  useEffect(() => {
    async function bootstrap() {
      await initEngine();
      startNewGame(gameTypeCode);
    }
    bootstrap();
  }, []);

  const handleGameSelect = (typeCode: number) => {
    setGameTypeCode(typeCode);
    startNewGame(typeCode);
  };

  useEffect(() => {
    return setupKeyboardNav({
      onUndo: () => { undoWasm(); updateLayout(); },
      onRedo: () => { redoWasm(); updateLayout(); },
      onNewGame: () => startNewGame(),
      onHint: () => {},
      onAutoPlay: () => {},
      onSettings: () => setIsSettingsOpen((o) => !o),
    });
  }, [updateLayout, startNewGame]);

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60).toString().padStart(2, "0");
    const s = (secs % 60).toString().padStart(2, "0");
    return `${m}:${s}`;
  };

  return (
    <div
      style={{
        width: "100vw",
        height: "100vh",
        position: "relative",
        overflow: "hidden",
        backgroundColor: currentTheme.tableColor,
      }}
      onPointerDown={(e) => {
        const bounds = cardBoundsListRef.current;
        pointerControllerRef.current.handlePointerDown(e, bounds);
        
        // Find hit card to start drag
        for (let i = bounds.length - 1; i >= 0; i--) {
          const b = bounds[i];
          if (b.cardId !== -1 && e.clientX >= b.x && e.clientX <= b.x + b.width && e.clientY >= b.y && e.clientY <= b.y + b.height) {
            const anim = animatedCardsRef.current.get(b.cardId);
            if (anim) {
              dragStateRef.current = {
                cardId: b.cardId,
                ptrX: e.clientX,
                ptrY: e.clientY,
                offsetX: e.clientX - anim.x,
                offsetY: e.clientY - anim.y
              };
            }
            break;
          }
        }
      }}
      onPointerMove={(e) => pointerControllerRef.current.handlePointerMove(e)}
      onPointerUp={(e) => {
        dragStateRef.current = null;
        pointerControllerRef.current.handlePointerUp(e, cardBoundsListRef.current);
      }}
      onPointerLeave={(e) => {
        dragStateRef.current = null;
        pointerControllerRef.current.handlePointerUp(e, cardBoundsListRef.current);
      }}
    >
      <div style={{ position: "absolute", top: 16, left: 24, right: 24, display: "flex", justifyContent: "space-between", alignItems: "center", background: "rgba(19, 19, 19, 0.65)", backdropFilter: "blur(16px)", borderRadius: "16px", padding: "12px 24px", border: "1px solid rgba(255, 255, 255, 0.12)", zIndex: 10, color: "#e5e2e1" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <h1 style={{ fontFamily: "Manrope, sans-serif", fontSize: "20px", fontWeight: 800, color: currentTheme.accentColor }}>Solitude</h1>
          <select value={gameTypeCode} onChange={(e) => handleGameSelect(Number(e.target.value))} style={{ background: "rgba(255, 255, 255, 0.1)", border: "1px solid rgba(255, 255, 255, 0.2)", borderRadius: "8px", color: "#e5e2e1", padding: "6px 12px", fontFamily: "Inter, sans-serif", fontSize: "14px", fontWeight: 600, cursor: "pointer", outline: "none" }}>
            <option value={0} style={{ background: "#1e1e1e", color: "#fff" }}>Klondike</option>
            <option value={2} style={{ background: "#1e1e1e", color: "#fff" }}>FreeCell</option>
            <option value={3} style={{ background: "#1e1e1e", color: "#fff" }}>Pyramid</option>
          </select>
        </div>
        <div style={{ display: "flex", gap: 24, fontFamily: "JetBrains Mono, monospace", fontSize: "14px" }}>
          <div><span style={{ opacity: 0.6 }}>TIME: </span>{formatTime(timerSeconds)}</div>
          <div><span style={{ opacity: 0.6 }}>MOVES: </span>{moveCount}</div>
        </div>
        <div style={{ display: "flex", gap: 12 }}>
          <button onClick={() => { undoWasm(); updateLayout(); }} title="Undo (U)" style={hudButtonStyle}><RotateCcw size={18} /></button>
          <button onClick={() => startNewGame()} title="New Game (N)" style={hudButtonStyle}><Play size={18} /></button>
          <button onClick={() => setIsSettingsOpen(true)} title="Settings (Esc)" style={hudButtonStyle}><SettingsIcon size={18} /></button>
        </div>
      </div>
      <canvas ref={canvasRef} style={{ width: "100%", height: "100%", display: "block", touchAction: "none" }} />
      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
    </div>
  );
};

function drawCard(ctx: CanvasRenderingContext2D, card: CardBounds, x: number, y: number, width: number, height: number, isCompact: boolean, accentColor: string, isSelected: boolean) {
  ctx.save();
  ctx.beginPath();
  ctx.roundRect(x, y, width, height, 8);

  if (!card.faceUp) {
    ctx.fillStyle = "#1e3a2b";
    ctx.fill();
    ctx.strokeStyle = isSelected ? "#ffd700" : accentColor;
    ctx.lineWidth = isSelected ? 2.5 : 1;
    ctx.stroke();
  } else {
    ctx.fillStyle = isSelected ? "#fffde7" : "#ffffff";
    ctx.fill();
    ctx.strokeStyle = isSelected ? "#ffd700" : "rgba(0,0,0,0.15)";
    ctx.lineWidth = isSelected ? 3 : 1;
    ctx.stroke();

    const isRed = card.suit === 0 || card.suit === 1;
    ctx.fillStyle = isRed ? "#cc3333" : "#111111";

    const rankStr = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"][card.rank - 1];
    const suitStr = ["♥", "♦", "♣", "♠"][card.suit];

    if (isCompact) {
      ctx.font = "bold 14px Inter, sans-serif";
      ctx.fillText(`${rankStr}${suitStr}`, x + 6, y + 18);
    } else {
      ctx.font = "bold 16px Manrope, sans-serif";
      ctx.fillText(rankStr, x + 8, y + 20);
      ctx.font = "14px Inter, sans-serif";
      ctx.fillText(suitStr, x + 8, y + 36);

      ctx.font = "28px Inter, sans-serif";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText(suitStr, x + width / 2, y + height / 2);
      ctx.textAlign = "start";
      ctx.textBaseline = "alphabetic";
    }
  }
  ctx.restore();
}

const hudButtonStyle: React.CSSProperties = { background: "rgba(255, 255, 255, 0.08)", border: "1px solid rgba(255, 255, 255, 0.15)", borderRadius: "8px", color: "#e5e2e1", padding: "8px 12px", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" };
export default App;
