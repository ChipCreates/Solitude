import React, { useEffect, useRef, useState, useCallback } from "react";
import {
  initEngine, initializeGame, getPilesLayout, tapStockWasm,
  undoWasm, redoWasm, executeMoveWasm, executePairMoveWasm,
  getHintWasm, autoPlayStepWasm, checkWinWasm, isLostWasm,
  reshuffleStockWasteWasm, resetTableauColumnWasm,
  shelveTopCardWasm, unshelveCardWasm, getShelvedCard, ShelvedCard,
  getSnapshotJson, restoreSnapshotJson,
} from "./wasm/engine";
import { calculateGridLayout } from "./canvas/layout/gridLayout";
import { calculatePyramidLayout, getPyramidCardPosition } from "./canvas/layout/pyramidLayout";
import { CardBounds } from "./input/cardBounds";
import { setupKeyboardNav } from "./input/keyboardNav";
import { THEME_PRESETS } from "./theme/presets";
import { useUIStore } from "./store/uiStore";
import { useProfileStore } from "./store/profileStore";
import { useStatisticsStore } from "./store/statisticsStore";
import { GAME_TYPE_NAMES } from "./data/gameTypes";
import { checkWinAchievements } from "./achievements/checkAchievements";
import type { SaveEnvelope } from "./persistence/store";
import { MUSIC_TRACKS, CUSTOM_TRACK_ID } from "./data/musicTracks";
import { CardWidget } from "./components/CardWidget";
import { SettingsModal } from "./components/SettingsModal";
import { GameChooserGrid } from "./components/GameChooserGrid";
import { LevelBadge } from "./components/LevelBadge";
import { VictoryModal } from "./components/VictoryModal";
import { HelpModal } from "./components/HelpModal";
import { AboutModal } from "./components/AboutModal";
import { SplashPage } from "./components/SplashPage";
import { MetaGameHub, STORE_ITEMS } from "./components/MetaGameHub";
import { POWER_UP_CONFIG } from "./powerups/config";
import { audioService } from "./audio/audioService";
import { ParticleSystem } from "./canvas/renderParticles";
import { RotateCcw, Play, Settings as SettingsIcon, Lightbulb, Sparkles, HelpCircle, Zap, Undo2, Info } from "lucide-react";

const POWER_UP_ITEMS = STORE_ITEMS.filter((i) => i.type === "power_up");
const RANK_STRS = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
const SUIT_STRS = ["♥", "♦", "♣", "♠"];

interface AnimatedCard { x: number; y: number; vx: number; vy: number; }

// Standard Vegas Klondike scoring: buy the deck for $52, earn $5 per card
// moved to a foundation. Derived from live pile state (not tracked
// incrementally) so it stays correct across undo/redo for free.
function computeVegasScore(): number {
  const foundationCards = getPilesLayout()
    .filter((p) => p.kind === 2)
    .reduce((n, p) => n + p.cards.length, 0);
  return -52 + foundationCards * 5;
}

function spiderSuitCountForDifficulty(difficulty: "easy" | "normal" | "hard"): number {
  if (difficulty === "easy") return 1;
  if (difficulty === "hard") return 4;
  return 2;
}

