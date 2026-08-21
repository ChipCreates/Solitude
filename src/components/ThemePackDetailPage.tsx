import React, { useEffect, useRef, useState } from "react";
import { ArrowLeft, Coins, PauseCircle, PlayCircle } from "lucide-react";
import { THEME_PRESETS } from "../theme/presets";
import { STORE_ITEMS, type StoreItem } from "../data/storeItems";
import { MUSIC_TRACKS } from "../data/musicTracks";
import { getSfxSet } from "../data/sfxSets";
import { useUIStore } from "../store/uiStore";
import { audioService } from "../audio/audioService";
import { CardWidget } from "./CardWidget";

interface ThemePackDetailPageProps {
  packId: string;
  onBack: () => void;
  onPurchase: (item: StoreItem) => void;
}

function SwatchRow({ label, hex }: { label: string; hex: string }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
      <div style={{ width: "28px", height: "28px", borderRadius: "8px", background: hex, border: "1px solid rgba(255,255,255,0.15)", flexShrink: 0 }} />
      <div>
        <div style={{ fontSize: "12px", color: "#e5e2e1" }}>{label}</div>
        <div style={{ fontSize: "11px", color: "#a5b8a9", fontFamily: "JetBrains Mono, monospace" }}>{hex}</div>
      </div>
    </div>
  );
}

