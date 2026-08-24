import React, { useEffect, useState } from "react";
import { Trophy, Store, Settings as SettingsIcon, ArrowLeft, LayoutGrid, Coins, PanelLeftClose, PanelLeftOpen, Info, Eye, Users, X, Menu, Clock, RotateCw, HelpCircle } from "lucide-react";
import { GraphicPlusIcon, GraphicKeyIcon, GraphicHintIcon, GraphicUndoIcon, GraphicStoreIcon, GraphicTrophyIcon, GraphicSettingsIcon, GraphicHomeIcon } from "./GraphicIcons";
import { useViewport } from "../hooks/useViewport";
import { useUIStore } from "../store/uiStore";
import { useProfileStore } from "../store/profileStore";
import { useStatisticsStore } from "../store/statisticsStore";
import { GAME_TYPE_NAMES } from "../data/gameTypes";
import achievementsData from "../data/achievements.json";
import { DashboardOverview } from "./DashboardOverview";
import { getLevelTitle, getLevelTitleDescription, getGlobalLevel, xpRequiredForLevel } from "../utils/levelTitles";
import { getAvatarOption } from "../data/avatars";
import { getGamePortrait } from "../data/gamePortraits";
import { applyThemePack } from "../theme/presets";
import { STORE_ITEMS } from "../data/storeItems";
import { atlasSpritePercent } from "./CardWidget";
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

// "Choose Your Game" is omitted — it's redundant with the fixed header title above it.
const CHOOSER_SUBTITLES = [
  "Deal Me In",
  "Pick Your Challenge",
  "Choose Your Hand",
  "Select Your Solitaire",
  "How Will You Play?",
  "Choose Your Battle",
  "Pick a Game to Play",
  "Choose Your Table",
  "What'll It Be?",
  "Deal the Cards",
  "Choose Your Adventure",
  "The Cards Await",
  "Your Move Begins Here",
  "Choose Your Fate",
  "Take Your Seat",
  "Pick Your Poison",
  "Name Your Game",
  "Let the Cards Decide",
  "Step Up to the Table",
  "The Cards Are Waiting",
  "What Will You Dare?",
  "What Lies in the Deck?",
  "The Table Awaits",
  "Which Hand Calls You?",
  "Let Fate Deal",
  "Enter the Game",
  "The Deck Has Chosen",
  "Your Fate Awaits",
  "Draw Your Destiny",
  "What Will the Cards Reveal?",
  "The Cards Know",
  "Fate Is in Your Hands",
  "Whisper to the Deck",
  "The First Move Is Yours",
  "There Is a Game to Be Played",
  "Choose What Awaits",
  "The Deck Remembers",
  "Turn the First Card",
  "See What Fate Deals",
  "What Will You Play?",
  "What Awaits You?",
  "Which Game Calls?",
  "What Will Fate Deal?",
  "Which Hand Will You Choose?",
  "What's Your Fortune?",
  "Where Will the Cards Lead?",
  "Which Secret Will You Uncover?",
  "What Lies Beneath?",
  "Shall We Deal?",
  "Care to Tempt Fate?",
  "Ready to See What Awaits?",
  "Come. The Cards Are Waiting.",
  "Let's See What Fate Has Dealt.",
  "The Next Hand Is Yours.",
  "Something Awaits in the Deck.",
  "Fate Has Left You a Hand.",
  "Go On. Choose a Game.",
  "The Deck Is Calling.",
  "There's More Than One Way to Play.",
  "Your Next Game Awaits.",
  "Turn the Cards. Discover What Awaits.",
  "Where Shall We Begin?",
  "What Shall We Play?",
  "Which Will It Be?",
  "Make Your Choice",
  "The Choice Is Yours",
  "Find Your Game",
  "Take Your Pick",
  "Set the Cards in Motion",
  "Begin Somewhere",
  "Let's Begin",
  "A Game Awaits",
  "Something Different?",
  "In the Mood for…",
  "What Tempts You?",
  "What Catches Your Eye?",
  "Which One Will You Try?",
  "Which one has your attention?",
  "Which one will you choose?",
  "What shall it be?",
  "Which one tempts you?",
  "What catches your eye?",
  "What are you in the mood for?",
  "Which one calls to you?",
  "What looks interesting?",
  "Shall we see?",
  "What will you try?",
  "Which one feels right?",
  "What will it be tonight?",
  "Care to choose?",
  "Something catch your eye?",
  "Which one is yours?",
  "What have you got in mind?",
  "Shall we play?",
  "Ready for something different?",
  "What are you drawn to?",
  "Go on. Pick one.",
  "Indulge your curiosity.",
  "Follow your inclination.",
  "Trust your instincts.",
  "See where it leads.",
  "Follow your fancy.",
  "Choose what intrigues you.",
  "Let curiosity decide.",
  "Make it interesting.",
  "Surprise yourself.",
  "What shall it be? Choose what awaits.",
];