export const App: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  // Use a ref for gameTypeCode so async callbacks always read the live value
  const gameTypeRef = useRef<number | null>(null);
  const [gameTypeCode, setGameTypeCodeState] = useState<number | null>(null);
  const setGameTypeCode = (n: number | null) => { 
    if (n !== null) gameTypeRef.current = n; 
    setGameTypeCodeState(n); 
  };

  const [moveCount, setMoveCount] = useState(0);
  const [timerSeconds, setTimerSeconds] = useState(0);
  // The render loop's rAF closure is set up once (updateLayout/currentTheme
  // rarely change) so it would otherwise see moveCount/timerSeconds frozen
  // at their value when the effect was created. Mirror them into refs so
  // win/loss statistics recording reads live values.
  const moveCountRef = useRef(0);
  const timerSecondsRef = useRef(0);
  useEffect(() => { moveCountRef.current = moveCount; }, [moveCount]);
  useEffect(() => { timerSecondsRef.current = timerSeconds; }, [timerSeconds]);
  const [, setLayoutTick] = useState(0);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  const [isHelpOpen, setIsHelpOpen] = useState(false);
  const [isAboutOpen, setIsAboutOpen] = useState(false);
  const [activeTab, setActiveTab] = useState<"gameboard" | "store" | "trophy">("gameboard");
  const [isEngineReady, setIsEngineReady] = useState(false);
  const [isSplashComplete, setIsSplashComplete] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [winData, setWinData] = useState<{ xpGained: number, leveledUp: boolean, newLevel: number, newXP: number, newlyUnlockedAchievements: string[] } | null>(null);

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

  // ─── Power-ups ────────────────────────────────────────────────────────────
  // Which power-up (if any) is awaiting a card/column tap to resolve its
  // target. Set by activatePowerUp(), consumed by the onPointerDown guard.
  const activePowerUpRef = useRef<string | null>(null);
  // onPointerDown is a frozen (empty-deps) callback, so it can't safely call
  // resolveTargetedPowerUp directly (that closure changes with updateLayout)
  // without going stale — mirror it into a ref like moveCountRef/
  // timerSecondsRef do for the same reason.
  const resolveTargetedPowerUpRef = useRef<(id: string, hit: CardBounds) => void>(() => {});
  const [powerUpTrayOpen, setPowerUpTrayOpen] = useState(false);
  const [powerUpToast, setPowerUpToast] = useState<string | null>(null);
  const [powerUpReveal, setPowerUpReveal] = useState<{ title: string; cards: { rank: number, suit: number }[] } | null>(null);
  const [shelvedCard, setShelvedCard] = useState<ShelvedCard | null>(null);

  const hintCardIdRef = useRef<number | null>(null);
  const [hintGhost, setHintGhost] = useState<{startX: number, startY: number, endX: number, endY: number, width: number, height: number, rank: number, suit: number} | null>(null);
  const [ghostPos, setGhostPos] = useState({x: 0, y: 0});
  const [isAutoPlaying, setIsAutoPlaying] = useState(false);
  const autoPlayTimeoutRef = useRef<number | null>(null);
  const shouldCancelAutoPlayRef = useRef(false);
  const isWonRef = useRef(false);
  const isLostRef = useRef(false);
  // Tracks whether the current round used a hint or undo, for the
  // "perfect_game" achievement (win without either).
  const usedHintOrUndoRef = useRef(false);
  // Guards against double-committing a Vegas-cumulative round's score: it can
  // be committed either on win (render loop) or on New Game (startNewGame),
  // whichever happens first for a given round.
  const vegasRoundCommittedRef = useRef(false);

  // ─── Save / Resume ────────────────────────────────────────────────────────
  // The variant options actually baked into the current WASM game instance
  // (frozen at startNewGame/resumeGame time) -- NOT read from uiStore at
  // save time, since the player could change Draw Mode etc. in Settings
  // mid-game without that affecting the game already in progress.
  const currentVariantOptionsRef = useRef({ klondikeDrawMode: 1, spiderSuitCount: 4, golfWrapAround: false });
  const [resumableSave, setResumableSave] = useState<SaveEnvelope | null>(null);

  // ─── Keyboard Navigation (Tab: cycle piles, Enter/Space: select) ─────────
  const [focusedPile, setFocusedPile] = useState<{ pileKind: number; pileIndex: number } | null>(null);
  const keyboardSelectedRef = useRef<CardBounds | null>(null);
  const [keyboardSelectedId, setKeyboardSelectedId] = useState<number | null>(null);

  const {
    themeId, themeOverlayIntensities, cardBackPattern, cardBackColor, soundEnabled, soundVolume, victoryPattern, scoringMode, vegasBankroll,
    musicEnabled, musicVolume, musicTrackId, customMusicUrl, powerUpInventory,
  } = useUIStore();
  const currentTheme = THEME_PRESETS[themeId] || THEME_PRESETS.classic_felt;
  const overlayIntensity = themeOverlayIntensities[themeId] ?? currentTheme.defaultOverlayIntensity;

  useEffect(() => { audioService.setConfig(soundEnabled, soundVolume); }, [soundEnabled, soundVolume]);
  useEffect(() => { audioService.setMusicConfig(musicEnabled, musicVolume); }, [musicEnabled, musicVolume]);
  useEffect(() => {
    const activeTrackUrl = musicTrackId === CUSTOM_TRACK_ID
      ? customMusicUrl
      : MUSIC_TRACKS.find((t) => t.id === musicTrackId)?.url ?? MUSIC_TRACKS[0]?.url ?? null;
    audioService.setMusicTrack(activeTrackUrl);
  }, [musicTrackId, customMusicUrl]);
  useEffect(() => {
    const timer = setInterval(() => setTimerSeconds((s) => s + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  // ─── Layout (type-agnostic) ───────────────────────────────────────────────
  const updateLayout = useCallback((typeCode?: number | null) => {
    const type = typeCode !== undefined ? typeCode : gameTypeRef.current;
    if (type === null) return;
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

      // Cards themselves are rendered as opaque DOM elements in #cards-layer
      // (which paints over this canvas), reading position from the same
      // animatedCardsRef the spring-physics step below updates — so that
      // physics step is live (it drives the DOM animation) even though
      // nothing here draws the cards themselves onto the canvas.
      const ds = dragStateRef.current;
      cardBoundsListRef.current.forEach((b) => {
        if (b.cardId === -1) {
          ctx.beginPath(); ctx.roundRect(b.x, b.y, b.width, b.height, 8); ctx.fill(); ctx.stroke();
        } else {
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

      if (checkWinWasm()) {
        if (!isWonRef.current) {
          isWonRef.current = true;
          clearSavedGame(); // a completed game has nothing left to resume
          audioService.playWin();
          particleSystemRef.current.spawnVictoryPattern(victoryPattern, rect.width, rect.height);
          
          // Reward XP & Coins
          const uiState = useUIStore.getState();
          const baseReward = 100;
          const diffMult = uiState.difficulty === "hard" ? 3 : uiState.difficulty === "normal" ? 2 : 1;
          const reward = baseReward * diffMult;
          uiState.addCoins(reward);

          // Vegas cumulative: commit this round's final score into the
          // persisted bankroll right away, so New Game doesn't double-commit.
          if (gameTypeRef.current === 0 && uiState.scoringMode === "vegas_cumulative" && !vegasRoundCommittedRef.current) {
            uiState.addToVegasBankroll(computeVegasScore());
            vegasRoundCommittedRef.current = true;
          }

          if (gameTypeRef.current !== null) {
            const xpResult = uiState.addXP(gameTypeRef.current.toString(), reward);
            const gameTypeName = GAME_TYPE_NAMES[gameTypeRef.current];
            const elapsedMs = timerSecondsRef.current * 1000;
            useStatisticsStore.getState().recordWin(gameTypeName, elapsedMs, moveCountRef.current);
            // recordWin() updates statsByGameType synchronously (before its
            // first await), so the fresh stats are already readable here.
            const newlyUnlocked = checkWinAchievements({
              elapsedMs,
              moveCount: moveCountRef.current,
              updatedStats: useStatisticsStore.getState().getStats(gameTypeName),
              usedHintOrUndo: usedHintOrUndoRef.current,
            });
            setWinData({
              xpGained: reward,
              leveledUp: xpResult.leveledUp,
              newLevel: xpResult.newLevel,
              newXP: xpResult.newXP,
              newlyUnlockedAchievements: newlyUnlocked,
            });
          }
        }
        particleSystemRef.current.updateAndRender(ctx, rect.width, rect.height, victoryPattern);
      } else if (isLostWasm()) {
        if (!isLostRef.current) {
          isLostRef.current = true;
          clearSavedGame(); // a lost game has nothing left to resume
          if (gameTypeRef.current !== null) {
            useStatisticsStore.getState().recordLoss(GAME_TYPE_NAMES[gameTypeRef.current]);
          }
          setToastMessage("No moves remaining. Better luck next time!");
        }
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

  // ─── Keyboard Navigation ──────────────────────────────────────────────────
  const getFocusablePiles = (): { pileKind: number; pileIndex: number }[] => {
    const seen = new Set<string>();
    const piles: { pileKind: number; pileIndex: number }[] = [];
    for (const b of cardBoundsListRef.current) {
      const key = `${b.pileKind}_${b.pileIndex}`;
      if (!seen.has(key)) { seen.add(key); piles.push({ pileKind: b.pileKind, pileIndex: b.pileIndex }); }
    }
    return piles;
  };

  const topCardOfPile = (pileKind: number, pileIndex: number): CardBounds | null => {
    // cardBoundsListRef is already ordered bottom-to-top per pile (matches
    // findHit's reverse-iteration hit test), so the last match is the top.
    const matches = cardBoundsListRef.current.filter((b) => b.pileKind === pileKind && b.pileIndex === pileIndex);
    return matches.length > 0 ? matches[matches.length - 1] : null;
  };

  const cycleFocusedPile = useCallback((direction: 1 | -1) => {
    const piles = getFocusablePiles();
    if (piles.length === 0) return;
    setFocusedPile((current) => {
      const currentIdx = current ? piles.findIndex((p) => p.pileKind === current.pileKind && p.pileIndex === current.pileIndex) : -1;
      const nextIdx = ((currentIdx === -1 ? 0 : currentIdx + direction) + piles.length) % piles.length;
      return piles[nextIdx];
    });
  }, []);

  const cancelKeyboardSelection = useCallback(() => {
    keyboardSelectedRef.current = null;
    setKeyboardSelectedId(null);
  }, []);

  const selectFocusedPile = useCallback(() => {
    if (!focusedPile) return;
    if (!keyboardSelectedRef.current) {
      // Stock has no "top card to pick up" in the usual sense -- Enter/Space
      // on it just draws, mirroring a click.
      if (focusedPile.pileKind === 0) {
        tapStockWasm();
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        updateLayout();
        return;
      }
      const top = topCardOfPile(focusedPile.pileKind, focusedPile.pileIndex);
      if (!top || top.cardId === -1 || !top.faceUp) return; // nothing selectable here
      keyboardSelectedRef.current = top;
      setKeyboardSelectedId(top.cardId);
      return;
    }

    const source = keyboardSelectedRef.current;
    cancelKeyboardSelection();
    if (source.pileKind === focusedPile.pileKind && source.pileIndex === focusedPile.pileIndex) return;
    if (executeMoveWasm(source.pileKind, source.pileIndex, focusedPile.pileKind, focusedPile.pileIndex, source.cardId)) {
      setMoveCount((m) => m + 1);
      audioService.playCardMove();
      updateLayout();
    }
  }, [focusedPile, updateLayout, cancelKeyboardSelection]);

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

  // Card bounds (cardBoundsListRef) and animated positions are stored in
  // canvas-local coordinates (0,0 = canvas top-left), but pointer events
  // report clientX/clientY in viewport coordinates. The canvas sits below
  // a sidebar and header, so those never coincide — hit-testing against raw
  // client coordinates silently missed every card. Convert to local space
  // once, here, before any hit-testing or drag-offset math.
  const toLocalPoint = (e: { clientX: number; clientY: number }): { x: number; y: number } => {
    const rect = canvasRef.current?.getBoundingClientRect();
    return { x: e.clientX - (rect?.left ?? 0), y: e.clientY - (rect?.top ?? 0) };
  };

  const onPointerDown = useCallback((e: React.PointerEvent) => {
    const { x, y } = toLocalPoint(e);

    if (activePowerUpRef.current) {
      const hit = findHit(x, y);
      const id = activePowerUpRef.current;
      activePowerUpRef.current = null;
      setPowerUpToast(null);
      if (hit) resolveTargetedPowerUpRef.current(id, hit);
      return;
    }

    pointerDownRef.current = { x, y };
    movedRef.current = false;
    const hit = findHit(x, y);
    dragStartCardRef.current = hit;
    if (hit && hit.cardId !== -1) {
      const anim = animatedCardsRef.current.get(hit.cardId);
      dragStateRef.current = {
        cardId: hit.cardId, ptrX: x, ptrY: y,
        offsetX: x - (anim?.x ?? hit.x), offsetY: y - (anim?.y ?? hit.y),
      };
    }
  }, []);

  const onPointerMove = useCallback((e: React.PointerEvent) => {
    const { x, y } = toLocalPoint(e);
    if (pointerDownRef.current && !movedRef.current) {
      const dist = Math.hypot(x - pointerDownRef.current.x, y - pointerDownRef.current.y);
      if (dist > 8) movedRef.current = true;
    }
    if (dragStateRef.current) {
      dragStateRef.current.ptrX = x;
      dragStateRef.current.ptrY = y;
    }
  }, []);

  const onPointerUp = useCallback((e: React.PointerEvent) => {
    if (!pointerDownRef.current) return;
    const { x, y } = toLocalPoint(e);
    const wasDrag = movedRef.current;
    const hit = findHit(x, y);

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
  // Shared between startNewGame and resumeGame -- everything except the
  // WASM game state itself and the move/timer counters, which the two
  // callers seed differently (zeroed vs. restored from a save).
  const resetUiStateForRound = useCallback(() => {
    animatedCardsRef.current.clear();
    setSelectedPyramidCard(null);
    hintCardIdRef.current = null;
    isWonRef.current = false;
    isLostRef.current = false;
    usedHintOrUndoRef.current = false;
    activePowerUpRef.current = null;
    setPowerUpToast(null);
    setPowerUpReveal(null);
    setShelvedCard(null); // initializeGame() already clears the Rust-side shelf
    particleSystemRef.current.clear();
    setIsAutoPlaying(false);
    setToastMessage(null);
    setFocusedPile(null);
    keyboardSelectedRef.current = null;
    setKeyboardSelectedId(null);
  }, []);

  const clearSavedGame = useCallback(() => {
    const profileId = useProfileStore.getState().activeProfileId;
    import("./persistence/store").then(({ store }) => store.clearGame(profileId));
    setResumableSave(null);
  }, []);

  const startNewGame = useCallback((typeCode?: number | null) => {
    const type = typeCode !== undefined ? typeCode : gameTypeRef.current;
    if (type === null) return;
    shouldCancelAutoPlayRef.current = true;
    if (autoPlayTimeoutRef.current !== null) {
      clearTimeout(autoPlayTimeoutRef.current);
      autoPlayTimeoutRef.current = null;
    }

    const uiState = useUIStore.getState();

    // Vegas cumulative: if the round being replaced wasn't already
    // committed on win, it's being abandoned — commit its current score
    // (the buy-in is already reflected: -52 + 5/foundation-card) before
    // wiping engine state.
    if (gameTypeRef.current === 0 && uiState.scoringMode === "vegas_cumulative" && !vegasRoundCommittedRef.current) {
      uiState.addToVegasBankroll(computeVegasScore());
    }
    vegasRoundCommittedRef.current = false;

    // Deliberately starting fresh abandons whatever was in progress.
    clearSavedGame();

    setGameTypeCode(type);
    const variantOptions = {
      klondikeDrawMode: uiState.drawMode,
      spiderSuitCount: spiderSuitCountForDifficulty(uiState.difficulty),
      golfWrapAround: uiState.golfWrapAround,
    };
    currentVariantOptionsRef.current = variantOptions;
    initializeGame(type, BigInt(Date.now()), variantOptions);
    resetUiStateForRound();
    setMoveCount(0); setTimerSeconds(0);
    updateLayout(type);
    requestAnimationFrame(() => updateLayout(type));
  }, [updateLayout, clearSavedGame, resetUiStateForRound]);

  const resumeGame = useCallback((envelope: SaveEnvelope) => {
    const type = GAME_TYPE_NAMES.indexOf(envelope.game_type);
    if (type === -1) return;
    const vd = envelope.variant_data as {
      klondikeDrawMode?: number; spiderSuitCount?: number; golfWrapAround?: boolean;
      stockRecycleCount?: number; history?: unknown;
    };
    const variantOptions = {
      klondikeDrawMode: vd.klondikeDrawMode ?? 1,
      spiderSuitCount: vd.spiderSuitCount ?? 4,
      golfWrapAround: vd.golfWrapAround ?? false,
    };
    currentVariantOptionsRef.current = variantOptions;

    setGameTypeCode(type);
    initializeGame(type, BigInt(Date.now()), variantOptions);
    restoreSnapshotJson(JSON.stringify({
      snapshot: { piles: envelope.piles, move_count: envelope.move_count, stock_recycle_count: vd.stockRecycleCount ?? 0 },
      history: vd.history ?? { past: [], future: [] },
    }));
    resetUiStateForRound();
    setResumableSave(null);
    setMoveCount(envelope.move_count);
    setTimerSeconds(Math.round(envelope.elapsed_ms / 1000));
    updateLayout(type);
    requestAnimationFrame(() => updateLayout(type));
  }, [updateLayout, resetUiStateForRound]);

  const autosaveGame = useCallback(() => {
    if (gameTypeCode === null || isWonRef.current || isLostRef.current) return;
    const snapshotJson = getSnapshotJson();
    if (!snapshotJson) return;
    let parsed: { snapshot: { piles: unknown[]; stock_recycle_count: number }; history: unknown };
    try {
      parsed = JSON.parse(snapshotJson);
    } catch {
      return;
    }
    const envelope: SaveEnvelope = {
      schema_version: 1,
      game_type: GAME_TYPE_NAMES[gameTypeCode],
      piles: parsed.snapshot.piles,
      move_count: moveCountRef.current,
      elapsed_ms: timerSecondsRef.current * 1000,
      saved_at: Date.now(),
      variant_data: {
        ...currentVariantOptionsRef.current,
        stockRecycleCount: parsed.snapshot.stock_recycle_count,
        history: parsed.history,
      },
    };
    const profileId = useProfileStore.getState().activeProfileId;
    import("./persistence/store").then(({ store }) => store.saveGame(profileId, envelope));
  }, [gameTypeCode]);

  // Autosave after every move -- moveCount already increments at every
  // single move site (stock tap, card move, autoplay step), so watching it
  // catches all of them without touching each call site individually.
  useEffect(() => {
    if (gameTypeCode === null || moveCount === 0) return;
    autosaveGame();
  }, [moveCount, gameTypeCode, autosaveGame]);

  const handleHint = useCallback(() => {
    if (isWonRef.current || isAutoPlaying) return;
    usedHintOrUndoRef.current = true;
    const hint = getHintWasm();
    if (hint && hint.cards && hint.cards.length > 0) {
      const sourceId = hint.cards[0];
      hintCardIdRef.current = sourceId;
      setLayoutTick(t => t + 1);

      const getPileKind = (k: any): number => {
        if (typeof k === 'number') return k;
        switch(k) {
          case "Stock": return 0; case "Waste": return 1; case "Foundation": return 2;
          case "Tableau": return 3; case "Cell": return 4; case "Reserve": return 5;
          case "Pyramid": return 6; case "Discard": return 7; default: return -1;
        }
      };

      const bounds = cardBoundsListRef.current;
      const sourceCard = bounds.find(b => b.cardId === sourceId);
      const destKind = getPileKind(hint.to.kind);
      const destPileItems = bounds.filter(b => b.pileKind === destKind && b.pileIndex === hint.to.index);

      if (sourceCard && destPileItems.length > 0) {
        const destCard = destPileItems[destPileItems.length - 1];
        const destY = destCard.y + (destCard.cardId !== -1 && destCard.pileKind === 3 ? 32 : 0);
        setGhostPos({ x: sourceCard.x, y: sourceCard.y });
        setHintGhost({
          startX: sourceCard.x, startY: sourceCard.y,
          endX: destCard.x, endY: destY,
          width: sourceCard.width, height: sourceCard.height,
          rank: sourceCard.rank, suit: sourceCard.suit,
        });
      }

      setTimeout(() => {
        hintCardIdRef.current = null;
        setHintGhost(null);
        setLayoutTick(t => t + 1);
      }, 1800);
    } else if (hint && hint.cards && hint.cards.length === 0) {
      setToastMessage("Hint: Tap the stock pile");
    } else {
      setToastMessage("No moves available.");
    }
  }, [isAutoPlaying]);

  // ─── Power-up Effects ─────────────────────────────────────────────────────
  // Instant-effect power-ups (POWER_UP_CONFIG[id].targeting === "none").
  // Returns whether the effect actually did something, so the caller can
  // refund the charge on a no-op (e.g. Undo Token with empty history).
  const applyInstantPowerUp = useCallback((id: string): boolean => {
    switch (id) {
      case "unstick_wand": {
        const moved = autoPlayStepWasm();
        if (moved) { setMoveCount((m) => m + 1); audioService.playCardMove(); updateLayout(); }
        return moved;
      }
      case "undo_token": {
        const ok = undoWasm();
        if (ok) updateLayout();
        return ok;
      }
      case "extra_hint":
      case "foundation_nudge": {
        // Both re-skin the same underlying solver hint the free Hint button
        // uses; the plan's own descriptions for these two overlap in effect.
        const hint = getHintWasm();
        if (!hint || !Array.isArray(hint.cards)) return false;
        handleHint();
        return true;
      }
      case "lucky_reshuffle": {
        const ok = reshuffleStockWasteWasm(BigInt(Date.now()));
        if (ok) updateLayout();
        return ok;
      }
      case "deck_whisper": {
        const stock = getPilesLayout().find((p) => p.kind === 0);
        if (!stock || stock.cards.length === 0) return false;
        const next = stock.cards.slice(-3).reverse();
        setPowerUpReveal({ title: "Next From Stock", cards: next.map((c) => ({ rank: c.rank, suit: c.suit })) });
        window.setTimeout(() => setPowerUpReveal(null), 3500);
        return true;
      }
      case "second_look": {
        const waste = getPilesLayout().find((p) => p.kind === 1);
        if (!waste || waste.cards.length < 2) return false;
        const beneath = waste.cards[waste.cards.length - 2];
        setPowerUpReveal({ title: "Beneath the Waste", cards: [{ rank: beneath.rank, suit: beneath.suit }] });
        window.setTimeout(() => setPowerUpReveal(null), 3500);
        return true;
      }
      case "time_ease": {
        if (timerSecondsRef.current <= 0) return false;
        setTimerSeconds((t) => Math.max(0, t - 60));
        return true;
      }
      default:
        return false;
    }
  }, [updateLayout, handleHint]);

  // Targeted power-ups (targeting === "card" | "column"): resolves against
  // whatever CardBounds the player's next tap hits. Consumes-then-refunds
  // rather than validating up front, so the logic for "did this do
  // anything" lives in one place per power-up.
  const resolveTargetedPowerUp = useCallback((id: string, hit: CardBounds) => {
    const config = POWER_UP_CONFIG[id];
    if (config?.compatibleGameTypes && gameTypeRef.current !== null && !config.compatibleGameTypes.includes(gameTypeRef.current)) {
      setPowerUpToast("Not usable in this game.");
      window.setTimeout(() => setPowerUpToast(null), 1800);
      return;
    }
    if (!useUIStore.getState().consumePowerUp(id)) return;

    let success = false;
    if (id === "peek_charm") {
      if (hit.cardId !== -1 && !hit.faceUp) {
        setPowerUpReveal({ title: "Peek", cards: [{ rank: hit.rank, suit: hit.suit }] });
        window.setTimeout(() => setPowerUpReveal(null), 3000);
        success = true;
      }
    } else if (id === "column_breather") {
      if (hit.pileKind === 3) {
        const pile = getPilesLayout().find((p) => p.kind === 3 && p.index === hit.pileIndex);
        const faceDown = pile ? pile.cards.filter((c) => !c.faceUp) : [];
        if (faceDown.length > 0) {
          const topTwo = faceDown.slice(-2).reverse();
          setPowerUpReveal({ title: "Column Breather", cards: topTwo.map((c) => ({ rank: c.rank, suit: c.suit })) });
          window.setTimeout(() => setPowerUpReveal(null), 3500);
          success = true;
        }
      }
    } else if (id === "reset_column") {
      if (hit.pileKind === 3) {
        success = resetTableauColumnWasm(hit.pileIndex, BigInt(Date.now()));
        if (success) updateLayout();
      }
    } else if (id === "free_slot") {
      if (hit.cardId !== -1 && hit.faceUp) {
        success = shelveTopCardWasm(hit.pileKind, hit.pileIndex, hit.cardId);
        if (success) { setShelvedCard(getShelvedCard()); updateLayout(); }
      }
    }

    if (!success) useUIStore.getState().refundPowerUp(id);
  }, [updateLayout]);
  useEffect(() => { resolveTargetedPowerUpRef.current = resolveTargetedPowerUp; }, [resolveTargetedPowerUp]);

  const activatePowerUp = useCallback((id: string) => {
    const config = POWER_UP_CONFIG[id];
    if (!config) return;
    if (config.compatibleGameTypes && gameTypeRef.current !== null && !config.compatibleGameTypes.includes(gameTypeRef.current)) return;

    setPowerUpTrayOpen(false);
    if (config.targeting !== "none") {
      activePowerUpRef.current = id;
      setPowerUpToast(config.targeting === "card" ? "Tap a card to target…" : "Tap a column to target…");
      return;
    }

    if (!useUIStore.getState().consumePowerUp(id)) return;
    if (!applyInstantPowerUp(id)) useUIStore.getState().refundPowerUp(id);
  }, [applyInstantPowerUp]);

  const returnShelvedCard = useCallback(() => {
    if (unshelveCardWasm()) {
      setShelvedCard(null);
      updateLayout();
    }
  }, [updateLayout]);

  const handleAutoPlay = useCallback(() => {
    if (isAutoPlaying) return; // Guard against re-entry (double click / repeated hotkey)

    usedHintOrUndoRef.current = true;
    shouldCancelAutoPlayRef.current = false;

    const nextStep = () => {
      if (shouldCancelAutoPlayRef.current) {
        setIsAutoPlaying(false);
        return;
      }
      if (checkWinWasm()) {
        setIsAutoPlaying(false);
        return;
      }
      if (isLostWasm()) {
        // The engine itself has determined no path to a win remains, even
        // though there may still be legal-but-useless moves to shuffle
        // through forever (this is what let AutoPlay run indefinitely on
        // an unwinnable deal). Stop here; the render loop's own loss
        // handling (stats, toast, clearing the save) picks this up on its
        // next frame regardless of AutoPlay.
        setIsAutoPlaying(false);
        return;
      }
      const success = autoPlayStepWasm();
      if (success) {
        setMoveCount((m) => m + 1);
        audioService.playCardMove();
        updateLayout();
        autoPlayTimeoutRef.current = window.setTimeout(nextStep, 120);
      } else {
        setIsAutoPlaying(false);
        if (!checkWinWasm()) {
          setToastMessage("No moves available.");
        }
      }
    };
    setIsAutoPlaying(true);
    nextStep();
  }, [isAutoPlaying, updateLayout]);

  // Cancel any in-flight autoplay chain when the component unmounts
  useEffect(() => {
    return () => {
      shouldCancelAutoPlayRef.current = true;
      if (autoPlayTimeoutRef.current !== null) {
        clearTimeout(autoPlayTimeoutRef.current);
        autoPlayTimeoutRef.current = null;
      }
    };
  }, []);

  useEffect(() => {
    useProfileStore.getState().loadProfiles().then(() => {
      useUIStore.getState().initializeStore().then(() => {
        initEngine().then(() => {
          setIsEngineReady(true);
          const profileId = useProfileStore.getState().activeProfileId;
          import("./persistence/store").then(({ store }) => {
            store.loadGame(profileId).then(setResumableSave);
          });
        });
      });
    });
  }, []);

  // Animate ghost from source -> dest -> source
  useEffect(() => {
    if (!hintGhost) return;
    const t1 = setTimeout(() => setGhostPos({ x: hintGhost.endX, y: hintGhost.endY }), 80);
    const t2 = setTimeout(() => setGhostPos({ x: hintGhost.startX, y: hintGhost.startY }), 950);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [hintGhost]);

  const handleGameSelect = useCallback((typeCode: number) => {
    setGameTypeCode(typeCode);
    startNewGame(typeCode);
  }, [startNewGame]);

  useEffect(() => {
    return setupKeyboardNav({
      onUndo: () => { usedHintOrUndoRef.current = true; undoWasm(); updateLayout(); },
      onRedo: () => { redoWasm(); updateLayout(); },
      onNewGame: () => startNewGame(),
      onHint: handleHint,
      onAutoPlay: handleAutoPlay,
      onSettings: () => { cancelKeyboardSelection(); setIsSettingsOpen((o) => !o); },
      onCycleFocus: cycleFocusedPile,
      onSelectFocused: selectFocusedPile,
    });
  }, [updateLayout, startNewGame, handleHint, handleAutoPlay, cycleFocusedPile, selectFocusedPile, cancelKeyboardSelection]);

  const formatTime = (s: number) => `${Math.floor(s / 60).toString().padStart(2, "0")}:${(s % 60).toString().padStart(2, "0")}`;

  const handleSplashComplete = useCallback(() => {
    setIsSplashComplete(true);
  }, []);

  const leftHeaderContent = activeTab === "gameboard" && gameTypeCode !== null ? (
    <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
      <button
        onClick={() => setGameTypeCode(null)}
        style={{ background: "rgba(255,255,255,0.1)", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", color: "#e5e2e1", padding: "6px 12px", fontFamily: "Inter,sans-serif", fontSize: "14px", fontWeight: 600, cursor: "pointer", outline: "none", marginLeft: "-8px" }}
      >
        {GAME_TYPE_NAMES[gameTypeCode] || "Choose Game"}
      </button>
      <LevelBadge gameTypeCode={gameTypeCode} />
    </div>
  ) : null;

  const showVegasScore = gameTypeCode === 0 && scoringMode !== "standard" && isEngineReady;
  const vegasScore = showVegasScore ? computeVegasScore() : 0;

  const rightHeaderContent = activeTab === "gameboard" && gameTypeCode !== null ? (
    <>
      <div style={{ display: "flex", gap: 16, fontFamily: "JetBrains Mono,monospace", fontSize: "14px", marginRight: "8px", alignItems: "center" }}>
        <div><span style={{ opacity: 0.6, color: "#e5e2e1" }}>TIME: </span><span style={{ color: "#fff" }}>{formatTime(timerSeconds)}</span></div>
        <div><span style={{ opacity: 0.6, color: "#e5e2e1" }}>MOVES: </span><span style={{ color: "#fff" }}>{moveCount}</span></div>
        {showVegasScore && (
          <div>
            <span style={{ opacity: 0.6, color: "#e5e2e1" }}>SCORE: </span>
            <span style={{ color: vegasScore >= 0 ? "#4caf50" : "#f44336" }}>${vegasScore}</span>
          </div>
        )}
        {showVegasScore && scoringMode === "vegas_cumulative" && (
          <div>
            <span style={{ opacity: 0.6, color: "#e5e2e1" }}>BANKROLL: </span>
            <span style={{ color: (vegasBankroll + vegasScore) >= 0 ? "#4caf50" : "#f44336" }}>${vegasBankroll + vegasScore}</span>
          </div>
        )}
      </div>
      <div style={{ display: "flex", gap: 8, alignItems: "center", position: "relative" }}>
        <button onClick={() => setIsHelpOpen(true)} title="Help" style={HUD_BTN}><HelpCircle size={18} /></button>
        <button onClick={() => setIsAboutOpen(true)} title="About" style={HUD_BTN}><Info size={18} /></button>
        <button onClick={() => setPowerUpTrayOpen((v) => !v)} title="Power-ups" style={{ ...HUD_BTN, position: "relative", color: powerUpTrayOpen ? currentTheme.accentColor : "#e5e2e1" }}>
          <Zap size={18} />
          {Object.values(powerUpInventory).some((n) => n > 0) && (
            <span style={{ position: "absolute", top: 2, right: 2, width: 8, height: 8, borderRadius: "50%", background: "#d4af37" }} />
          )}
        </button>
        {powerUpTrayOpen && (
          <div style={{ position: "absolute", top: "calc(100% + 8px)", right: 0, width: 280, maxHeight: 360, overflowY: "auto", background: "rgba(19,19,19,0.97)", backdropFilter: "blur(16px)", border: "1px solid rgba(255,255,255,0.15)", borderRadius: 12, padding: 12, zIndex: 200, display: "flex", flexDirection: "column", gap: 8 }}>
            {POWER_UP_ITEMS.filter((item) => (powerUpInventory[item.id] ?? 0) > 0).length === 0 ? (
              <div style={{ color: "rgba(255,255,255,0.5)", fontSize: 13, textAlign: "center", padding: "12px 4px" }}>No power-ups owned. Visit The Emporium to buy some.</div>
            ) : POWER_UP_ITEMS.filter((item) => (powerUpInventory[item.id] ?? 0) > 0).map((item) => {
              const config = POWER_UP_CONFIG[item.id];
              const compatible = !config?.compatibleGameTypes || gameTypeCode === null || config.compatibleGameTypes.includes(gameTypeCode);
              return (
                <button
                  key={item.id}
                  onClick={() => activatePowerUp(item.id)}
                  disabled={!compatible}
                  title={!compatible ? "Not usable in this game" : item.description}
                  style={{
                    display: "flex", alignItems: "center", gap: 10, padding: "8px 10px", borderRadius: 8,
                    background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)",
                    color: compatible ? "#e5e2e1" : "rgba(255,255,255,0.3)", textAlign: "left",
                    cursor: compatible ? "pointer" : "not-allowed", fontFamily: "Inter, sans-serif",
                  }}
                >
                  <span style={{ fontWeight: 700, color: compatible ? "#d4af37" : "rgba(255,255,255,0.3)", minWidth: 20 }}>×{powerUpInventory[item.id]}</span>
                  <span style={{ flex: 1 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{item.name}</div>
                    <div style={{ fontSize: 11, opacity: 0.7, lineHeight: 1.3 }}>{item.description}</div>
                  </span>
                </button>
              );
            })}
          </div>
        )}
        <button onClick={handleHint} title="Hint (H)" style={HUD_BTN}><Lightbulb size={18} /></button>
        <button onClick={handleAutoPlay} title="Auto Play (A)" style={{ ...HUD_BTN, color: isAutoPlaying ? currentTheme.accentColor : "#e5e2e1" }}><Sparkles size={18} /></button>
        <button onClick={() => { usedHintOrUndoRef.current = true; undoWasm(); updateLayout(); }} title="Undo (U)" style={HUD_BTN}><RotateCcw size={18} /></button>
        <button onClick={() => startNewGame()} title="New Game (N)" style={HUD_BTN}><Play size={18} /></button>
      </div>
    </>
  ) : (
    <>
      <button className="mobile-only-flex" onClick={() => setIsSettingsOpen(true)} style={{ background: "none", border: "none", color: "#e5e2e1", cursor: "pointer", display: "flex", alignItems: "center" }}><SettingsIcon size={20} /></button>
    </>
  );

  return (
    <>
      {(!isEngineReady || !isSplashComplete) && (
        <SplashPage onLoadComplete={handleSplashComplete} />
      )}
      {isEngineReady && isSplashComplete && (
        <MetaGameHub 
          activeTab={activeTab} 
          onTabChange={setActiveTab} 
          onOpenSettings={() => setIsSettingsOpen(true)}
          leftHeaderContent={leftHeaderContent}
          rightHeaderContent={rightHeaderContent}
        >
          {activeTab === "gameboard" && gameTypeCode === null ? (
            <GameChooserGrid onSelectGame={handleGameSelect} resumableSave={resumableSave} onResumeGame={resumableSave ? () => resumeGame(resumableSave) : undefined} />
          ) : (
            <div
              style={{ width: "100%", height: "100%", position: "relative", overflow: "hidden", backgroundColor: currentTheme.tableColor, display: activeTab === "gameboard" ? "block" : "none" }}
              onPointerDown={onPointerDown}
              onPointerMove={onPointerMove}
              onPointerUp={onPointerUp}
              onPointerLeave={onPointerUp}
            >
        <canvas ref={canvasRef} style={{ width: "100%", height: "100%", display: "block", position: "absolute", top: 0, left: 0 }} />
        <div id="cards-layer" style={{ position: "absolute", top: 0, left: 0, width: "100%", height: "100%", pointerEvents: "none" }}>
          {/* Render Slots (empty piles) */}
          {cardBoundsListRef.current.filter((b) => b.cardId === -1).map((b) => (
            <div key={`slot-${b.pileKind}-${b.pileIndex}`} style={{ position: "absolute", left: b.x, top: b.y, width: b.width, height: b.height, borderRadius: "8px", border: `2px dashed ${currentTheme.accentColor}`, opacity: 0.3, pointerEvents: "none" }} />
          ))}

          {/* Keyboard-nav focus ring: highlights the Tab-focused pile */}
          {focusedPile && (() => {
            const target = topCardOfPile(focusedPile.pileKind, focusedPile.pileIndex);
            if (!target) return null;
            return (
              <div style={{
                position: "absolute", left: target.x - 3, top: target.y - 3,
                width: target.width + 6, height: target.height + 6,
                borderRadius: "10px", border: `3px solid ${currentTheme.accentColor}`,
                boxShadow: `0 0 10px ${currentTheme.accentColor}`, pointerEvents: "none", zIndex: 998,
              }} />
            );
          })()}
          {/* Render Cards */}
          {cardBoundsListRef.current.filter(b => b.cardId !== -1).map(b => {
            const anim = animatedCardsRef.current.get(b.cardId);
            const isDragging = dragStateRef.current?.cardId === b.cardId;
            const x = isDragging ? dragStateRef.current!.ptrX - dragStateRef.current!.offsetX : (anim ? anim.x : b.x);
            const y = isDragging ? dragStateRef.current!.ptrY - dragStateRef.current!.offsetY : (anim ? anim.y : b.y);

            const isPerfectlyStacked = b.pileKind === 0 || b.pileKind === 2 || b.pileKind === 7;
            
            return (
              <div
                key={b.cardId}
                style={{
                  position: "absolute", left: 0, top: 0, width: b.width, height: b.height,
                  transform: `translate(${x}px, ${y}px)`,
                  zIndex: isDragging ? 1000 : b.pileKind === 3 ? b.cardIndex : 10,
                  transition: isDragging ? "none" : (isAutoPlaying ? "transform 0.1s linear" : "transform 0.25s cubic-bezier(0.25, 0.8, 0.25, 1)"),
                }}
              >
                <CardWidget
                  id={b.cardId}
                  rank={b.rank}
                  suit={b.suit}
                  faceUp={b.faceUp}
                  width={b.width}
                  height={b.height}
                  theme={currentTheme}
                  overlayIntensity={overlayIntensity}
                  cardBackPattern={cardBackPattern}
                  cardBackColor={cardBackColor}
                  isSelected={selectedPyramidCardRef.current?.cardId === b.cardId || keyboardSelectedId === b.cardId}
                  isHint={hintCardIdRef.current === b.cardId}
                  hideShadow={isPerfectlyStacked && b.cardIndex > 0}
                />
              </div>
            );
          })}

          {/* Hint ghost: translucent card that flies source → dest → source */}
          {hintGhost && (
            <div style={{
              position: "absolute", left: 0, top: 0,
              width: hintGhost.width, height: hintGhost.height,
              transform: `translate(${ghostPos.x}px, ${ghostPos.y}px)`,
              transition: "transform 0.65s cubic-bezier(0.4, 0, 0.2, 1)",
              opacity: 0.55, zIndex: 999, pointerEvents: "none"
            }}>
              <CardWidget
                id={-2} rank={hintGhost.rank} suit={hintGhost.suit} faceUp={true}
                width={hintGhost.width} height={hintGhost.height}
                theme={currentTheme} overlayIntensity={overlayIntensity}
                cardBackPattern={cardBackPattern} cardBackColor={cardBackColor}
                isSelected={false} isHint={false}
              />
            </div>
          )}

          {powerUpToast && (
            <div style={{ position: "absolute", top: 16, left: "50%", transform: "translateX(-50%)", background: "rgba(19,19,19,0.9)", backdropFilter: "blur(16px)", padding: "10px 20px", borderRadius: "999px", border: `1px solid ${currentTheme.accentColor}`, zIndex: 150, color: "#e5e2e1", fontFamily: "Manrope,sans-serif", fontSize: 14, fontWeight: 600, pointerEvents: "none" }}>
              {powerUpToast}
            </div>
          )}

          {powerUpReveal && (
            <div style={{ position: "absolute", top: 16, left: "50%", transform: "translateX(-50%)", background: "rgba(19,19,19,0.95)", backdropFilter: "blur(16px)", padding: "16px 20px", borderRadius: "12px", border: "1px solid rgba(255,255,255,0.2)", zIndex: 150, display: "flex", flexDirection: "column", alignItems: "center", gap: 10, pointerEvents: "none" }}>
              <div style={{ color: "#d4af37", fontFamily: "Manrope,sans-serif", fontSize: 13, fontWeight: 700, letterSpacing: 1, textTransform: "uppercase" }}>{powerUpReveal.title}</div>
              <div style={{ display: "flex", gap: 8 }}>
                {powerUpReveal.cards.map((c, i) => {
                  const isRed = c.suit === 0 || c.suit === 1;
                  return (
                    <div key={i} style={{ width: 44, height: 62, borderRadius: 6, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", color: isRed ? "#cc3333" : "#111111", fontWeight: 800, fontFamily: "Manrope, sans-serif" }}>
                      <div style={{ fontSize: 14 }}>{RANK_STRS[c.rank - 1]}</div>
                      <div style={{ fontSize: 16 }}>{SUIT_STRS[c.suit]}</div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {shelvedCard && (
            <button
              onClick={returnShelvedCard}
              title="Tap to return to its pile"
              style={{ position: "absolute", bottom: 16, left: "50%", transform: "translateX(-50%)", zIndex: 150, display: "flex", alignItems: "center", gap: 8, background: "rgba(19,19,19,0.95)", border: `1px solid ${currentTheme.accentColor}`, borderRadius: 10, padding: "8px 14px", cursor: "pointer", pointerEvents: "auto" }}
            >
              <div style={{ width: 32, height: 45, borderRadius: 5, background: "#fff", display: "flex", alignItems: "center", justifyContent: "center", flexDirection: "column", color: (shelvedCard.suit === 0 || shelvedCard.suit === 1) ? "#cc3333" : "#111111", fontWeight: 800, fontSize: 11, fontFamily: "Manrope, sans-serif" }}>
                <div>{RANK_STRS[shelvedCard.rank - 1]}</div>
                <div>{SUIT_STRS[shelvedCard.suit]}</div>
              </div>
              <span style={{ color: "#e5e2e1", fontSize: 13, fontWeight: 600, display: "flex", alignItems: "center", gap: 6 }}><Undo2 size={14} /> Return card</span>
            </button>
          )}

          {toastMessage && (
            <div style={{ position: "absolute", top: "50%", left: "50%", transform: "translate(-50%, -50%)", background: "rgba(19,19,19,0.9)", backdropFilter: "blur(16px)", padding: "24px", borderRadius: "16px", border: "1px solid rgba(255,255,255,0.2)", zIndex: 100, display: "flex", flexDirection: "column", alignItems: "center", gap: 16, pointerEvents: "auto" }}>
              <div style={{ color: "#e5e2e1", fontFamily: "Manrope,sans-serif", fontSize: "18px", fontWeight: 600 }}>{toastMessage}</div>
              <div style={{ display: "flex", gap: 12 }}>
                <button onClick={() => { setToastMessage(null); startNewGame(); }} style={{ background: currentTheme.accentColor, color: "#111", border: "none", borderRadius: "8px", padding: "10px 20px", fontWeight: 700, cursor: "pointer", fontFamily: "Inter,sans-serif" }}>New Game</button>
                <button onClick={() => setToastMessage(null)} style={{ background: "transparent", color: "#e5e2e1", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "10px 20px", fontWeight: 600, cursor: "pointer", fontFamily: "Inter,sans-serif" }}>Dismiss</button>
              </div>
            </div>
          )}
        </div>
      </div>
      )}
    </MetaGameHub>
  )}

      <SettingsModal isOpen={isSettingsOpen} onClose={() => setIsSettingsOpen(false)} gameTypeCode={gameTypeCode ?? undefined} />
      {gameTypeCode !== null && <HelpModal isOpen={isHelpOpen} onClose={() => setIsHelpOpen(false)} gameType={gameTypeCode} />}
      <AboutModal isOpen={isAboutOpen} onClose={() => setIsAboutOpen(false)} />

      {winData && gameTypeCode !== null && (
        <VictoryModal
          gameName={GAME_TYPE_NAMES[gameTypeCode] || "Game"}
          winData={winData}
          onNewGame={() => {
            setWinData(null);
            setToastMessage(null);
            startNewGame();
          }}
          onHome={() => {
            setWinData(null);
            setToastMessage(null);
            setGameTypeCode(null);
          }}
        />
      )}
    </>
  );
};

const HUD_BTN: React.CSSProperties = { background: "rgba(255,255,255,0.08)", border: "1px solid rgba(255,255,255,0.15)", borderRadius: "8px", color: "#e5e2e1", padding: "8px 12px", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center" };
export default App;
