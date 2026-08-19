import React from "react";
import { useUIStore } from "../store/uiStore";

interface LevelBadgeProps {
  gameTypeCode: number;
}

export const LevelBadge: React.FC<LevelBadgeProps> = ({ gameTypeCode }) => {
  const { gameProgress, themeId } = useUIStore();
  const progress = gameProgress[gameTypeCode] || { level: 1, xp: 0 };
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");

  const { level, xp } = progress;
  
  // XP required for current level
  const xpForCurrentLevel = level === 1 ? 0 : Math.floor(500 * Math.pow(level - 1, 1.5));
  // XP required for next level
  const xpForNextLevel = Math.floor(500 * Math.pow(level, 1.5));
  
  // Progress within the current level (0 to 1)
  const levelProgress = (xp - xpForCurrentLevel) / (xpForNextLevel - xpForCurrentLevel);
  const progressPercentage = Math.max(0, Math.min(100, Math.floor(levelProgress * 100)));

  return (
    <div style={{ display: "flex", alignItems: "center", backgroundColor: "rgba(0,0,0,0.3)", borderRadius: "24px", padding: "4px 12px 4px 4px", border: "1px solid rgba(255,255,255,0.1)" }}>
      <div style={{ 
        position: "relative", width: "32px", height: "32px", borderRadius: "50%", 
        backgroundColor: "#1e3a2b", display: "flex", alignItems: "center", justifyContent: "center",
        boxShadow: "0 0 10px rgba(0,0,0,0.5)",
        marginRight: "8px"
      }}>
        {/* SVG Circular Progress Bar */}
        <svg style={{ position: "absolute", top: -2, left: -2, width: "36px", height: "36px", transform: "rotate(-90deg)" }}>
          <circle cx="18" cy="18" r="16" fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="3" />
          <circle cx="18" cy="18" r="16" fill="none" stroke={accentColor} strokeWidth="3" 
            strokeDasharray="100.53" // 2 * PI * 16
            strokeDashoffset={100.53 - (100.53 * progressPercentage) / 100}
            strokeLinecap="round"
          />
        </svg>
        <span style={{ fontSize: "13px", fontWeight: 800, color: "#fff", fontFamily: "JetBrains Mono, monospace" }}>{level}</span>
      </div>
      
      <div style={{ display: "flex", flexDirection: "column", justifyContent: "center" }}>
        <div style={{ fontSize: "10px", color: "rgba(255,255,255,0.6)", textTransform: "uppercase", fontWeight: "bold", lineHeight: 1, marginBottom: "2px" }}>Level {level}</div>
        <div style={{ fontSize: "14px", color: "#fff", fontWeight: "bold", lineHeight: 1 }}>{xp} XP</div>
      </div>
    </div>
  );
};
