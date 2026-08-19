import { describe, expect, it } from "vitest";
import { bucketCoinLedgerByWeek } from "./coinLedger";

const DAY = 24 * 60 * 60 * 1000;
const WEEK = 7 * DAY;

describe("bucketCoinLedgerByWeek", () => {
  it("returns `weeks` zeroed buckets, oldest to newest, when the ledger is empty", () => {
    const buckets = bucketCoinLedgerByWeek([], 4, 1_000_000);
    expect(buckets.map((b) => b.label)).toEqual(["W1", "W2", "W3", "W4"]);
    expect(buckets.every((b) => b.coins === 0)).toBe(true);
  });

  it("sums entries into their trailing 7-day window", () => {
    const now = 8 * WEEK; // arbitrary anchor far enough from 0 to avoid negative windows
    const buckets = bucketCoinLedgerByWeek(
      [
        { ts: now - 1 * DAY, amount: 100 }, // most recent week (W4)
        { ts: now - 2 * DAY, amount: 50 }, // most recent week (W4)
        { ts: now - (3 * WEEK + 1 * DAY), amount: 25 }, // oldest week (W1)
      ],
      4,
      now
    );
    expect(buckets).toEqual([
      { label: "W1", coins: 25 },
      { label: "W2", coins: 0 },
      { label: "W3", coins: 0 },
      { label: "W4", coins: 150 },
    ]);
  });

  it("excludes entries outside the requested window", () => {
    const now = 8 * WEEK;
    const buckets = bucketCoinLedgerByWeek(
      [{ ts: now - 10 * WEEK, amount: 999 }],
      4,
      now
    );
    expect(buckets.reduce((sum, b) => sum + b.coins, 0)).toBe(0);
  });
});
