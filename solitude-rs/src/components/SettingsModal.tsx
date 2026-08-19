import React from "react";
import { THEME_PRESETS } from "../theme/presets";
import { useUIStore } from "../store/uiStore";

import { getBackPatternCss, getBackPatternSize, getBackPatternPosition } from "./CardWidget";

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  gameTypeCode?: number;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({ isOpen, onClose, gameTypeCode }) => {
  const [activeTab, setActiveTab] = React.useState<"theme" | "gameplay" | "sound">("theme");
  const {
    drawMode,
    themeId,
    themeOverlayIntensities,
    cardBackPattern,
    cardBackColor,
    soundEnabled,
    soundVolume,
    leftHandMode,
    victoryPattern,
    difficulty,
    showTimer,
    autoplay,
    scoringMode,
    vegasBankroll,
    golfWrapAround,
    musicEnabled,
    musicVolume,
    autoComplete,

    setDrawMode,
    setThemeId,
    setThemeOverlayIntensity,
    setCardBackPattern,
    setCardBackColor,
    setSoundEnabled,
    setSoundVolume,
    setLeftHandMode,
    setVictoryPattern,
    setDifficulty,
    setShowTimer,
    setAutoplay,
    setScoringMode,
    resetVegasBankroll,
    setGolfWrapAround,
    setMusicEnabled,
    setMusicVolume,
    setAutoComplete,
  } = useUIStore();

  if (!isOpen) return null;

  const handleSelectTheme = (id: string) => {
    setThemeId(id);
  };

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0, 0, 0, 0.65)",
        backdropFilter: "blur(16px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 1500,
      }}
    >
      <div
        style={{
          width: "90%",
          maxWidth: "800px",
          background: "rgba(26, 26, 26, 0.9)",
          border: "1px solid rgba(255, 255, 255, 0.15)",
          borderRadius: "24px",
          padding: "24px",
          color: "#e5e2e1",
          boxShadow: "0 20px 40px rgba(0,0,0,0.5)",
        }}
      >
        {/* Header */}
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "20px" }}>
          <h2 style={{ fontFamily: "Manrope, sans-serif", fontSize: "24px", fontWeight: 700 }}>Settings</h2>
          <button
            onClick={onClose}
            style={{
              background: "none",
              border: "none",
              color: "#e5e2e1",
              fontSize: "24px",
              cursor: "pointer",
            }}
          >
            ✕
          </button>
        </div>

        {/* Tabs */}
        <div style={{ display: "flex", gap: "12px", borderBottom: "1px solid rgba(255, 255, 255, 0.1)", paddingBottom: "12px", marginBottom: "20px" }}>
          {(["theme", "gameplay", "sound"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              style={{
                background: activeTab === tab ? "rgba(233, 195, 73, 0.2)" : "none",
                border: activeTab === tab ? "1px solid #e9c349" : "1px solid transparent",
                borderRadius: "8px",
                padding: "8px 16px",
                color: activeTab === tab ? "#e9c349" : "#8c928b",
                fontFamily: "Manrope, sans-serif",
                fontWeight: 600,
                cursor: "pointer",
                textTransform: "capitalize",
              }}
            >
              {tab}
            </button>
          ))}
        </div>

        {/* Content */}
        {activeTab === "theme" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "24px", maxHeight: "60vh", overflowY: "auto", paddingRight: "8px" }}>
            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Select Table Theme</h3>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(140px, 1fr))", gap: "12px" }}>
                {Object.values(THEME_PRESETS).map((preset) => (
                  <div
                    key={preset.id}
                    onClick={() => handleSelectTheme(preset.id)}
                    style={{
                      background: preset.tableColor,
                      border: themeId === preset.id ? "2px solid #e9c349" : "1px solid rgba(255, 255, 255, 0.1)",
                      borderRadius: "12px",
                      padding: "16px",
                      cursor: "pointer",
                      textAlign: "center",
                    }}
                  >
                    <div style={{ fontSize: "14px", fontWeight: 600, color: "#ffffff" }}>{preset.name}</div>
                  </div>
                ))}
              </div>
            </div>
            
            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Card Face Tint Intensity</h3>
              <input 
                type="range" 
                min="0" max="1" step="0.01" 
                value={themeOverlayIntensities[themeId] ?? THEME_PRESETS[themeId]?.defaultOverlayIntensity ?? 0} 
                onChange={(e) => setThemeOverlayIntensity(themeId, parseFloat(e.target.value))}
                style={{ width: "100%" }}
              />
            </div>

            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Card Back Pattern</h3>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: "12px" }}>
                {["diamond", "crosshatch", "dots", "waves", "bicycle", "filigree", "botanical", "mystic"].map(pattern => (
                   <button
                     key={pattern}
                     onClick={() => setCardBackPattern(pattern)}
                     style={{
                       display: "flex", flexDirection: "column", alignItems: "center", gap: "8px",
                       padding: "12px 8px", borderRadius: "12px", textTransform: "capitalize",
                       background: cardBackPattern === pattern ? "rgba(233,195,73,0.15)" : "rgba(255,255,255,0.05)",
                       border: cardBackPattern === pattern ? "2px solid #e9c349" : "2px solid transparent",
                       color: cardBackPattern === pattern ? "#e9c349" : "#e5e2e1",
                       fontWeight: 600, cursor: "pointer", fontSize: "12px", transition: "all 0.2s"
                     }}
                   >
                     <div style={{
                       width: "40px", height: "56px", borderRadius: "4px",
                       backgroundColor: cardBackColor,
                       backgroundImage: getBackPatternCss(pattern),
                       backgroundSize: getBackPatternSize(pattern),
                       backgroundPosition: getBackPatternPosition(pattern),
                       boxShadow: "0 2px 8px rgba(0,0,0,0.3)"
                     }} />
                     {pattern}
                   </button>
                ))}
              </div>
            </div>

            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Card Back Color</h3>
              <div style={{ display: "flex", gap: "12px" }}>
                {["#1e3a2b", "#1a2a47", "#471a24", "#1a1a1a", "#d4af37"].map(color => (
                   <div
                     key={color}
                     onClick={() => setCardBackColor(color)}
                     style={{
                       width: "40px", height: "40px", borderRadius: "50%", background: color, cursor: "pointer",
                       border: cardBackColor === color ? "3px solid #e9c349" : "2px solid rgba(255,255,255,0.2)"
                     }}
                   />
                ))}
              </div>
            </div>
          </div>
        )}

        {activeTab === "gameplay" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            {(gameTypeCode === undefined || gameTypeCode === 0) && (
              <>
                <div>
                  <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Draw Mode</label>
                  <div style={{ display: "flex", gap: "12px" }}>
                    {[1, 3].map((mode) => (
                      <button
                        key={mode}
                        onClick={() => setDrawMode(mode)}
                        style={{
                          flex: 1,
                          padding: "10px",
                          borderRadius: "8px",
                          background: drawMode === mode ? "#e9c349" : "rgba(255,255,255,0.05)",
                          color: drawMode === mode ? "#131313" : "#e5e2e1",
                          border: "none",
                          fontWeight: 600,
                          cursor: "pointer",
                        }}
                      >
                        Draw {mode}
                      </button>
                    ))}
                  </div>
                </div>

                <div>
                  <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Scoring Mode</label>
                  <div style={{ display: "flex", gap: "8px" }}>
                    {[
                      { id: "standard", label: "Standard" },
                      { id: "vegas", label: "Vegas" },
                      { id: "vegas_cumulative", label: "Cumulative" }
                    ].map((mode) => (
                      <button
                        key={mode.id}
                        onClick={() => setScoringMode(mode.id as any)}
                        style={{
                          flex: 1,
                          padding: "8px 4px",
                          borderRadius: "8px",
                          background: scoringMode === mode.id ? "#e9c349" : "rgba(255,255,255,0.05)",
                          color: scoringMode === mode.id ? "#131313" : "#e5e2e1",
                          border: "none",
                          fontWeight: 600,
                          fontSize: "13px",
                          cursor: "pointer",
                        }}
                      >
                        {mode.label}
                      </button>
                    ))}
                  </div>
                </div>
                
                {scoringMode === "vegas_cumulative" && (
                  <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", background: "rgba(0,0,0,0.3)", padding: "12px", borderRadius: "8px" }}>
                    <div style={{ display: "flex", flexDirection: "column" }}>
                      <span style={{ fontSize: "14px", color: "#c2c8c0" }}>Vegas Bankroll</span>
                      <span style={{ fontSize: "18px", fontWeight: "bold", color: vegasBankroll >= 0 ? "#4caf50" : "#f44336" }}>
                        ${vegasBankroll}
                      </span>
                    </div>
                    <button
                      onClick={resetVegasBankroll}
                      style={{ padding: "6px 12px", background: "rgba(255,255,255,0.1)", border: "none", borderRadius: "6px", color: "#e5e2e1", cursor: "pointer" }}
                    >
                      Reset
                    </button>
                  </div>
                )}
              </>
            )}

            {gameTypeCode === 4 && (
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", flexDirection: "column" }}>
                  <span>Wrap Around</span>
                  <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Allow King and Ace to chain on the waste pile</span>
                </div>
                <input
                  type="checkbox"
                  checked={golfWrapAround}
                  onChange={(e) => setGolfWrapAround(e.target.checked)}
                  style={{ width: "20px", height: "20px" }}
                />
              </div>
            )}

            {(!gameTypeCode || (gameTypeCode !== 4 && gameTypeCode !== 5 && gameTypeCode !== 6)) && (
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ display: "flex", flexDirection: "column" }}>
                  <span>Auto-Complete</span>
                  <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Finish game when all cards are revealed</span>
                </div>
                <input
                  type="checkbox"
                  checked={autoComplete}
                  onChange={(e) => setAutoComplete(e.target.checked)}
                  style={{ width: "20px", height: "20px" }}
                />
              </div>
            )}

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", flexDirection: "column" }}>
                <span>Autoplay</span>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Let the game play itself</span>
              </div>
              <input
                type="checkbox"
                checked={autoplay}
                onChange={(e) => setAutoplay(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", flexDirection: "column" }}>
                <span>Show Timer</span>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Display elapsed game time</span>
              </div>
              <input
                type="checkbox"
                checked={showTimer}
                onChange={(e) => setShowTimer(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", flexDirection: "column" }}>
                <span>Left Handed Mode</span>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Swap foundations and stock positions</span>
              </div>
              <input
                type="checkbox"
                checked={leftHandMode}
                onChange={(e) => setLeftHandMode(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Victory Pattern</label>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: "8px" }}>
                {[
                  { id: "cascade", label: "Cascade" },
                  { id: "fountain", label: "Fountain" },
                  { id: "scatter", label: "Scatter" },
                  { id: "vortex", label: "Vortex" }
                ].map((pattern) => (
                  <button
                    key={pattern.id}
                    onClick={() => setVictoryPattern(pattern.id as any)}
                    style={{
                      padding: "10px",
                      borderRadius: "8px",
                      background: victoryPattern === pattern.id ? "#e9c349" : "rgba(255,255,255,0.05)",
                      color: victoryPattern === pattern.id ? "#131313" : "#e5e2e1",
                      border: "none",
                      fontWeight: 600,
                      fontSize: "13px",
                      cursor: "pointer",
                    }}
                  >
                    {pattern.label}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>
                Difficulty (Affects Coins Multiplier{gameTypeCode === 1 ? "; Spider Suit Count" : ""})
              </label>
              <div style={{ display: "flex", gap: "12px" }}>
                {["easy", "normal", "hard"].map((level) => {
                  return (
                    <button
                      key={level}
                      onClick={() => setDifficulty(level as any)}
                      style={{
                        flex: 1,
                        padding: "10px",
                        borderRadius: "8px",
                        background: difficulty === level ? "#e9c349" : "rgba(255,255,255,0.05)",
                        color: difficulty === level ? "#131313" : "#e5e2e1",
                        border: "none",
                        fontWeight: 600,
                        cursor: "pointer",
                        textTransform: "capitalize",
                      }}
                    >
                      {level}
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        )}

        {activeTab === "sound" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", flexDirection: "column" }}>
                <span>Sound Effects</span>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Play audio feedback</span>
              </div>
              <input
                type="checkbox"
                checked={soundEnabled}
                onChange={(e) => setSoundEnabled(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            {soundEnabled && (
              <div>
                <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Volume ({(soundVolume * 100).toFixed(0)}%)</label>
                <input
                  type="range"
                  min="0" max="1" step="0.05"
                  value={soundVolume}
                  onChange={(e) => setSoundVolume(parseFloat(e.target.value))}
                  style={{ width: "100%", accentColor: "#e9c349" }}
                />
              </div>
            )}

            <div style={{ height: "1px", background: "rgba(255,255,255,0.1)", margin: "8px 0" }} />

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <div style={{ display: "flex", flexDirection: "column" }}>
                <span>Background Music</span>
                <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.5)" }}>Play music during the game</span>
              </div>
              <input
                type="checkbox"
                checked={musicEnabled}
                onChange={(e) => setMusicEnabled(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            {musicEnabled && (
              <div>
                <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Music Volume ({(musicVolume * 100).toFixed(0)}%)</label>
                <input
                  type="range"
                  min="0"
                  max="1"
                  step="0.05"
                  value={musicVolume}
                  onChange={(e) => setMusicVolume(parseFloat(e.target.value))}
                  style={{ width: "100%", accentColor: "#e9c349" }}
                />
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
