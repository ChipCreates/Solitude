import { describe, expect, it } from "vitest";
import { atlasSprite, cardImagePath, getBackPatternCss, getBackPatternPosition, getBackPatternSize } from "./CardWidget";
import { GILDED_MYSTERY_ATLAS_CELLS } from "../data/gildedMysteryAtlas";
import { DEFAULT_ATLAS_CELLS } from "../data/defaultAtlas";

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

describe("cardImagePath", () => {
  it("resolves a hypothetical per-file deck (none exist today -- every current deck is atlas-backed) to an individual asset path", () => {
    expect(cardImagePath("bicycle", 1, 3, 30)).toBe("/assets/cards/bicycle/AS.png");
  });
});

describe("atlasSprite", () => {
  it("maps a desktop Gilded Mystery card to its cell at 1:1 scale", () => {
    const cell = GILDED_MYSTERY_ATLAS_CELLS["gilded_mystery:AS"];
    const sprite = atlasSprite("gilded_mystery", "AS", cell.w);
    expect(sprite).not.toBeNull();
    expect(sprite!.backgroundPosition).toBe(`-${cell.x}px -${cell.y}px`);
    expect(sprite!.backgroundImage).toContain("gilded_mystery_atlas.webp");
  });

  it("scales the cell and its position together for a smaller on-screen card", () => {
    const cell = GILDED_MYSTERY_ATLAS_CELLS["gilded_mystery_mini:KD"];
    const sprite = atlasSprite("gilded_mystery_mini", "KD", cell.w / 2);
    expect(sprite!.backgroundPosition).toBe(`-${cell.x / 2}px -${cell.y / 2}px`);
  });

  it("maps the default deck's desktop and mini cards to the default atlas", () => {
    const cell = DEFAULT_ATLAS_CELLS["default:AS"];
    const sprite = atlasSprite("default", "AS", cell.w);
    expect(sprite).not.toBeNull();
    expect(sprite!.backgroundPosition).toBe(`-${cell.x}px -${cell.y}px`);
    expect(sprite!.backgroundImage).toContain("default_atlas.webp");

    const miniCell = DEFAULT_ATLAS_CELLS["default_mini:joker"];
    const miniSprite = atlasSprite("default_mini", "joker", miniCell.w);
    expect(miniSprite!.backgroundPosition).toBe(`-${miniCell.x}px -${miniCell.y}px`);
  });

  it("returns null for a deck/code that has no atlas cell", () => {
    expect(atlasSprite("bicycle", "AS", 100)).toBeNull();
    expect(atlasSprite("gilded_mystery", "not_a_code", 100)).toBeNull();
    expect(atlasSprite("default", "not_a_code", 100)).toBeNull();
  });
});
