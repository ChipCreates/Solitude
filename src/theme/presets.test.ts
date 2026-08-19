import { describe, expect, it, vi } from "vitest";
import { applyThemePack, THEME_PRESETS } from "./presets";

describe("applyThemePack", () => {
  it("always sets the theme id, even for a plain (non-pack) preset", () => {
    const setters = {
      setThemeId: vi.fn(),
      setCardBackPattern: vi.fn(),
      setSfxSetId: vi.fn(),
      setMusicTrackId: vi.fn(),
    };
    applyThemePack("classic_felt", setters);

    expect(setters.setThemeId).toHaveBeenCalledWith("classic_felt");
    expect(setters.setCardBackPattern).not.toHaveBeenCalled();
    expect(setters.setSfxSetId).not.toHaveBeenCalled();
    expect(setters.setMusicTrackId).not.toHaveBeenCalled();
  });

  it("fans out the bundled card back, SFX set, and music track for a full theme pack", () => {
    const setters = {
      setThemeId: vi.fn(),
      setCardBackPattern: vi.fn(),
      setSfxSetId: vi.fn(),
      setMusicTrackId: vi.fn(),
    };
    applyThemePack("dragons_hoard", setters);

    const preset = THEME_PRESETS.dragons_hoard;
    expect(setters.setThemeId).toHaveBeenCalledWith("dragons_hoard");
    expect(setters.setCardBackPattern).toHaveBeenCalledWith(preset.cardBackPatternId);
    expect(setters.setSfxSetId).toHaveBeenCalledWith(preset.sfxSetId);
    expect(setters.setMusicTrackId).toHaveBeenCalledWith(preset.musicTrackId);
  });

  it("does nothing beyond setting the theme id for an unknown theme id", () => {
    const setters = {
      setThemeId: vi.fn(),
      setCardBackPattern: vi.fn(),
      setSfxSetId: vi.fn(),
      setMusicTrackId: vi.fn(),
    };
    applyThemePack("not_a_real_theme", setters);

    expect(setters.setThemeId).toHaveBeenCalledWith("not_a_real_theme");
    expect(setters.setCardBackPattern).not.toHaveBeenCalled();
  });
});
