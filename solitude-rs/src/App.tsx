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
  WasmCard,
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

export const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [gameTypeCode, setGameTypeCode] = useState<number>(0); // 0: Klondike, 2: FreeCell, 3: Pyramid
  const [moveCount, setMoveCount] = useState(0);
  const [timerSeconds, setTimerSeconds] = useState(0);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  // Selected card state for Pyramid pair matching
  const [selectedPyramidCard, setSelectedPyramidCard] = useState<CardBounds | null>(null);

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
    const boundsList: CardBounds[] = [];

    ctx.lineWidth = 1.5;
    ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
    ctx.fillStyle = "rgba(255, 255, 255, 0.03)";

    if (gameTypeCode === 3) {
      // --- PYRAMID LAYOUT ---
      const pyrLayout = calculatePyramidLayout(rect.width, rect.height);

      // Render 28 Pyramid pile slots
      let pIdx = 0;
      for (let row = 0; row < 7; row++) {
        for (let col = 0; col <= row; col++) {
          const pos = getPyramidCardPosition(row, col, pyrLayout);
          ctx.beginPath();
          ctx.roundRect(pos.x, pos.y, pyrLayout.cardWidth, pyrLayout.cardHeight, 8);
          ctx.fill();
          ctx.stroke();
          pIdx++;
        }
      }

      // Render Bottom Row slots: Stock & Waste (left), Discard (right)
      const bottomY = pyrLayout.bottomY;
      const stockX = 24;
      const wasteX = 24 + pyrLayout.cardWidth + 12;
      const discardX = rect.width - 24 - pyrLayout.cardWidth;

      // Stock slot
      ctx.beginPath();
      ctx.roundRect(stockX, bottomY, pyrLayout.cardWidth, pyrLayout.cardHeight, 8);
      ctx.fill();
      ctx.stroke();

      // Waste slot
      ctx.beginPath();
      ctx.roundRect(wasteX, bottomY, pyrLayout.cardWidth, pyrLayout.cardHeight, 8);
      ctx.fill();
      ctx.stroke();

      // Discard slot
      ctx.beginPath();
      ctx.roundRect(discardX, bottomY, pyrLayout.cardWidth, pyrLayout.cardHeight, 8);
      ctx.fill();
      ctx.stroke();

      // Render Cards in Pyramid
      piles.forEach((pile) => {
        let baseX = 0;
        let baseY = 0;

        if (pile.kind === 6) {
          // Pyramid pile (0..27)
          // Compute row and col from pile.index
          let idx = pile.index;
          let row = 0;
          while (idx > row) {
            idx -= row + 1;
            row++;
          }
          let col = idx;
          const pos = getPyramidCardPosition(row, col, pyrLayout);
          baseX = pos.x;
          baseY = pos.y;
        } else if (pile.kind === 0) {
          // Stock
          baseX = stockX;
          baseY = bottomY;
        } else if (pile.kind === 1) {
          // Waste
          baseX = wasteX;
          baseY = bottomY;
        } else if (pile.kind === 7) {
          // Discard
          baseX = discardX;
          baseY = bottomY;
        }

        pile.cards.forEach((card, cardIdx) => {
          const cardX = baseX;
          const cardY = baseY;

          const isSelected =
            selectedPyramidCard !== null &&
            selectedPyramidCard.cardId === card.id;

          boundsList.push({
            pileKind: pile.kind,
            pileIndex: pile.index,
            cardIndex: cardIdx,
            cardId: card.id,
            x: cardX,
            y: cardY,
            width: pyrLayout.cardWidth,
            height: pyrLayout.cardHeight,
            faceUp: card.faceUp,
          });

          // Draw Card Body
          drawCard(
            ctx,
            card,
            cardX,
            cardY,
            pyrLayout.cardWidth,
            pyrLayout.cardHeight,
            pyrLayout.isCompactTier,
            currentTheme.accentColor,
            isSelected
          );
        });
      });
    } else if (gameTypeCode === 2) {
      // --- FREECELL LAYOUT ---
      const layout = calculateGridLayout(rect.width, rect.height, 8);

      // Top row slots: 4 FreeCells (left) + 4 Foundations (right)
      for (let c = 0; c < 4; c++) {
        const x = layout.startX + c * (layout.cardWidth + layout.gap);
        ctx.beginPath();
        ctx.roundRect(x, layout.topOffset, layout.cardWidth, layout.cardHeight, 8);
        ctx.fill();
        ctx.stroke();
      }
      for (let f = 0; f < 4; f++) {
        const x = layout.startX + (4 + f) * (layout.cardWidth + layout.gap);
        ctx.beginPath();
        ctx.roundRect(x, layout.topOffset, layout.cardWidth, layout.cardHeight, 8);
        ctx.fill();
        ctx.stroke();
      }

      // Render Cards
      piles.forEach((pile) => {
        let baseX = layout.startX;
        let baseY = layout.topOffset;

        if (pile.kind === 4) {
          // Cell (0..3)
          baseX = layout.startX + pile.index * (layout.cardWidth + layout.gap);
        } else if (pile.kind === 2) {
          // Foundation (0..3)
          baseX = layout.startX + (4 + pile.index) * (layout.cardWidth + layout.gap);
        } else if (pile.kind === 3) {
          // Tableau (0..7)
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

          drawCard(
            ctx,
            card,
            baseX,
            cardY,
            layout.cardWidth,
            layout.cardHeight,
            layout.isCompactTier,
            currentTheme.accentColor,
            false
          );
        });
      });
    } else {
      // --- KLONDIKE LAYOUT ---
      const layout = calculateGridLayout(rect.width, rect.height, 7);

      // Stock & Waste slots
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

      // Render Cards
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

          drawCard(
            ctx,
            card,
            baseX,
            cardY,
            layout.cardWidth,
            layout.cardHeight,
            layout.isCompactTier,
            currentTheme.accentColor,
            false
          );
        });
      });
    }

    cardBoundsListRef.current = boundsList;
    ctx.restore();
  }, [currentTheme, gameTypeCode, selectedPyramidCard]);

  // Handle Card Taps & Pyramid Pair Matching
  const handleSingleTap = useCallback(
    (card: CardBounds) => {
      if (card.pileKind === 0) {
        // Tap Stock
        tapStockWasm();
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        setSelectedPyramidCard(null);
        refreshPilesAndRender();
        return;
      }

      if (gameTypeCode === 3) {
        // Pyramid Game Interaction
        if (selectedPyramidCard === null) {
          // First card selected
          setSelectedPyramidCard(card);
          // Try King self-removal (cardId to Discard pile 7)
          if (executeMoveWasm(card.pileKind, card.pileIndex, 7, 0, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            setSelectedPyramidCard(null);
            refreshPilesAndRender();
          }
        } else {
          // Second card selected: try pair move
          if (selectedPyramidCard.cardId === card.cardId) {
            // Deselect on second tap of same card
            setSelectedPyramidCard(null);
          } else {
            const success = executePairMoveWasm(
              selectedPyramidCard.pileKind,
              selectedPyramidCard.pileIndex,
              7,
              0,
              selectedPyramidCard.cardId,
              card.cardId
            );
            if (success) {
              setMoveCount((m) => m + 1);
              audioService.playCardMove();
              setSelectedPyramidCard(null);
              refreshPilesAndRender();
            } else {
              // Select the new card instead
              setSelectedPyramidCard(card);
            }
          }
        }
      }
    },
    [gameTypeCode, selectedPyramidCard, refreshPilesAndRender]
  );

  const handleDoubleTap = useCallback(
    (card: CardBounds) => {
      if (gameTypeCode === 0) {
        // Klondike auto-move to foundations
        for (let f = 0; f < 4; f++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            refreshPilesAndRender();
            break;
          }
        }
      } else if (gameTypeCode === 2) {
        // FreeCell auto-move to foundations or empty cell
        for (let f = 0; f < 4; f++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 2, f, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            refreshPilesAndRender();
            return;
          }
        }
        for (let c = 0; c < 4; c++) {
          if (executeMoveWasm(card.pileKind, card.pileIndex, 4, c, card.cardId)) {
            setMoveCount((m) => m + 1);
            audioService.playCardMove();
            refreshPilesAndRender();
            return;
          }
        }
      }
    },
    [gameTypeCode, refreshPilesAndRender]
  );

  const pointerControllerRef = useRef(
    new PointerController(
      (c) => handleSingleTap(c),
      (c) => handleDoubleTap(c),
      () => {}
    )
  );

  // Bootstrap & Switch Games
  const startNewGame = useCallback(
    (typeCode?: number) => {
      const targetType = typeCode !== undefined ? typeCode : gameTypeCode;
      initializeGame(targetType, BigInt(Date.now()));
      setSelectedPyramidCard(null);
      setMoveCount(0);
      setTimerSeconds(0);
      refreshPilesAndRender();
    },
    [gameTypeCode, refreshPilesAndRender]
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
      onNewGame: () => startNewGame(),
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

          {/* Game Selection Dropdown */}
          <select
            value={gameTypeCode}
            onChange={(e) => handleGameSelect(Number(e.target.value))}
            style={{
              background: "rgba(255, 255, 255, 0.1)",
              border: "1px solid rgba(255, 255, 255, 0.2)",
              borderRadius: "8px",
              color: "#e5e2e1",
              padding: "6px 12px",
              fontFamily: "Inter, sans-serif",
              fontSize: "14px",
              fontWeight: 600,
              cursor: "pointer",
              outline: "none",
            }}
          >
            <option value={0} style={{ background: "#1e1e1e", color: "#fff" }}>
              Klondike
            </option>
            <option value={2} style={{ background: "#1e1e1e", color: "#fff" }}>
              FreeCell
            </option>
            <option value={3} style={{ background: "#1e1e1e", color: "#fff" }}>
              Pyramid
            </option>
          </select>
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

          <button onClick={() => startNewGame()} title="New Game (N)" style={hudButtonStyle}>
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

function drawCard(
  ctx: CanvasRenderingContext2D,
  card: WasmCard,
  x: number,
  y: number,
  width: number,
  height: number,
  isCompact: boolean,
  accentColor: string,
  isSelected: boolean
) {
  ctx.save();
  ctx.beginPath();
  ctx.roundRect(x, y, width, height, 8);

  if (!card.faceUp) {
    // Card Back Pattern
    ctx.fillStyle = "#1e3a2b";
    ctx.fill();
    ctx.strokeStyle = isSelected ? "#ffd700" : accentColor;
    ctx.lineWidth = isSelected ? 2.5 : 1;
    ctx.stroke();
  } else {
    // Card Face
    ctx.fillStyle = isSelected ? "#fffde7" : "#ffffff";
    ctx.fill();
    ctx.strokeStyle = isSelected ? "#ffd700" : "rgba(0,0,0,0.15)";
    ctx.lineWidth = isSelected ? 3 : 1;
    ctx.stroke();

    // Card Rank & Suit Glyphs
    const isRed = card.suit === 0 || card.suit === 1;
    ctx.fillStyle = isRed ? "#cc3333" : "#111111";

    const rankStr = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"][card.rank - 1];
    const suitStr = ["♥", "♦", "♣", "♠"][card.suit];

    if (isCompact) {
      // Compact rendering tier: single pip + rank letter
      ctx.font = "bold 14px Inter, sans-serif";
      ctx.fillText(`${rankStr}${suitStr}`, x + 6, y + 18);
    } else {
      // Standard rendering tier: corner rank + suit badge
      ctx.font = "bold 16px Manrope, sans-serif";
      ctx.fillText(rankStr, x + 8, y + 20);
      ctx.font = "14px Inter, sans-serif";
      ctx.fillText(suitStr, x + 8, y + 36);

      // Center large suit glyph
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
