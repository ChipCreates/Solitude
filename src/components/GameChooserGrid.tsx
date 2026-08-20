import React, { useState } from "react";
import { PlayCircle } from "lucide-react";
import { useUIStore } from "../store/uiStore";
import { useViewport } from "../hooks/useViewport";
import { GameVariantModal } from "./GameVariantModal";
import type { SaveEnvelope } from "../persistence/store";
import { GAME_PORTRAITS } from "../data/gamePortraits";

interface GameChooserGridProps {
  onSelectGame: (gameType: number) => void;
  resumableSave?: SaveEnvelope | null;
  onResumeGame?: () => void;
}

const GAMES = [
  {
    id: 0,
    name: "Klondike",
    portrait: GAME_PORTRAITS[0],
    description: "The quintessential version of Solitaire. Build four foundations from Ace to King by maneuvering cards through a tableau of descending, alternating colors."
  },
  {
    id: 1,
    name: "Spider",
    portrait: GAME_PORTRAITS[1],
    description: "Assemble complete suits within the tableau itself before they can be removed. Dealing two decks of cards, you must weave complex sequences to clear the board."
  },
  {
    id: 2,
    name: "FreeCell",
    portrait: GAME_PORTRAITS[2],
    description: "A game of open information. All cards are visible from the start, and you are given four temporary \"free cells\" to hold cards while you reorganize the tableau."
  },
  {
    id: 3,
    name: "Pyramid",
    portrait: GAME_PORTRAITS[3],
    description: "A mathematical puzzle where the goal is to dismantle a pyramid of cards by pairing them up to equal 13."
  },
  {
    id: 4,
    name: "Golf",
    portrait: GAME_PORTRAITS[4],
    description: "Clear a tableau of cards into a single waste pile. You can play any card that is one rank higher or lower than the top card, regardless of suit."
  },
  {
    id: 5,
    name: "TriPeaks",
    portrait: GAME_PORTRAITS[5],
    description: "Clear three overlapping pyramids of cards by removing any card that is one rank higher or lower than the top card of the waste pile."
  },
  {
    id: 6,
    name: "Yukon",
    portrait: GAME_PORTRAITS[6],
    description: "Move any group of face-up cards regardless of what is beneath them, placing them on a card of the opposite color and next highest rank."
  },
  {
    id: 7,
    name: "Forty Thieves",
    portrait: GAME_PORTRAITS[7],
    description: "A difficult variant using two decks. You face a wide tableau where you can only move the top card of each stack, and must build sequences by suit."
  },
  {
    id: 8,
    name: "Canfield",
    portrait: GAME_PORTRAITS[8],
    description: "A casino game with a high-difficulty challenge. You must move cards to the foundation while managing a small tableau and a difficult draw pile."
  },
  {
    id: 9,
    name: "Scorpion",
    portrait: GAME_PORTRAITS[9],
    description: "Build complete suits from King down to Ace within the tableau. Move large groups of cards even if they aren't in order."
  }
];

function formatElapsed(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export const GameChooserGrid: React.FC<GameChooserGridProps> = ({ onSelectGame, resumableSave, onResumeGame }) => {
  const [hoveredId, setHoveredId] = useState<number | null>(null);
  const [selectedGameId, setSelectedGameId] = useState<number | null>(null);
  const themeId = useUIStore((s) => s.themeId);
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");
  const { isMobile } = useViewport();

  const portraitHeight = isMobile ? 150 : 200;
  const portraitOverflowX = isMobile ? 6 : 20;

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        padding: isMobile ? "20px 16px" : "48px 35px",
        overflowY: "auto"
      }}
    >
      {resumableSave && onResumeGame && (
        <button
          onClick={onResumeGame}
          style={{
            display: "flex", alignItems: "center", justifyContent: "center", gap: "12px",
            maxWidth: "1200px", width: "100%", margin: "0 auto 32px", padding: "16px 24px",
            background: "rgba(233,195,73,0.1)", border: `1px solid ${accentColor}`, borderRadius: "12px",
            color: accentColor, cursor: "pointer", fontFamily: "Inter, sans-serif"
          }}
        >
          <PlayCircle size={22} />
          <span style={{ fontSize: "16px", fontWeight: 700 }}>Continue {resumableSave.game_type}</span>
          <span style={{ fontSize: "13px", opacity: 0.7 }}>
            {resumableSave.move_count} moves · {formatElapsed(resumableSave.elapsed_ms)}
          </span>
        </button>
      )}

      <div
        style={{
          flex: 1,
          display: "grid",
          gridTemplateColumns: isMobile ? "1fr" : "repeat(auto-fit, minmax(380px, 1fr))",
          gap: isMobile ? "28px" : "36px 56px",
          width: "100%",
          alignContent: "start"
        }}
      >
        {GAMES.map((game) => {
          const isHovered = hoveredId === game.id;
          return (
            <div
              key={game.id}
              onMouseEnter={() => setHoveredId(game.id)}
              onMouseLeave={() => setHoveredId(null)}
              onClick={() => setSelectedGameId(game.id)}
              style={{
                display: "flex",
                alignItems: "center",
                cursor: "pointer"
              }}
            >
              {/* Large, unbordered — its own baked-in gold oval frame does the
                  framing. Taller than the text box, so it pokes past the
                  box's top and bottom too. Bled left via negative margin. */}
              <img
                src={game.portrait}
                alt={game.name}
                style={{
                  height: `${portraitHeight}px`,
                  width: "auto",
                  flexShrink: 0,
                  marginLeft: `-${portraitOverflowX}px`,
                  position: "relative",
                  zIndex: 1,
                  filter: isHovered ? "drop-shadow(0 4px 16px rgba(212, 175, 55, 0.55))" : "drop-shadow(0 4px 10px rgba(0, 0, 0, 0.5))",
                  transition: "filter 0.2s ease-out"
                }}
              />
              {/* A separate framed panel — not wrapped around the portrait —
                  holding just the name and description. Overlaps the
                  portrait's right edge slightly via its own negative margin
                  instead of leaving a gap between them. */}
              <div
                style={{
                  flex: "1 1 0%",
                  backgroundColor: isHovered ? "rgba(212, 175, 55, 0.1)" : "#0f1c15",
                  borderRadius: "16px",
                  padding: isMobile ? "4px 4px 4px 46px" : "22px 57px",
                  border: isHovered ? "2px solid #f0d878" : "2px solid rgba(212, 175, 55, 0.45)",
                  boxShadow: isHovered ? "0 8px 24px rgba(212, 175, 55, 0.15)" : "none",
                  transition: "0.2s ease-out",
                  marginLeft: isMobile ? "-42px" : "-43px",
                  minHeight: isMobile ? "auto" : "135px",
                  maxHeight: isMobile ? "120px" : "none"
                }}
              >
                <h3 style={{ fontSize: isMobile ? "17px" : "18px", fontWeight: 800, color: "#e9c349", marginBottom: isMobile ? "3px" : "8px", fontFamily: "Manrope, sans-serif" }}>
                  {game.name}
                </h3>
                <p style={{ fontSize: "13px", lineHeight: 1.5, color: "#a5b8a9", margin: 0 }}>
                  {game.description}
                </p>
              </div>
            </div>
          );
        })}
      </div>

      {selectedGameId !== null && (
        <GameVariantModal
          gameId={selectedGameId}
          gameName={GAMES.find(g => g.id === selectedGameId)?.name || "Game"}
          onPlay={() => {
            onSelectGame(selectedGameId);
            setSelectedGameId(null);
          }}
          onCancel={() => setSelectedGameId(null)}
        />
      )}
    </div>
  );
};
