export interface AvatarOption {
  id: string;
  label: string;
  src: string;
  ringColor: string;
}

// Illustrated local avatars — purely cosmetic, no images to fetch remotely
// and no personal data involved. Sliced from a single hand-authored sprite
// sheet at public/assets/avatars.jpeg.
export const AVATAR_OPTIONS: AvatarOption[] = [
  { id: "queen", label: "Queen", src: "/assets/avatars/queen.png", ringColor: "#c94a4a" },
  { id: "king", label: "King", src: "/assets/avatars/king.png", ringColor: "#e9c349" },
  { id: "sorceress", label: "Sorceress", src: "/assets/avatars/sorceress.png", ringColor: "#9b6fd1" },
  { id: "jester", label: "Jester", src: "/assets/avatars/jester.png", ringColor: "#4fa8e0" },
  { id: "knight", label: "Knight", src: "/assets/avatars/knight.png", ringColor: "#7fa9d1" },
  { id: "grandma", label: "Grandma", src: "/assets/avatars/grandma.png", ringColor: "#c98a4b" },
];

export const DEFAULT_AVATAR_ID = AVATAR_OPTIONS[0].id;

export function getAvatarOption(avatarId: string): AvatarOption {
  return AVATAR_OPTIONS.find((a) => a.id === avatarId) ?? AVATAR_OPTIONS[0];
}
