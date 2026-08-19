class AudioService {
  private ctx: AudioContext | null = null;
  private isEnabled: boolean = true;
  private volume: number = 0.8;

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

  public playCardMove() {
    if (!this.isEnabled) return;
    this.initCtx();
    if (!this.ctx) return;

    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = "sine";
    osc.frequency.setValueAtTime(440, this.ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(880, this.ctx.currentTime + 0.05);

    gain.gain.setValueAtTime(0.1 * this.volume, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.05);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start();
    osc.stop(this.ctx.currentTime + 0.05);
  }

  public playWin() {
    if (!this.isEnabled) return;
    this.initCtx();
    if (!this.ctx) return;

    const notes = [523.25, 659.25, 783.99, 1046.5];
    notes.forEach((freq, i) => {
      if (!this.ctx) return;
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();

      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.15 * this.volume, this.ctx.currentTime + i * 0.1);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + i * 0.1 + 0.3);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(this.ctx.currentTime + i * 0.1);
      osc.stop(this.ctx.currentTime + i * 0.1 + 0.3);
    });
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