const STORE_CATEGORIES = [
  { id: "card_back", label: "CARD BACKS" },
  { id: "card_deck", label: "CARD DECKS" },
  { id: "theme", label: "THEMES" },
  { id: "theme_pack", label: "THEME PACKS" },
  { id: "power_up", label: "POWER UPS" },
  { id: "victory", label: "ANIMATIONS" },
];

export const MetaGameHub: React.FC<MetaGameHubProps> = ({ activeTab, onTabChange, onOpenAbout, gameTypeCode, leftHeaderContent, rightHeaderContent, activeGameName, children, mobileGameHud }) => {
  const { coins, subtractCoins, unlockedItems, unlockItem, cardBackPattern, setCardBackPattern, cardFaceSetId, setCardFaceSetId, themeId, setThemeId, setSfxSetId, setMusicTrackId, unlockedAchievements, powerUpInventory, purchasePowerUp, gameProgress } = useUIStore();
  const { profiles, activeProfileId } = useProfileStore();
  const { statsByGameType, loadAllStats } = useStatisticsStore();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isAvatarMenuOpen, setIsAvatarMenuOpen] = useState(false);
  const [storeCategory, setStoreCategory] = useState("card_back");
  const [trophySubTab, setTrophySubTab] = useState<"overview" | "stats">("overview");
  const [previewThemePackId, setPreviewThemePackId] = useState<string | null>(null);
  const [chooserSubtitle] = useState(() => CHOOSER_SUBTITLES[Math.floor(Math.random() * CHOOSER_SUBTITLES.length)]);
  const { isMobile, isLandscape } = useViewport();

  const goToDashboard = () => {
    onTabChange("trophy");
    setTrophySubTab("overview");
    setIsAvatarMenuOpen(false);
  };

  const activeProfile = profiles.find(p => p.id === activeProfileId) || profiles[0];
  const activeAvatar = getAvatarOption(activeProfile?.avatarId ?? "");
  const activeGamePortrait = gameTypeCode !== undefined ? getGamePortrait(gameTypeCode) : undefined;
  // Global, game-agnostic: pools XP earned across every variant into one account-wide level/title.
  const globalLevel = getGlobalLevel(gameProgress);
  const globalLevelTitle = getLevelTitle(globalLevel.level);
  // Per-game: the level pill shown during an active game reflects that specific variant's own progress.
  const activeGameProgress = gameTypeCode !== undefined ? (gameProgress[String(gameTypeCode)] ?? { level: 1, xp: 0 }) : undefined;
  const isChooserActive = activeTab === "gameboard" && gameTypeCode === undefined;

  useEffect(() => {
    if (activeTab === "trophy") loadAllStats();
  }, [activeTab, activeProfileId, loadAllStats]);

  // --- Store Handlers ---
  const equipItem = (item: any) => {
    if (item.type === "card_back") setCardBackPattern(item.id);
    // A card deck bundles matching face art + back art together.
    if (item.type === "card_deck") {
      setCardFaceSetId(item.cardFaceSetId ?? item.id);
      setCardBackPattern(item.cardBackPatternId ?? item.id);
    }
    // Theme packs bundle a coordinated card face/back/SFX/music with the
    // theme, fanned out by applyThemePack; plain themes just set the color
    // scheme.
    if (item.type === "theme" || item.type === "theme_pack") {
      applyThemePack(item.id, { setThemeId, setCardBackPattern, setCardFaceSetId, setSfxSetId, setMusicTrackId });
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
    if (item.type === "card_deck" && cardFaceSetId === (item.cardFaceSetId ?? item.id)) return true;
    if ((item.type === "theme" || item.type === "theme_pack") && themeId === item.id) return true;
    return false;
  };

  // --- Trophy Handlers ---
  const totalEarned = unlockedAchievements.length;
  const totalAvailable = achievementsData.achievements.length;
  const progressPercent = Math.round((totalEarned / totalAvailable) * 100) || 0;

  const avatarMenuItems = [
    ...(isMobile ? [{ label: "Switch Profile", icon: <Users size={isMobile ? 20 : 15} />, onClick: goToDashboard }] : []),
    { label: "Dashboard", icon: <GraphicTrophyIcon size={isMobile ? 20 : 16} />, onClick: goToDashboard },
    { label: "Settings", icon: <GraphicSettingsIcon size={isMobile ? 20 : 16} />, onClick: () => { onTabChange("settings"); setIsAvatarMenuOpen(false); } },
    { label: "About", icon: <Info size={isMobile ? 20 : 15} />, onClick: () => { onOpenAbout(); setIsAvatarMenuOpen(false); } },
  ];

  const gameMenuItems = mobileGameHud ? [
    { label: "New Game", icon: <GraphicPlusIcon size={20} />, onClick: () => { mobileGameHud.onNewGame(); setIsAvatarMenuOpen(false); } },
    { label: "Help", icon: <HelpCircle size={20} />, onClick: () => { mobileGameHud.onOpenHelp(); setIsAvatarMenuOpen(false); } },
  ] : [];

  return (
    <div style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "#0a120d", zIndex: 1000, display: "flex", flexDirection: "column", fontFamily: "Inter, sans-serif" }}>

      {/* Top Header */}
      {!isMobile ? (
        <div style={{ height: "108px", flexShrink: 0, position: "relative", zIndex: 3000, background: "linear-gradient(180deg, #142419 0%, #0a140d 100%)", borderBottom: "1px solid rgba(212, 175, 55, 0.3)", display: "flex", alignItems: isChooserActive ? "center" : "flex-start", justifyContent: "space-between", padding: isChooserActive ? "0 28px" : "18px 28px 0", boxShadow: "0 4px 24px rgba(0,0,0,0.6)" }}>
          <div style={{ flex: 1, display: "flex", alignItems: "center", gap: "16px" }}>
            {activeTab !== "gameboard" ? (
              <button onClick={() => onTabChange("gameboard")} style={{ display: "flex", alignItems: "center", gap: "8px", background: "none", border: "none", color: "#e9c349", fontSize: "16px", fontWeight: 600, cursor: "pointer", padding: "8px", marginLeft: "-8px" }}>
                <ArrowLeft size={20} /> Back
              </button>
            ) : (
              <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
                <div style={{ width: "44px", height: "44px", borderRadius: "50%", overflow: "hidden", border: `2px solid ${activeAvatar.ringColor || "#d4af37"}`, boxShadow: "0 2px 8px rgba(0,0,0,0.5)", flexShrink: 0 }}>
                  <img src={activeAvatar.src} alt={activeAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                </div>
                <div style={{ display: "flex", flexDirection: "column", gap: "4px" }}>
                  <span style={{ fontSize: "16px", fontWeight: 800, color: "#fff", fontFamily: "Inter, sans-serif" }}>{activeProfile?.name || "Chip"}</span>
                  <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
                    <span style={{ fontSize: "15px", fontWeight: 800, color: "#e9c349", fontFamily: "Inter, sans-serif", flexShrink: 0 }}>{globalLevelTitle}</span>
                    <span style={{ fontSize: "13px", color: "rgba(255,255,255,0.35)", flexShrink: 0 }}>•</span>
                    <span style={{ fontSize: "11px", fontStyle: "italic", color: "rgba(255,255,255,0.6)", fontFamily: "Inter, sans-serif", lineHeight: 1.35, maxWidth: "220px" }}>{getLevelTitleDescription(globalLevel.level)}</span>
                  </div>
                </div>
                {/* Straddles the header/felt seam: anchored to the header (which is position:relative), not the flex column above.
                    Level progress is tracked per game variant, not globally, so it's meaningless on the chooser screen — only show it inside an active game. */}
                {activeGameName && activeGameProgress && (
                  <div style={{ position: "absolute", left: "28px", bottom: "-26px", display: "flex", flexDirection: "column", gap: "7px", background: "rgba(10, 20, 15, 0.9)", border: "1px solid rgba(212, 175, 55, 0.35)", borderRadius: "14px", padding: "9px 16px", minWidth: "270px", boxShadow: "0 4px 12px rgba(0,0,0,0.5)" }}>
                    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: "14px" }}>
                      <span style={{ fontSize: "11px", fontWeight: 800, color: "#e9c349", fontFamily: "JetBrains Mono, monospace", whiteSpace: "nowrap" }}>LVL {activeGameProgress.level}</span>
                      <span style={{ fontSize: "10px", color: "rgba(255,255,255,0.7)", fontFamily: "Inter, sans-serif", whiteSpace: "nowrap" }}>Next Unlocks: Gold Card Frame at Level 5</span>
                    </div>
                    <div style={{ width: "100%", height: "10px", background: "rgba(255,255,255,0.1)", borderRadius: "5px", overflow: "hidden" }}>
                      <div style={{ width: `${Math.min(100, Math.floor((activeGameProgress.xp / xpRequiredForLevel(activeGameProgress.level)) * 100))}%`, height: "100%", background: "linear-gradient(90deg, #2e7d32, #4caf50)" }} />
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
          <div style={{ flex: "3 1 0%", display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", minWidth: 0 }}>
            <div style={{ fontSize: "28px", fontWeight: 800, color: "#e9c349", fontFamily: "'Cinzel', 'Playfair Display', 'Georgia', serif", letterSpacing: "1.5px", textShadow: "0 2px 8px rgba(0,0,0,0.8)", whiteSpace: "nowrap", overflow: "visible" }}>
              {activeTab === "gameboard" && activeGameName ? `SOLITUDE: ${activeGameName.toUpperCase()}` : "SOLITUDE"}
            </div>
            {activeTab === "gameboard" && !activeGameName && (
              <div style={{ fontSize: "20px", color: "rgba(255,255,255,0.65)", fontFamily: "Inter, sans-serif" }}>{chooserSubtitle}</div>
            )}
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: "16px", flex: 1, justifyContent: "flex-end" }}>
            {rightHeaderContent}
          </div>
          {leftHeaderContent}
        </div>
      ) : (
        <div style={{ flexShrink: 0, background: "radial-gradient(circle at 50% 0%, #1e3a2b, #0d1a13)", borderBottom: "1px solid rgba(0,0,0,0.3)", paddingTop: "env(safe-area-inset-top)" }}>
          {/* Row 1: exit/back, title, menu */}
          <div style={{ height: isLandscape ? "44px" : "52px", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 12px" }}>
            <div style={{ width: "36px" }}>
              {mobileGameHud ? (
                <button onClick={mobileGameHud.onExitGame} style={{ background: "none", border: "none", cursor: "pointer", padding: "4px", display: "flex" }} title="Exit to Menu">
                  <GraphicHomeIcon size={isLandscape ? 22 : 26} />
                </button>
              ) : activeTab !== "gameboard" ? (
                <button onClick={() => onTabChange("gameboard")} style={{ background: "none", border: "none", cursor: "pointer", padding: "4px", display: "flex" }} title="Back to Game">
                  <GraphicHomeIcon size={isLandscape ? 22 : 26} />
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
            <div style={{ padding: "0 12px 24px" }}>
              <div style={{ position: "relative", display: "flex", alignItems: "center", gap: "10px", background: "rgba(0,0,0,0.35)", borderRadius: "999px", height: "26px", marginTop: "16px", padding: "0 14px", border: "1px solid rgba(255,255,255,0.08)" }}>
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

                {/* Avatar is centered on the pill itself (not the flex flow) so its
                    position doesn't drift with the left/right groups' widths. */}
                <div style={{ position: "absolute", left: "50%", top: "50%", transform: "translate(-50%, -50%)", width: "56px", height: "56px", borderRadius: "50%", overflow: "hidden", border: "2px solid rgba(255,255,255,0.85)", boxShadow: "0 2px 6px rgba(0,0,0,0.4)" }}>
                  <img src={activeAvatar.src} alt={activeAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover", display: "block" }} />
                </div>

                <div style={{ display: "flex", alignItems: "center", gap: "14px", flexShrink: 0, marginLeft: "auto" }}>
                  {mobileGameHud && (
                    <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#fff", fontSize: "13px", fontFamily: "JetBrains Mono, monospace" }}>
                      <RotateCw size={14} color="#fff" /> {mobileGameHud.moveCount}
                    </div>
                  )}
                  <div style={{ display: "flex", alignItems: "center", gap: "4px", color: "#fff", fontSize: "13px", fontWeight: 700, fontFamily: "JetBrains Mono, monospace" }}>
                    <Coins size={14} color="#e9c349" /> {coins}
                  </div>
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
        <div style={{ width: sidebarOpen ? "240px" : "80px", transition: "width 0.2s ease", background: "#13261a", borderRight: "1px solid rgba(255,255,255,0.05)", display: "flex", flexDirection: "column", padding: "44px 0 24px", flexShrink: 0 }}>
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

          <div style={{ flex: "1 1 auto", minHeight: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "flex-end", padding: sidebarOpen ? "16px 20px 4px" : "16px 8px 4px" }}>
            {activeGamePortrait && (
              <img
                src={activeGamePortrait}
                alt={activeGameName}
                style={{
                  width: sidebarOpen ? "160px" : "56px",
                  maxWidth: "100%",
                  maxHeight: "100%",
                  objectFit: "contain",
                  transition: "width 0.2s ease"
                }}
              />
            )}
          </div>
          <div style={{ borderTop: "1px solid rgba(255,255,255,0.05)", width: "100%", display: "flex", justifyContent: sidebarOpen ? "flex-end" : "center", padding: sidebarOpen ? "16px 24px 0" : "16px 8px 0", flexShrink: 0 }}>
            <button onClick={() => setSidebarOpen(!sidebarOpen)} title={sidebarOpen ? "Collapse sidebar" : "Expand sidebar"} style={{ background: "none", border: "none", color: "#a5b8a9", cursor: "pointer", padding: "4px", display: "flex" }}>
              {sidebarOpen ? <PanelLeftClose size={20} /> : <PanelLeftOpen size={20} />}
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
                    'card_deck': 'CARD DECKS',
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
                                {item.iconAtlas ? (
                                  <div style={{ width: "100%", aspectRatio: "5/7", borderRadius: "10px", boxShadow: "0 8px 32px rgba(0,0,0,0.6)", ...(atlasSpritePercent(item.iconAtlas.deckId, item.iconAtlas.code) ?? {}) }} />
                                ) : item.icon ? (
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

      {/* Bottom Tab Bar (mobile only) */}
      {isMobile && (
        <div style={{ display: "flex", flexShrink: 0, background: "#111111", borderTop: "1px solid rgba(255,255,255,0.12)", paddingBottom: "env(safe-area-inset-bottom)" }}>
          {/* 1. New (Gameboard / New Game) */}
          <button
            onClick={() => {
              onTabChange("gameboard");
              if (mobileGameHud) {
                mobileGameHud.onNewGame();
              }
            }}
            title="New Game"
            style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: activeTab === "gameboard" ? "#e9c349" : "#a5b8a9", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
          >
            <GraphicPlusIcon size={isLandscape ? 28 : 34} />
            <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>New</span>
          </button>

          {/* Gameplay controls (only shown when active game HUD is available) */}
          {mobileGameHud && (
            <>
              {/* 2. Solver */}
              <button
                onClick={mobileGameHud.onToggleAutoplay}
                title="Solver"
                style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: mobileGameHud.isAutoPlaying ? "rgba(233,195,73,0.15)" : "none", border: "none", color: mobileGameHud.isAutoPlaying ? "#e9c349" : "#a5b8a9", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
              >
                <GraphicKeyIcon size={isLandscape ? 28 : 34} />
                <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>{mobileGameHud.isAutoPlaying ? "Stop" : "Solver"}</span>
              </button>

              {/* 3. Hint */}
              <button
                onClick={mobileGameHud.onHint}
                title="Get hint"
                style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: "#e9c349", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
              >
                <GraphicHintIcon size={isLandscape ? 28 : 34} />
                <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>Hint</span>
              </button>

              {/* 4. Undo */}
              <button
                onClick={mobileGameHud.onUndo}
                title="Undo move"
                style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: "#a5b8a9", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
              >
                <GraphicUndoIcon size={isLandscape ? 28 : 34} />
                <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>Undo</span>
              </button>
            </>
          )}

          {/* 5. Emporium */}
          <button
            onClick={() => onTabChange("store")}
            style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: activeTab === "store" ? "#e9c349" : "#a5b8a9", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
          >
            <GraphicStoreIcon size={isLandscape ? 28 : 34} />
            <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>Emporium</span>
          </button>

          {/* 6. Trophies */}
          <button
            onClick={() => onTabChange("trophy")}
            style={{ flex: 1, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", gap: "4px", background: "none", border: "none", color: activeTab === "trophy" ? "#e9c349" : "#a5b8a9", padding: "8px 2px", cursor: "pointer", minHeight: isLandscape ? "56px" : "68px" }}
          >
            <GraphicTrophyIcon size={isLandscape ? 28 : 34} />
            <span style={{ fontSize: "12px", fontWeight: 600, letterSpacing: "0.2px" }}>Trophies</span>
          </button>
        </div>
      )}
    </div>
  );
};
