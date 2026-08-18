import React, { useEffect, useRef } from "react";

interface GameCanvasProps {
  wasmPingResult?: number | null;
}

export const GameCanvas: React.FC<GameCanvasProps> = ({ wasmPingResult }) => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;

    const resizeAndRender = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = canvas.getBoundingClientRect();

      canvas.width = Math.floor(rect.width * dpr);
      canvas.height = Math.floor(rect.height * dpr);

      ctx.save();
      ctx.scale(dpr, dpr);

      // Background: Deep felt green gradient
      const gradient = ctx.createRadialGradient(
        rect.width / 2,
        rect.height / 2,
        100,
        rect.width / 2,
        rect.height / 2,
        Math.max(rect.width, rect.height)
      );
      gradient.addColorStop(0, "#184528");
      gradient.addColorStop(1, "#0a1e12");

      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, rect.width, rect.height);

      // Draw static card slot placeholders
      const slotWidth = Math.min(100, rect.width * 0.11);
      const slotHeight = slotWidth * 1.4;
      const gap = 16;
      const topOffset = 40;
      const startX = 24;

      ctx.lineWidth = 1.5;
      ctx.strokeStyle = "rgba(255, 255, 255, 0.15)";
      ctx.fillStyle = "rgba(255, 255, 255, 0.03)";

      // Top row slots (Stock + Waste, 4 Foundations)
      for (let i = 0; i < 7; i++) {
        const x = startX + i * (slotWidth + gap);
        if (x + slotWidth > rect.width - 24) break;

        ctx.beginPath();
        ctx.roundRect(x, topOffset, slotWidth, slotHeight, 8);
        ctx.fill();
        ctx.stroke();
      }

      // Display WASM ping indicator text in gold
      ctx.fillStyle = "#e9c349";
      ctx.font = "600 16px Inter, sans-serif";
      ctx.fillText(
        `Solitude Engine WASM Status: ${
          wasmPingResult !== null && wasmPingResult !== undefined
            ? `Connected (Ping Code: ${wasmPingResult})`
            : "Initializing..."
        }`,
        startX,
        topOffset + slotHeight + 36
      );

      ctx.restore();
    };

    const renderLoop = () => {
      resizeAndRender();
      animationFrameId = requestAnimationFrame(renderLoop);
    };

    renderLoop();

    const handleResize = () => {
      resizeAndRender();
    };

    window.addEventListener("resize", handleResize);

    return () => {
      cancelAnimationFrame(animationFrameId);
      window.removeEventListener("resize", handleResize);
    };
  }, [wasmPingResult]);

  return (
    <canvas
      ref={canvasRef}
      style={{
        width: "100%",
        height: "100%",
        display: "block",
      }}
    />
  );
};
