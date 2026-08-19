import type { CoinLedgerEntry } from "../persistence/store";

export interface WeeklyCoinBucket {
  label: string; // "W1" .. "W{weeks}", oldest to newest
  coins: number;
}

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

// Buckets ledger entries into `weeks` trailing 7-day windows ending "now",
// oldest first, so the dashboard can chart real coin-earning activity
// without fabricating data the app hasn't actually recorded yet.
export function bucketCoinLedgerByWeek(
  ledger: CoinLedgerEntry[],
  weeks: number,
  now: number = Date.now()
): WeeklyCoinBucket[] {
  const buckets: WeeklyCoinBucket[] = Array.from({ length: weeks }, (_, i) => ({
    label: `W${i + 1}`,
    coins: 0,
  }));

  const windowStart = now - weeks * WEEK_MS;
  for (const entry of ledger) {
    if (entry.ts < windowStart || entry.ts > now) continue;
    const index = Math.min(weeks - 1, Math.floor((entry.ts - windowStart) / WEEK_MS));
    buckets[index].coins += entry.amount;
  }
  return buckets;
}
