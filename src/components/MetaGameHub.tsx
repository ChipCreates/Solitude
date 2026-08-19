import React, { useEffect, useState } from "react";
import { Trophy, Store, Settings as SettingsIcon, ArrowLeft, LayoutGrid, Lock, Coins, PanelLeftClose, PanelLeftOpen, User } from "lucide-react";
import { useUIStore } from "../store/uiStore";
import { useProfileStore } from "../store/profileStore";
import { useStatisticsStore } from "../store/statisticsStore";
import { GAME_TYPE_NAMES } from "../data/gameTypes";
import achievementsData from "../data/achievements.json";
import { ProfileManagerModal } from "./ProfileManagerModal";

interface MetaGameHubProps {
  activeTab: "gameboard" | "store" | "trophy";
  onTabChange: (tab: "gameboard" | "store" | "trophy") => void;
  onOpenSettings: () => void;
  leftHeaderContent?: React.ReactNode;
  rightHeaderContent?: React.ReactNode;
  activeGameName?: string;
  children?: React.ReactNode;
}

function formatDuration(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const m = Math.floor(totalSeconds / 60);
  const s = totalSeconds % 60;
  return `${m}:${s.toString().padStart(2, "0")}`;
}

export const STORE_ITEMS = [
  { id: "bicycle", type: "card_back", name: "Bicycle Blue", price: 0 },
  { id: "diamond", type: "card_back", name: "Classic Diamond", price: 0 },
  { id: "botanical", type: "card_back", name: "Botanical Garden", price: 500, icon: "/assets/cards/back_botanical.png" },
  { id: "mystic", type: "card_back", name: "Mystic Aura", price: 500, icon: "/assets/cards/back_mystic.png" },
  { id: "filigree", type: "card_back", name: "Golden Filigree", price: 500, icon: "/assets/cards/back_filigree.png" },
  { id: "dragon", type: "card_back", name: "Dragon Ruby", price: 1000, icon: "/assets/cards/card_back_dragon_1787130558476.png" },
  { id: "celestial", type: "card_back", name: "Celestial Skies", price: 1000, icon: "/assets/cards/card_back_celestial_1787130567064.png" },
  { id: "classic_felt", type: "theme", name: "Casino Green", price: 0 },
  { id: "midnight_blue", type: "theme", name: "Midnight Blue", price: 300 },
  { id: "burgundy_velvet", type: "theme", name: "Burgundy Velvet", price: 300 },
  { id: "obsidian_glass", type: "theme", name: "Obsidian Glass", price: 800 },
  { id: "confetti", type: "victory", name: "Confetti Explosion", price: 400 },
  { id: "fireworks", type: "victory", name: "Golden Fireworks", price: 1000 },
  { id: "unstick_wand", type: "power_up", name: "Unstick Wand", description: "Forces one legal-but-blocked move to become available.", price: 300, icon: "/assets/store/item_unstick_wand_1787130506774.png" },
  { id: "peek_charm", type: "power_up", name: "Peek Charm", description: "Reveal one face-down card without flipping it into play.", price: 150, icon: "/assets/store/item_peek_charm_1787130514247.png" },
  { id: "deck_whisper", type: "power_up", name: "Deck Whisper", description: "Shows the next 3 cards coming from the stock pile.", price: 200, icon: "/assets/store/item_deck_whisper_1787130523895.png" },
  { id: "lucky_reshuffle", type: "power_up", name: "Lucky Reshuffle", description: "Reshuffles just the stock/waste pile without restarting.", price: 250, icon: "/assets/store/item_lucky_reshuffle_1787130533491.png" },
  { id: "undo_token", type: "power_up", name: "Undo Token", description: "Reverses your last move.", price: 100, icon: "/assets/store/item_undo_token_1787130542748.png" },
  { id: "column_breather", type: "power_up", name: "Column Breather", description: "Temporarily reveals the top 2 cards of one face-down column.", price: 350, icon: "/assets/store/item_column_breather_1787130550493.png" },
  { id: "extra_hint", type: "power_up", name: "Extra Hint", description: "Highlights one available legal move you haven't spotted.", price: 100, icon: "/assets/store/item_extra_hint_1787130597111.png" },
  { id: "second_look", type: "power_up", name: "Second Look", description: "Un-flips one card you already committed to.", price: 200, icon: "/assets/store/item_second_look_1787130604583.png" },
  { id: "foundation_nudge", type: "power_up", name: "Foundation Nudge", description: "Flags which card would unlock the most downstream moves.", price: 250, icon: "/assets/store/item_foundation_nudge_1787130612217.png" },
  { id: "time_ease", type: "power_up", name: "Time Ease", description: "Adds 60 seconds on timed modes.", price: 150, icon: "/assets/store/item_time_ease_1787130619507.png" },
  { id: "free_slot", type: "power_up", name: "Free Slot", description: "Temporarily opens an extra holding spot for one card.", price: 300, icon: "/assets/store/item_free_slot_1787130628168.png" },
  { id: "reset_column", type: "power_up", name: "Reset Column", description: "Restacks one fully-dead-end column into a fresh random order.", price: 400, icon: "/assets/store/item_lucky_reshuffle_1787130533491.png" },
];

