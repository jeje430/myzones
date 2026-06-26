import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { localTodayIso } from "../../../shared/utils/localDateUtils";

function faultDateFromApi(row) {
  const raw = row.faultDate ?? row.fault_date ?? row.createdAt ?? row.created_at ?? "";
  const str = String(raw);
  if (/^\d{4}-\d{2}-\d{2}/.test(str)) return str.slice(0, 10);
  return "";
}

function mapApiFault(row) {
  const faultDate = faultDateFromApi(row);
  const isScheduled = faultDate ? faultDate > localTodayIso() : false;

  return {
    id: row.id,
    deviceId: row.deviceId ?? row.device_id,
    deviceName: row.deviceName ?? row.device_name ?? "",
    deviceType: row.deviceType ?? row.device_type ?? "",
    deviceTypeLabel: row.deviceTypeLabel ?? "—",
    faultType: row.faultType ?? row.fault_type ?? "other",
    faultTypeCustom: row.faultTypeCustom ?? row.fault_type_custom ?? "",
    status: isScheduled ? "scheduled" : row.status,
    faultDate,
    applyMaintenanceNow: row.applyMaintenanceNow ?? row.apply_maintenance_now ?? !isScheduled,
    createdAt: row.createdAt ?? row.created_at ?? "",
    resolvedAt: row.resolvedAt ?? row.resolved_at ?? "",
    maintenanceCost: Number(row.maintenanceCost ?? row.maintenance_cost ?? 0),
    maintenanceEmployeeName: row.maintenanceEmployeeName ?? row.maintenance_employee_name ?? "",
    details: row.details ?? "",
    archived: Boolean(row.archived),
  };
}

export async function fetchMaintenanceFaults({ archived = false } = {}) {
  try {
    const { data } = await apiClient.get("/staff/maintenance/faults", {
      params: { archived: archived ? 1 : 0 },
    });
    const faults = (data.faults || []).map(mapApiFault);
    return { ok: true, faults };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), faults: [] };
  }
}

export async function createMaintenanceFault(payload) {
  try {
    const { data } = await apiClient.post("/staff/maintenance/faults", {
      device_id: payload.deviceId,
      fault_type: payload.faultType,
      fault_type_custom: payload.faultTypeCustom || null,
      details: payload.details || null,
      maintenance_employee_name: payload.maintenanceEmployeeName || null,
      reported_at: payload.faultDate || null,
      apply_maintenance_now: payload.applyMaintenanceNow !== false,
    });
    return {
      ok: true,
      fault: mapApiFault(data.fault),
      device: data.device,
      message: data.message,
      cancelledBookingsCount: data.cancelled_bookings_count ?? 0,
      cancelledBookings: data.cancelled_bookings ?? [],
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function startMaintenanceFault(faultId) {
  try {
    const { data } = await apiClient.post(`/staff/maintenance/faults/${faultId}/start`);
    return {
      ok: true,
      fault: mapApiFault(data.fault),
      device: data.device,
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function resolveMaintenanceFault(faultId, maintenanceCost = 0) {
  try {
    const { data } = await apiClient.post(`/staff/maintenance/faults/${faultId}/resolve`, {
      maintenance_cost: maintenanceCost,
    });
    return {
      ok: true,
      fault: mapApiFault(data.fault),
      device: data.device,
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export { mapApiFault };
