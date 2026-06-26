import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

export const BOOKING_STOPS_EVENT = "zones-booking-stops-updated";

export function emitBookingStopsUpdated(detail = {}) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(BOOKING_STOPS_EVENT, { detail }));
}

function mapRecord(row) {
  return {
    id: row.id,
    code: row.code ?? `H-${String(row.id).padStart(4, "0")}`,
    reasonKey: row.reasonKey ?? row.reason_key,
    reason: row.reasonLabel ?? row.reason ?? row.reason_key,
    startsOn: row.startsOn ?? row.starts_on,
    startDate: row.startDate ?? row.starts_on,
    endsOn: row.endsOn ?? row.ends_on ?? "",
    endDate: row.endDate ?? row.ended_at ?? row.ends_on ?? "",
    status: row.status === "active" || row.isActive ? "active" : "ended",
    message: row.message ?? null,
    source: "api",
  };
}

function mapActive(active) {
  if (!active) return null;
  return {
    id: active.id,
    reasonKey: active.reason_key,
    reason: active.reason_label,
    startsOn: active.starts_on,
    endsOn: active.ends_on ?? "",
    message: active.message,
    buttonLabel: active.button_label,
    openEnded: active.open_ended,
  };
}

export async function fetchManagerBookingStops() {
  try {
    const { data } = await apiClient.get("/manager/booking-stops");
    return {
      ok: true,
      records: (data.records || []).map(mapRecord),
      active: mapActive(data.active),
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), records: [], active: null };
  }
}

export async function fetchBookingStopReasons() {
  try {
    const { data } = await apiClient.get("/manager/booking-stops/reasons");
    return { ok: true, reasons: data.reasons || [] };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), reasons: [] };
  }
}

export async function createManagerBookingStop(payload) {
  try {
    const { data } = await apiClient.post("/manager/booking-stops", {
      reason_key: payload.reasonKey,
      starts_on: payload.startsOn,
      ends_on: payload.endsOn || null,
    });
    emitBookingStopsUpdated({ action: "create", record: data.record });
    return {
      ok: true,
      record: mapRecord(data.record),
      active: mapActive(data.active),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateManagerBookingStop(id, payload) {
  try {
    const { data } = await apiClient.put(`/manager/booking-stops/${id}`, {
      reason_key: payload.reasonKey,
      ends_on: payload.endsOn || null,
    });
    emitBookingStopsUpdated({ action: "update", record: data.record });
    return {
      ok: true,
      record: mapRecord(data.record),
      active: mapActive(data.active),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function resumeManagerBookingStop(id) {
  try {
    const { data } = await apiClient.patch(`/manager/booking-stops/${id}/resume`);
    emitBookingStopsUpdated({ action: "resume", id });
    return { ok: true, record: mapRecord(data.record), message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerBookingStop(id) {
  try {
    const { data } = await apiClient.delete(`/manager/booking-stops/${id}`);
    emitBookingStopsUpdated({ action: "delete", id });
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export { mapRecord, mapActive };
