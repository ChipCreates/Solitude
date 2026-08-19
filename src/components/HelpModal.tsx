import React from "react";
import { useUIStore } from "../store/uiStore";
import { Flag, PlayCircle, BookOpen, Key, Trophy } from "lucide-react";

interface HelpModalProps {
  isOpen: boolean;
  onClose: () => void;
  gameType: number;
}

const GAME_NAMES = ["Klondike", "Spider", "FreeCell", "Pyramid", "Golf", "TriPeaks", "Yukon", "Forty Thieves", "Canfield", "Scorpion"];

const HELP_DATA = [
  // 0: Klondike
  {
    tagline: "The classic card game of patience and strategy.",
    objective: "Move all 52 cards to the four foundation piles at the top-right, organized by suit from Ace to King.",
    winCondition: "Win by completing all four foundation piles: ♠ ♥ ♣ ♦",
    rules: [
      { title: "Foundations (Top-Right)", text: "Build up from Ace to King in the same suit. Start each foundation with an Ace." },
      { title: "Tableau (Bottom Seven Columns)", text: "Build down in alternating colors. Only Kings can be placed in empty tableau columns." },
      { title: "Stock & Waste (Top-Left)", text: "Tap the stock to draw cards. Drawn cards appear in the waste pile and can be played to tableau or foundations." },
      { title: "Moving Cards", text: "Drag and drop cards or tap to auto-move. You can move sequences of face-up cards in the tableau." }
    ]
  },
  // 1: Spider
  {
    tagline: "Build complete suits within the tableau.",
    objective: "Build complete same-suit sequences from King to Ace within the tableau. When complete, they are automatically moved to the foundation.",
    winCondition: "Win by building 8 complete King-to-Ace sequences",
    rules: [
      { title: "Tableau (10 Columns)", text: "Build down regardless of suit for movement. Only same-suit sequences can be moved as a group." },
      { title: "Complete Sequences", text: "When you build a complete King-to-Ace same-suit sequence, it is automatically removed." },
      { title: "Stock (Top-Left)", text: "Tap to deal one card to each tableau column. All columns must have at least one card." },
      { title: "Empty Columns", text: "Any card or sequence can be moved to an empty column." }
    ]
  },
  // 2: FreeCell
  {
    tagline: "Strategic play with four free cells.",
    objective: "Move all 52 cards to the four foundation piles, building up by suit from Ace to King. Use the four free cells to temporarily store cards.",
    winCondition: "Win by moving all cards to the foundations: ♠ ♥ ♣ ♦",
    rules: [
      { title: "Free Cells (Top-Left)", text: "Four cells that can each hold one card temporarily. Use them to maneuver cards." },
      { title: "Foundations (Top-Right)", text: "Build up by suit from Ace to King." },
      { title: "Tableau (8 Columns)", text: "Build down in alternating colors. Any card can fill an empty column." },
      { title: "Supermove", text: "Move multiple cards at once based on available free cells and empty columns." }
    ]
  },
  // 3: Pyramid
  {
    tagline: "Match cards that add up to 13.",
    objective: "Remove pairs of cards that add up to 13 from the pyramid. Kings (value 13) can be removed alone.",
    winCondition: "Win by clearing all cards from the pyramid",
    rules: [
      { title: "Matching Pairs", text: "Remove pairs that add up to 13. A=1, J=11, Q=12, K=13 (removed alone)." },
      { title: "Exposed Cards", text: "Only fully exposed cards (not covered by others) can be matched." },
      { title: "Stock & Waste", text: "Draw from stock to find matching cards. Waste card can pair with pyramid cards." },
      { title: "Card Values", text: "A=1, 2-10=face value, J=11, Q=12, K=13" }
    ]
  },
  // 4: Golf
  {
    tagline: "Score the lowest by clearing cards.",
    objective: "Move all cards from the tableau to the waste pile by playing cards one rank higher or lower, regardless of suit.",
    winCondition: "Win by clearing all tableau cards to the waste",
    rules: [
      { title: "Tableau (7 Columns)", text: "Play any top card that is one rank higher or lower than the waste pile." },
      { title: "Waste Pile", text: "Build by playing cards ±1 rank regardless of suit." },
      { title: "Stock", text: "Draw when stuck. Each draw counts against your score." },
      { title: "Scoring", text: "Lower is better. Cards left in tableau count against you." }
    ]
  },
  // 5: TriPeaks
  {
    tagline: "Clear three overlapping pyramids.",
    objective: "Clear all cards from the three peaks by playing cards that are one rank higher or lower than the top card of the waste pile.",
    winCondition: "Win by clearing all three peaks",
    rules: [
      { title: "Three Peaks", text: "Clear overlapping pyramid formations by removing one card at a time." },
      { title: "Playing Cards", text: "Play any exposed card that is one rank higher or lower than the waste pile top card." },
      { title: "Wrapping", text: "Ace can be placed on 2 or King. King can be placed on Ace or Queen." },
      { title: "Stock", text: "Draw from stock when no moves are available." }
    ]
  },
  // 6: Yukon
  {
    tagline: "Move any face-up card freely.",
    objective: "Move all cards to the four foundation piles, building up by suit from Ace to King. You can move any face-up card along with all cards on top of it.",
    winCondition: "Win by completing all four foundation piles: ♠ ♥ ♣ ♦",
    rules: [
      { title: "Free Movement", text: "Move any face-up card with all cards above it, even if not in sequence." },
      { title: "Tableau Building", text: "Build down in alternating colors, like Klondike." },
      { title: "Foundations", text: "Build up by suit from Ace to King." },
      { title: "Empty Columns", text: "Only Kings can be placed in empty columns." }
    ]
  },
  // 7: Forty Thieves
  {
    tagline: "A rigorous two-deck challenge.",
    objective: "Move all 104 cards (two decks) to the eight foundation piles, building up by suit from Ace to King.",
    winCondition: "Win by completing all eight foundation piles",
    rules: [
      { title: "Tableau (10 Columns)", text: "Build down by suit. Only the top card of each column can be moved." },
      { title: "Foundations (8 Piles)", text: "Build up by suit from Ace to King." },
      { title: "Stock & Waste", text: "Draw one card at a time. Waste top card is available." },
      { title: "Empty Columns", text: "Any single card can fill an empty tableau column." }
    ]
  },
  // 8: Canfield
  {
    tagline: "Compact casino-style gameplay.",
    objective: "Move all cards to the four foundation piles, building up by suit from the base card (first card dealt to foundation).",
    winCondition: "Win by completing all four foundation piles",
    rules: [
      { title: "Reserve (Left)", text: "A pile of 13 cards. Top card is always available to play." },
      { title: "Foundations", text: "Build up by suit, wrapping A after K. Base card determines starting rank." },
      { title: "Tableau (4 Columns)", text: "Build down in alternating colors, wrapping K to A." },
      { title: "Stock", text: "Draw 3 cards at a time to waste pile." }
    ]
  },
  // 9: Scorpion
  {
    tagline: "Build King-to-Ace suit sequences.",
    objective: "Build four complete same-suit sequences from King to Ace within the tableau columns.",
    winCondition: "Win by building 4 complete King-to-Ace suit sequences",
    rules: [
      { title: "Tableau (7 Columns)", text: "Build down by the same suit. Move any face-up card with all cards below it." },
      { title: "Complete Sequences", text: "Build King-to-Ace same-suit sequences. Completed sequences are removed." },
      { title: "Stock (3 Cards)", text: "Deal 3 reserve cards to the first three columns when stuck." },
      { title: "Empty Columns", text: "Only Kings can fill empty columns." }
    ]
  }
];

