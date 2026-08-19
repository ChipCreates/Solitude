import React, { useState } from "react";
import { Layers, Bug, Triangle, FlagTriangleRight, LayoutGrid, Mountain, Trees, Shield, Dices, Scissors } from "lucide-react";
import { useUIStore } from "../store/uiStore";

interface GameChooserModalProps {
  isOpen: boolean;
  onSelectGame: (gameType: number) => void;
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

export const GameChooserModal: React.FC<GameChooserModalProps> = ({ isOpen, onSelectGame }) => {
  const [hoveredId, setHoveredId] = useState<number | null>(null);
  const themeId = useUIStore((s) => s.themeId);
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");

  if (!isOpen) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0, 0, 0, 0.8)",
        backdropFilter: "blur(8px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 200,
        padding: "24px"
      }}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "1000px",
          height: "85vh",
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div style={{ textAlign: "center", marginBottom: "24px" }}>
          <h2 style={{ fontSize: "32px", fontWeight: 800, color: accentColor, marginBottom: "8px" }}>Choose Your Game</h2>
          <p style={{ fontSize: "16px", color: "#a1a1aa" }}>Select a solitaire variant to play</p>
        </div>

        <div
          style={{
            flex: 1,
            overflowY: "auto",
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
            gap: "16px",
            padding: "8px"
          }}
        >
          {GAMES.map((game) => {
            const isHovered = hoveredId === game.id;
            return (
              <div
                key={game.id}
                onMouseEnter={() => setHoveredId(game.id)}
                onMouseLeave={() => setHoveredId(null)}
                onClick={() => onSelectGame(game.id)}
                style={{
                  backgroundColor: isHovered ? "rgba(255,255,255,0.1)" : "rgba(30, 30, 30, 0.9)",
                  borderRadius: "16px",
                  padding: "20px",
                  cursor: "pointer",
                  border: isHovered ? `2px solid ${accentColor}` : "2px solid rgba(255,255,255,0.1)",
                  transition: "all 0.2s ease-out",
                  transform: isHovered ? "translateY(-4px)" : "none",
                  boxShadow: isHovered ? `0 8px 24px rgba(0,0,0,0.5)` : "0 4px 12px rgba(0,0,0,0.3)",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  textAlign: "center"
                }}
              >
                <h3 style={{ fontSize: "18px", fontWeight: 700, color: isHovered ? accentColor : "#fff", marginBottom: "16px" }}>
                  {game.name}
                </h3>
                <div
                  style={{
                    width: "80px",
                    height: "80px",
                    borderRadius: "50%",
                    backgroundColor: isHovered ? `${accentColor}33` : "rgba(255,255,255,0.05)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: isHovered ? accentColor : "#a1a1aa",
                    marginBottom: "16px",
                    transition: "all 0.2s ease-out"
                  }}
                >
                  {game.icon}
                </div>
                <p style={{ fontSize: "13px", lineHeight: 1.5, color: "#a1a1aa", flex: 1 }}>
                  {game.description}
                </p>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
