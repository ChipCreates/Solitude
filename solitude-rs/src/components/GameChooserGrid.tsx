import React, { useState } from "react";
import { Layers, Bug, Triangle, FlagTriangleRight, LayoutGrid, Mountain, Trees, Shield, Dices, Scissors, PlayCircle } from "lucide-react";
import { useUIStore } from "../store/uiStore";
import { GameVariantModal } from "./GameVariantModal";
import type { SaveEnvelope } from "../persistence/store";

interface GameChooserGridProps {
  onSelectGame: (gameType: number) => void;
  resumableSave?: SaveEnvelope | null;
  onResumeGame?: () => void;
}

const GAMES = [
  {
    id: 0,
    name: "Klondike",
    icon: <Layers size={32} />,
    description: "The quintessential version of Solitaire. Build four foundations from Ace to King by maneuvering cards through a tableau of descending, alternating colors."
  },
  {
    id: 1,
    name: "Spider",
    icon: <Bug size={32} />,
    description: "Assemble complete suits within the tableau itself before they can be removed. Dealing two decks of cards, you must weave complex sequences to clear the board."
  },
  {
    id: 2,
    name: "FreeCell",
    icon: <LayoutGrid size={32} />,
    description: "A game of open information. All cards are visible from the start, and you are given four temporary \"free cells\" to hold cards while you reorganize the tableau."
  },
  {
    id: 3,
    name: "Pyramid",
    icon: <Triangle size={32} />,
    description: "A mathematical puzzle where the goal is to dismantle a pyramid of cards by pairing them up to equal 13."
  },
  {
    id: 4,
    name: "Golf",
    icon: <FlagTriangleRight size={32} />,
    description: "Clear a tableau of cards into a single waste pile. You can play any card that is one rank higher or lower than the top card, regardless of suit."
  },
  {
    id: 5,
    name: "TriPeaks",
    icon: <Mountain size={32} />,
    description: "Clear three overlapping pyramids of cards by removing any card that is one rank higher or lower than the top card of the waste pile."
  },
  {
    id: 6,
    name: "Yukon",
    icon: <Trees size={32} />,
    description: "Move any group of face-up cards regardless of what is beneath them, placing them on a card of the opposite color and next highest rank."
  },
  {
    id: 7,
    name: "Forty Thieves",
    icon: <Shield size={32} />,
    description: "A difficult variant using two decks. You face a wide tableau where you can only move the top card of each stack, and must build sequences by suit."
  },
  {
    id: 8,
    name: "Canfield",
    icon: <Dices size={32} />,
    description: "A casino game with a high-difficulty challenge. You must move cards to the foundation while managing a small tableau and a difficult draw pile."
  },
  {
    id: 9,
    name: "Scorpion",
    icon: <Scissors size={32} />,
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

  return (
    <div
      style={{
        width: "100%",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        padding: "48px 48px",
        overflowY: "auto"
      }}
    >
      <div style={{ textAlign: "center", marginBottom: "40px" }}>
        <h2 style={{ fontSize: "36px", fontWeight: 800, color: accentColor, marginBottom: "12px", fontFamily: "Manrope, sans-serif" }}>Choose Your Game</h2>
        <p style={{ fontSize: "16px", color: "#a5b8a9" }}>Select a solitaire variant to play</p>
      </div>

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
          gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
          gap: "24px",
          maxWidth: "1200px",
          margin: "0 auto",
          width: "100%"
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
                backgroundColor: isHovered ? "rgba(212, 175, 55, 0.1)" : "#0f1c15",
                borderRadius: "16px",
                padding: "24px",
                cursor: "pointer",
                border: isHovered ? `1px solid ${accentColor}` : "1px solid rgba(255,255,255,0.05)",
                transition: "all 0.2s ease-out",
                transform: isHovered ? "translateY(-4px)" : "none",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                textAlign: "center"
              }}
            >
              <div
                style={{
                  width: "64px",
                  height: "64px",
                  borderRadius: "50%",
                  backgroundColor: isHovered ? `${accentColor}33` : "rgba(255,255,255,0.05)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: isHovered ? accentColor : "#a5b8a9",
                  marginBottom: "20px",
                  transition: "all 0.2s ease-out",
                  border: isHovered ? `1px solid ${accentColor}` : "1px solid transparent"
                }}
              >
                {game.icon}
              </div>
              <h3 style={{ fontSize: "18px", fontWeight: 700, color: isHovered ? accentColor : "#fff", marginBottom: "12px", fontFamily: "Manrope, sans-serif" }}>
                {game.name}
              </h3>
              <p style={{ fontSize: "13px", lineHeight: 1.5, color: "#a5b8a9", flex: 1 }}>
                {game.description}
              </p>
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
