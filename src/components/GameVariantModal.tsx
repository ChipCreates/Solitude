import React, { useState } from "react";
import { useUIStore } from "../store/uiStore";

interface GameVariantModalProps {
  gameId: number;
  gameName: string;
  onPlay: () => void;
  onCancel: () => void;
}

const VARIANTS: Record<number, { id: string; label: string; action: (store: any) => void }[]> = {
  // Klondike (id: 0)
  0: [
    { id: "std_1", label: "Standard (Draw 1)", action: (s) => { s.setDrawMode(1); s.setScoringMode("standard"); } },
    { id: "std_3", label: "Standard (Draw 3)", action: (s) => { s.setDrawMode(3); s.setScoringMode("standard"); } },
    { id: "vegas_1", label: "Las Vegas (Draw 1)", action: (s) => { s.setDrawMode(1); s.setScoringMode("vegas"); } },
    { id: "vegas_3", label: "Las Vegas (Draw 3)", action: (s) => { s.setDrawMode(3); s.setScoringMode("vegas"); } },
    { id: "vegas_cum_1", label: "Cumulative Vegas (Draw 1)", action: (s) => { s.setDrawMode(1); s.setScoringMode("vegas_cumulative"); } },
    { id: "vegas_cum_3", label: "Cumulative Vegas (Draw 3)", action: (s) => { s.setDrawMode(3); s.setScoringMode("vegas_cumulative"); } },
  ]
};

export const GameVariantModal: React.FC<GameVariantModalProps> = ({ gameId, gameName, onPlay, onCancel }) => {
  const uiStore = useUIStore();
  const themeId = uiStore.themeId;
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");
  
  const progress = uiStore.gameProgress[gameId] || { level: 1, xp: 0 };
  const level = progress.level;

  const variants = VARIANTS[gameId];
  
  // If game has no variants, auto-play or show simple start
  const [selectedVariantId, setSelectedVariantId] = useState(variants ? variants[0].id : null);
  const [isRandom, setIsRandom] = useState(false);

  const handlePlay = () => {
    if (variants && selectedVariantId) {
      const v = variants.find(v => v.id === selectedVariantId);
      if (v) v.action(uiStore);
    }
    // Note: We'd ideally pass the 'isRandom' flag to startNewGame. 
    // For now we'll just trigger play.
    onPlay();
  };

  return (
    <div style={{
      position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: "rgba(0, 0, 0, 0.75)", backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center", zIndex: 10000
    }}>
      <div style={{
        width: "90%", maxWidth: "360px",
        backgroundColor: "#0d2016",
        borderRadius: "16px",
        overflow: "hidden",
        boxShadow: "0 24px 48px rgba(0,0,0,0.5)",
        border: "1px solid rgba(255,255,255,0.1)"
      }}>
        {/* Header */}
        <div style={{
          backgroundColor: "#1e3a2b", padding: "16px", display: "flex", alignItems: "center", borderBottom: `4px solid ${accentColor}`
        }}>
          {/* Avatar Placeholder */}
          <div style={{ width: "32px", height: "32px", borderRadius: "50%", backgroundColor: "rgba(255,255,255,0.2)", marginRight: "12px" }}></div>
          <h2 style={{ margin: 0, fontSize: "20px", color: "#fff", fontWeight: "bold", flex: 1, fontFamily: "Manrope, sans-serif" }}>
            {gameName}
          </h2>
          {/* Level Badge */}
          <div style={{
            position: "relative", width: "48px", height: "48px", borderRadius: "50%", 
            border: `3px solid ${accentColor}`, display: "flex", flexDirection: "column", 
            alignItems: "center", justifyContent: "center", backgroundColor: "#0f1c15"
          }}>
            <span style={{ fontSize: "10px", color: "#a5b8a9", textTransform: "uppercase", fontWeight: "bold", lineHeight: 1 }}>Level</span>
            <span style={{ fontSize: "16px", color: "#fff", fontWeight: "bold", lineHeight: 1 }}>{level}</span>
          </div>
        </div>

        {/* Content */}
        <div style={{ padding: "20px", backgroundColor: "#0b1810" }}>
          {variants ? (
            <div style={{ 
              backgroundColor: "rgba(255,255,255,0.05)", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.1)", overflow: "hidden" 
            }}>
              {variants.map(v => (
                <div 
                  key={v.id}
                  onClick={() => setSelectedVariantId(v.id)}
                  style={{
                    padding: "12px 16px",
                    cursor: "pointer",
                    backgroundColor: selectedVariantId === v.id ? "rgba(255,255,255,0.1)" : "transparent",
                    color: selectedVariantId === v.id ? "#fff" : "#a5b8a9",
                    fontWeight: selectedVariantId === v.id ? "bold" : "normal",
                    borderBottom: "1px solid rgba(255,255,255,0.05)",
                    transition: "all 0.15s ease"
                  }}
                >
                  {v.label}
                </div>
              ))}
              
              <div style={{ padding: "12px 16px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                <label style={{ display: "flex", alignItems: "center", cursor: "pointer", color: "#fff" }}>
                  <input type="radio" checked={isRandom} onChange={() => setIsRandom(true)} style={{ marginRight: "8px", accentColor }} />
                  Random
                </label>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>No Reward ?</span>
              </div>
            </div>
          ) : (
            <div style={{ color: "#a5b8a9", textAlign: "center", padding: "20px" }}>
              Standard rules apply.
            </div>
          )}
        </div>

        {/* Footer */}
        <div style={{ padding: "16px", display: "flex", gap: "12px", backgroundColor: "#1e3a2b" }}>
          <button 
            onClick={handlePlay}
            style={{
              flex: 1, padding: "12px", borderRadius: "8px", border: "none",
              background: `linear-gradient(180deg, ${accentColor}, #b08d24)`,
              color: "#111", fontWeight: "bold", fontSize: "16px", cursor: "pointer",
              boxShadow: "0 2px 4px rgba(0,0,0,0.3)"
            }}
          >
            Play
          </button>
          <button 
            onClick={onCancel}
            style={{
              flex: 1, padding: "12px", borderRadius: "8px", border: "none",
              backgroundColor: "rgba(255,255,255,0.1)", color: "#fff", fontWeight: "bold", fontSize: "16px", cursor: "pointer"
            }}
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
};
