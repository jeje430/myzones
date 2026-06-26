import { loadTournamentRows } from "../tournamentsListStorage";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-tournament-participants-v2";
const storageKey = () => hallScopedKey(BASE_KEY);

export const TOURNAMENT_PARTICIPANTS_EVENT = "zones-tournament-participants-updated";

const LEGACY_KEYS = ["zones-tournament-participants-v1", "zones-tournament-participants-v2"];
const LEGACY_PURGE_FLAG = "zones-tournament-participants-legacy-purged-v3";

function purgeLegacyParticipantsStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyParticipantsStorage();

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(TOURNAMENT_PARTICIPANTS_EVENT));
}

function normalizeParticipant(row, fallbackSlot) {
  return {
    ...row,
    slotIndex: Number(row.slotIndex) || fallbackSlot,
    isWinner: Boolean(row.isWinner),
  };
}

export function loadTournamentParticipants() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.length) return [];
    return parsed.map((p, i) => normalizeParticipant(p, i + 1));
  } catch {
    return [];
  }
}

export function saveTournamentParticipants(list) {
  try {
    const encoded = JSON.stringify(list);
    const prev = localStorage.getItem(storageKey());
    if (prev === encoded) return;
    localStorage.setItem(storageKey(), encoded);
    notifyUpdated();
  } catch {
    /* ignore */
  }
}

export function getTournamentCapacity(tournamentId) {
  const t = loadTournamentRows().find((r) => r.id === tournamentId);
  return Math.max(2, Number(t?.participants) || 8);
}

export function getParticipantsByTournamentId(tournamentId, list = loadTournamentParticipants()) {
  return list
    .filter((p) => p.tournamentId === tournamentId)
    .sort((a, b) => a.slotIndex - b.slotIndex);
}

export function countParticipantsForTournament(tournamentId, list = loadTournamentParticipants()) {
  return getParticipantsByTournamentId(tournamentId, list).length;
}

export function isTournamentParticipantsFull(tournamentId, capacity = getTournamentCapacity(tournamentId)) {
  return countParticipantsForTournament(tournamentId) >= capacity;
}

export function getParticipantNamesForTournament(tournamentId) {
  return getParticipantsByTournamentId(tournamentId).map((p) => p.fullName);
}

export function buildTournamentSlotGrid(tournamentId, capacity = getTournamentCapacity(tournamentId)) {
  const participants = getParticipantsByTournamentId(tournamentId);
  const bySlot = new Map(participants.map((p) => [p.slotIndex, p]));
  const slots = [];
  for (let i = 1; i <= capacity; i += 1) {
    slots.push({
      slotIndex: i,
      participant: bySlot.get(i) ?? null,
    });
  }
  return slots;
}

export function getTournamentFilterOptions(participants = []) {
  const names = [...new Set(participants.map((p) => p.tournamentName).filter(Boolean))];
  return names.sort((a, b) => a.localeCompare(b, "ar"));
}

/** يُستدعى من التطبيق عند اشتراك جديد في بطولة */
export function addTournamentParticipant(entry) {
  const list = loadTournamentParticipants();
  const tournamentId = entry.tournamentId;
  const capacity = getTournamentCapacity(tournamentId);
  const existing = getParticipantsByTournamentId(tournamentId, list);

  if (existing.length >= capacity) {
    return { ok: false, error: "البطولة مكتملة — لا يمكن قبول مشتركين جدد." };
  }

  const nextSlot = existing.length + 1;
  const nid = Math.max(0, ...list.map((p) => p.id)) + 1;
  const participant = normalizeParticipant(
    {
      id: nid,
      isWinner: false,
      registeredAt: new Date().toISOString(),
      slotIndex: nextSlot,
      ...entry,
    },
    nextSlot,
  );

  const next = [...list, participant];
  saveTournamentParticipants(next);

  return { ok: true, participant, slotIndex: nextSlot, isFull: nextSlot >= capacity };
}
