import React from "react";
import { useUIStore } from "../store/uiStore";
import { Info, Code, Shield, Github, User, FileText } from "lucide-react";

interface AboutModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const AboutModal: React.FC<AboutModalProps> = ({ isOpen, onClose }) => {
  const themeId = useUIStore((s) => s.themeId);
  const accentColor = themeId === "classic" ? "#166534" : (themeId === "midnight" ? "#818cf8" : "#e9c349");

  if (!isOpen) return null;

  return (
    <div
      style={{
        position: "fixed",
        inset: 0,
        backgroundColor: "rgba(0, 0, 0, 0.7)",
        backdropFilter: "blur(8px)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        zIndex: 200,
        padding: "24px"
      }}
      onClick={onClose}
    >
      <div
        style={{
          width: "100%",
          maxWidth: "600px",
          maxHeight: "85vh",
          display: "flex",
          flexDirection: "column",
          backgroundColor: "rgba(30, 30, 30, 0.95)",
          borderRadius: "16px",
          border: `1px solid rgba(255,255,255,0.1)`,
          boxShadow: `0 16px 48px rgba(0,0,0,0.5)`,
          overflow: "hidden"
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ padding: "20px 24px", borderBottom: "1px solid rgba(255,255,255,0.1)", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
            <Info color={accentColor} size={24} />
            <h2 style={{ fontSize: "20px", fontWeight: 700, color: "#e5e2e1" }}>About Solitude</h2>
          </div>
          <button onClick={onClose} style={{ background: "none", border: "none", color: "#a1a1aa", cursor: "pointer", fontSize: "24px" }}>&times;</button>
        </div>

        <div style={{ padding: "24px", overflowY: "auto", flex: 1, display: "flex", flexDirection: "column", gap: "32px", color: "#d4d4d8", lineHeight: 1.6 }}>
          
          <div style={{ textAlign: "center" }}>
            <div style={{ 
              width: "80px", height: "80px", borderRadius: "16px", backgroundColor: "rgba(255,255,255,0.05)",
              border: `2px solid ${accentColor}80`, margin: "0 auto 16px", display: "flex", alignItems: "center", justifyContent: "center"
            }}>
              <span style={{ fontSize: "40px", color: accentColor }}>♠</span>
            </div>
            <h1 style={{ fontSize: "28px", fontWeight: 800, color: "#fff", marginBottom: "4px" }}>Solitude</h1>
            <p style={{ fontSize: "14px", color: accentColor, fontWeight: 600, letterSpacing: "1px" }}>VERSION 1.0.0</p>
            <p style={{ fontSize: "16px", color: "#a1a1aa", marginTop: "8px" }}>A beautiful, open-source solitaire game.</p>
          </div>

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <FileText size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>License</h3>
            </div>
            <p style={{ fontSize: "14px", marginBottom: "12px" }}>Solitude is free software licensed under the GNU General Public License v3.0 (GPL-3.0).</p>
            <p style={{ fontSize: "14px", color: "#a1a1aa" }}>You are free to use, study, modify, and distribute this software, under the condition that you preserve the same freedoms for others.</p>
          </div>

          <div style={{ height: "1px", backgroundColor: "rgba(255,255,255,0.1)" }} />

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <User size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Credits</h3>
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: "16px" }}>
              <div style={{ backgroundColor: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.05)" }}>
                <h4 style={{ fontSize: "14px", fontWeight: 700, color: "#fff" }}>Card Graphics</h4>
                <p style={{ fontSize: "14px", color: "#a1a1aa", margin: "4px 0" }}>SVG Playing Cards by David Bellot, maintained by Huub de Beer</p>
                <p style={{ fontSize: "12px", color: accentColor }}>Licensed under LGPL 2.1+ | github.com/htdebeer/SVG-cards</p>
              </div>
              <div style={{ backgroundColor: "rgba(255,255,255,0.03)", padding: "16px", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.05)" }}>
                <h4 style={{ fontSize: "14px", fontWeight: 700, color: "#fff" }}>Font</h4>
                <p style={{ fontSize: "14px", color: "#a1a1aa", margin: "4px 0" }}>Inter by Rasmus Andersson</p>
                <p style={{ fontSize: "12px", color: accentColor }}>Licensed under SIL Open Font License | rsms.me/inter</p>
              </div>
            </div>
          </div>

          <div style={{ height: "1px", backgroundColor: "rgba(255,255,255,0.1)" }} />

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <Code size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Source Code</h3>
            </div>
            <p style={{ fontSize: "14px", marginBottom: "12px" }}>The complete source code for Solitude is available on GitHub.</p>
            <div style={{ display: "flex", alignItems: "center", gap: "12px", backgroundColor: "rgba(0,0,0,0.3)", padding: "12px 16px", borderRadius: "8px", border: "1px solid rgba(255,255,255,0.05)" }}>
              <Github size={20} color={accentColor} />
              <span style={{ fontSize: "14px", fontFamily: "monospace", color: "#e5e2e1" }}>github.com/plotworx/solitude</span>
            </div>
          </div>

          <div style={{ height: "1px", backgroundColor: "rgba(255,255,255,0.1)" }} />

          <div>
            <div style={{ display: "flex", alignItems: "center", gap: "8px", marginBottom: "16px", color: "#e5e2e1" }}>
              <Shield size={18} color={accentColor} />
              <h3 style={{ fontSize: "16px", fontWeight: 700, textTransform: "uppercase", letterSpacing: "1px" }}>Privacy & Data</h3>
            </div>
            <p style={{ fontSize: "14px", marginBottom: "12px" }}>Solitude respects your privacy. All game data is stored locally on your device.</p>
            <ul style={{ listStyleType: "none", padding: 0, margin: 0, display: "flex", flexDirection: "column", gap: "8px" }}>
              {["No personal information is collected", "No data is sent to external servers", "No analytics or tracking", "Game stats and progress stay on your device"].map((item, i) => (
                <li key={i} style={{ display: "flex", alignItems: "center", gap: "8px", fontSize: "14px", color: "#a1a1aa" }}>
                  <div style={{ width: "4px", height: "4px", borderRadius: "50%", backgroundColor: accentColor }} />
                  {item}
                </li>
              ))}
            </ul>
          </div>

        </div>
      </div>
    </div>
  );
};
