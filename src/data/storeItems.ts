export interface StoreItem {
  id: string;
  type: "card_back" | "theme" | "theme_pack" | "victory" | "power_up";
  name: string;
  price: number;
  description?: string;
  icon?: string;
}

export const STORE_ITEMS: StoreItem[] = [
  { id: "bicycle", type: "card_back", name: "Bicycle Blue", price: 0 },
  { id: "diamond", type: "card_back", name: "Classic Diamond", price: 0 },
  { id: "botanical", type: "card_back", name: "Botanical Garden", price: 500, icon: "/assets/cards/back_botanical.png" },
  { id: "mystic", type: "card_back", name: "Mystic Aura", price: 500, icon: "/assets/cards/back_mystic.png" },
  { id: "filigree", type: "card_back", name: "Golden Filigree", price: 500, icon: "/assets/cards/back_filigree.png" },
  { id: "dragon", type: "card_back", name: "Dragon Ruby", price: 1000, icon: "/assets/cards/card_back_dragon_1787130558476.png" },
  { id: "celestial", type: "card_back", name: "Celestial Skies", price: 1000, icon: "/assets/cards/card_back_celestial_1787130567064.png" },
  { id: "classic_felt", type: "theme", name: "Casino Green", price: 0 },
  { id: "midnight", type: "theme", name: "Midnight Blue", price: 300 },
  { id: "burgundy_velvet", type: "theme", name: "Burgundy Velvet", price: 300 },
  { id: "nordic", type: "theme", name: "Obsidian Glass", price: 800 },
  { id: "dragons_hoard", type: "theme_pack", name: "Dragon's Hoard", description: "A full pack: table felt, the Dragon Ruby card back, arcade SFX, and Golden Hour Bet music, bundled together.", price: 1400, icon: "/assets/cards/card_back_dragon_1787130558476.png" },
  { id: "celestial_veil", type: "theme_pack", name: "Celestial Veil", description: "A full pack: table felt, the Celestial Skies card back, mystic SFX, and Aces at Dawn music, bundled together.", price: 1400, icon: "/assets/cards/card_back_celestial_1787130567064.png" },
  { id: "confetti", type: "victory", name: "Confetti Explosion", price: 400 },
  { id: "fireworks", type: "victory", name: "Golden Fireworks", price: 1000 },
  { id: "unstick_wand", type: "power_up", name: "Unstick Wand", description: "Forces one legal-but-blocked move to become available.", price: 300, icon: "/assets/store/item_unstick_wand_1787130506774.png" },
  { id: "peek_charm", type: "power_up", name: "Peek Charm", description: "Reveal one face-down card without flipping it into play.", price: 150, icon: "/assets/store/item_peek_charm_1787130514247.png" },
  { id: "deck_whisper", type: "power_up", name: "Deck Whisper", description: "Shows the next 3 cards coming from the stock pile.", price: 200, icon: "/assets/store/item_deck_whisper_1787130523895.png" },
  { id: "lucky_reshuffle", type: "power_up", name: "Lucky Reshuffle", description: "Reshuffles just the stock/waste pile without restarting.", price: 250, icon: "/assets/store/item_lucky_reshuffle_1787130533491.png" },
  { id: "undo_token", type: "power_up", name: "Undo Token", description: "Reverses your last move.", price: 100, icon: "/assets/store/item_undo_token_1787130542748.png" },
  { id: "column_breather", type: "power_up", name: "Column Breather", description: "Temporarily reveals the top 2 cards of one face-down column.", price: 350, icon: "/assets/store/item_column_breather_1787130550493.png" },
  { id: "extra_hint", type: "power_up", name: "Extra Hint", description: "Highlights one available legal move you haven't spotted.", price: 100, icon: "/assets/store/item_extra_hint_1787130597111.png" },
  { id: "second_look", type: "power_up", name: "Second Look", description: "Un-flips one card you already committed to.", price: 200, icon: "/assets/store/item_second_look_1787130604583.png" },
  { id: "foundation_nudge", type: "power_up", name: "Foundation Nudge", description: "Flags which card would unlock the most downstream moves.", price: 250, icon: "/assets/store/item_foundation_nudge_1787130612217.png" },
  { id: "time_ease", type: "power_up", name: "Time Ease", description: "Adds 60 seconds on timed modes.", price: 150, icon: "/assets/store/item_time_ease_1787130619507.png" },
  { id: "free_slot", type: "power_up", name: "Free Slot", description: "Temporarily opens an extra holding spot for one card.", price: 300, icon: "/assets/store/item_free_slot_1787130628168.png" },
  { id: "reset_column", type: "power_up", name: "Reset Column", description: "Restacks one fully-dead-end column into a fresh random order.", price: 400, icon: "/assets/store/item_lucky_reshuffle_1787130533491.png" },
];
