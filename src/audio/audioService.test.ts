import { describe, expect, it, vi, beforeEach, afterEach } from "vitest";
import { audioService } from "./audioService";

class MockParam {
  value = 0;
  setValueAtTime = vi.fn();
  exponentialRampToValueAtTime = vi.fn();
}

class MockOscillator {
  type = "";
  frequency = new MockParam();
  connect = vi.fn();
  start = vi.fn();
  stop = vi.fn();
}

class MockGainNode {
  gain = new MockParam();
  connect = vi.fn();
}

class MockAudioContext {
  currentTime = 0;
  destination = {};
  createOscillator() {
    return new MockOscillator();
  }
  createGain() {
    return new MockGainNode();
  }
}

describe("audioService SFX sets", () => {
  beforeEach(() => {
    (window as unknown as { AudioContext: typeof AudioContext }).AudioContext =
      MockAudioContext as unknown as typeof AudioContext;
    audioService.setConfig(true, 1);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("uses the classic set's sine wave and 440Hz start frequency by default", () => {
    audioService.setSfxSet("classic");
    const spy = vi.spyOn(MockAudioContext.prototype, "createOscillator");
    audioService.playCardMove();

    const osc = spy.mock.results[spy.mock.results.length - 1].value as MockOscillator;
    expect(osc.type).toBe("sine");
    expect(osc.frequency.setValueAtTime).toHaveBeenCalledWith(440, expect.any(Number));
  });

  it("switches oscillator type and frequency when a different SFX set is selected", () => {
    audioService.setSfxSet("arcade");
    const spy = vi.spyOn(MockAudioContext.prototype, "createOscillator");
    audioService.playCardMove();

    const osc = spy.mock.results[spy.mock.results.length - 1].value as MockOscillator;
    expect(osc.type).toBe("square");
    expect(osc.frequency.setValueAtTime).toHaveBeenCalledWith(300, expect.any(Number));
  });

  it("plays one oscillator per win note using the selected set's oscillator type", () => {
    audioService.setSfxSet("mystic");
    const spy = vi.spyOn(MockAudioContext.prototype, "createOscillator");
    audioService.playWin();

    expect(spy).toHaveBeenCalledTimes(4);
    const lastFour = spy.mock.results.slice(-4).map((r) => r.value as MockOscillator);
    expect(lastFour.every((osc) => osc.type === "triangle")).toBe(true);
  });

  it("previewCardMove plays the requested set even when SFX is disabled and doesn't change the equipped set", () => {
    audioService.setSfxSet("classic");
    audioService.setConfig(false, 1); // SFX disabled — playCardMove() would no-op
    const spy = vi.spyOn(MockAudioContext.prototype, "createOscillator");

    audioService.previewCardMove("arcade");
    const osc = spy.mock.results[spy.mock.results.length - 1].value as MockOscillator;
    expect(osc.type).toBe("square");

    // The equipped set is untouched — a subsequent real playCardMove (once
    // re-enabled) still uses "classic", not the previewed "arcade".
    audioService.setConfig(true, 1);
    audioService.playCardMove();
    const equippedOsc = spy.mock.results[spy.mock.results.length - 1].value as MockOscillator;
    expect(equippedOsc.type).toBe("sine");
  });

  it("previewWin plays the requested set's notes regardless of the SFX enabled setting", () => {
    audioService.setConfig(false, 1);
    const spy = vi.spyOn(MockAudioContext.prototype, "createOscillator");

    audioService.previewWin("mystic");

    expect(spy).toHaveBeenCalledTimes(4);
    expect(spy.mock.results.every((r) => (r.value as MockOscillator).type === "triangle")).toBe(true);
  });
});
