import React, { useState } from "react";
import { Trophy, Store, Settings as SettingsIcon, ArrowLeft, LayoutGrid, CheckCircle, Lock, Coins, PanelLeftClose, PanelLeftOpen, User } from "lucide-react";
import { useUIStore } from "../store/uiStore";
import { useProfileStore } from "../store/profileStore";
import achievementsData from "../data/achievements.json";
import { ProfileManagerModal } from "./ProfileManagerModal";

interface MetaGameHubProps {
  activeTab: "gameboard" | "store" | "trophy";
  onTabChange: (tab: "gameboard" | "store" | "trophy") => void;
  onOpenSettings: () => void;
  leftHeaderContent?: React.ReactNode;
  rightHeaderContent?: React.ReactNode;
  children?: React.ReactNode;
}

const STORE_ITEMS = [
  { id: "bicycle", type: "card_back", name: "Bicycle Blue", price: 0 },
  { id: "diamond", type: "card_back", name: "Classic Diamond", price: 0 },
  { id: "botanical", type: "card_back", name: "Botanical Garden", price: 500 },
  { id: "mystic", type: "card_back", name: "Mystic Aura", price: 500 },
  { id: "filigree", type: "card_back", name: "Golden Filigree", price: 500 },
  { id: "classic_felt", type: "theme", name: "Casino Green", price: 0 },
  { id: "midnight_blue", type: "theme", name: "Midnight Blue", price: 300 },
  { id: "burgundy_velvet", type: "theme", name: "Burgundy Velvet", price: 300 },
  { id: "obsidian_glass", type: "theme", name: "Obsidian Glass", price: 800 },
  { id: "confetti", type: "victory", name: "Confetti Explosion", price: 400 },
  { id: "fireworks", type: "victory", name: "Golden Fireworks", price: 1000 },
];

export const MetaGameHub: React.FC<MetaGameHubProps> = ({ activeTab, onTabChange, onOpenSettings, leftHeaderContent, rightHeaderContent, children }) => {
  const { coins, subtractCoins, unlockedItems, unlockItem, cardBackPattern, setCardBackPattern, themeId, setThemeId, unlockedAchievements } = useUIStore();
  const { profiles, activeProfileId } = useProfileStore();
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isProfileManagerOpen, setIsProfileManagerOpen] = useState(false);
  
  const activeProfile = profiles.find(p => p.id === activeProfileId) || profiles[0];

  // --- Store Handlers ---
  const handlePurchase = (item: any) => {
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
          Solitude
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
              <Store size={18} color={activeTab === "store" ? "#e9c349" : "#a5b8a9"} /> {sidebarOpen && "Storefront"}
            </button>
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
                  <h2 style={{ margin: 0, fontSize: "28px", color: "#e9c349", fontFamily: "Manrope, sans-serif", letterSpacing: "2px", textTransform: "uppercase" }}>Storefront</h2>
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

              <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(280px, 1fr))", gap: "24px" }}>
                {STORE_ITEMS.map(item => {
                  const unlocked = unlockedItems.includes(item.id) || item.price === 0;
                  const equipped = isEquipped(item);
                  const canAfford = coins >= item.price;

                  return (
                    <div key={item.id} style={{ background: "#0f1c15", border: equipped ? "1px solid #d4af37" : "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "24px", display: "flex", flexDirection: "column" }}>
                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "16px" }}>
                        <div>
                          <h3 style={{ margin: 0, fontSize: "16px", color: "#fff" }}>{item.name}</h3>
                          <p style={{ margin: "4px 0 0 0", fontSize: "12px", color: "#a5b8a9", textTransform: "uppercase", letterSpacing: "1px" }}>{item.type.replace('_', ' ')}</p>
                        </div>
                        {equipped && <CheckCircle size={20} color="#d4af37" />}
                        {!unlocked && !canAfford && <Lock size={20} color="rgba(255,255,255,0.2)" />}
                      </div>

                      <div style={{ marginTop: "auto", paddingTop: "16px" }}>
                        <button
                          onClick={() => handlePurchase(item)}
                          disabled={!unlocked && !canAfford}
                          style={{
                            width: "100%", padding: "12px", borderRadius: "8px", border: "none", fontWeight: 700, fontSize: "14px", cursor: (!unlocked && !canAfford) ? "not-allowed" : "pointer", transition: "all 0.2s",
                            background: equipped ? "rgba(212, 175, 55, 0.1)" : unlocked ? "#1e3a2b" : canAfford ? "#d4af37" : "rgba(255,255,255,0.05)",
                            color: equipped ? "#d4af37" : unlocked ? "#fff" : canAfford ? "#111" : "rgba(255,255,255,0.3)",
                            borderWidth: "1px", borderStyle: "solid",
                            borderColor: equipped ? "#d4af37" : "transparent"
                          }}
                        >
                          {equipped ? "Equipped" : unlocked ? "Equip" : `Buy for ${item.price} Coins`}
                        </button>
                      </div>
                    </div>
                  );
                })}
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
