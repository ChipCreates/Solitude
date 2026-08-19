export interface ThemePreset {
  id: string;
  name: string;
  tableColor: string;
  tableGradientEnd: string;
  accentColor: string;
  cardFaceOverlay: string;
  defaultOverlayIntensity: number;
}

export const THEME_PRESETS: Record<string, ThemePreset> = {
  classic_felt: {
    id: "classic_felt",
    name: "Classic Felt",
    tableColor: "#184528",
    tableGradientEnd: "#0a1e12",
    accentColor: "#e9c349",
    cardFaceOverlay: "#000000",
    defaultOverlayIntensity: 0.0,
  },
  royal_blue: {
    id: "royal_blue",
    name: "Royal Blue",
    tableColor: "#1a2a47",
    tableGradientEnd: "#0c1424",
    accentColor: "#49a3e9",
    cardFaceOverlay: "#001133",
    defaultOverlayIntensity: 0.05,
  },
  burgundy_velvet: {
    id: "burgundy_velvet",
    name: "Burgundy Velvet",
    tableColor: "#471a24",
    tableGradientEnd: "#240c12",
    accentColor: "#e94968",
    cardFaceOverlay: "#330011",
    defaultOverlayIntensity: 0.05,
  },
  midnight: {
    id: "midnight",
    name: "Midnight",
    tableColor: "#1a1a1a",
    tableGradientEnd: "#0d0d0d",
    accentColor: "#c6c6c7",
    cardFaceOverlay: "#000000",
    defaultOverlayIntensity: 0.1,
  },
  vintage_light: {
    id: "vintage_light",
    name: "Vintage Light",
    tableColor: "#d4c5b0",
    tableGradientEnd: "#a89780",
    accentColor: "#8c5a2b",
    cardFaceOverlay: "#7a5c36",
    defaultOverlayIntensity: 0.08,
  },
  nordic: {
    id: "nordic",
    name: "Nordic Minimal",
    tableColor: "#2b353b",
    tableGradientEnd: "#161b1e",
    accentColor: "#93b5c6",
    cardFaceOverlay: "#1a2226",
    defaultOverlayIntensity: 0.05,
  },
};
