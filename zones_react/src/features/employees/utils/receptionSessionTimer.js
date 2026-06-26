const HOUR_MS = 60 * 60 * 1000;

function parseHourOnDate(dateIso, hourStr) {
  const [h, m = 0] = String(hourStr || "0:0").split(":").map(Number);
  return new Date(`${dateIso}T${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}:00`);
}

/** Session end = booking hourTo, or start + 1 hour (legacy countdown helper). */
export function getSlotSessionEndTime(dateIso, hourStr, hourToStr) {
  if (hourToStr && hourToStr !== "—" && hourToStr !== hourStr) {
    return parseHourOnDate(dateIso, hourToStr);
  }
  const start = parseHourOnDate(dateIso, hourStr);
  return new Date(start.getTime() + HOUR_MS);
}

export function getSessionRemainingMs(dateIso, hourStr, hourToStr, now = Date.now()) {
  const end = getSlotSessionEndTime(dateIso, hourStr, hourToStr);
  return Math.max(0, end.getTime() - now);
}

/** Live elapsed duration since session started (increasing timer). */
export function getSessionElapsedMs(startedAtIso, now = Date.now()) {
  if (!startedAtIso) return 0;
  const startMs = new Date(startedAtIso).getTime();
  if (!Number.isFinite(startMs)) return 0;
  return Math.max(0, now - startMs);
}

export function formatSessionDuration(ms) {
  const totalSec = Math.max(0, Math.floor(ms / 1000));
  const hours = Math.floor(totalSec / 3600);
  const minutes = Math.floor((totalSec % 3600) / 60);
  const seconds = totalSec % 60;
  return `${String(hours).padStart(2, "0")}:${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
}

/** @deprecated Use formatSessionDuration with getSessionElapsedMs for live sessions */
export function formatSessionRemaining(ms) {
  return formatSessionDuration(ms);
}
