import { describe, expect, it, vi } from "vitest";
import { applyThemePack, THEME_PRESETS } from "./presets";

function makeSetters() {
  return {
    setThemeId: vi.fn(),
    setCardBackPattern: vi.fn(),
    setCardFaceSetId: vi.fn(),
    setSfxSetId: vi.fn(),
    setMusicTrackId: vi.fn(),
  };
}

describe("applyThemePack", () => {
  it("always sets the theme id, even for a plain (non-pack) preset", () => {
    const setters = makeSetters();
    applyThemePack("classic_felt", setters);

    expect(setters.setThemeId).toHaveBeenCalledWith("classic_felt");
    expect(setters.setCardBackPattern).not.toHaveBeenCalled();
    expect(setters.setCardFaceSetId).not.toHaveBeenCalled();
    expect(setters.setSfxSetId).not.toHaveBeenCalled();
    expect(setters.setMusicTrackId).not.toHaveBeenCalled();
  });

  it("fans out the bundled card back, SFX set, and music track for a full theme pack", () => {
    const setters = makeSetters();
    applyThemePack("dragons_hoard", setters);

    const preset = THEME_PRESETS.dragons_hoard;
    expect(setters.setThemeId).toHaveBeenCalledWith("dragons_hoard");
    expect(setters.setCardBackPattern).toHaveBeenCalledWith(preset.cardBackPatternId);
    expect(setters.setSfxSetId).toHaveBeenCalledWith(preset.sfxSetId);
    expect(setters.setMusicTrackId).toHaveBeenCalledWith(preset.musicTrackId);
    // dragons_hoard has no cardFaceSetId -- documents the sticky-field
    // behavior as intentional (see gilded_manor test below).
    expect(setters.setCardFaceSetId).not.toHaveBeenCalled();
  });

  it("also fans out the bundled card face set for a pack that includes illustrated card faces", () => {
    const setters = makeSetters();
    applyThemePack("gilded_manor", setters);

    const preset = THEME_PRESETS.gilded_manor;
    expect(setters.setThemeId).toHaveBeenCalledWith("gilded_manor");
    expect(setters.setCardFaceSetId).toHaveBeenCalledWith("gilded_mystery");
    expect(setters.setCardBackPattern).toHaveBeenCalledWith(preset.cardBackPatternId);
    expect(setters.setSfxSetId).toHaveBeenCalledWith(preset.sfxSetId);
    expect(setters.setMusicTrackId).toHaveBeenCalledWith(preset.musicTrackId);
  });

  it("does nothing beyond setting the theme id for an unknown theme id", () => {
    const setters = makeSetters();
    applyThemePack("not_a_real_theme", setters);

    expect(setters.setThemeId).toHaveBeenCalledWith("not_a_real_theme");
    expect(setters.setCardBackPattern).not.toHaveBeenCalled();
    expect(setters.setCardFaceSetId).not.toHaveBeenCalled();
  });
});
