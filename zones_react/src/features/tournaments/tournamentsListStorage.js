import { hallScopedKey } from "../../shared/tenant/hallScopedStorage";

export const TOURNAMENTS_LIST_KEY = "zones-tournaments-list-v2";
const storageKey = () => hallScopedKey(TOURNAMENTS_LIST_KEY);

export const TOURNAMENTS_LIST_EVENT = "zones-tournaments-list-updated";

const LEGACY_KEYS = ["zones-tournaments-list-v1", "zones-tournaments-list-v2"];
const LEGACY_PURGE_FLAG = "zones-tournaments-list-legacy-purged-v3";

function purgeLegacyTournamentStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyTournamentStorage();

function notifyTournamentsUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(TOURNAMENTS_LIST_EVENT));
}

function normalizeRow(row) {
  return {
    ...row,
    isArchived: Boolean(row.isArchived),
    archivedAt: row.archivedAt || null,
  };
}

export function loadTournamentRows() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length ? parsed.map(normalizeRow) : [];
  } catch {
    return [];
  }
}

export function loadActiveTournamentRows() {
  return loadTournamentRows().filter((r) => !r.isArchived);
}

export function archiveTournamentRow(rows, id) {
  const now = new Date().toISOString();
  return rows.map((r) =>
    r.id === id ? { ...r, isArchived: true, archivedAt: now, status: "archived" } : r,
  );
}

export function saveTournamentRows(rows) {
  try {
    const encoded = JSON.stringify(rows);
    if (encoded.length > 4_800_000) return false;
    const prev = localStorage.getItem(storageKey());
    if (prev === encoded) return true;
    localStorage.setItem(storageKey(), encoded);
    notifyTournamentsUpdated();
    return true;
  } catch {
    return false;
  }
}