export const ThemePackDetailPage: React.FC<ThemePackDetailPageProps> = ({ packId, onBack, onPurchase }) => {
  const { coins, unlockedItems, themeId, cardBackPattern, cardFaceSetId } = useUIStore();
  const [isMusicPlaying, setIsMusicPlaying] = useState(false);
  const previewAudioRef = useRef<HTMLAudioElement | null>(null);

  const pack = THEME_PRESETS[packId];
  const storeItem = STORE_ITEMS.find((i) => i.id === packId);
  const musicTrack = pack?.musicTrackId ? MUSIC_TRACKS.find((t) => t.id === pack.musicTrackId) : undefined;
  const sfxSet = pack?.sfxSetId ? getSfxSet(pack.sfxSetId) : undefined;

  useEffect(() => {
    // Stop any preview playback when leaving this page or switching packs.
    return () => {
      previewAudioRef.current?.pause();
    };
  }, [packId]);

  if (!pack || !storeItem) {
    return (
      <div style={{ maxWidth: "700px", margin: "0 auto", padding: "48px" }}>
        <button onClick={onBack} style={{ display: "flex", alignItems: "center", gap: "8px", background: "none", border: "none", color: "#e9c349", cursor: "pointer", marginBottom: "24px" }}>
          <ArrowLeft size={18} /> Back to Emporium
        </button>
        <p style={{ color: "#a5b8a9" }}>This pack is no longer available.</p>
      </div>
    );
  }

  const unlocked = unlockedItems.includes(pack.id) || storeItem.price === 0;
  const equipped = themeId === pack.id;
  const canAfford = coins >= storeItem.price;
  const disabled = !unlocked && !canAfford;

  const toggleMusicPreview = () => {
    if (!musicTrack) return;
    const el = previewAudioRef.current;
    if (!el) return;
    if (isMusicPlaying) {
      el.pause();
      setIsMusicPlaying(false);
    } else {
      el.src = musicTrack.url;
      el.volume = 0.7;
      el.play().catch(() => {});
      setIsMusicPlaying(true);
    }
  };

  const cardBackForPreview = pack.cardBackPatternId ?? cardBackPattern;
  const cardFaceSetForPreview = pack.cardFaceSetId ?? cardFaceSetId;
  // Illustrated decks need more room than the default 90-100px preview size
  // to read their corner glyphs/heraldry.
  const previewScale = pack.cardFaceSetId ? 1.7 : 1;

  return (
    <div style={{ maxWidth: "900px", margin: "0 auto", padding: "48px 48px" }}>
      <button onClick={onBack} style={{ display: "flex", alignItems: "center", gap: "8px", background: "none", border: "none", color: "#e9c349", fontSize: "14px", fontWeight: 600, cursor: "pointer", marginBottom: "24px", padding: 0 }}>
        <ArrowLeft size={18} /> Back to Emporium
      </button>

      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "32px", gap: "24px", flexWrap: "wrap" }}>
        <div>
          <h2 style={{ margin: 0, fontSize: "28px", color: "#e9c349", fontFamily: "Manrope, sans-serif" }}>{storeItem.name}</h2>
          <p style={{ margin: "8px 0 0 0", fontSize: "15px", color: "#a5b8a9", maxWidth: "500px" }}>{storeItem.description}</p>
        </div>
        <button
          onClick={() => onPurchase(storeItem)}
          disabled={disabled}
          style={{
            padding: "14px 28px", borderRadius: "8px", fontWeight: 700, fontSize: "14px", letterSpacing: "1px", textTransform: "uppercase", cursor: disabled ? "not-allowed" : "pointer", display: "flex", alignItems: "center", gap: "8px", flexShrink: 0,
            background: equipped ? "rgba(212, 175, 55, 0.15)" : (unlocked || canAfford) ? "#e9c349" : "rgba(255,255,255,0.05)",
            color: equipped ? "#d4af37" : (unlocked || canAfford) ? "#111" : "rgba(255,255,255,0.3)",
            border: equipped ? "1px solid #d4af37" : "none",
          }}
        >
          {equipped ? "Equipped" : unlocked ? "Equip" : (<>{storeItem.price} <Coins size={16} /></>)}
        </button>
      </div>

      {/* Live sample preview using the real card renderer */}
      <div style={{ marginBottom: "32px" }}>
        <h3 style={{ fontSize: "13px", color: "#e9c349", textTransform: "uppercase", letterSpacing: "1px", marginBottom: "12px" }}>Preview</h3>
        <div
          style={{
            borderRadius: "16px",
            padding: "40px",
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            gap: "24px",
            background: `radial-gradient(circle at 50% 30%, ${pack.tableColor}, ${pack.tableGradientEnd})`,
            border: "1px solid rgba(255,255,255,0.1)",
          }}
        >
          <div style={{ position: "relative", width: `${90 * previewScale}px`, height: `${126 * previewScale}px`, transform: "rotate(-6deg)" }}>
            <CardWidget id={1} rank={13} suit={2} faceUp={false} width={90 * previewScale} height={126 * previewScale} theme={pack} overlayIntensity={pack.defaultOverlayIntensity} cardFaceSet={cardFaceSetForPreview} cardBackPattern={cardBackForPreview} cardBackColor={pack.tableGradientEnd} isSelected={false} isHint={false} hideShadow />
          </div>
          <div style={{ position: "relative", width: `${100 * previewScale}px`, height: `${140 * previewScale}px` }}>
            <CardWidget id={2} rank={13} suit={2} faceUp={true} width={100 * previewScale} height={140 * previewScale} theme={pack} overlayIntensity={pack.defaultOverlayIntensity} cardFaceSet={cardFaceSetForPreview} cardBackPattern={cardBackForPreview} cardBackColor={pack.tableGradientEnd} isSelected={false} isHint={false} hideShadow />
          </div>
          <div style={{ position: "relative", width: `${90 * previewScale}px`, height: `${126 * previewScale}px`, transform: "rotate(6deg)" }}>
            <CardWidget id={3} rank={1} suit={3} faceUp={true} width={90 * previewScale} height={126 * previewScale} theme={pack} overlayIntensity={pack.defaultOverlayIntensity} cardFaceSet={cardFaceSetForPreview} cardBackPattern={cardBackForPreview} cardBackColor={pack.tableGradientEnd} isSelected={false} isHint={false} hideShadow />
          </div>
        </div>
      </div>

      <div style={{ display: "flex", gap: "32px", flexWrap: "wrap" }}>
        <div style={{ flex: "1 1 240px" }}>
          <h3 style={{ fontSize: "13px", color: "#e9c349", textTransform: "uppercase", letterSpacing: "1px", marginBottom: "12px" }}>Color Palette</h3>
          <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
            <SwatchRow label="Table" hex={pack.tableColor} />
            <SwatchRow label="Table Shadow" hex={pack.tableGradientEnd} />
            <SwatchRow label="Accent" hex={pack.accentColor} />
          </div>
        </div>

        {(sfxSet || musicTrack) && (
          <div style={{ flex: "1 1 240px" }}>
            <h3 style={{ fontSize: "13px", color: "#e9c349", textTransform: "uppercase", letterSpacing: "1px", marginBottom: "12px" }}>Sound Samples</h3>
            <div style={{ display: "flex", flexDirection: "column", gap: "10px" }}>
              {sfxSet && (
                <>
                  <button
                    onClick={() => audioService.previewCardMove(sfxSet.id)}
                    style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "10px 14px", color: "#e5e2e1", cursor: "pointer", fontSize: "13px", textAlign: "left" }}
                  >
                    <PlayCircle size={16} color="#e9c349" /> Move Sound
                  </button>
                  <button
                    onClick={() => audioService.previewWin(sfxSet.id)}
                    style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "10px 14px", color: "#e5e2e1", cursor: "pointer", fontSize: "13px", textAlign: "left" }}
                  >
                    <PlayCircle size={16} color="#e9c349" /> Win Sound
                  </button>
                </>
              )}
              {musicTrack && (
                <button
                  onClick={toggleMusicPreview}
                  style={{ display: "flex", alignItems: "center", gap: "8px", background: "rgba(255,255,255,0.05)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "8px", padding: "10px 14px", color: "#e5e2e1", cursor: "pointer", fontSize: "13px", textAlign: "left" }}
                >
                  {isMusicPlaying ? <PauseCircle size={16} color="#e9c349" /> : <PlayCircle size={16} color="#e9c349" />} {musicTrack.name}
                </button>
              )}
              <audio ref={previewAudioRef} onEnded={() => setIsMusicPlaying(false)} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