export const MetaGameHub: React.FC<MetaGameHubProps> = ({ activeTab, onTabChange, onOpenSettings, leftHeaderContent, rightHeaderContent, activeGameName, children }) => {
  const { coins, subtractCoins, unlockedItems, unlockItem, cardBackPattern, setCardBackPattern, themeId, setThemeId, unlockedAchievements, powerUpInventory, purchasePowerUp } = useUIStore();
  const { profiles, activeProfileId } = useProfileStore();
  const { statsByGameType, loadAllStats } = useStatisticsStore();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isProfileManagerOpen, setIsProfileManagerOpen] = useState(false);
  const [storeCategory, setStoreCategory] = useState("card_back");

  const activeProfile = profiles.find(p => p.id === activeProfileId) || profiles[0];

  useEffect(() => {
    if (activeTab === "trophy") loadAllStats();
  }, [activeTab, activeProfileId, loadAllStats]);

  // --- Store Handlers ---
  const handlePurchase = (item: any) => {
    // Power-ups are consumable: every click buys another one (spending
    // coins), rather than a one-time unlock+equip like cosmetics.
    if (item.type === "power_up") {
      purchasePowerUp(item.id, item.price);
      return;
    }
    if (unlockedItems.includes(item.id) || item.price === 0) {
      if (item.type === "card_back") setCardBackPattern(item.id);
      if (item.type === "theme") setThemeId(item.id);
      return;
    }
    if (coins >= item.price) {
      if (subtractCoins(item.price)) {
        unlockItem(item.id);
        if (item.type === "card_back") setCardBackPattern(item.id);
        if (item.type === "theme") setThemeId(item.id);
      }
    }
  };

  const isEquipped = (item: any) => {
    if (item.type === "card_back" && cardBackPattern === item.id) return true;
    if (item.type === "theme" && themeId === item.id) return true;
    return false;
  };

  // --- Trophy Handlers ---
  const totalEarned = unlockedAchievements.length;
  const totalAvailable = achievementsData.achievements.length;
  const progressPercent = Math.round((totalEarned / totalAvailable) * 100) || 0;

  return (
    <div style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", background: "#0a120d", zIndex: 1000, display: "flex", flexDirection: "column", fontFamily: "Inter, sans-serif" }}>
      
      {/* Top Header */}
      <div style={{ height: "64px", background: "#111111", borderBottom: "1px solid rgba(255,255,255,0.05)", display: "flex", alignItems: "center", justifyContent: "space-between", padding: "0 24px" }}>
        <div style={{ flex: 1, display: "flex", alignItems: "center", gap: "16px" }}>
          {activeTab !== "gameboard" ? (
            <button onClick={() => onTabChange("gameboard")} style={{ display: "flex", alignItems: "center", gap: "8px", background: "none", border: "none", color: "#e9c349", fontSize: "16px", fontWeight: 600, cursor: "pointer", padding: "8px", marginLeft: "-8px" }}>
              <ArrowLeft size={20} /> Back
            </button>
          ) : leftHeaderContent}
        </div>
        <div style={{ fontSize: "28px", fontWeight: 800, color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "1px", flex: 1, textAlign: "center" }}>
          Solitude{activeTab === "gameboard" && activeGameName ? `: ${activeGameName}` : ""}
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: "16px", flex: 1, justifyContent: "flex-end" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "6px", background: "rgba(0,0,0,0.4)", padding: "4px 12px", borderRadius: "12px", border: "1px solid rgba(233, 195, 73, 0.3)" }}>
            <span style={{ color: "#e9c349", fontWeight: "bold", fontSize: "14px", fontFamily: "JetBrains Mono, monospace" }}>{coins}</span>
            <span style={{ fontSize: "12px", opacity: 0.8, color: "#e5e2e1", fontFamily: "Inter, sans-serif" }}>Coins</span>
          </div>
          <button onClick={() => setIsProfileManagerOpen(true)} style={{ background: "none", cursor: "pointer", display: "flex", alignItems: "center", justifyContent: "center", width: "36px", height: "36px", borderRadius: "50%", backgroundColor: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)" }}>
            <User size={18} color="#a5b8a9" />
          </button>
          {rightHeaderContent}
        </div>
      </div>

      <div style={{ display: "flex", flex: 1, overflow: "hidden" }}>
        {/* Left Sidebar */}
        <div style={{ width: sidebarOpen ? "240px" : "80px", transition: "width 0.2s ease", background: "#13261a", borderRight: "1px solid rgba(255,255,255,0.05)", display: "flex", flexDirection: "column", padding: "24px 0", flexShrink: 0 }}>
          <div style={{ padding: sidebarOpen ? "0 24px" : "0", marginBottom: "32px", display: "flex", justifyContent: sidebarOpen ? "space-between" : "center", alignItems: "flex-start" }}>
            {sidebarOpen ? (
              <>
                <div>
                  <div style={{ fontSize: "22px", fontWeight: 700, color: "#e9c349", fontFamily: "Manrope, sans-serif" }}>{activeProfile?.name || "Player"}</div>
                  <div style={{ fontSize: "12px", color: "#a5b8a9", fontFamily: "JetBrains Mono, monospace", marginTop: "4px" }}>Level 1 - Novice</div>
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
                {[
                  { id: "card_back", label: "CARD BACKS" },
                  { id: "theme", label: "THEMES" },
                  { id: "power_up", label: "POWER UPS" },
                  { id: "victory", label: "ANIMATIONS" },
                ].map(cat => (
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
            <button onClick={onOpenSettings} style={{ display: "flex", alignItems: "center", gap: "12px", padding: sidebarOpen ? "12px 24px" : "12px", justifyContent: sidebarOpen ? "flex-start" : "center", background: "transparent", border: "none", color: "#a5b8a9", fontSize: "14px", fontWeight: 600, cursor: "pointer", borderRadius: sidebarOpen ? "0" : "8px" }}>
              <SettingsIcon size={18} /> {sidebarOpen && "Settings"}
            </button>
          </div>
        </div>

        {/* Main Content Area */}
        <div style={{ flex: 1, position: "relative", background: "radial-gradient(circle at 50% 0%, #1e3a2b, #0d1a13)", overflowY: "auto" }}>
          
          <div style={{ display: activeTab === "gameboard" ? "block" : "none", width: "100%", height: "100%", overflow: "hidden" }}>
            {children}
          </div>

          {activeTab === "trophy" && (
            <div style={{ maxWidth: "1000px", margin: "0 auto", padding: "48px 48px" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "40px" }}>
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

              <div style={{ marginBottom: "48px" }}>
                <h3 style={{ fontSize: "18px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "1px", marginBottom: "16px" }}>Statistics</h3>
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
              </div>

              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))", gap: "24px" }}>
                {achievementsData.achievements.map((ach) => {
                  const isUnlocked = unlockedAchievements.includes(ach.id);
                  return (
                    <div key={ach.id} style={{ background: "#0f1c15", border: isUnlocked ? "1px solid #d4af37" : "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "24px", display: "flex", flexDirection: "column" }}>
                      <div style={{ display: "flex", gap: "16px", marginBottom: "24px" }}>
                        <div style={{ width: "48px", height: "48px", borderRadius: "50%", border: isUnlocked ? "2px solid #d4af37" : "2px solid rgba(255,255,255,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                          {isUnlocked ? <Trophy size={20} color="#d4af37" /> : <Lock size={20} color="rgba(255,255,255,0.2)" />}
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontSize: "16px", fontWeight: 600, color: isUnlocked ? "#d4af37" : "rgba(255,255,255,0.5)", marginBottom: "4px" }}>{ach.title}</div>
                          <div style={{ fontSize: "13px", color: "rgba(255,255,255,0.7)", lineHeight: "1.4" }}>{ach.description}</div>
                        </div>
                      </div>
                      <div style={{ marginTop: "auto", display: "flex", justifyContent: "space-between", alignItems: "center", fontSize: "12px", fontFamily: "JetBrains Mono, monospace" }}>
                        <span style={{ color: "rgba(255,255,255,0.4)" }}>{isUnlocked ? "Unlocked" : "Progress"}</span>
                        {isUnlocked ? (
                          <span style={{ color: "#d4af37" }}>Active</span>
                        ) : (
                          <span style={{ color: "rgba(255,255,255,0.4)" }}>Locked</span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {activeTab === "store" && (
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

                          return (
                            <div key={item.id} style={{ background: "rgba(10, 20, 15, 0.6)", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "16px", padding: "16px", display: "flex", flexDirection: "column", alignItems: "center", position: "relative" }}>
                              {isPowerUp && owned > 0 && (
                                <div style={{ position: "absolute", top: "12px", right: "12px", background: "#d4af37", color: "#111", fontWeight: 800, fontSize: "12px", borderRadius: "999px", padding: "2px 9px", zIndex: 1 }}>
                                  ×{owned}
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
                                  onClick={() => handlePurchase(item)}
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
        </div>
      </div>
      
      {isProfileManagerOpen && (
        <ProfileManagerModal onClose={() => setIsProfileManagerOpen(false)} />
      )}
    </div>
  );
};
