export interface SfxSet {
  id: string;
  name: string;
  cardMove: {
    oscillatorType: OscillatorType;
    startFreq: number;
    endFreq: number;
  };
  win: {
    oscillatorType: OscillatorType;
    noteFreqs: number[];
  };
}

// Coordinated sound-effect variants for theme packs. All synthesized live
// via the Web Audio API (see src/audio/audioService.ts) rather than sample
// files, so a new set is just a new set of oscillator parameters — no new
// binary assets to source or ship.
export const SFX_SETS: SfxSet[] = [
  {
    id: "classic",
    name: "Classic",
    cardMove: { oscillatorType: "sine", startFreq: 440, endFreq: 880 },
    win: { oscillatorType: "sine", noteFreqs: [523.25, 659.25, 783.99, 1046.5] },
  },
  {
    id: "arcade",
    name: "Arcade",
    cardMove: { oscillatorType: "square", startFreq: 300, endFreq: 660 },
    win: { oscillatorType: "square", noteFreqs: [440, 554.37, 659.25, 880] },
  },
  {
    id: "mystic",
    name: "Mystic",
    cardMove: { oscillatorType: "triangle", startFreq: 500, endFreq: 1000 },
    win: { oscillatorType: "triangle", noteFreqs: [587.33, 739.99, 880, 1174.66] },
  },
];

export const DEFAULT_SFX_SET_ID = SFX_SETS[0].id;

export function getSfxSet(id: string): SfxSet {
  return SFX_SETS.find((s) => s.id === id) ?? SFX_SETS[0];
}
