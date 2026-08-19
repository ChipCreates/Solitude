import { describe, expect, it } from "vitest";
import { calculatePyramidLayout } from "./pyramidLayout";

describe("calculatePyramidLayout", () => {
  it("never shrinks card width below the 44px minimum touch-target guidance, even on a very narrow viewport", () => {
    const layout = calculatePyramidLayout(280, 600);
    expect(layout.cardWidth).toBeGreaterThanOrEqual(44);
  });

  it("caps card width at 100px on a very wide viewport", () => {
    const layout = calculatePyramidLayout(2000, 1200);
    expect(layout.cardWidth).toBe(100);
  });

  it("flags compact tier once card width drops below 60px", () => {
    const narrow = calculatePyramidLayout(280, 600);
    expect(narrow.cardWidth).toBeLessThan(60);
    expect(narrow.isCompactTier).toBe(true);

    const wide = calculatePyramidLayout(1200, 800);
    expect(wide.isCompactTier).toBe(false);
  });
});