export const HelpModal: React.FC<HelpModalProps> = ({ isOpen, onClose, gameType }) => {
  const themeId = useUIStore((s) => s.themeId);
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");

  if (!isOpen) return null;

  const data = HELP_DATA[gameType] || HELP_DATA[0];

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0, 0, 0, 0.7)",
        backdropFilter: "blur(8px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1500,
        padding: "24px"
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "600px",
          maxHeight: "85vh",
          display: "flex",
          flexDirection: "column",
          backgroundColor: "rgba(30, 30, 30, 0.95)",
          borderRadius: "16px",
          border: `1px solid rgba(255,255,255,0.1)`,
          boxShadow: `0 16px 48px rgba(0,0,0,0.5)`,
          overflow: "hidden"
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ padding: "20px 24px", borderBottom: "1px solid rgba(255,255,255,0.1)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <BookOpen color={accentColor} size={24} />
            <h2 style={{ fontSize: "20px", fontWeight: 700, color: "#e5e2e1" }}>How to Play {GAME_NAMES[gameType]}</h2>
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "#a1a1aa", cursor: "pointer", fontSize: "24px" }}>&times;</button>
        </div>

        <div style={{ padding: "24px", overflowY: "auto", flex: 1, display: "flex", flexDirection: "column", gap: "24px", color: "#d4d4d8", lineHeight: 1.6 }}>
          
          <div style={{ textAlign: "center", marginBottom: "8px" }}>
            <p style={{ fontSize: "16px", fontStyle: "italic", color: accentColor }}>{data.tagline}</p>
          </div>

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "12px", color: "#e5e2e1" }}>
              <Flag size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Objective</h3>
            </div>
            <p style={{ fontSize: "14px" }}>{data.objective}</p>
            
            <div style={{ marginTop: "12px", padding: "12px", borderRadius: "8px", backgroundColor: `${accentColor}22`, border: `1px solid ${accentColor}44`, display: "flex", alignItems: "center", gap: "12px" }}>
              <Trophy size={20} color={accentColor} />
              <span style={{ fontSize: "14px", fontWeight: 600, color: "#fff" }}>{data.winCondition}</span>
            </div>
          </div>

          <div style={{ height: "1px", backgroundColor: "rgba(255,255,255,0.1)" }} />

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <PlayCircle size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Gameplay Rules</h3>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              {data.rules.map((rule, idx) => (
                <div key={idx} style={{ display: "flex", gap: "12px" }}>
                  <div style={{ marginTop: "6px", width: "6px", height: "6px", borderRadius: "50%", backgroundColor: accentColor, flexShrink: 0 }} />
                  <div>
                    <h4 style={{ fontSize: "14px", fontWeight: 600, color: "#e5e2e1", marginBottom: "4px" }}>{rule.title}</h4>
                    <p style={{ fontSize: "14px", color: "#a1a1aa" }}>{rule.text}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div style={{ height: "1px", backgroundColor: "rgba(255,255,255,0.1)" }} />

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <Key size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Keyboard Shortcuts</h3>
            </div>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "12px", fontSize: "13px" }}>
              <div><strong style={{ color: "#fff" }}>Tab</strong>: Cycle through piles</div>
              <div><strong style={{ color: "#fff" }}>Enter/Space</strong>: Select focused pile</div>
              <div><strong style={{ color: "#fff" }}>U</strong>: Undo last move</div>
              <div><strong style={{ color: "#fff" }}>H</strong>: Show hint</div>
              <div><strong style={{ color: "#fff" }}>N</strong>: Start new game</div>
              <div><strong style={{ color: "#fff" }}>A</strong>: Auto play</div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
};
