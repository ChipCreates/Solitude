import React, { useEffect, useState } from "react";

interface SplashPageProps {
  onLoadComplete: () => void;
}

export const SplashPage: React.FC<SplashPageProps> = ({ onLoadComplete }) => {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    let start = performance.now();
    const duration = 2000; // 2 seconds minimum splash duration

    const updateProgress = (time: number) => {
      const elapsed = time - start;
      const t = Math.min(elapsed / duration, 1);
      setProgress(t);

      if (t < 1) {
        requestAnimationFrame(updateProgress);
      } else {
        // Wait a tiny bit after reaching 100% before firing complete
        setTimeout(onLoadComplete, 200);
      }
    };

    requestAnimationFrame(updateProgress);
  }, [onLoadComplete]);

  return (
    <div style={{
      position: "fixed",
      inset: 0,
      backgroundColor: "#1a1a1a",
      backgroundImage: "url('/assets/solitude-bg.webp')",
      backgroundSize: "cover",
      backgroundPosition: "center",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      zIndex: 9999
    }}>
      <img src="/assets/solitude-logo.svg" alt="Solitude Logo" style={{ width: "200px", maxWidth: "80%", marginBottom: "24px" }} />
      <h1 style={{ fontFamily: "Georgia, serif", fontSize: "48px", color: "white", letterSpacing: "2px", textShadow: "0 2px 8px rgba(0,0,0,0.8)", margin: 0, marginBottom: "48px" }}>
        Solitude
      </h1>
      
      <div style={{ width: "240px", height: "4px", backgroundColor: "rgba(0,0,0,0.5)", borderRadius: "4px", overflow: "hidden", marginBottom: "16px" }}>
        <div style={{
          width: `${progress * 100}%`,
          height: "100%",
          backgroundColor: "#fff",
          boxShadow: "0 0 10px rgba(255,255,255,0.8)",
          transition: "width 0.05s linear"
        }} />
      </div>

      <p style={{ fontFamily: "Georgia, serif", fontSize: "14px", fontStyle: "italic", color: "rgba(255,255,255,0.8)" }}>
        Shuffling the deck...
      </p>
    </div>
  );
};
