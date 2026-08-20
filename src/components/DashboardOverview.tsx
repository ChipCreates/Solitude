import React, { useEffect, useMemo, useState } from "react";
import { Trophy, Lock, Flame, Plus, Pencil, Trash2, Check, X } from "lucide-react";
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  AreaChart,
  Area,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import { useUIStore } from "../store/uiStore";
import { useProfileStore } from "../store/profileStore";
import { useStatisticsStore } from "../store/statisticsStore";
import { GAME_TYPE_NAMES } from "../data/gameTypes";
import achievementsData from "../data/achievements.json";
import { getLevelTitle, getLevelTitleDescription, getGlobalLevel, xpRequiredForLevel } from "../utils/levelTitles";
import { bucketCoinLedgerByWeek } from "../utils/coinLedger";
import { loadProfileSummary, type ProfileSummary } from "../utils/profileSummary";
import { AVATAR_OPTIONS, DEFAULT_AVATAR_ID, getAvatarOption } from "../data/avatars";

const GOLD = "#e9c349";
const GOLD_MUTED = "rgba(233, 195, 73, 0.25)";
const SAGE = "#a5b8a9";
const TREND_WEEKS = 8;

function StatTile({ label, value, accent, sub, children }: { label: string; value: React.ReactNode; accent?: boolean; sub?: React.ReactNode; children?: React.ReactNode }) {
  return (
    <div style={{ flex: 1, minWidth: "160px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: "12px", padding: "16px", display: "flex", flexDirection: "column", gap: "4px" }}>
      <div style={{ fontSize: "11px", color: SAGE, fontFamily: "JetBrains Mono, monospace", letterSpacing: "0.5px", textTransform: "uppercase" }}>{label}</div>
      <div style={{ display: "flex", alignItems: "baseline", gap: "10px" }}>
        <span style={{ fontSize: "28px", fontWeight: 800, color: accent ? GOLD : "#fff", fontFamily: "Manrope, sans-serif" }}>{value}</span>
        {sub}
      </div>
      {children}
    </div>
  );
}

function XPRing({ percent, size = 44 }: { percent: number; size?: number }) {
  const r = (size - 6) / 2;
  const circumference = 2 * Math.PI * r;
  return (
    <svg width={size} height={size} style={{ transform: "rotate(-90deg)", flexShrink: 0 }}>
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="4" />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke={GOLD}
        strokeWidth="4"
        strokeDasharray={circumference}
        strokeDashoffset={circumference - (circumference * percent) / 100}
        strokeLinecap="round"
      />
    </svg>
  );
}

const ACHIEVEMENT_CATEGORY_LABELS: Record<string, string> = {
  speed: "Speed",
  efficiency: "Efficiency",
  streak: "Streak",
  milestone: "Milestone",
  special: "Special",
};

export const DashboardOverview: React.FC = () => {
  const { coins, totalCoinsEarned, coinLedger, unlockedAchievements, gameProgress } = useUIStore();
  const { profiles, activeProfileId, setActiveProfileId, createProfile, updateProfile, deleteProfile } = useProfileStore();
  const { statsByGameType, getAggregateStats } = useStatisticsStore();
  const [achievementFilter, setAchievementFilter] = useState<string>("all");
  const [profileSummaries, setProfileSummaries] = useState<Record<string, ProfileSummary>>({});
  const [isCreatingProfile, setIsCreatingProfile] = useState(false);
  const [newProfileName, setNewProfileName] = useState("");
  const [editProfileId, setEditProfileId] = useState<string | null>(null);
  const [editProfileName, setEditProfileName] = useState("");
  const [editGamerTag, setEditGamerTag] = useState("");
  const [editAvatarId, setEditAvatarId] = useState(DEFAULT_AVATAR_ID);

  const aggregate = getAggregateStats();
  const globalLevel = getGlobalLevel(gameProgress);
  const globalLevelTitle = getLevelTitle(globalLevel.level);
  const xpProgressPercent = Math.max(0, Math.min(100, Math.round((globalLevel.xp / xpRequiredForLevel(globalLevel.level)) * 100)));

  const winRateData = useMemo(
    () =>
      GAME_TYPE_NAMES.map((game) => {
        const s = statsByGameType[game];
        const played = s?.gamesPlayed ?? 0;
        const won = s?.gamesWon ?? 0;
        return { game, winRate: played > 0 ? Math.round((won / played) * 100) : 0, played };
      }),
    [statsByGameType]
  );

  const trendData = useMemo(() => bucketCoinLedgerByWeek(coinLedger, TREND_WEEKS), [coinLedger]);

  const achievementCategories = useMemo(
    () => Array.from(new Set(achievementsData.achievements.map((a) => a.category))),
    []
  );
  const categoryBreakdown = useMemo(
    () =>
      achievementCategories.map((cat) => {
        const inCategory = achievementsData.achievements.filter((a) => a.category === cat);
        const unlockedInCategory = inCategory.filter((a) => unlockedAchievements.includes(a.id)).length;
        return { category: cat, unlocked: unlockedInCategory, total: inCategory.length };
      }),
    [achievementCategories, unlockedAchievements]
  );
  const totalAchievements = achievementsData.achievements.length;
  const unlockedCount = unlockedAchievements.length;
  const achievementPercent = totalAchievements > 0 ? Math.round((unlockedCount / totalAchievements) * 100) : 0;
  const donutData = [
    { name: "Unlocked", value: unlockedCount },
    { name: "Locked", value: Math.max(0, totalAchievements - unlockedCount) },
  ];

  const filteredAchievements =
    achievementFilter === "all"
      ? achievementsData.achievements
      : achievementsData.achievements.filter((a) => a.category === achievementFilter);

  useEffect(() => {
    let cancelled = false;
    Promise.all(profiles.map(async (p) => [p.id, await loadProfileSummary(p.id)] as const)).then((entries) => {
      if (cancelled) return;
      setProfileSummaries(Object.fromEntries(entries));
    });
    return () => {
      cancelled = true;
    };
  }, [profiles]);

  const handleCreateProfile = async () => {
    if (!newProfileName.trim()) return;
    await createProfile(newProfileName.trim(), DEFAULT_AVATAR_ID);
    setNewProfileName("");
    setIsCreatingProfile(false);
  };

  const handleStartEditProfile = (p: (typeof profiles)[number]) => {
    setEditProfileId(p.id);
    setEditProfileName(p.name);
    setEditGamerTag(p.gamerTag ?? "");
    setEditAvatarId(p.avatarId || DEFAULT_AVATAR_ID);
  };

  const handleSaveProfileEdit = async () => {
    if (editProfileId && editProfileName.trim()) {
      await updateProfile(editProfileId, {
        name: editProfileName.trim(),
        gamerTag: editGamerTag.trim() || undefined,
        avatarId: editAvatarId,
      });
    }
    setEditProfileId(null);
  };

  const handleDeleteProfile = async (id: string) => {
    if (profiles.length <= 1) {
      alert("You cannot delete the last remaining profile.");
      return;
    }
    if (confirm("Delete this profile? All of its statistics and progress will be lost.")) {
      await deleteProfile(id);
    }
  };

  return (
    <div style={{ display: "flex", flexDirection: "column", gap: "24px" }}>
      {/* Hero summary row */}
      <div style={{ display: "flex", gap: "16px", flexWrap: "wrap" }}>
        <StatTile label="Total Games Played" value={aggregate.totalGamesPlayed} />
        <StatTile
          label="Total Wins"
          value={aggregate.totalGamesWon}
          sub={<span style={{ fontSize: "13px", color: "#7fd99a", fontWeight: 600 }}>{aggregate.overallWinRate}% Win Rate</span>}
        />
        <StatTile label="Lifetime Coins Earned" value={totalCoinsEarned.toLocaleString()} accent sub={<span style={{ fontSize: "12px", color: SAGE }}>{coins.toLocaleString()} on hand</span>} />
        <StatTile
          label="Best Win Streak"
          value={aggregate.bestStreak}
          sub={<Flame size={16} color="#f59e0b" />}
        />
        <div style={{ flex: 1, minWidth: "200px", background: "rgba(0,0,0,0.3)", border: "1px solid rgba(255,255,255,0.08)", borderRadius: "12px", padding: "16px", display: "flex", alignItems: "center", justifyContent: "space-between" }}>
          <div>
            <div style={{ fontSize: "11px", color: SAGE, fontFamily: "JetBrains Mono, monospace", letterSpacing: "0.5px", textTransform: "uppercase" }}>Level {globalLevel.level}</div>
            <div title={getLevelTitleDescription(globalLevel.level)} style={{ fontSize: "22px", fontWeight: 800, color: "#fff", fontFamily: "Manrope, sans-serif", cursor: "default" }}>{globalLevelTitle}</div>
          </div>
          <div style={{ position: "relative", display: "flex", alignItems: "center", justifyContent: "center" }}>
            <XPRing percent={xpProgressPercent} />
            <span style={{ position: "absolute", fontSize: "10px", fontWeight: 700, color: GOLD, fontFamily: "JetBrains Mono, monospace" }}>{xpProgressPercent}%</span>
          </div>
        </div>
      </div>

      {/* Per-game performance */}
      <div style={{ background: "#0f1c15", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "20px" }}>
        <h3 style={{ margin: "0 0 16px 0", fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "1px", textTransform: "uppercase" }}>Variant Win Rates</h3>
        <ResponsiveContainer width="100%" height={320}>
          <BarChart data={winRateData} layout="vertical" margin={{ left: 24, right: 24 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" horizontal={false} />
            <XAxis type="number" domain={[0, 100]} tick={{ fill: SAGE, fontSize: 11 }} unit="%" stroke="rgba(255,255,255,0.1)" />
            <YAxis type="category" dataKey="game" width={90} tick={{ fill: "#e5e2e1", fontSize: 12 }} stroke="rgba(255,255,255,0.1)" />
            <Tooltip
              contentStyle={{ background: "#111", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }}
              labelStyle={{ color: "#fff" }}
              formatter={(value, _name, item) => [`${value}% (${item.payload.played} played)`, "Win rate"]}
            />
            <Bar dataKey="winRate" fill={GOLD} radius={[0, 6, 6, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Trend + achievement progress */}
      <div style={{ display: "flex", gap: "24px", flexWrap: "wrap" }}>
        <div style={{ flex: "2 1 400px", background: "#0f1c15", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "20px" }}>
          <h3 style={{ margin: "0 0 16px 0", fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "1px", textTransform: "uppercase" }}>Coins Earned Over Time</h3>
          <ResponsiveContainer width="100%" height={220}>
            <AreaChart data={trendData} margin={{ left: 8, right: 8 }}>
              <defs>
                <linearGradient id="coinsGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={GOLD} stopOpacity={0.4} />
                  <stop offset="100%" stopColor={GOLD} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
              <XAxis dataKey="label" tick={{ fill: SAGE, fontSize: 11 }} stroke="rgba(255,255,255,0.1)" />
              <YAxis tick={{ fill: SAGE, fontSize: 11 }} stroke="rgba(255,255,255,0.1)" width={40} />
              <Tooltip contentStyle={{ background: "#111", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px" }} labelStyle={{ color: "#fff" }} />
              <Area type="monotone" dataKey="coins" stroke={GOLD} strokeWidth={2} fill="url(#coinsGradient)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        <div style={{ flex: "1 1 260px", background: "#0f1c15", border: "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "20px", display: "flex", flexDirection: "column" }}>
          <h3 style={{ margin: "0 0 16px 0", fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "1px", textTransform: "uppercase" }}>Achievement Progress</h3>
          <div style={{ display: "flex", alignItems: "center", gap: "20px", flex: 1 }}>
            <div style={{ position: "relative", width: "120px", height: "120px", flexShrink: 0 }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={donutData} dataKey="value" innerRadius={40} outerRadius={58} startAngle={90} endAngle={-270} stroke="none">
                    <Cell fill={GOLD} />
                    <Cell fill="rgba(255,255,255,0.08)" />
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div style={{ position: "absolute", inset: 0, display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center" }}>
                <span style={{ fontSize: "22px", fontWeight: 800, color: "#fff", fontFamily: "Manrope, sans-serif" }}>{achievementPercent}%</span>
                <span style={{ fontSize: "9px", color: SAGE, letterSpacing: "0.5px" }}>UNLOCKED</span>
              </div>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "8px", flex: 1 }}>
              {categoryBreakdown.map(({ category, unlocked, total }) => (
                <div key={category} style={{ display: "flex", justifyContent: "space-between", fontSize: "12px" }}>
                  <span style={{ color: "#e5e2e1" }}>{ACHIEVEMENT_CATEGORY_LABELS[category] ?? category}</span>
                  <span style={{ color: SAGE, fontFamily: "JetBrains Mono, monospace" }}>{unlocked}/{total}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Achievements grid */}
      <div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "16px" }}>
          <h3 style={{ margin: 0, fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "1px", textTransform: "uppercase" }}>Achievements</h3>
          <div style={{ display: "flex", gap: "6px", flexWrap: "wrap" }}>
            {["all", ...achievementCategories].map((cat) => (
              <button
                key={cat}
                onClick={() => setAchievementFilter(cat)}
                style={{
                  padding: "4px 12px", borderRadius: "999px", cursor: "pointer", fontSize: "11px", fontWeight: 600,
                  fontFamily: "JetBrains Mono, monospace", textTransform: "uppercase", letterSpacing: "0.5px",
                  background: achievementFilter === cat ? GOLD_MUTED : "transparent",
                  border: `1px solid ${achievementFilter === cat ? GOLD : "rgba(255,255,255,0.15)"}`,
                  color: achievementFilter === cat ? GOLD : SAGE,
                }}
              >
                {cat === "all" ? "All" : ACHIEVEMENT_CATEGORY_LABELS[cat] ?? cat}
              </button>
            ))}
          </div>
        </div>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(240px, 1fr))", gap: "16px" }}>
          {filteredAchievements.map((ach) => {
            const isUnlocked = unlockedAchievements.includes(ach.id);
            return (
              <div key={ach.id} style={{ background: "#0f1c15", border: isUnlocked ? "1px solid #d4af37" : "1px solid rgba(255,255,255,0.05)", borderRadius: "12px", padding: "16px", display: "flex", gap: "12px", opacity: isUnlocked ? 1 : 0.6 }}>
                <div style={{ width: "40px", height: "40px", flexShrink: 0, borderRadius: "50%", border: isUnlocked ? "2px solid #d4af37" : "2px solid rgba(255,255,255,0.1)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  {isUnlocked ? <Trophy size={18} color="#d4af37" /> : <Lock size={18} color="rgba(255,255,255,0.2)" />}
                </div>
                <div>
                  <div style={{ fontSize: "14px", fontWeight: 600, color: isUnlocked ? "#d4af37" : "rgba(255,255,255,0.6)" }}>{ach.title}</div>
                  <div style={{ fontSize: "12px", color: "rgba(255,255,255,0.6)", marginTop: "2px" }}>{ach.description}</div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Profiles: switch, rename, delete, or add a local profile */}
      <div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: "16px" }}>
          <h3 style={{ margin: 0, fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "1px", textTransform: "uppercase" }}>Profiles</h3>
          {!isCreatingProfile && (
            <button
              onClick={() => setIsCreatingProfile(true)}
              style={{ display: "flex", alignItems: "center", gap: "6px", background: "none", border: "1px dashed rgba(233,195,73,0.5)", borderRadius: "8px", padding: "6px 12px", color: GOLD, cursor: "pointer", fontSize: "12px", fontWeight: 600 }}
            >
              <Plus size={14} /> Add Profile
            </button>
          )}
        </div>

        {isCreatingProfile && (
          <div style={{ display: "flex", gap: "8px", marginBottom: "16px", background: "rgba(255,255,255,0.05)", padding: "12px", borderRadius: "12px" }}>
            <input
              type="text"
              placeholder="Player name"
              value={newProfileName}
              onChange={(e) => setNewProfileName(e.target.value)}
              autoFocus
              style={{ flex: 1, background: "#1a1a1a", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "8px 10px", color: "white", outline: "none" }}
            />
            <button onClick={handleCreateProfile} style={{ background: GOLD, border: "none", borderRadius: "8px", padding: "8px 14px", color: "#111", fontWeight: 700, cursor: "pointer" }}>Create</button>
            <button onClick={() => { setIsCreatingProfile(false); setNewProfileName(""); }} style={{ background: "rgba(255,255,255,0.1)", border: "none", borderRadius: "8px", padding: "8px 14px", color: "white", cursor: "pointer" }}>Cancel</button>
          </div>
        )}

        <div style={{ display: "flex", gap: "16px", flexWrap: "wrap" }}>
          {profiles.map((p) => {
            const summary = profileSummaries[p.id];
            const isActive = p.id === activeProfileId;
            const isEditing = editProfileId === p.id;
            const avatar = getAvatarOption(p.avatarId);

            if (isEditing) {
              const draftAvatar = getAvatarOption(editAvatarId);
              return (
                <div key={p.id} style={{ flex: "1 1 100%", background: "rgba(0,0,0,0.35)", border: "1px solid rgba(233,195,73,0.5)", borderRadius: "12px", padding: "24px", display: "flex", flexDirection: "column", gap: "20px" }}>
                  <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
                    <h4 style={{ margin: 0, fontSize: "14px", color: GOLD, fontFamily: "Manrope, sans-serif", letterSpacing: "0.5px", textTransform: "uppercase" }}>Edit Profile</h4>
                    <div style={{ display: "flex", gap: "8px" }}>
                      <button onClick={() => setEditProfileId(null)} style={{ display: "flex", alignItems: "center", gap: "6px", background: "rgba(255,255,255,0.08)", border: "none", borderRadius: "8px", padding: "6px 12px", color: SAGE, cursor: "pointer", fontSize: "12px" }}><X size={14} /> Cancel</button>
                      <button onClick={handleSaveProfileEdit} style={{ display: "flex", alignItems: "center", gap: "6px", background: GOLD, border: "none", borderRadius: "8px", padding: "6px 12px", color: "#111", fontWeight: 700, cursor: "pointer", fontSize: "12px" }}><Check size={14} /> Save</button>
                    </div>
                  </div>

                  <div style={{ display: "flex", gap: "24px", flexWrap: "nowrap", alignItems: "flex-start" }}>
                    <div style={{ display: "flex", flexDirection: "column", gap: "8px", width: "260px", flexShrink: 0 }}>
                      <label style={{ fontSize: "11px", color: SAGE, textTransform: "uppercase", letterSpacing: "0.5px" }}>Name</label>
                      <input
                        type="text"
                        value={editProfileName}
                        onChange={(e) => setEditProfileName(e.target.value)}
                        autoFocus
                        style={{ background: "#1a1a1a", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "10px 12px", color: "white", outline: "none" }}
                      />
                      <label style={{ fontSize: "11px", color: SAGE, textTransform: "uppercase", letterSpacing: "0.5px", marginTop: "8px" }}>Gamer Tag (optional)</label>
                      <input
                        type="text"
                        value={editGamerTag}
                        onChange={(e) => setEditGamerTag(e.target.value)}
                        placeholder="e.g. cardshark88"
                        style={{ background: "#1a1a1a", border: "1px solid rgba(255,255,255,0.2)", borderRadius: "8px", padding: "10px 12px", color: "white", outline: "none" }}
                      />

                      <div style={{ display: "flex", alignItems: "center", gap: "12px", marginTop: "16px" }}>
                        <div style={{ width: "72px", height: "72px", borderRadius: "50%", overflow: "hidden", border: `3px solid ${draftAvatar.ringColor}`, flexShrink: 0 }}>
                          <img src={draftAvatar.src} alt={draftAvatar.label} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                        </div>
                        <div>
                          <div style={{ fontSize: "13px", fontWeight: 600, color: "#fff" }}>{draftAvatar.label}</div>
                          <div style={{ fontSize: "11px", color: SAGE }}>Selected avatar</div>
                        </div>
                      </div>
                    </div>

                    <div style={{ flex: 1, minWidth: 0, borderLeft: "1px solid rgba(255,255,255,0.08)", paddingLeft: "24px" }}>
                      <label style={{ fontSize: "11px", color: SAGE, textTransform: "uppercase", letterSpacing: "0.5px" }}>Choose an Avatar</label>
                      <div style={{ display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: "16px", marginTop: "10px", maxWidth: "360px" }}>
                        {AVATAR_OPTIONS.map((opt) => {
                          const selected = opt.id === editAvatarId;
                          return (
                            <button
                              key={opt.id}
                              onClick={() => setEditAvatarId(opt.id)}
                              title={opt.label}
                              style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: "6px", background: "none", border: "none", cursor: "pointer", padding: "4px" }}
                            >
                              <div style={{ width: "88px", height: "88px", borderRadius: "50%", overflow: "hidden", border: selected ? `3px solid ${opt.ringColor}` : "2px solid rgba(255,255,255,0.12)", boxShadow: selected ? `0 0 0 3px ${opt.ringColor}33` : "none", transition: "all 0.15s" }}>
                                <img src={opt.src} alt={opt.label} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                              </div>
                              <span style={{ fontSize: "11px", color: selected ? opt.ringColor : SAGE, fontWeight: selected ? 700 : 500 }}>{opt.label}</span>
                            </button>
                          );
                        })}
                      </div>
                    </div>
                  </div>
                </div>
              );
            }

            return (
              <div
                key={p.id}
                onClick={() => setActiveProfileId(p.id)}
                style={{ flex: "1 1 220px", background: "rgba(0,0,0,0.3)", border: isActive ? "1px solid rgba(233,195,73,0.5)" : "1px solid rgba(255,255,255,0.08)", borderRadius: "12px", padding: "16px", display: "flex", gap: "12px", alignItems: "center", cursor: "pointer" }}
              >
                <div style={{ width: "40px", height: "40px", borderRadius: "50%", overflow: "hidden", border: `1px solid ${avatar.ringColor}88`, flexShrink: 0 }}>
                  <img src={avatar.src} alt={avatar.label} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: "14px", fontWeight: 600, color: isActive ? GOLD : "#fff", overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
                    {p.name}
                    {p.gamerTag && <span style={{ color: SAGE, fontWeight: 400 }}> · @{p.gamerTag}</span>}
                  </div>
                  <div style={{ fontSize: "11px", color: SAGE, fontFamily: "JetBrains Mono, monospace" }}>
                    {summary ? `Lv.${summary.level} · ${summary.gamesWon}W · ${summary.coins.toLocaleString()} coins` : "Loading…"}
                  </div>
                </div>
                <div style={{ display: "flex", gap: "2px", flexShrink: 0 }} onClick={(e) => e.stopPropagation()}>
                  <button onClick={() => handleStartEditProfile(p)} title="Edit Profile" style={{ background: "none", border: "none", color: "rgba(255,255,255,0.3)", cursor: "pointer", padding: "4px" }}><Pencil size={14} /></button>
                  <button onClick={() => handleDeleteProfile(p.id)} title="Delete" style={{ background: "none", border: "none", color: "rgba(255,255,255,0.3)", cursor: "pointer", padding: "4px" }}><Trash2 size={14} /></button>
                </div>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
};
