import { describe, expect, it, vi } from "vitest";
import { getCachedImage } from "./boardTexture";

describe("getCachedImage", () => {
  it("returns null until the image has actually finished loading", () => {
    expect(getCachedImage("/assets/texture-not-loaded.png")).toBeNull();
  });

  it("constructs only one Image per URL even across repeated calls", () => {
    const ctorSpy = vi.fn();
    class SpiedImage extends Image {
      constructor() {
        super();
        ctorSpy();
      }
    }
    const original = window.Image;
    (window as unknown as { Image: typeof Image }).Image = SpiedImage as unknown as typeof Image;

    const url = "/assets/texture-cached.png";
    getCachedImage(url);
    getCachedImage(url);
    getCachedImage(url);

    expect(ctorSpy).toHaveBeenCalledTimes(1);
    (window as unknown as { Image: typeof Image }).Image = original;
  });
});
