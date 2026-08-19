import React, { useEffect, useState } from "react";
import { useUIStore } from "../store/uiStore";
import { User, Check, Sparkles } from "lucide-react";

interface VictoryModalProps {
  gameName: string;
  winData: {
    xpGained: number;
    leveledUp: boolean;
    newLevel: number;
    newXP: number;
  };
  onNewGame: () => void;
  onHome: () => void;
}

export const VictoryModal: React.FC<VictoryModalProps> = ({ gameName, winData, onNewGame, onHome }) => {
  const { themeId } = useUIStore();
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");
  const [showLevelUp, setShowLevelUp] = useState(false);

  // Show "Congratulations" first, then optionally overlay "Level Up!"
  useEffect(() => {
    if (winData.leveledUp) {
      const t = setTimeout(() => setShowLevelUp(true), 1500);
      return () => clearTimeout(t);
    }
  }, [winData.leveledUp]);

  // Math to display progress bar correctly
  const xpForCurrentLevel = winData.newLevel === 1 ? 0 : Math.floor(500 * Math.pow(winData.newLevel - 1, 1.5));
  const xpForNextLevel = Math.floor(500 * Math.pow(winData.newLevel, 1.5));
  const levelProgress = (winData.newXP - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
  const progressPercentage = Math.max(0, Math.min(100, Math.floor(levelProgress * 100)));

  return (
    <div style={{
      position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
      backgroundColor: "rgba(0, 0, 0, 0.7)", backdropFilter: "blur(4px)",
      display: "flex", alignItems: "center", justifyContent: "center", zIndex: 10000,
      animation: "fadeIn 0.5s ease-out forwards"
    }}>
      <style>{`
        @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
        @keyframes slideUp { from { transform: translateY(20px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
        @keyframes pulseGlow { 0% { box-shadow: 0 0 0 0 rgba(212, 175, 55, 0.4); } 70% { box-shadow: 0 0 0 15px rgba(212, 175, 55, 0); } 100% { box-shadow: 0 0 0 0 rgba(212, 175, 55, 0); } }
      `}</style>
      
      <div style={{
        position: "relative",
        width: "90%", maxWidth: "400px",
        backgroundColor: "#0d2016",
        borderRadius: "16px",
        boxShadow: "0 24px 48px rgba(0,0,0,0.5)",
        border: "2px solid rgba(255,255,255,0.1)",
        overflow: "visible",
        animation: "slideUp 0.6s cubic-bezier(0.16, 1, 0.3, 1) forwards"
      }}>
        {/* Ribbon Header */}
        <div style={{
          position: "absolute", top: "-12px", left: "50%", transform: "translateX(-50%)",
          backgroundColor: "#1e3a2b", padding: "8px 24px", borderRadius: "16px",
          border: `2px solid ${accentColor}`, display: "flex", alignItems: "center", gap: "8px",
          boxShadow: "0 4px 12px rgba(0,0,0,0.5)", zIndex: 10
        }}>
          <Check size={20} color={accentColor} />
          <span style={{ color: "#fff", fontWeight: "bold", fontSize: "18px", letterSpacing: "1px" }}>Congratulations!</span>
        </div>

        {/* Content */}
        <div style={{ padding: "48px 24px 24px", display: "flex", flexDirection: "column", alignItems: "center" }}>
          
          <div style={{ 
            position: "relative", width: "100px", height: "100px", borderRadius: "50%", 
            backgroundColor: "#1e3a2b", display: "flex", alignItems: "center", justifyContent: "center",
            boxShadow: "inset 0 4px 8px rgba(0,0,0,0.5), 0 8px 16px rgba(0,0,0,0.3)",
            marginBottom: "16px"
          }}>
            <svg style={{ position: "absolute", top: -4, left: -4, width: "108px", height: "108px", transform: "rotate(-90deg)" }}>
              <circle cx="54" cy="54" r="50" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="6" />
              <circle cx="54" cy="54" r="50" fill="none" stroke={accentColor} strokeWidth="6" 
                strokeDasharray="314.15" // 2 * PI * 50
                strokeDashoffset={314.15 - (314.15 * progressPercentage) / 100}
                strokeLinecap="round"
                style={{ transition: "stroke-dashoffset 1.5s cubic-bezier(0.16, 1, 0.3, 1)" }}
              />
            </svg>
            <User size={48} color="#fff" />
          </div>

          <h2 style={{ fontSize: "28px", fontWeight: 800, color: "#fff", margin: "0 0 24px", textTransform: "uppercase", letterSpacing: "2px" }}>
            Level {winData.newLevel}
          </h2>

          <div style={{ display: "flex", alignItems: "center", gap: "12px", marginBottom: "32px" }}>
            <span style={{ color: "#a5b8a9", fontSize: "16px" }}>Reward:</span>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", backgroundColor: "rgba(212, 175, 55, 0.1)", padding: "8px 16px", borderRadius: "24px", border: `1px solid ${accentColor}` }}>
              <Sparkles size={16} color={accentColor} />
              <span style={{ color: accentColor, fontWeight: "bold", fontSize: "18px" }}>{winData.xpGained} XP</span>
            </div>
          </div>

          {/* Actions */}
          <div style={{ display: "flex", gap: "12px", width: "100%" }}>
            <button 
              onClick={onNewGame}
              style={{
                flex: 1, padding: "14px", borderRadius: "8px", border: "none",
                background: `linear-gradient(180deg, ${accentColor}, #b08d24)`,
                color: "#111", fontWeight: "bold", fontSize: "16px", cursor: "pointer",
                boxShadow: "0 4px 8px rgba(0,0,0,0.3)"
              }}
            >
              New Game
            </button>
            <button 
              onClick={onHome}
              style={{
                flex: 1, padding: "14px", borderRadius: "8px", border: "none",
                backgroundColor: "rgba(255,255,255,0.1)", color: "#fff", fontWeight: "bold", fontSize: "16px", cursor: "pointer"
              }}
            >
              Home
            </button>
          </div>
        </div>

        {/* Level Up Overlay */}
        {showLevelUp && (
          <div style={{
            position: "absolute", top: 0, left: 0, right: 0, bottom: 0,
            backgroundColor: "rgba(0, 0, 0, 0.85)", display: "flex", flexDirection: "column", 
            alignItems: "center", justifyContent: "center", zIndex: 20,
            borderRadius: "16px",
            animation: "fadeIn 0.4s ease-out forwards"
          }}>
            <div style={{
              backgroundColor: accentColor, width: "100%", padding: "12px", textAlign: "center", 
              transform: "rotate(-2deg)", margin: "24px 0", boxShadow: "0 8px 16px rgba(0,0,0,0.5)"
            }}>
              <span style={{ color: "#111", fontWeight: 900, fontSize: "28px", letterSpacing: "4px", textTransform: "uppercase" }}>LEVEL-UP!</span>
            </div>
            
            <p style={{ color: "#fff", fontSize: "16px", margin: "0 0 16px" }}>You've Reached</p>
            
            <div style={{ 
              position: "relative", width: "80px", height: "80px", borderRadius: "50%", 
              backgroundColor: "#1e3a2b", display: "flex", alignItems: "center", justifyContent: "center",
              boxShadow: "0 0 20px rgba(212, 175, 55, 0.5)", marginBottom: "24px",
              animation: "pulseGlow 2s infinite"
            }}>
              <svg style={{ position: "absolute", top: -3, left: -3, width: "86px", height: "86px", transform: "rotate(-90deg)" }}>
                <circle cx="43" cy="43" r="40" fill="none" stroke={accentColor} strokeWidth="6" />
              </svg>
              <User size={36} color="#fff" />
            </div>

            <h3 style={{ margin: "0 0 8px", fontSize: "22px", color: "#fff", textTransform: "uppercase" }}>{gameName} Level {winData.newLevel}</h3>
            <p style={{ margin: "0 0 32px", fontSize: "14px", color: "#a5b8a9" }}>Next card back at level {Math.ceil((winData.newLevel + 1) / 5) * 5}</p>

            <button 
              onClick={() => setShowLevelUp(false)}
              style={{
                padding: "12px 48px", borderRadius: "8px", border: "none",
                background: `linear-gradient(180deg, ${accentColor}, #b08d24)`,
                color: "#111", fontWeight: "bold", fontSize: "16px", cursor: "pointer",
                boxShadow: "0 4px 8px rgba(0,0,0,0.3)"
              }}
            >
              OK
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
