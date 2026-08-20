import { describe, expect, it } from "vitest";
import { getLevelTitle, getLevelTitleDescription, getGlobalLevel } from "./levelTitles";

describe("getLevelTitle", () => {
  it("maps levels to the correct title band", () => {
    expect(getLevelTitle(1)).toBe("Novice");
    expect(getLevelTitle(2)).toBe("Novice");
    expect(getLevelTitle(3)).toBe("Apprentice");
    expect(getLevelTitle(6)).toBe("Adept");
    expect(getLevelTitle(10)).toBe("Journeyman");
    expect(getLevelTitle(15)).toBe("Expert");
    expect(getLevelTitle(22)).toBe("Specialist");
    expect(getLevelTitle(30)).toBe("Veteran");
    expect(getLevelTitle(40)).toBe("Master");
    expect(getLevelTitle(55)).toBe("Grandmaster");
    expect(getLevelTitle(75)).toBe("Elite");
    expect(getLevelTitle(100)).toBe("Legend");
    expect(getLevelTitle(150)).toBe("Immortal");
    expect(getLevelTitle(999)).toBe("Immortal");
  });
});

describe("getLevelTitleDescription", () => {
  it("has a description for every title band", () => {
    for (const level of [1, 3, 6, 10, 15, 22, 30, 40, 55, 75, 100, 150]) {
      expect(getLevelTitleDescription(level).length).toBeGreaterThan(0);
    }
  });

  it("matches the title band boundaries, not just the exact minLevel", () => {
    expect(getLevelTitleDescription(2)).toBe(getLevelTitleDescription(1));
    expect(getLevelTitleDescription(99)).toBe(getLevelTitleDescription(75));
  });
});

describe("getGlobalLevel", () => {
  it("returns level 1 / 0 xp when no game progress exists", () => {
    expect(getGlobalLevel({})).toEqual({ level: 1, xp: 0 });
  });

  it("round-trips a single variant's own level/xp exactly", () => {
    const progress = { "0": { level: 5, xp: 300 } };
    expect(getGlobalLevel(progress)).toEqual({ level: 5, xp: 300 });
  });

  it("pools total XP earned across variants into one higher account level", () => {
    // Total XP earned per variant = its own xp remainder + every level-up
    // it already paid for. Pooling all three should out-level any single
    // variant on its own, since none of them individually reaches level 3
    // with 850 xp to spare.
    const progress = {
      "0": { level: 3, xp: 100 },
      "1": { level: 2, xp: 50 },
      "2": { level: 1, xp: 200 },
    };
    expect(getGlobalLevel(progress)).toEqual({ level: 3, xp: 850 });
  });
});
