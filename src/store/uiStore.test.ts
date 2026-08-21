import { describe, expect, it, vi, beforeEach } from "vitest";

vi.mock("../persistence/store", () => ({
  store: {
    saveSettings: vi.fn().mockResolvedValue(undefined),
    loadSettings: vi.fn().mockResolvedValue({}),
    saveProgression: vi.fn().mockResolvedValue(undefined),
    loadProgression: vi.fn().mockResolvedValue({
      coins: 0,
      totalCoinsEarned: 0,
      coinLedger: [],
      unlockedItems: [],
      unlockedAchievements: [],
      difficulty: "normal",
      gameProgress: {},
      powerUpInventory: {},
    }),
  },
}));

import { useUIStore } from "./uiStore";
import { store } from "../persistence/store";

describe("uiStore", () => {
  beforeEach(() => {
    useUIStore.setState({
      coins: 0,
      totalCoinsEarned: 0,
      coinLedger: [],
      unlockedItems: [],
      unlockedAchievements: [],
      powerUpInventory: {},
      gameProgress: {},
    });
  });

  it("adds and subtracts coins, refusing to go negative", () => {
    useUIStore.getState().addCoins(100);
    expect(useUIStore.getState().coins).toBe(100);
    expect(useUIStore.getState().coinLedger).toEqual([
      { ts: expect.any(Number), amount: 100 },
    ]);

    const ok = useUIStore.getState().subtractCoins(40);
    expect(ok).toBe(true);
    expect(useUIStore.getState().coins).toBe(60);
    // Lifetime-earned tracks total inflow only — spending doesn't reduce it.
    expect(useUIStore.getState().totalCoinsEarned).toBe(100);

    const insufficient = useUIStore.getState().subtractCoins(1000);
    expect(insufficient).toBe(false);
    expect(useUIStore.getState().coins).toBe(60);
  });

  it("unlockItem is idempotent", () => {
    useUIStore.getState().unlockItem("classic_felt");
    useUIStore.getState().unlockItem("classic_felt");
    expect(useUIStore.getState().unlockedItems).toEqual(["classic_felt"]);
  });

  it("purchasePowerUp deducts coins and increments inventory only when affordable", () => {
    useUIStore.setState({ coins: 100 });

    expect(useUIStore.getState().purchasePowerUp("undo_token", 150)).toBe(false);
    expect(useUIStore.getState().coins).toBe(100);

    expect(useUIStore.getState().purchasePowerUp("undo_token", 100)).toBe(true);
    expect(useUIStore.getState().coins).toBe(0);
    expect(useUIStore.getState().powerUpInventory.undo_token).toBe(1);
  });

  it("consumePowerUp fails when inventory is empty", () => {
    expect(useUIStore.getState().consumePowerUp("undo_token")).toBe(false);
  });

  it("addXP levels up using the 500 * level^1.5 curve and carries remainder xp", () => {
    // Level 1 -> 2 threshold is floor(500 * 1^1.5) = 500
    const result = useUIStore.getState().addXP("klondike", 600);
    expect(result.leveledUp).toBe(true);
    expect(result.newLevel).toBe(2);
    expect(result.newXP).toBe(100);
    expect(useUIStore.getState().gameProgress.klondike).toEqual({ level: 2, xp: 100 });
  });

  it("addXP does not level up when xp is below the threshold", () => {
    const result = useUIStore.getState().addXP("spider", 200);
    expect(result.leveledUp).toBe(false);
    expect(result.newLevel).toBe(1);
    expect(result.newXP).toBe(200);
  });

  describe("cardFaceSetId", () => {
    it("defaults to the always-available 'default' illustrated deck", () => {
      expect(useUIStore.getState().cardFaceSetId).toBe("default");
    });

    it("setCardFaceSetId updates state and persists the change", async () => {
      vi.mocked(store.saveSettings).mockClear();
      useUIStore.getState().setCardFaceSetId("gilded_mystery");
      expect(useUIStore.getState().cardFaceSetId).toBe("gilded_mystery");
      // The save is fired via a dynamic import, so let its promise settle.
      await new Promise((resolve) => setTimeout(resolve, 0));
      expect(store.saveSettings).toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ cardFaceSet: "gilded_mystery" })
      );
    });

    it("initializeStore falls back to 'default' when a pre-existing save has no cardFaceSet field", async () => {
      vi.mocked(store.loadSettings).mockResolvedValueOnce({
        drawMode: 1, autoComplete: true, themeId: "classic_felt", cardBack: "diamond",
        soundEnabled: true, soundVolume: 0.8,
        // cardFaceSet intentionally omitted -- simulates a save from before this field existed.
      } as any);
      await useUIStore.getState().initializeStore();
      expect(useUIStore.getState().cardFaceSetId).toBe("default");
    });
  });
});
