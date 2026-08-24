export interface StoreItem {
  id: string;
  type: "card_back" | "card_deck" | "theme" | "theme_pack" | "victory" | "power_up";
  name: string;
  price: number;
  description?: string;
  icon?: string;
  // For atlas-backed decks (gilded_mystery, fantasy), the preview icon is a
  // sprite crop from the shared atlas instead of a standalone file -- there
  // is no individual per-card image on disk to point `icon` at.
  iconAtlas?: { deckId: string; code: string };
  // A "card_deck" bundles matching face art + back art; a "theme_pack" may
  // additionally bundle both on top of its table/SFX/music. Both default to
  // the item's own id when unset (see MetaGameHub's equip/isEquipped logic).
  cardFaceSetId?: string;
  cardBackPatternId?: string;
}

export const STORE_ITEMS: StoreItem[] = [
  { id: "bicycle", type: "card_back", name: "Bicycle Blue", price: 0, icon: "/assets/cards/back_bicycle.png" },
  { id: "diamond", type: "card_back", name: "Classic Diamond", price: 0, icon: "/assets/cards/back_diamond_classic.png" },
  { id: "botanical", type: "card_back", name: "Botanical Garden", price: 500, icon: "/assets/cards/back_botanical.png" },
  { id: "mystic", type: "card_back", name: "Mystic Aura", price: 500, icon: "/assets/cards/back_mystic.png" },
  { id: "filigree", type: "card_back", name: "Golden Filigree", price: 500, icon: "/assets/cards/back_filigree.png" },
  { id: "royal_navy", type: "card_back", name: "Royal Navy", price: 500, icon: "/assets/cards/back_navy_gold.png", description: "Midnight-blue linework framing a gilt spade and heart, bound in a gold-scrolled border." },
  { id: "crimson_lattice", type: "card_back", name: "Crimson Lattice", price: 500, icon: "/assets/cards/back_red_lattice.png", description: "A scarlet diamond lattice on cream, edged with a scalloped gold-and-red border." },
  { id: "dragon", type: "card_back", name: "Dragon Ruby", price: 1000, icon: "/assets/cards/card_back_dragon_1787130558476.png" },
  { id: "celestial", type: "card_back", name: "Celestial Skies", price: 1000, icon: "/assets/cards/card_back_celestial_1787130567064.png" },
  { id: "gilded_mystery", type: "card_back", name: "Gilded Mystery", price: 1000, iconAtlas: { deckId: "gilded_mystery", code: "back" }, description: "Black leather and gilt heraldry — griffin and peacock, handcrafted for the refined." },
  { id: "gilded_mystery_deck", type: "card_deck", name: "The Gilded Mystery Deck", price: 1600, iconAtlas: { deckId: "gilded_mystery", code: "KH" }, description: "The full Arcanum deck: 52 hand-illustrated gilt faces bound in black leather, with the matching gilded back.", cardFaceSetId: "gilded_mystery", cardBackPatternId: "gilded_mystery" },
  { id: "fantasy", type: "card_back", name: "Dragon's Aegis", price: 1000, iconAtlas: { deckId: "fantasy", code: "back" }, description: "A dragon-wreathed sigil in scale and gold, guarding the deck beneath." },
  { id: "fantasy_deck", type: "card_deck", name: "The Fantasy Deck", price: 2500, iconAtlas: { deckId: "fantasy", code: "KH" }, description: "The full Fantasy deck: 52 hand-illustrated faces of knights, mages, and royalty, with the matching dragon back.", cardFaceSetId: "fantasy", cardBackPatternId: "fantasy" },
  { id: "classic_felt", type: "theme", name: "Casino Green", price: 0 },
  { id: "midnight", type: "theme", name: "Midnight Blue", price: 300 },
  { id: "burgundy_velvet", type: "theme", name: "Burgundy Velvet", price: 300 },
  { id: "nordic", type: "theme", name: "Obsidian Glass", price: 800 },
  { id: "dragons_hoard", type: "theme_pack", name: "Dragon's Hoard", description: "A full pack: table felt, the Dragon Ruby card back, arcade SFX, and Golden Hour Bet music, bundled together.", price: 1400, icon: "/assets/cards/card_back_dragon_1787130558476.png" },
  { id: "celestial_veil", type: "theme_pack", name: "Celestial Veil", description: "A full pack: table felt, the Celestial Skies card back, mystic SFX, and Aces at Dawn music, bundled together.", price: 1400, icon: "/assets/cards/card_back_celestial_1787130567064.png" },
  { id: "gilded_manor", type: "theme_pack", name: "The Gilded Mystery", description: "A full pack: the illustrated Gilded Mystery deck (faces + back), candlelit felt, classic SFX, and Velvet at Seven music, bundled together.", price: 2200, iconAtlas: { deckId: "gilded_mystery", code: "QS" } },
  { id: "fantasy_realm", type: "theme_pack", name: "Fantasy Realm", description: "A full pack: the illustrated Fantasy deck (faces + back), enchanted felt, classic SFX, and Velvet at Seven music, bundled together.", price: 2200, iconAtlas: { deckId: "fantasy", code: "QS" } },
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
