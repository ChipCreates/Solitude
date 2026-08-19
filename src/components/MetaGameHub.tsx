import React, { useEffect, useState } from "react";
import { Trophy, Store, Settings as SettingsIcon, ArrowLeft, LayoutGrid, Coins, PanelLeftClose, PanelLeftOpen, Info, Eye, Users, X, Home, Menu, Clock, RotateCw, Lightbulb, Sparkles, Play, HelpCircle } from "lucide-react";
import { useViewport } from "../hooks/useViewport";
import { useUIStore } from "../store/uiStore";
import { useProfileStore } from "../store/profileStore";
import { useStatisticsStore } from "../store/statisticsStore";
import { GAME_TYPE_NAMES } from "../data/gameTypes";
import achievementsData from "../data/achievements.json";
import { DashboardOverview } from "./DashboardOverview";
import { getLevelTitle, getOverallLevel } from "../utils/levelTitles";
import { getAvatarOption } from "../data/avatars";
import { applyThemePack } from "../theme/presets";
import { STORE_ITEMS } from "../data/storeItems";
import { SettingsPage } from "./SettingsPage";
import { ThemePackDetailPage } from "./ThemePackDetailPage";

export { STORE_ITEMS };

export type MetaGameHubTab = "gameboard" | "store" | "trophy" | "settings";

interface MobileGameHud {
  timerSeconds: number;
  moveCount: number;
  isAutoPlaying: boolean;
  onExitGame: () => void;
  onNewGame: () => void;
  onHint: () => void;
  onUndo: () => void;
  onToggleAutoplay: () => void;
  onOpenHelp: () => void;
}

interface MetaGameHubProps {
  activeTab: MetaGameHubTab;
  onTabChange: (tab: MetaGameHubTab) => void;
  onOpenAbout: () => void;
  gameTypeCode?: number;
  leftHeaderContent?: React.ReactNode;
  rightHeaderContent?: React.ReactNode;
  activeGameName?: string;
  children?: React.ReactNode;
  // Drives MetaGameHub's own compact 2-row mobile header — kept separate
  // from leftHeaderContent/rightHeaderContent, which stay desktop-shaped
  // (those two are simply not rendered on mobile at all).
  mobileGameHud?: MobileGameHud;
}

