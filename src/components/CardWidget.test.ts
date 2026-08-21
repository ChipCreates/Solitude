import { describe, expect, it } from "vitest";
import { getBackPatternCss, getBackPatternPosition, getBackPatternSize } from "./CardWidget";

describe("card back pattern helpers", () => {
  it("resolves dragon and celestial to their purchased artwork instead of falling through to the default diamond pattern", () => {
    expect(getBackPatternCss("dragon")).toBe("url(/assets/cards/card_back_dragon_1787130558476.png)");
    expect(getBackPatternCss("celestial")).toBe("url(/assets/cards/card_back_celestial_1787130567064.png)");
    expect(getBackPatternSize("dragon")).toBe("100% 100%");
    expect(getBackPatternSize("celestial")).toBe("100% 100%");
    expect(getBackPatternPosition("dragon")).toBe("center");
    expect(getBackPatternPosition("celestial")).toBe("center");
  });

  it("still falls back to the diamond CSS pattern for an unrecognized pattern id", () => {
    expect(getBackPatternCss("not_a_real_pattern")).toContain("repeating-linear-gradient");
    expect(getBackPatternSize("not_a_real_pattern")).toBe("auto");
  });

  it("resolves bundled image patterns to their asset URLs", () => {
    expect(getBackPatternCss("bicycle")).toBe("url(/assets/cards/back_bicycle.png)");
    expect(getBackPatternCss("mystic")).toBe("url(/assets/cards/back_mystic.png)");
  });

  it("resolves the Gilded Mystery card back to its own asset folder", () => {
    expect(getBackPatternCss("gilded_mystery")).toBe("url(/assets/cards/the_gilded_mystery/back.webp)");
    expect(getBackPatternSize("gilded_mystery")).toBe("100% 100%");
    expect(getBackPatternPosition("gilded_mystery")).toBe("center");
  });
});
