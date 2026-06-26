/**
 * Local calendar dates (YYYY-MM-DD) — never use toISOString() for date-only values.
 * UTC conversion shifts the day for Libya/Middle East timezones.
 */

export function formatLocalIsoDate(date) {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

export function localTodayIso() {
  return formatLocalIsoDate(new Date());
}

export function parseLocalIso(iso) {
  const [y, m, d] = String(iso || "").split("-").map(Number);
  if (!y || !m || !d) return new Date();
  return new Date(y, m - 1, d);
}

export function shiftLocalIsoDate(iso, deltaDays) {
  const d = parseLocalIso(iso);
  d.setDate(d.getDate() + deltaDays);
  return formatLocalIsoDate(d);
}

export function formatDisplayDateEnGb(iso) {
  return parseLocalIso(iso).toLocaleDateString("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });
}
