import { DEFAULT_SFX_SET_ID, getSfxSet, type SfxSet } from "../data/sfxSets";

// Fixed, settings-independent volume for one-off previews (e.g. the
// Emporium's theme pack detail page) — a deliberate "sample this" action
// should always be audible regardless of the player's saved SFX volume.
const PREVIEW_VOLUME = 0.7;

class AudioService {
  private ctx: AudioContext | null = null;
  private isEnabled: boolean = true;
  private volume: number = 0.8;
  private sfxSetId: string = DEFAULT_SFX_SET_ID;

  private musicEl: HTMLAudioElement | null = null;
  private musicEnabled: boolean = false;
  private musicVolume: number = 0.5;
  private currentMusicUrl: string | null = null;
  private unlockListenerAttached = false;

  constructor() {
    // Web Audio Context initialization on demand
  }

  private initCtx() {
    if (!this.ctx && typeof window !== "undefined") {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.ctx = new AudioCtx();
      }
    }
  }

  public setConfig(enabled: boolean, volume: number) {
    this.isEnabled = enabled;
    this.volume = volume;
  }

  public setSfxSet(id: string) {
    this.sfxSetId = id;
  }

  private playCardMoveWithParams(params: SfxSet["cardMove"], volume: number) {
    this.initCtx();
    if (!this.ctx) return;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = params.oscillatorType;
    osc.frequency.setValueAtTime(params.startFreq, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(params.endFreq, this.ctx.currentTime + 0.05);

    gain.gain.setValueAtTime(0.1 * volume, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.05);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.05);
  }

  private playWinWithParams(params: SfxSet["win"], volume: number) {
    this.initCtx();
    if (!this.ctx) return;

    params.noteFreqs.forEach((freq, i) => {
      if (!this.ctx) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.type = params.oscillatorType;
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.15 * volume, this.ctx.currentTime + i * 0.1);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + i * 0.1 + 0.3);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(this.ctx.currentTime + i * 0.1);
      osc.stop(this.ctx.currentTime + i * 0.1 + 0.3);
    });
  }

  public playCardMove() {
    if (!this.isEnabled) return;
    this.playCardMoveWithParams(getSfxSet(this.sfxSetId).cardMove, this.volume);
  }

  public playWin() {
    if (!this.isEnabled) return;
    this.playWinWithParams(getSfxSet(this.sfxSetId).win, this.volume);
  }

  // Settings-independent one-off previews, e.g. from the Emporium's theme
  // pack detail page — play regardless of the player's SFX enabled/volume
  // settings, without touching the currently-equipped SFX set.
  public previewCardMove(sfxSetId: string) {
    this.playCardMoveWithParams(getSfxSet(sfxSetId).cardMove, PREVIEW_VOLUME);
  }

  public previewWin(sfxSetId: string) {
    this.playWinWithParams(getSfxSet(sfxSetId).win, PREVIEW_VOLUME);
  }

  private ensureMusicEl(): HTMLAudioElement | null {
    if (typeof window === "undefined") return null;
    if (!this.musicEl) {
      this.musicEl = new Audio();
      this.musicEl.loop = true;
      this.musicEl.volume = this.musicVolume;
    }
    return this.musicEl;
  }

  // Browsers block audio playback started without a user gesture. Settings
  // toggles/uploads count, but restoring musicEnabled from a persisted
  // profile on page load doesn't — retry once on the first real interaction
  // if playback is still supposed to be running but isn't.
  private armAutoplayUnlock() {
    if (this.unlockListenerAttached || typeof window === "undefined") return;
    this.unlockListenerAttached = true;
    const retry = () => {
      window.removeEventListener("pointerdown", retry);
      window.removeEventListener("keydown", retry);
      const el = this.musicEl;
      if (el && this.musicEnabled && this.currentMusicUrl && el.paused) {
        el.play().catch(() => {});
      }
    };
    window.addEventListener("pointerdown", retry, { once: true });
    window.addEventListener("keydown", retry, { once: true });
  }

  /** Selects which track is loaded. Pass null to stop and clear the player. */
  public setMusicTrack(url: string | null) {
    if (url === this.currentMusicUrl) return;
    this.currentMusicUrl = url;
    const el = this.ensureMusicEl();
    if (!el) return;

    if (!url) {
      el.pause();
      el.removeAttribute("src");
      return;
    }

    el.src = url;
    if (this.musicEnabled) {
      el.play().catch(() => this.armAutoplayUnlock());
    }
  }

  public setMusicConfig(enabled: boolean, volume: number) {
    this.musicEnabled = enabled;
    this.musicVolume = Math.max(0, Math.min(1, volume));
    const el = this.ensureMusicEl();
    if (!el) return;

    el.volume = this.musicVolume;
    if (enabled && this.currentMusicUrl) {
      el.play().catch(() => this.armAutoplayUnlock());
    } else if (!enabled) {
      el.pause();
    }
  }
}

export const audioService = new AudioService();
