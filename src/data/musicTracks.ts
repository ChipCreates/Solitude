export interface MusicTrack {
  id: string;
  name: string;
  url: string;
}

// Bundled background-music tracks shipped with the app. Add an entry here
// whenever a new file is dropped into public/assets/sound/background-music/.
export const MUSIC_TRACKS: MusicTrack[] = [
  { id: "velvet_at_seven", name: "Velvet at Seven", url: "/assets/sound/background-music/Velvet_at_Seven.mp3" },
  { id: "aces_at_dawn", name: "Aces at Dawn", url: "/assets/sound/background-music/Aces_at_Dawn.mp3" },
  { id: "golden_hour_bet", name: "Golden Hour Bet", url: "/assets/sound/background-music/Golden_Hour_Bet.mp3" },
];

// Sentinel track id for a track the player picked from their own device.
export const CUSTOM_TRACK_ID = "custom";