function formatTimer(totalSeconds: number): string {
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

function formatDuration(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

const STORE_CATEGORIES = [
  { id: "card_back", label: "CARD BACKS" },
  { id: "theme", label: "THEMES" },
  { id: "theme_pack", label: "THEME PACKS" },
  { id: "power_up", label: "POWER UPS" },
  { id: "victory", label: "ANIMATIONS" },
];

export const MetaGameHub: React.FC<MetaGameHubProps> = ({ activeTab, onTabChange, onOpenAbout, gameTypeCode, leftHeaderContent, rightHeaderContent, activeGameName, children, mobileGameHud }) => {
  const { coins, subtractCoins, unlockedItems, unlockItem, cardBackPattern, setCardBackPattern, themeId, setThemeId, setSfxSetId, setMusicTrackId, unlockedAchievements, powerUpInventory, purchasePowerUp, gameProgress } = useUIStore();
  const { profiles, activeProfileId } = useProfileStore();
  const { statsByGameType, loadAllStats } = useStatisticsStore();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isAvatarMenuOpen, setIsAvatarMenuOpen] = useState(false);
  const [storeCategory, setStoreCategory] = useState("card_back");
  const [trophySubTab, setTrophySubTab] = useState<"overview" | "stats">("overview");
  const [previewThemePackId, setPreviewThemePackId] = useState<string | null>(null);
  const { isMobile, isLandscape } = useViewport();
  // Only hide the tab bar once a game is actually in progress — the game
  // chooser grid itself isn't gameplay and still needs primary nav.
  const hideBottomChromeForLandscapeGameplay = isMobile && isLandscape && activeTab === "gameboard" && gameTypeCode !== undefined;

  const goToDashboard = () => {
    onTabChange("trophy");
    setTrophySubTab("overview");
    setIsAvatarMenuOpen(false);
  };

  const activeProfile = profiles.find(p => p.id === activeProfileId) || profiles[0];
  const activeAvatar = getAvatarOption(activeProfile?.avatarId ?? "");
  const overallLevel = getOverallLevel(gameProgress);
  const overallLevelTitle = getLevelTitle(overallLevel.level);

  useEffect(() => {
    if (activeTab === "trophy") loadAllStats();
  }, [activeTab, activeProfileId, loadAllStats]);

  // --- Store Handlers ---
  const equipItem = (item: any) => {
    if (item.type === "card_back") setCardBackPattern(item.id);
    // Theme packs bundle a coordinated card back/SFX/music with the theme,
    // fanned out by applyThemePack; plain themes just set the color scheme.
    if (item.type === "theme" || item.type === "theme_pack") {
      applyThemePack(item.id, { setThemeId, setCardBackPattern, setSfxSetId, setMusicTrackId });
    }
  };

  const handlePurchase = (item: any) => {
    // Power-ups are consumable: every click buys another one (spending
    // coins), rather than a one-time unlock+equip like cosmetics.
    if (item.type === "power_up") {
      purchasePowerUp(item.id, item.price);
      return;
    }
    if (unlockedItems.includes(item.id) || item.price === 0) {
      equipItem(item);
      return;
    }
    if (coins >= item.price) {
      if (subtractCoins(item.price)) {
        unlockItem(item.id);
        equipItem(item);
      }
    }
  };

  const isEquipped = (item: any) => {
    if (item.type === "card_back" && cardBackPattern === item.id) return true;
    if ((item.type === "theme" || item.type === "theme_pack") && themeId === item.id) return true;
    return false;
  };

  // --- Trophy Handlers ---
  const totalEarned = unlockedAchievements.length;
  const totalAvailable = achievementsData.achievements.length;
  const progressPercent = Math.round((totalEarned / totalAvailable) * 100) || 0;

  const avatarMenuItems = [
    ...(isMobile ? [{ label: "Switch Profile", icon: <Users size={isMobile ? 20 : 15} />, onClick: goToDashboard }] : []),
    { label: "Dashboard", icon: <Trophy size={isMobile ? 20 : 15} />, onClick: goToDashboard },
    { label: "Settings", icon: <SettingsIcon size={isMobile ? 20 : 15} />, onClick: () => { onTabChange("settings"); setIsAvatarMenuOpen(false); } },
    { label: "About", icon: <Info size={isMobile ? 20 : 15} />, onClick: () => { onOpenAbout(); setIsAvatarMenuOpen(false); } },
  ];

  const gameMenuItems = mobileGameHud ? [
    { label: "New Game", icon: <Play size={20} />, onClick: () => { mobileGameHud.onNewGame(); setIsAvatarMenuOpen(false); } },
    { label: "Hint", icon: <Lightbulb size={20} />, onClick: () => { mobileGameHud.onHint(); setIsAvatarMenuOpen(false); } },
    { label: "Undo", icon: <ArrowLeft size={20} />, onClick: () => { mobileGameHud.onUndo(); setIsAvatarMenuOpen(false); } },
    { label: mobileGameHud.isAutoPlaying ? "Stop Autoplay" : "Autoplay", icon: <Sparkles size={20} />, onClick: () => { mobileGameHud.onToggleAutoplay(); setIsAvatarMenuOpen(false); } },
    { label: "Help", icon: <HelpCircle size={20} />, onClick: () => { mobileGameHud.onOpenHelp(); setIsAvatarMenuOpen(false); } },
  ] : [];

  return (
    <div style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "#0a120d", zIndex: 1000, display: "flex", flexDirection: "column", fontFamily: "Inter, sans-serif" }}>

      {/* Top Header */}
      {!isMobile ? (
        <div style={{ height: "64px", flexShrink: 0, background: "#111111", borderBottom: "1px solid rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 24px" }}>
          <div style={{ flex: 1, display: "flex", alignItems: "center", gap: "16px" }}>
            {activeTab !== "gameboard" ? (
              <button onClick={() => onTabChange("gameboard")} style={{ display: "flex", alignItems: "center", gap: "8px", background: "none", border: "none", color: "#e9c349", fontSize: "16px", fontWeight: 600, cursor: "pointer", padding: "8px", marginLeft: "-8px" }}>
                <ArrowLeft size={20} /> Back
              </button>
            ) : leftHeaderContent}
          </div>
          <div style={{ fontSize: "28px", fontWeight: 800, color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "1px", flex: 1, textAlign: "center", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
            Solitude{activeTab === "gameboard" && activeGameName ? `: ${activeGameName}` : ""}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "16px", flex: 1, justifyContent: "flex-end" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "6px", background: "rgba(0,0,0,0.4)", padding: "4px 12px", borderRadius: "12px", border: "1px solid rgba(233, 195, 73, 0.3)" }}>
              <span style={{ color: "#e9c349", fontWeight: "bold", fontSize: "14px", fontFamily: "JetBrains Mono, monospace" }}>{coins}</span>
              <span style={{ fontSize: "12px", opacity: 0.8, color: "#e5e2e1", fontFamily: "Inter, sans-serif" }}>Coins</span>
            </div>
            <div style={{ position: "relative" }}>
              <button
                onClick={() => setIsAvatarMenuOpen((open) => !open)}
                data-testid="avatar-menu-button"
                style={{ background: "none", cursor: "pointer", padding: 0, width: "36px", height: "36px", borderRadius: "50%", overflow: "hidden", border: `1px solid ${activeAvatar.ringColor}88`, flexShrink: 0 }}
              >
                <img src={activeAvatar.src} alt={activeAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
              </button>
              {isAvatarMenuOpen && (
                <>
                  <div onClick={() => setIsAvatarMenuOpen(false)} style={{ position: "fixed", inset: 0, zIndex: 1099 }} />
                  <div style={{ position: "absolute", top: "44px", right: 0, minWidth: "180px", background: "#111111", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "12px", boxShadow: "0 8px 32px rgba(0,0,0,0.5)", zIndex: 1100, overflow: "hidden", padding: "6px" }}>
                    <div style={{ padding: "8px 12px", fontSize: "12px", color: "#e9c349", fontWeight: 700 }}>{activeProfile?.name || "Player"}</div>
                    {avatarMenuItems.map((item) => (
                      <button
                        key={item.label}
                        onClick={item.onClick}
                        style={{ width: "100%", display: "flex", alignItems: "center", gap: "10px", background: "none", border: "none", color: "#e5e2e1", fontSize: "13px", fontWeight: 500, padding: "8px 12px", borderRadius: "8px", cursor: "pointer", textAlign: "left" }}
                        onMouseEnter={(e) => (e.currentTarget.style.background = "rgba(255,255,255,0.06)")}
                        onMouseLeave={(e) => (e.currentTarget.style.background = "none")}
                      >
                        {item.icon} {item.label}
                      </button>
                    ))}
                  </div>
                </>
              )}
            </div>
            {rightHeaderContent}
          </div>
        </div>
      ) : (
        <div style={{ flexShrink: 0, background: "radial-gradient(circle at 50% 0%, #1e3a2b, #0d1a13)", borderBottom: "1px solid rgba(0,0,0,0.3)", paddingTop: "env(safe-area-inset-top)" }}>
          {/* Row 1: exit/back, title, menu */}
          <div style={{ height: isLandscape ? "44px" : "52px", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 12px" }}>
            <div style={{ width: "36px" }}>
              {mobileGameHud ? (
                <button onClick={mobileGameHud.onExitGame} style={{ background: "none", border: "none", color: "#e9c349", cursor: "pointer", padding: "6px", display: "flex" }}>
                  <Home size={22} />
                </button>
              ) : activeTab !== "gameboard" ? (
                <button onClick={() => onTabChange("gameboard")} style={{ background: "none", border: "none", color: "#e9c349", cursor: "pointer", padding: "6px", display: "flex" }}>
                  <ArrowLeft size={22} />
                </button>
              ) : null}
            </div>
            <div style={{ fontSize: "17px", fontWeight: 800, color: "#e5e2e1", fontFamily: "Manrope, sans-serif", letterSpacing: "0.5px", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
              Solitude{activeTab === "gameboard" && activeGameName ? <span style={{ color: "#e9c349" }}>: {activeGameName}</span> : ""}
            </div>
            <button onClick={() => setIsAvatarMenuOpen(true)} data-testid="avatar-menu-button" style={{ width: "36px", background: "none", border: "none", color: "#e5e2e1", cursor: "pointer", padding: "6px", display: "flex", justifyContent: "flex-end" }}>
              <Menu size={22} />
            </button>
          </div>

          {/* Row 2: stat pill */}
          {!isLandscape && (
            <div style={{ padding: "0 12px 10px" }}>
              <div style={{ display: "flex", alignItems: "center", gap: "10px", background: "rgba(0,0,0,0.35)", borderRadius: "999px", padding: "6px 14px", border: "1px solid rgba(255,255,255,0.08)", overflowX: "auto" }}>
                {mobileGameHud && gameTypeCode !== undefined && (
                  <div style={{ display: "flex", alignItems: "center", gap: "6px", flexShrink: 0 }}>
                    <div style={{ width: "24px", height: "24px", borderRadius: "50%", background: "#2e8b4f", border: "1px solid rgba(255,255,255,0.3)", display: "flex", alignItems: "center", justifyContent: "center", fontSize: "10px", fontWeight: 800, color: "#fff" }}>
                      Lv
                    </div>
                    <span style={{ color: "#fff", fontSize: "13px", fontWeight: 700 }}>Lv {gameProgress[gameTypeCode]?.level ?? 1}</span>
                  </div>
                )}
                {mobileGameHud && (
                  <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#fff", fontSize: "13px", fontFamily: "JetBrains Mono, monospace", flexShrink: 0 }}>
                    <Clock size={14} color="#fff" /> {formatTimer(mobileGameHud.timerSeconds)}
                  </div>
                )}
                <div style={{ width: "22px", height: "22px", borderRadius: "50%", overflow: "hidden", border: `1px solid ${activeAvatar.ringColor}88`, flexShrink: 0 }}>
                  <img src={activeAvatar.src} alt={activeAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                </div>
                {mobileGameHud && (
                  <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#fff", fontSize: "13px", fontFamily: "JetBrains Mono, monospace", flexShrink: 0 }}>
                    <RotateCw size={14} color="#fff" /> {mobileGameHud.moveCount}
                  </div>
                )}
                <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#fff", fontSize: "13px", fontWeight: 700, fontFamily: "JetBrains Mono, monospace", flexShrink: 0, marginLeft: "auto" }}>
                  <Coins size={14} color="#e9c349" /> {coins}
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Full-screen menu (mobile) */}
      {isAvatarMenuOpen && isMobile && (
        <div style={{ position: "fixed", inset: 0, background: "#0a120d", zIndex: 2000, display: "flex", flexDirection: "column", paddingTop: "env(safe-area-inset-top)", paddingBottom: "env(safe-area-inset-bottom)" }}>
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "16px 20px", borderBottom: "1px solid rgba(255,255,255,0.08)" }}>
            <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
              <div style={{ width: "40px", height: "40px", borderRadius: "50%", overflow: "hidden", border: `1px solid ${activeAvatar.ringColor}88`, flexShrink: 0 }}>
                <img src={activeAvatar.src} alt={activeAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
              </div>
              <div style={{ fontSize: "16px", fontWeight: 700, color: "#e9c349" }}>{activeProfile?.name || "Player"}</div>
            </div>
            <button onClick={() => setIsAvatarMenuOpen(false)} style={{ background: "rgba(255,255,255,0.08)", border: "none", borderRadius: "50%", width: "40px", height: "40px", display: "flex", alignItems: "center", justifyContent: "center", color: "#e5e2e1", cursor: "pointer" }}>
              <X size={20} />
            </button>
          </div>
          <div style={{ display: "flex", flexDirection: "column", padding: "8px 12px", overflowY: "auto" }}>
            {gameMenuItems.length > 0 && (
              <>
                <div style={{ fontSize: "11px", color: "#a5b8a9", letterSpacing: "1px", textTransform: "uppercase", padding: "12px 12px 4px" }}>Game</div>
                {gameMenuItems.map((item) => (
                  <button
                    key={item.label}
                    onClick={item.onClick}
                    style={{ width: "100%", display: "flex", alignItems: "center", gap: "16px", background: "none", border: "none", borderBottom: "1px solid rgba(255,255,255,0.05)", color: "#e5e2e1", fontSize: "16px", fontWeight: 600, padding: "18px 12px", cursor: "pointer", textAlign: "left", minHeight: "44px" }}
                  >
                    {item.icon} {item.label}
                  </button>
                ))}
                <div style={{ fontSize: "11px", color: "#a5b8a9", letterSpacing: "1px", textTransform: "uppercase", padding: "12px 12px 4px" }}>Account</div>
              </>
            )}
            {avatarMenuItems.map((item) => (
              <button
                key={item.label}
                onClick={item.onClick}
                style={{ width: "100%", display: "flex", alignItems: "center", gap: "16px", background: "none", border: "none", borderBottom: "1px solid rgba(255,255,255,0.05)", color: "#e5e2e1", fontSize: "16px", fontWeight: 600, padding: "18px 12px", cursor: "pointer", textAlign: "left", minHeight: "44px" }}
              >
                {item.icon} {item.label}
              </button>
            ))}
          </div>
        </div>
      )}

      <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
        {/* Left Sidebar (desktop only — mobile uses the bottom tab bar instead) */}
        {!isMobile && (
        <div style={{ width: sidebarOpen ? "240px" : "80px", transition: "width 0.2s ease", background: "#13261a", borderRight: "1px solid rgba(255,255,255,0.05)", display: "flex", flexDirection: "column", padding: "24px 0", flexShrink: 0 }}>
          <div style={{ padding: sidebarOpen ? "0 24px" : "0", marginBottom: "32px", display: "flex", justifyContent: sidebarOpen ? "space-between" : "center", alignItems: "flex-start" }}>
            {sidebarOpen ? (
              <>
                <div>
                  <div style={{ fontSize: "22px", fontWeight: 700, color: "#e9c349", fontFamily: "Manrope, sans-serif" }}>{activeProfile?.name || "Player"}</div>
                  <div style={{ fontSize: "12px", color: "#a5b8a9", fontFamily: "JetBrains Mono, monospace", marginTop: "4px" }}>Level {overallLevel.level} - {overallLevelTitle}</div>
                </div>
                <button onClick={() => setSidebarOpen(false)} style={{ background: "none", border: "none", color: "#a5b8a9", cursor: "pointer", padding: "4px", marginTop: "2px" }}>
                  <PanelLeftClose size={20} />
                </button>
              </>
            ) : (
              <button onClick={() => setSidebarOpen(true)} style={{ background: "none", border: "none", color: "#a5b8a9", cursor: "pointer", padding: "4px", marginTop: "2px" }}>
                <PanelLeftOpen size={20} />
              </button>
            )}
          </div>
          
          <div style={{ display: "flex", flexDirection: "column", gap: "4px", padding: sidebarOpen ? "0" : "0 8px" }}>
            <button onClick={() => onTabChange("gameboard")} style={{ display: "flex", alignItems: "center", gap: "12px", padding: sidebarOpen ? "12px 24px" : "12px", justifyContent: sidebarOpen ? "flex-start" : "center", background: activeTab === "gameboard" ? "#1e3a2b" : "transparent", border: "none", color: activeTab === "gameboard" ? "#e9c349" : "#a5b8a9", fontSize: "14px", fontWeight: 600, cursor: "pointer", borderRadius: sidebarOpen ? "0" : "8px" }}>
              <LayoutGrid size={18} color={activeTab === "gameboard" ? "#e9c349" : "#a5b8a9"} /> {sidebarOpen && "Gameboard"}
            </button>
            <button onClick={() => onTabChange("store")} style={{ display: "flex", alignItems: "center", gap: "12px", padding: sidebarOpen ? "12px 24px" : "12px", justifyContent: sidebarOpen ? "flex-start" : "center", background: activeTab === "store" ? "#1e3a2b" : "transparent", border: "none", color: activeTab === "store" ? "#e9c349" : "#a5b8a9", fontSize: "14px", fontWeight: 600, cursor: "pointer", borderRadius: sidebarOpen ? "0" : "8px" }}>
              <Store size={18} color={activeTab === "store" ? "#e9c349" : "#a5b8a9"} /> {sidebarOpen && "The Emporium"}
            </button>
            {sidebarOpen && activeTab === "store" && (
              <div style={{ display: "flex", flexDirection: "column", paddingLeft: "48px", paddingRight: "24px", gap: "8px", marginTop: "4px", marginBottom: "8px" }}>
                <div style={{ fontSize: "10px", color: "rgba(165,184,169,0.5)", letterSpacing: "1px", marginBottom: "4px" }}>CATEGORIES</div>
                {STORE_CATEGORIES.map(cat => (
                  <button
                    key={cat.id}
                    onClick={() => setStoreCategory(cat.id)}
                    style={{
                      background: storeCategory === cat.id ? "rgba(233,195,73,0.1)" : "transparent",
                      border: "none",
                      color: storeCategory === cat.id ? "#e9c349" : "#a5b8a9",
                      fontSize: "12px",
                      fontWeight: 600,
                      textAlign: "left",
                      padding: "8px 12px",
                      borderRadius: "6px",
                      cursor: "pointer",
                      width: "100%",
                      transition: "all 0.2s"
                    }}
                  >
                    {cat.label}
                  </button>
                ))}
              </div>
            )}
            <button onClick={() => onTabChange("trophy")} style={{ display: "flex", alignItems: "center", gap: "12px", padding: sidebarOpen ? "12px 24px" : "12px", justifyContent: sidebarOpen ? "flex-start" : "center", background: activeTab === "trophy" ? "#1e3a2b" : "transparent", border: "none", color: activeTab === "trophy" ? "#e9c349" : "#a5b8a9", fontSize: "14px", fontWeight: 600, cursor: "pointer", borderRadius: sidebarOpen ? "0" : "8px" }}>
              <Trophy size={18} color={activeTab === "trophy" ? "#e9c349" : "#a5b8a9"} /> {sidebarOpen && "Trophy Room"}
            </button>
            <button onClick={() => onTabChange("settings")} style={{ display: "flex", alignItems: "center", gap: "12px", padding: sidebarOpen ? "12px 24px" : "12px", justifyContent: sidebarOpen ? "flex-start" : "center", background: activeTab === "settings" ? "#1e3a2b" : "transparent", border: "none", color: activeTab === "settings" ? "#e9c349" : "#a5b8a9", fontSize: "14px", fontWeight: 600, cursor: "pointer", borderRadius: sidebarOpen ? "0" : "8px" }}>
              <SettingsIcon size={18} color={activeTab === "settings" ? "#e9c349" : "#a5b8a9"} /> {sidebarOpen && "Settings"}
            </button>
          </div>
        </div>
        )}

        {/* Main Content Area */}
        <div style={{ flex: 1, position: "relative", background: "radial-gradient(circle at 50% 0%, #1e3a2b, #0d1a13)", overflowY: "auto" }}>

          {isMobile && activeTab === "store" && (
            <div style={{ display: "flex", gap: "8px", overflowX: "auto", padding: "12px", position: "sticky", top: 0, background: "rgba(10,20,15,0.9)", backdropFilter: "blur(8px)", zIndex: 10, borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
              {STORE_CATEGORIES.map((cat) => (
                <button
                  key={cat.id}
                  onClick={() => setStoreCategory(cat.id)}
                  style={{
                    flexShrink: 0, whiteSpace: "nowrap", background: storeCategory === cat.id ? "rgba(233,195,73,0.15)" : "rgba(255,255,255,0.05)",
                    border: storeCategory === cat.id ? "1px solid #e9c349" : "1px solid transparent",
                    color: storeCategory === cat.id ? "#e9c349" : "#a5b8a9", fontSize: "12px", fontWeight: 700,
                    padding: "10px 16px", borderRadius: "999px", cursor: "pointer", minHeight: "44px",
                  }}
                >
                  {cat.label}
                </button>
              ))}
            </div>
          )}

          <div style={{ display: activeTab === "gameboard" ? "block" : "none", width: "100%", height: "100%", overflow: "hidden" }}>
            {children}
          </div>

          {activeTab === "trophy" && (
            <div style={{ maxWidth: "1100px", margin: "0 auto", padding: "48px 48px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "24px" }}>
                <div>
                  <h2 style={{ margin: 0, fontSize: "28px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "2px", textTransform: "uppercase" }}>Trophy Room</h2>
                  <p style={{ margin: "8px 0 0 0", fontSize: "16px", color: "#a5b8a9" }}>Your legacy of triumph and skill.</p>
                </div>
                <div style={{ background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "16px", width: "240px" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: "8px", fontSize: "12px", color: "#e5e2e1", fontFamily: "JetBrains Mono, monospace" }}>
                    <span>Completion</span>
                    <span style={{ color: "#e9c349" }}>{progressPercent}%</span>
                  </div>
                  <div style={{ width: "100%", height: "6px", background: "rgba(255,255,255,0.1)", borderRadius: "3px", overflow: "hidden" }}>
                    <div style={{ width: `${progressPercent}%`, height: "100%", background: "#e9c349" }} />
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", gap: "4px", marginBottom: "32px", background: "rgba(0,0,0,0.3)", padding: "4px", borderRadius: "8px", width: "fit-content" }}>
                {([{ id: "overview", label: "Overview" }, { id: "stats", label: "Detailed Stats" }] as const).map((t) => (
                  <button
                    key={t.id}
                    onClick={() => setTrophySubTab(t.id)}
                    style={{
                      padding: "8px 20px", borderRadius: "6px", border: "none", cursor: "pointer",
                      fontSize: "13px", fontWeight: 600, fontFamily: "Manrope, sans-serif",
                      background: trophySubTab === t.id ? "#1e3a2b" : "transparent",
                      color: trophySubTab === t.id ? "#e9c349" : "#a5b8a9",
                    }}
                  >
                    {t.label}
                  </button>
                ))}
              </div>

              {trophySubTab === "overview" && <DashboardOverview />}

              {trophySubTab === "stats" && (
                <div style={{ background: "#0f1c15", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", overflow: "hidden" }}>
                  <div style={{ overflowX: "auto" }}>
                    <table style={{ width: "100%", borderCollapse: "collapse", fontSize: "13px" }}>
                      <thead>
                        <tr style={{ background: "rgba(255,255,255,0.03)", textAlign: "left" }}>
                          {["Game", "Played", "Won", "Win %", "Streak", "Best Streak", "Best Time", "Fewest Moves"].map((h) => (
                            <th key={h} style={{ padding: "12px 16px", color: "rgba(255,255,255,0.5)", fontWeight: 600, whiteSpace: "nowrap" }}>{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody>
                        {GAME_TYPE_NAMES.map((gameType) => {
                          const s = statsByGameType[gameType];
                          const played = s?.gamesPlayed ?? 0;
                          const won = s?.gamesWon ?? 0;
                          const winPct = played > 0 ? Math.round((won / played) * 100) : 0;
                          const bestTime = s?.bestTimeMs != null ? formatDuration(s.bestTimeMs) : "—";
                          const fewestMoves = s?.fewestMoves ?? "—";
                          return (
                            <tr key={gameType} style={{ borderTop: "1px solid rgba(255,255,255,0.05)" }}>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1", fontWeight: 600 }}>{gameType}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{played}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{won}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{winPct}%</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{s?.currentStreak ?? 0}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{s?.bestStreak ?? 0}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1", fontFamily: "JetBrains Mono, monospace" }}>{bestTime}</td>
                              <td style={{ padding: "10px 16px", color: "#e5e2e1" }}>{fewestMoves}</td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === "store" && previewThemePackId && (
            <ThemePackDetailPage
              packId={previewThemePackId}
              onBack={() => setPreviewThemePackId(null)}
              onPurchase={handlePurchase}
            />
          )}

          {activeTab === "store" && !previewThemePackId && (
            <div style={{ maxWidth: "1000px", margin: "0 auto", padding: "48px 48px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px" }}>
                <div>
                  <h2 style={{ margin: 0, fontSize: "28px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "2px", textTransform: "uppercase" }}>The Emporium</h2>
                  <p style={{ margin: "8px 0 0 0", fontSize: "16px", color: "#a5b8a9" }}>Customize your game experience.</p>
                </div>
                <div style={{ background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "16px", display: "flex", alignItems: "center", gap: "12px" }}>
                  <Coins size={24} color="#ffd700" />
                  <div>
                    <div style={{ fontSize: "12px", color: "#a5b8a9", fontFamily: "JetBrains Mono, monospace" }}>Balance</div>
                    <div style={{ fontSize: "20px", fontWeight: 800, color: "#ffd700" }}>{coins} Coins</div>
                  </div>
                </div>
              </div>

              <div style={{ display: "flex", flexDirection: "column", gap: "64px" }}>
                {(() => {
                  const items = STORE_ITEMS.filter(i => i.type === storeCategory);
                  if (items.length === 0) return (
                    <div style={{ textAlign: "center", padding: "64px", color: "rgba(255,255,255,0.5)" }}>
                      Coming soon...
                    </div>
                  );
                  
                  const categoryNames: Record<string, string> = {
                    'card_back': 'CARD BACKS',
                    'theme': 'THEMES',
                    'theme_pack': 'THEME PACKS',
                    'power_up': 'POWER UPS',
                    'victory': 'ANIMATIONS'
                  };

                  return (
                    <div key={storeCategory}>
                      <div style={{ display: "flex", alignItems: "center", gap: "24px", marginBottom: "32px", opacity: 0.9 }}>
                        <div style={{ flex: 1, height: "1px", background: "linear-gradient(to right, transparent, rgba(233,195,73,0.4))" }}></div>
                        <h3 style={{ margin: 0, fontSize: "20px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "4px", fontWeight: 600 }}>{categoryNames[storeCategory]}</h3>
                        <div style={{ flex: 1, height: "1px", background: "linear-gradient(to left, transparent, rgba(233,195,73,0.4))" }}></div>
                      </div>

                      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "24px" }}>
                        {items.map(item => {
                          const isPowerUp = item.type === "power_up";
                          const owned = powerUpInventory[item.id] ?? 0;
                          const unlocked = unlockedItems.includes(item.id) || item.price === 0;
                          const equipped = isEquipped(item);
                          const canAfford = coins >= item.price;
                          const disabled = isPowerUp ? !canAfford : (!unlocked && !canAfford);

                          const isThemePack = item.type === "theme_pack";

                          return (
                            <div
                              key={item.id}
                              onClick={isThemePack ? () => setPreviewThemePackId(item.id) : undefined}
                              style={{ background: "rgba(10, 20, 15, 0.6)", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "16px", padding: "16px", display: "flex", flexDirection: "column", alignItems: "center", position: "relative", cursor: isThemePack ? "pointer" : "default" }}
                            >
                              {isPowerUp && owned > 0 && (
                                <div style={{ position: "absolute", top: "12px", right: "12px", background: "#d4af37", color: "#111", fontWeight: 800, fontSize: "12px", borderRadius: "999px", padding: "2px 9px", zIndex: 1 }}>
                                  ×{owned}
                                </div>
                              )}
                              {isThemePack && (
                                <div style={{ position: "absolute", top: "12px", left: "12px", display: "flex", alignItems: "center", gap: "4px", background: "rgba(0,0,0,0.6)", color: "#e9c349", fontWeight: 700, fontSize: "11px", borderRadius: "999px", padding: "3px 9px", zIndex: 1, border: "1px solid rgba(233,195,73,0.3)" }}>
                                  <Eye size={12} /> Preview
                                </div>
                              )}
                              <div style={{ width: "100%", display: "flex", justifyContent: "center", marginBottom: "24px" }}>
                                {item.icon ? (
                                  <img src={item.icon} alt={item.name} style={{ width: "100%", aspectRatio: "5/7", objectFit: "cover", borderRadius: "10px", boxShadow: "0 8px 32px rgba(0,0,0,0.6)" }} />
                                ) : (
                                  <div style={{ width: "100%", aspectRatio: "5/7", background: "rgba(255,255,255,0.05)", borderRadius: "10px", display: "flex", alignItems: "center", justifyContent: "center", border: "1px dashed rgba(255,255,255,0.1)" }}>
                                    <span style={{ color: "rgba(255,255,255,0.2)", fontSize: "12px", textTransform: "uppercase" }}>{item.type.replace('_', ' ')}</span>
                                  </div>
                                )}
                              </div>

                              <div style={{ textAlign: "center", marginBottom: "24px", minHeight: "60px", width: "100%", padding: "0 8px" }}>
                                <h3 style={{ margin: "0 0 8px 0", fontSize: "20px", color: "#fff", fontWeight: 600, fontFamily: "Manrope, sans-serif" }}>{item.name}</h3>
                                <p style={{ margin: 0, fontSize: "13px", color: "#a5b8a9", lineHeight: "1.4" }}>{item.description || `Enhance your game with the elegant ${item.name} design.`}</p>
                              </div>

                              <div style={{ width: "100%" }}>
                                <button
                                  onClick={(e) => { e.stopPropagation(); handlePurchase(item); }}
                                  disabled={disabled}
                                  style={{
                                    width: "100%", padding: "14px", borderRadius: "8px", border: "none", fontWeight: 700, fontSize: "13px", letterSpacing: "1.5px", textTransform: "uppercase", cursor: disabled ? "not-allowed" : "pointer", transition: "all 0.2s", display: "flex", alignItems: "center", justifyContent: "center", gap: "8px",
                                    background: equipped ? "rgba(212, 175, 55, 0.1)" : (isPowerUp ? canAfford : unlocked || canAfford) ? "rgba(50, 65, 40, 0.8)" : "transparent",
                                    color: equipped ? "#d4af37" : (isPowerUp ? canAfford : unlocked || canAfford) ? "#e9c349" : "rgba(255,255,255,0.3)",
                                    borderWidth: "1px", borderStyle: "solid",
                                    borderColor: equipped ? "#d4af37" : (isPowerUp ? canAfford : unlocked || canAfford) ? "rgba(100, 120, 80, 0.5)" : "rgba(255,255,255,0.1)"
                                  }}
                                >
                                  {isPowerUp ? (
                                    <>{owned > 0 ? "Buy Another" : "Buy"} · {item.price} <Coins size={16} /></>
                                  ) : equipped ? "Equipped" : unlocked ? "Equip" : (
                                    <>
                                      {item.price} <Coins size={16} />
                                    </>
                                  )}
                                </button>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  );
                })()}
              </div>
            </div>
          )}

          {activeTab === "settings" && <SettingsPage gameTypeCode={gameTypeCode} />}
        </div>
      </div>

      {/* Bottom Tab Bar (mobile only — hidden during landscape gameplay to maximize board space) */}
      {isMobile && !hideBottomChromeForLandscapeGameplay && (
        <div style={{ display: "flex", flexShrink: 0, background: "#111111", borderTop: "1px solid rgba(255,255,255,0.08)", paddingBottom: "env(safe-area-inset-bottom)" }}>
          {([
            { id: "gameboard" as const, label: "Gameboard", Icon: LayoutGrid },
            { id: "store" as const, label: "Emporium", Icon: Store },
            { id: "trophy" as const, label: "Trophies", Icon: Trophy },
            { id: "settings" as const, label: "Settings", Icon: SettingsIcon },
          ]).map(({ id, label, Icon }) => {
            const active = activeTab === id;
            return (
              <button
                key={id}
                onClick={() => onTabChange(id)}
                style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: active ? "#e9c349" : "#a5b8a9", padding: "10px 4px", cursor: "pointer", minHeight: "56px" }}
              >
                <Icon size={22} color={active ? "#e9c349" : "#a5b8a9"} />
                <span style={{ fontSize: "11px", fontWeight: 600 }}>{label}</span>
              </button>
            );
          })}
        </div>
      )}
    </div>
  );
};
