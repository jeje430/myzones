import { formatAlertDateTime } from "./alertsMeta";
import {
  pushBookingsStartNotification,
  pushBookingsStopNotification,
} from "./hallNotificationsStorage";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";
import { getActiveStaffSession, isApiStaffSession } from "../../devices-packages/data/hallCatalogSync";
import {
  BOOKING_STOPS_EVENT,
  createManagerBookingStop,
  deleteManagerBookingStop,
  fetchManagerBookingStops,
  resumeManagerBookingStop,
  updateManagerBookingStop,
} from "./managerBookingStopsApi";
import { BOOKINGS_STOP_NAME, reasonLabelForKey } from "./bookingsStopMessages";

const BASE_KEY = "zones-bookings-stop-v1";
const storageKey = () => hallScopedKey(BASE_KEY);
export const BOOKINGS_STOP_EVENT = BOOKING_STOPS_EVENT;

let cachedActive = null;
let cachedRecords = null;

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(BOOKINGS_STOP_EVENT));
}

function useApi() {
  const session = getActiveStaffSession();
  return isApiStaffSession(session) && session?.role === "manager";
}

function normalizeRecord(row) {
  return {
    ...row,
    name: BOOKINGS_STOP_NAME,
    reason: row.reason?.trim() || reasonLabelForKey(row.reasonKey) || "",
    endDate: row.endDate || row.endsOn || "",
    status: row.status === "active" ? "active" : "ended",
  };
}

function readStoredRecords() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.map(normalizeRecord);
  } catch {
    return [];
  }
}

function saveBookingsStopRecords(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list.map(normalizeRecord)));
    notifyUpdated();
  } catch {
    /* ignore */
  }
}

export function formatBookingsStopCode(id) {
  return `H-${String(id ?? 0).padStart(4, "0")}`;
}

export function loadBookingsStopRecords() {
  if (cachedRecords) return cachedRecords;
  return readStoredRecords();
}

export function getActiveBookingsStopRecord() {
  if (cachedActive) {
    return normalizeRecord({
      id: cachedActive.id,
      reasonKey: cachedActive.reasonKey,
      reason: cachedActive.reason,
      status: "active",
      startDate: cachedActive.startsOn,
      endDate: cachedActive.endsOn || "",
    });
  }
  return readStoredRecords().find((row) => row.status === "active") ?? null;
}

export function isBookingsStopped() {
  return Boolean(getActiveBookingsStopRecord());
}

export function getBookingsStopBlockMessage() {
  const active = getActiveBookingsStopRecord();
  if (active?.message) return active.message;
  return "الحجوزات متوقفة مؤقتاً. لا يمكن إضافة حجز جديد حتى يُستأنف الحجز.";
}

export async function refreshBookingStopsFromApi() {
  if (!useApi()) return { ok: false, skipped: true };
  const result = await fetchManagerBookingStops();
  if (!result.ok) return result;

  cachedRecords = result.records.map(normalizeRecord);
  cachedActive = result.active;
  saveBookingsStopRecords(cachedRecords);
  notifyUpdated();
  return result;
}

export async function startBookingsStop({
  reasonKey = "",
  startsOn = "",
  endsOn = null,
} = {}) {
  if (useApi()) {
    const result = await createManagerBookingStop({
      reasonKey,
      startsOn: startsOn || new Date().toISOString().slice(0, 10),
      endsOn: endsOn || null,
    });
    if (result.ok) await refreshBookingStopsFromApi();
    return result.ok
      ? { ok: true, record: result.record }
      : { ok: false, error: result.error };
  }

  const trimmedReason = reasonLabelForKey(reasonKey);
  if (!trimmedReason) {
    return { ok: false, error: "يرجى اختيار سبب إيقاف الحجوزات." };
  }

  const list = readStoredRecords();
  const record = normalizeRecord({
    id: list.reduce((max, row) => Math.max(max, row.id ?? 0), 2000) + 1,
    reasonKey,
    reason: trimmedReason,
    status: "active",
    startDate: formatAlertDateTime(),
    endDate: endsOn || "",
  });

  pushBookingsStopNotification({ hallName: trimmedReason, reason: trimmedReason });
  saveBookingsStopRecords([record, ...list]);
  return { ok: true, record };
}

export async function resumeBookingsStop(recordId) {
  if (useApi()) {
    const active = getActiveBookingsStopRecord();
    const id = recordId ?? active?.id;
    if (!id) return { ok: false, error: "لا يوجد إيقاف نشط للحجوزات." };
    const result = await resumeManagerBookingStop(id);
    if (result.ok) {
      cachedActive = null;
      await refreshBookingStopsFromApi();
      pushBookingsStartNotification({});
    }
    return result.ok ? { ok: true } : { ok: false, error: result.error };
  }

  const active = getActiveBookingsStopRecord();
  if (!active) return { ok: false, error: "لا يوجد إيقاف نشط للحجوزات." };

  const endDate = formatAlertDateTime();
  saveBookingsStopRecords(
    readStoredRecords().map((row) =>
      row.id === active.id ? { ...row, status: "ended", endDate } : row,
    ),
  );
  pushBookingsStartNotification({});
  return { ok: true };
}

export async function updateBookingsStopRecord(id, { reasonKey, endsOn }) {
  if (useApi()) {
    const result = await updateManagerBookingStop(id, { reasonKey, endsOn: endsOn || null });
    if (result.ok) await refreshBookingStopsFromApi();
    return result.ok ? { ok: true, record: result.record } : { ok: false, error: result.error };
  }
  return { ok: false, error: "يتطلب جلسة مدير API" };
}

export async function deleteBookingsStopRecord(id) {
  if (useApi()) {
    const result = await deleteManagerBookingStop(id);
    if (result.ok) await refreshBookingStopsFromApi();
    return result;
  }
  saveBookingsStopRecords(readStoredRecords().filter((row) => row.id !== id));
  return { ok: true };
}

export function getActiveBookingsStopAlert() {
  return getActiveBookingsStopRecord();
}

export function endBookingsStop() {
  return resumeBookingsStop();
}

export function nextBookingsStopId(list = loadBookingsStopRecords()) {
  return list.reduce((max, row) => Math.max(max, row.id ?? 0), 2000) + 1;
}
