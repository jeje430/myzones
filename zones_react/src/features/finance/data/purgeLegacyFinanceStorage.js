/**
 * Removes legacy client-side revenue ledger (localStorage).
 * Finance now reads only from Laravel /manager/finance APIs.
 */

const LEGACY_LEDGER_PREFIX = "zones-booking-revenue-ledger-v1";
const LEGACY_LEDGER_EXACT = "zones-booking-revenue-ledger-v1";
const PURGE_FLAG = "zones-legacy-revenue-ledger-purged-v2";

export function purgeLegacyBookingRevenueLedger(force = false) {
  if (typeof window === "undefined") return { removedKeys: [], removedEntries: 0 };

  if (!force && localStorage.getItem(PURGE_FLAG)) {
    return { removedKeys: [], removedEntries: 0, alreadyPurged: true };
  }

  const removedKeys = [];
  let removedEntries = 0;

  for (let i = localStorage.length - 1; i >= 0; i -= 1) {
    const key = localStorage.key(i);
    if (!key) continue;

    const isLegacyLedger =
      key === LEGACY_LEDGER_EXACT ||
      key.startsWith(`${LEGACY_LEDGER_PREFIX}::`);

    if (!isLegacyLedger) continue;

    try {
      const raw = localStorage.getItem(key);
      const parsed = raw ? JSON.parse(raw) : [];
      if (Array.isArray(parsed)) {
        removedEntries += parsed.length;
      }
    } catch {
      // ignore malformed legacy payload
    }

    localStorage.removeItem(key);
    removedKeys.push(key);
  }

  localStorage.setItem(PURGE_FLAG, "1");

  return { removedKeys, removedEntries, alreadyPurged: false };
}
