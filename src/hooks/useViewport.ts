import { useEffect, useState } from "react";

const MOBILE_BREAKPOINT = 768;

function readViewport() {
  if (typeof window === "undefined") return { isMobile: false, isLandscape: false };
  const { innerWidth: w, innerHeight: h } = window;
  return {
    // Use the device's narrower dimension so a phone in landscape (e.g.
    // 932x430) is still recognized as mobile, not misread as desktop
    // just because its current width exceeds the breakpoint.
    isMobile: Math.min(w, h) <= MOBILE_BREAKPOINT,
    isLandscape: w > h,
  };
}

export function useViewport() {
  const [viewport, setViewport] = useState(readViewport);

  useEffect(() => {
    const update = () => setViewport(readViewport());
    window.addEventListener("resize", update);
    window.addEventListener("orientationchange", update);
    return () => {
      window.removeEventListener("resize", update);
      window.removeEventListener("orientationchange", update);
    };
  }, []);

  return viewport;
}
