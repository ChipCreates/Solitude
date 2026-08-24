export interface ThemePreset {
  id: string;
  name: string;
  tableColor: string;
  tableGradientEnd: string;
  accentColor: string;
  cardFaceOverlay: string;
  defaultOverlayIntensity: number;
  // Theme *pack* fields — additive/optional so the built-in presets below
  // keep working unmodified. When present, selecting this theme (from
  // Settings or by purchasing it in the Emporium) equips the matching
  // card back / SFX / music together via `applyThemePack` rather than
  // leaving them as independently-chosen settings.
  cardBackPatternId?: string;
  cardFaceSetId?: string;
  sfxSetId?: string;
  musicTrackId?: string;
  // Optional felt/board texture image, drawn under the table gradient.
  // No built-in preset sets this yet — the board-render code falls back
  // to the plain gradient when it's absent.
  boardTextureUrl?: string;
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
  dragons_hoard: {
    id: "dragons_hoard",
    name: "Dragon's Hoard",
    tableColor: "#3a0e0e",
    tableGradientEnd: "#1a0505",
    accentColor: "#e9852f",
    cardFaceOverlay: "#2a0a00",
    defaultOverlayIntensity: 0.05,
    cardBackPatternId: "dragon",
    sfxSetId: "arcade",
    musicTrackId: "golden_hour_bet",
  },
  celestial_veil: {
    id: "celestial_veil",
    name: "Celestial Veil",
    tableColor: "#1c1440",
    tableGradientEnd: "#0a0620",
    accentColor: "#9b6fd1",
    cardFaceOverlay: "#120a2e",
    defaultOverlayIntensity: 0.05,
    cardBackPatternId: "celestial",
    sfxSetId: "mystic",
    musicTrackId: "aces_at_dawn",
  },
  gilded_manor: {
    id: "gilded_manor",
    name: "The Gilded Mystery",
    tableColor: "#1a1410",
    tableGradientEnd: "#0d0a08",
    accentColor: "#d4af37",
    cardFaceOverlay: "#2a1f10",
    defaultOverlayIntensity: 0,
    cardBackPatternId: "gilded_mystery",
    cardFaceSetId: "gilded_mystery",
    sfxSetId: "classic",
    musicTrackId: "velvet_at_seven",
  },
  fantasy_realm: {
    id: "fantasy_realm",
    name: "Fantasy Realm",
    tableColor: "#0f2418",
    tableGradientEnd: "#081208",
    accentColor: "#c9a24b",
    cardFaceOverlay: "#102015",
    defaultOverlayIntensity: 0,
    cardBackPatternId: "fantasy",
    cardFaceSetId: "fantasy",
    sfxSetId: "classic",
    musicTrackId: "velvet_at_seven",
  },
};

export interface ThemePackSetters {
  setThemeId: (id: string) => void;
  setCardBackPattern: (pattern: string) => void;
  setCardFaceSetId: (id: string) => void;
  setSfxSetId: (id: string) => void;
  setMusicTrackId: (id: string) => void;
}

// Single place that fans a theme selection out to its bundled card
// back/SFX/music — used by both the Settings theme picker and the
// Emporium purchase flow so the two stay in sync automatically.
export function applyThemePack(themeId: string, setters: ThemePackSetters): void {
  setters.setThemeId(themeId);
  const preset = THEME_PRESETS[themeId];
  if (!preset) return;
  if (preset.cardBackPatternId) setters.setCardBackPattern(preset.cardBackPatternId);
  if (preset.cardFaceSetId) setters.setCardFaceSetId(preset.cardFaceSetId);
  if (preset.sfxSetId) setters.setSfxSetId(preset.sfxSetId);
  if (preset.musicTrackId) setters.setMusicTrackId(preset.musicTrackId);
}
