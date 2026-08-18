import React from "react";
import { THEME_PRESETS } from "../theme/presets";
import { useUIStore } from "../store/uiStore";
import { store } from "../persistence/store";

interface SettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const SettingsModal: React.FC<SettingsModalProps> = ({ isOpen, onClose }) => {
  const [activeTab, setActiveTab] = React.useState<"theme" | "gameplay" | "sound">("theme");
  const {
    drawMode,
    themeId,
    soundEnabled,
    soundVolume,
    leftHandMode,
    victoryPattern,
    setDrawMode,
    setThemeId,
    setSoundEnabled,
    setSoundVolume,
    setLeftHandMode,
    setVictoryPattern,
  } = useUIStore();

  if (!isOpen) return null;

  const handleSelectTheme = (id: string) => {
    setThemeId(id);
    store.saveSettings({
      drawMode,
      autoComplete: true,
      themeId: id,
      cardBack: "classic_gold",
      soundEnabled,
      soundVolume,
      leftHandMode,
    });
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
        zIndex: 100,
      }}
    >
      <div
        style={{
          width: "90%",
          maxWidth: "640px",
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
        )}

        {activeTab === "gameplay" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
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

            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span>Left Handed Mode</span>
              <input
                type="checkbox"
                checked={leftHandMode}
                onChange={(e) => setLeftHandMode(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Victory Pattern</label>
              <select
                value={victoryPattern}
                onChange={(e) => setVictoryPattern(e.target.value as any)}
                style={{
                  width: "100%",
                  padding: "10px",
                  borderRadius: "8px",
                  background: "rgba(255,255,255,0.1)",
                  border: "1px solid rgba(255,255,255,0.2)",
                  color: "#e5e2e1",
                  fontSize: "14px",
                  outline: "none",
                }}
              >
                <option value="cascade" style={{ background: "#1e1e1e" }}>Cascade (Bouncing)</option>
                <option value="fountain" style={{ background: "#1e1e1e" }}>Fountain (Erupting)</option>
                <option value="scatter" style={{ background: "#1e1e1e" }}>Scatter (Explosion)</option>
                <option value="vortex" style={{ background: "#1e1e1e" }}>Vortex (Spiral)</option>
              </select>
            </div>
          </div>
        )}

        {activeTab === "sound" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
              <span>Sound Effects</span>
              <input
                type="checkbox"
                checked={soundEnabled}
                onChange={(e) => setSoundEnabled(e.target.checked)}
                style={{ width: "20px", height: "20px" }}
              />
            </div>

            <div>
              <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Volume</label>
              <input
                type="range"
                min="0"
                max="1"
                step="0.05"
                value={soundVolume}
                onChange={(e) => setSoundVolume(parseFloat(e.target.value))}
                style={{ width: "100%" }}
              />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
