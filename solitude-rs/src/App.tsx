import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  initEngine,
  initializeGame,
  getPilesLayout,
  tapStockWasm,
  undoWasm,
  redoWasm,
  executeMoveWasm,
} from "./wasm/engine";
import { calculateGridLayout } from "./canvas/layout/gridLayout";
import { PointerController, CardBounds } from "./input/pointerController";
import { setupKeyboardNav } from "./input/keyboardNav";
import { THEME_PRESETS } from "./theme/presets";
import { useUIStore } from "./store/uiStore";
import { SettingsModal } from "./components/SettingsModal";
import { audioService } from "./audio/audioService";
import { RotateCcw, Play, Settings as SettingsIcon } from "lucide-react";

export const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [moveCount, setMoveCount] = useState(0);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const cardBoundsListRef = useRef<CardBounds[]>([]);

  const { themeId, soundEnabled, soundVolume } = useUIStore();
  const currentTheme = THEME_PRESETS[themeId] || THEME_PRESETS.classic_felt;

  // Sync audio config
  useEffect(() => {
    audioService.setConfig(soundEnabled, soundVolume);
  }, [soundEnabled, soundVolume]);

  // Timer interval
  useEffect(() => {
    const timer = setInterval(() => {
      setTimerSeconds((s) => s + 1);
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const refreshPilesAndRender = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();

    canvas.width = Math.floor(rect.width * dpr);
    canvas.height = Math.floor(rect.height * dpr);

    ctx.save();
    ctx.scale(dpr, dpr);

    // Render table background from theme
    const gradient = ctx.createRadialGradient(
      rect.width / 2,
      rect.height / 2,
      100,
      rect.width / 2,
      rect.height / 2,
      Math.max(rect.width, rect.height)
    );
    gradient.addColorStop(0, currentTheme.tableColor);
    gradient.addColorStop(1, currentTheme.tableGradientEnd);

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, rect.width, rect.height);

    const piles = getPilesLayout();
    const layout = calculateGridLayout(rect.width, rect.height, 7);
    const boundsList: CardBounds[] = [];

    ctx.lineWidth = 1.5;
    ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
    ctx.fillStyle = "rgba(255, 255, 255, 0.03)";

    // Render pile slots
    // Stock & Waste
    ctx.beginPath();
    ctx.roundRect(layout.startX, layout.topOffset, layout.cardWidth, layout.cardHeight, 8);
    ctx.fill();
    ctx.stroke();

    ctx.beginPath();
    ctx.roundRect(layout.startX + layout.cardWidth + layout.gap, layout.topOffset, layout.cardWidth, layout.cardHeight, 8);
    ctx.fill();
    ctx.stroke();

    // Foundations (piles 2..5)
    for (let f = 0; f < 4; f++) {
      const x = layout.startX + (3 + f) * (layout.cardWidth + layout.gap);
      ctx.beginPath();
      ctx.roundRect(x, layout.topOffset, layout.cardWidth, layout.cardHeight, 8);
      ctx.fill();
      ctx.stroke();
    }

    // Render Cards in Piles
    piles.forEach((pile) => {
      let baseX = layout.startX;
      let baseY = layout.topOffset;

      if (pile.kind === 0) {
        baseX = layout.startX;
      } else if (pile.kind === 1) {
        baseX = layout.startX + layout.cardWidth + layout.gap;
      } else if (pile.kind === 2) {
        baseX = layout.startX + (3 + pile.index) * (layout.cardWidth + layout.gap);
      } else if (pile.kind === 3) {
        baseX = layout.startX + pile.index * (layout.cardWidth + layout.gap);
        baseY = layout.topOffset + layout.cardHeight + 24;
      }

      pile.cards.forEach((card, cardIdx) => {
        let cardY = baseY;
        if (pile.kind === 3) {
          cardY += cardIdx * layout.stackOffset;
        }

        boundsList.push({
          pileKind: pile.kind,
          pileIndex: pile.index,
          cardIndex: cardIdx,
          cardId: card.id,
          x: baseX,
          y: cardY,
          width: layout.cardWidth,
          height: layout.cardHeight,
          faceUp: card.faceUp,
        });

        // Draw Card Body
        ctx.save();
        ctx.beginPath();
        ctx.roundRect(baseX, cardY, layout.cardWidth, layout.cardHeight, 8);

        if (!card.faceUp) {
          // Card Back Pattern
          ctx.fillStyle = "#1e3a2b";
          ctx.fill();
          ctx.strokeStyle = currentTheme.accentColor;
          ctx.lineWidth = 1;
          ctx.stroke();
        } else {
          // Card Face
          ctx.fillStyle = "#ffffff";
          ctx.fill();
          ctx.strokeStyle = "rgba(0,0,0,0.1)";
          ctx.stroke();

          // Card Rank & Suit Glyphs
          const isRed = card.suit === 0 || card.suit === 1;
          ctx.fillStyle = isRed ? "#cc3333" : "#111111";

          const rankStr = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"][card.rank - 1];
          const suitStr = ["♥", "♦", "♣", "♠"][card.suit];

          if (layout.isCompactTier) {
            // Compact rendering tier: single pip + rank letter
            ctx.font = "bold 14px Inter, sans-serif";
            ctx.fillText(`${rankStr}${suitStr}`, baseX + 6, cardY + 18);
          } else {
            // Standard rendering tier: corner rank + suit badge
            ctx.font = "bold 16px Manrope, sans-serif";
            ctx.fillText(rankStr, baseX + 8, cardY + 20);
            ctx.font = "14px Inter, sans-serif";
            ctx.fillText(suitStr, baseX + 8, cardY + 36);

            // Center large suit glyph
            ctx.font = "28px Inter, sans-serif";
            ctx.textAlign = "center";
            ctx.textBaseline = "middle";
            ctx.fillText(suitStr, baseX + layout.cardWidth / 2, cardY + layout.cardHeight / 2);
            ctx.textAlign = "start";
            ctx.textBaseline = "alphabetic";
          }
        }
        ctx.restore();
      });
    });

    cardBoundsListRef.current = boundsList;
    ctx.restore();
  }, [currentTheme]);

  const handleSingleTap = useCallback(
    (card: CardBounds) => {
      if (card.pileKind === 0) {
        tapStockWasm();
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        refreshPilesAndRender();
      }
    },
    [refreshPilesAndRender]
  );

  const handleDoubleTap = useCallback(
    (card: CardBounds) => {
      for (let f = 0; f < 4; f++) {
        if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
          setMoveCount((m) => m + 1);
          audioService.playCardMove();
          refreshPilesAndRender();
          break;
        }
      }
    },
    [refreshPilesAndRender]
  );

  const pointerControllerRef = useRef(
    new PointerController(
      (c) => handleSingleTap(c),
      (c) => handleDoubleTap(c),
      () => {}
    )
  );

  // Bootstrap Klondike
  const startNewGame = useCallback(() => {
    initializeGame(0, BigInt(Date.now()));
    setMoveCount(0);
    setTimerSeconds(0);
    refreshPilesAndRender();
  }, [refreshPilesAndRender]);

  useEffect(() => {
    async function bootstrap() {
      await initEngine();
      startNewGame();
    }
    bootstrap();
  }, [startNewGame]);

  // Keyboard shortcuts
  useEffect(() => {
    return setupKeyboardNav({
      onUndo: () => {
        undoWasm();
        refreshPilesAndRender();
      },
      onRedo: () => {
        redoWasm();
        refreshPilesAndRender();
      },
      onNewGame: startNewGame,
      onHint: () => {},
      onAutoPlay: () => {},
      onSettings: () => setIsSettingsOpen((o) => !o),
    });
  }, [refreshPilesAndRender, startNewGame]);

  const formatTime = (secs: number) => {
    const m = Math.floor(secs / 60)
      .toString()
      .padStart(2, "0");
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
      onPointerDown={(e) => pointerControllerRef.current.handlePointerDown(e)}
      onPointerMove={(e) => pointerControllerRef.current.handlePointerMove(e)}
      onPointerUp={(e) => pointerControllerRef.current.handlePointerUp(e, cardBoundsListRef.current)}
    >
      {/* Top Glassmorphism HUD Navbar */}
      <div
        style={{
          position: "absolute",
          top: 16,
          left: 24,
          right: 24,
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          background: "rgba(19, 19, 19, 0.65)",
          backdropFilter: "blur(16px)",
          borderRadius: "16px",
          padding: "12px 24px",
          border: "1px solid rgba(255, 255, 255, 0.12)",
          zIndex: 10,
          color: "#e5e2e1",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          <h1 style={{ fontFamily: "Manrope, sans-serif", fontSize: "20px", fontWeight: 800, color: currentTheme.accentColor }}>
            Solitude
          </h1>
          <span style={{ fontSize: "14px", opacity: 0.7 }}>Klondike</span>
        </div>

        {/* HUD Info */}
        <div style={{ display: "flex", gap: 24, fontFamily: "JetBrains Mono, monospace", fontSize: "14px" }}>
          <div>
            <span style={{ opacity: 0.6 }}>TIME: </span>
            {formatTime(timerSeconds)}
          </div>
          <div>
            <span style={{ opacity: 0.6 }}>MOVES: </span>
            {moveCount}
          </div>
        </div>

        {/* HUD Controls */}
        <div style={{ display: "flex", gap: 12 }}>
          <button
            onClick={() => {
              undoWasm();
              refreshPilesAndRender();
            }}
            title="Undo (U)"
            style={hudButtonStyle}
          >
            <RotateCcw size={18} />
          </button>

          <button onClick={startNewGame} title="New Game (N)" style={hudButtonStyle}>
            <Play size={18} />
          </button>

          <button onClick={() => setIsSettingsOpen(true)} title="Settings (Esc)" style={hudButtonStyle}>
            <SettingsIcon size={18} />
          </button>
        </div>
      </div>

      {/* Main Canvas rendering area */}
      <canvas ref={canvasRef} style={{ width: "100%", height: "100%", display: "block" }} />

      {/* Settings Modal */}
      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} />
    </div>
  );
};

const hudButtonStyle: React.CSSProperties = {
  background: "rgba(255, 255, 255, 0.08)",
  border: "1px solid rgba(255, 255, 255, 0.15)",
  borderRadius: "8px",
  color: "#e5e2e1",
  padding: "8px 12px",
  cursor: "pointer",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
};

export default App;
