import { describe, expect, it, afterEach } from "vitest";
import { act, renderHook } from "@testing-library/react";
import { useViewport } from "./useViewport";

function setWindowSize(width: number, height: number) {
  Object.defineProperty(window, "innerWidth", { writable: true, configurable: true, value: width });
  Object.defineProperty(window, "innerHeight", { writable: true, configurable: true, value: height });
}

describe("useViewport", () => {
  afterEach(() => {
    setWindowSize(1024, 768);
  });

  it("treats a narrow portrait window as mobile", () => {
    setWindowSize(390, 844);
    const { result } = renderHook(() => useViewport());
    expect(result.current.isMobile).toBe(true);
    expect(result.current.isLandscape).toBe(false);
  });

  it("still recognizes a phone rotated to landscape as mobile, not desktop", () => {
    // A phone in landscape can have a width well past the 768 breakpoint
    // (e.g. iPhone 14 Pro Max: 932x430) — the narrower dimension (height)
    // is what should determine "is this a phone."
    setWindowSize(932, 430);
    const { result } = renderHook(() => useViewport());
    expect(result.current.isMobile).toBe(true);
    expect(result.current.isLandscape).toBe(true);
  });

  it("treats a normal desktop window as non-mobile", () => {
    setWindowSize(1440, 900);
    const { result } = renderHook(() => useViewport());
    expect(result.current.isMobile).toBe(false);
    expect(result.current.isLandscape).toBe(true);
  });

  it("updates when the window is resized", () => {
    setWindowSize(1440, 900);
    const { result } = renderHook(() => useViewport());
    expect(result.current.isMobile).toBe(false);

    act(() => {
      setWindowSize(390, 844);
      window.dispatchEvent(new Event("resize"));
    });
    expect(result.current.isMobile).toBe(true);
  });

  it("updates on orientationchange even if the resize event lags", () => {
    setWindowSize(390, 844);
    const { result } = renderHook(() => useViewport());
    expect(result.current.isLandscape).toBe(false);

    act(() => {
      setWindowSize(844, 390);
      window.dispatchEvent(new Event("orientationchange"));
    });
    expect(result.current.isLandscape).toBe(true);
  });
});
