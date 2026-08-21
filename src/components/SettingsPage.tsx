import React from "react";
import { Lock } from "lucide-react";
import { THEME_PRESETS, applyThemePack } from "../theme/presets";
import { OverlayValidator, hexToRgb } from "../theme/overlayValidator";
import { MUSIC_TRACKS, CUSTOM_TRACK_ID } from "../data/musicTracks";
import { STORE_ITEMS } from "../data/storeItems";
import { useUIStore } from "../store/uiStore";

import { getBackPatternCss, getBackPatternSize, getBackPatternPosition } from "./CardWidget";

interface SettingsPageProps {
  gameTypeCode?: number;
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ gameTypeCode }) => {
  const [activeTab, setActiveTab] = React.useState<"theme" | "gameplay" | "sound">("theme");
  const [intensityWarning, setIntensityWarning] = React.useState(false);
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
    musicTrackId,
    customMusicUrl,
    customMusicName,
    autoComplete,
    unlockedItems,

    setDrawMode,
    setThemeId,
    setThemeOverlayIntensity,
    setCardFaceSetId,
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
    setMusicTrackId,
    setSfxSetId,
    setCustomMusicTrack,
    setAutoComplete,
  } = useUIStore();

  const musicFileInputRef = React.useRef<HTMLInputElement | null>(null);

  const handleCustomMusicFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (customMusicUrl) URL.revokeObjectURL(customMusicUrl);
    setCustomMusicTrack(URL.createObjectURL(file), file.name);
    setMusicTrackId(CUSTOM_TRACK_ID);
    e.target.value = "";
  };

  const handleSelectTheme = (id: string) => {
    applyThemePack(id, { setThemeId, setCardBackPattern, setCardFaceSetId, setSfxSetId, setMusicTrackId });
    setIntensityWarning(false);
  };

  const handleIntensityChange = (intensity: number) => {
    const theme = THEME_PRESETS[themeId];
    if (theme && theme.cardFaceOverlay) {
      const overlayRgb = hexToRgb(theme.cardFaceOverlay);
      if (OverlayValidator.isLegible(overlayRgb, intensity)) {
        setIntensityWarning(false);
        setThemeOverlayIntensity(themeId, intensity);
      } else {
        setIntensityWarning(true);
        setThemeOverlayIntensity(themeId, OverlayValidator.findMaxIntensity(overlayRgb));
      }
    } else {
      setThemeOverlayIntensity(themeId, intensity);
    }
  };

  // Only themes actually sold somewhere (free or paid) are selectable here —
  // a theme with no matching store entry isn't reachable by any purchase
  // path, so it's excluded rather than shown as permanently locked.
  const selectableThemes = Object.values(THEME_PRESETS)
    .map((preset) => ({
      preset,
      storeItem: STORE_ITEMS.find((i) => (i.type === "theme" || i.type === "theme_pack") && i.id === preset.id),
    }))
    .filter((entry): entry is { preset: typeof entry.preset; storeItem: NonNullable<typeof entry.storeItem> } => !!entry.storeItem);

  return (
    <div style={{ maxWidth: "1000px", margin: "0 auto", padding: "48px 48px" }}>
      <div style={{ marginBottom: "24px" }}>
        <h2 style={{ margin: 0, fontSize: "28px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "2px", textTransform: "uppercase" }}>Settings</h2>
        <p style={{ margin: "8px 0 0 0", fontSize: "16px", color: "#a5b8a9" }}>Tune the table to your taste.</p>
      </div>

      {/* Tabs */}
      <div style={{ display: "flex", gap: "4px", borderBottom: "1px solid rgba(255, 255, 255, 0.1)", paddingBottom: "16px", marginBottom: "24px", background: "rgba(0,0,0,0.3)", padding: "4px", borderRadius: "8px", width: "fit-content" }}>
        {(["theme", "gameplay", "sound"] as const).map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            style={{
              background: activeTab === tab ? "#1e3a2b" : "transparent",
              border: "none",
              borderRadius: "6px",
              padding: "8px 20px",
              color: activeTab === tab ? "#e9c349" : "#a5b8a9",
              fontFamily: "Manrope, sans-serif",
              fontWeight: 600,
              fontSize: "13px",
              cursor: "pointer",
              textTransform: "capitalize",
            }}
          >
            {tab}
          </button>
        ))}
      </div>

      <div style={{ maxWidth: "700px" }}>
        {/* Content */}
        {activeTab === "theme" && (
          <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Select Table Theme</h3>
              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(140px, 1fr))", gap: "12px" }}>
                {selectableThemes.map(({ preset, storeItem }) => {
                  const unlocked = unlockedItems.includes(preset.id) || storeItem.price === 0;
                  return (
                    <div
                      key={preset.id}
                      onClick={unlocked ? () => handleSelectTheme(preset.id) : undefined}
                      style={{
                        background: preset.tableColor,
                        border: themeId === preset.id ? "2px solid #e9c349" : "1px solid rgba(255, 255, 255, 0.1)",
                        borderRadius: "12px",
                        padding: "16px",
                        cursor: unlocked ? "pointer" : "not-allowed",
                        textAlign: "center",
                        position: "relative",
                        opacity: unlocked ? 1 : 0.55,
                      }}
                    >
                      <div style={{ fontSize: "14px", fontWeight: 600, color: "#ffffff" }}>{preset.name}</div>
                      {!unlocked && (
                        <div style={{ display: "flex", alignItems: "center", justifyContent: "center", gap: "4px", marginTop: "6px", fontSize: "11px", color: "#e9c349" }}>
                          <Lock size={11} /> {storeItem.price} in Emporium
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            <div>
              <h3 style={{ fontSize: "16px", marginBottom: "12px", color: "#c2c8c0" }}>Card Face Tint Intensity</h3>
              <input
                type="range"
                min="0" max="1" step="0.01"
                value={themeOverlayIntensities[themeId] ?? THEME_PRESETS[themeId]?.defaultOverlayIntensity ?? 0}
                onChange={(e) => handleIntensityChange(parseFloat(e.target.value))}
                style={{ width: "100%" }}
              />
              {intensityWarning && (
                <p style={{ margin: "8px 0 0 0", fontSize: "13px", color: "#e9a53a" }}>
                  ⚠️ Overlay intensity clamped to keep card suits legible
                </p>
              )}
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
              <>
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

                <div>
                  <label style={{ display: "block", marginBottom: "8px", fontSize: "14px", color: "#c2c8c0" }}>Track</label>
                  <div style={{ display: "flex", flexDirection: "column", gap: "8px" }}>
                    {MUSIC_TRACKS.map((track) => (
                      <button
                        key={track.id}
                        onClick={() => setMusicTrackId(track.id)}
                        style={{
                          textAlign: "left",
                          padding: "10px 14px",
                          borderRadius: "8px",
                          background: musicTrackId === track.id ? "#e9c349" : "rgba(255,255,255,0.05)",
                          color: musicTrackId === track.id ? "#131313" : "#e5e2e1",
                          border: "none",
                          fontWeight: 600,
                          fontSize: "14px",
                          cursor: "pointer",
                        }}
                      >
                        {track.name}
                      </button>
                    ))}
                    <button
                      onClick={() => customMusicUrl ? setMusicTrackId(CUSTOM_TRACK_ID) : musicFileInputRef.current?.click()}
                      style={{
                        textAlign: "left",
                        padding: "10px 14px",
                        borderRadius: "8px",
                        background: musicTrackId === CUSTOM_TRACK_ID ? "#e9c349" : "rgba(255,255,255,0.05)",
                        color: musicTrackId === CUSTOM_TRACK_ID ? "#131313" : "#e5e2e1",
                        border: "1px dashed rgba(255,255,255,0.2)",
                        fontWeight: 600,
                        fontSize: "14px",
                        cursor: "pointer",
                      }}
                    >
                      {customMusicName ? `🎵 ${customMusicName}` : "Choose a file from your device…"}
                    </button>
                    {customMusicUrl && (
                      <button
                        onClick={() => musicFileInputRef.current?.click()}
                        style={{ alignSelf: "flex-start", background: "none", border: "none", color: "#a5b8a9", fontSize: "12px", cursor: "pointer", padding: "2px 4px", textDecoration: "underline" }}
                      >
                        Choose a different file
                      </button>
                    )}
                    <input
                      ref={musicFileInputRef}
                      type="file"
                      accept="audio/*"
                      onChange={handleCustomMusicFile}
                      style={{ display: "none" }}
                    />
                    <span style={{ fontSize: "11px", color: "rgba(255,255,255,0.4)" }}>
                      Files chosen from your device play for this session only.
                    </span>
                  </div>
                </div>
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
};
