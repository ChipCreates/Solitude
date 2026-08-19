import { describe, expect, it } from "vitest";
import { getLevelTitle, getOverallLevel } from "./levelTitles";

describe("getLevelTitle", () => {
  it("maps levels to the correct title band", () => {
    expect(getLevelTitle(1)).toBe("Novice");
    expect(getLevelTitle(2)).toBe("Novice");
    expect(getLevelTitle(3)).toBe("Apprentice");
    expect(getLevelTitle(6)).toBe("Adept");
    expect(getLevelTitle(10)).toBe("Expert");
    expect(getLevelTitle(15)).toBe("Master");
    expect(getLevelTitle(20)).toBe("Grandmaster");
    expect(getLevelTitle(99)).toBe("Grandmaster");
  });
});

describe("getOverallLevel", () => {
  it("returns level 1 / 0 xp when no game progress exists", () => {
    expect(getOverallLevel({})).toEqual({ level: 1, xp: 0 });
  });

  it("picks the highest-level entry across variants", () => {
    const progress = {
      "0": { level: 3, xp: 100 },
      "1": { level: 7, xp: 50 },
      "2": { level: 5, xp: 400 },
    };
    expect(getOverallLevel(progress)).toEqual({ level: 7, xp: 50 });
  });

  it("breaks ties on level by higher xp", () => {
    const progress = {
      "0": { level: 5, xp: 100 },
      "1": { level: 5, xp: 300 },
    };
    expect(getOverallLevel(progress)).toEqual({ level: 5, xp: 300 });
  });
});
