import { loadDevices } from "../../devices-packages/data/devicesStorage";
import { formatFaultDateTime } from "./faultMeta";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-maintenance-faults-v6";
const storageKey = () => hallScopedKey(BASE_KEY);
export const MAINTENANCE_FAULTS_EVENT = "zones-maintenance-faults-updated";

const LEGACY_KEYS = [
  "zones-maintenance-faults-v4",
  "zones-maintenance-faults-v5",
  "zones-maintenance-faults-v6",
];
const LEGACY_PURGE_FLAG = "zones-maintenance-faults-legacy-purged-v7";

function purgeLegacyFaultStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyFaultStorage();

function lookupDeviceTypeLabel(deviceId, deviceName) {
  const devices = loadDevices();
  const device = devices.find((d) => d.id === deviceId) || devices.find((d) => d.name === deviceName);
  return device ? { type: device.type, typeLabel: device.typeLabel } : { type: "", typeLabel: "—" };
}

function normalizeFault(row) {
  const legacy = lookupDeviceTypeLabel(row.deviceId, row.deviceName);
  return {
    ...row,
    archived: Boolean(row.archived),
    maintenanceCost: Number(row.maintenanceCost) || 0,
    deviceType: row.deviceType || legacy.type,
    deviceTypeLabel: row.deviceTypeLabel || legacy.typeLabel,
    resolvedAt: row.resolvedAt || (row.status === "resolved" ? row.archivedAt || "" : ""),
  };
}

export function loadFaults() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.map(normalizeFault);
  } catch {
    return [];
  }
}

export function saveFaults(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list.map(normalizeFault)));
    window.dispatchEvent(new Event(MAINTENANCE_FAULTS_EVENT));
  } catch {
    /* ignore */
  }
}

export function nextFaultId(list) {
  const all = list.length ? list : loadFaults();
  const base = all.reduce((max, f) => Math.max(max, f.id ?? 0), 1000);
  return base + 1;
}

export function getActiveFaults() {
  return loadFaults().filter((f) => !f.archived);
}

/** الأعطال الحالية — معلّقة أو قيد الإصلاح لأجهزة الصالة */
export function isBlockingFault(f) {
  if (!f || f.archived) return false;
  if (f.status === "in_progress") return true;
  if (f.status === "scheduled") return false;
  if (f.status === "pending") {
    return f.applyMaintenanceNow !== false;
  }
  return false;
}

const OPEN_FAULT_STATUSES = new Set(["pending", "in_progress", "scheduled"]);

export function isOpenFaultRecord(fault) {
  if (!fault || fault.archived) return false;
  return OPEN_FAULT_STATUSES.has(fault.status);
}

/** تحويل الأرقام العربية إلى غربية لتحليل التواريخ */
function normalizeDateDigits(str) {
  const eastern = "٠١٢٣٤٥٦٧٨٩";
  return String(str).replace(/[٠-٩]/g, (c) => String(eastern.indexOf(c)));
}

/** تاريخ بداية العطل بصيغة YYYY-MM-DD */
export function getFaultEffectiveDateIso(fault) {
  if (!fault) return null;
  if (fault.faultDate) {
    const d = String(fault.faultDate).slice(0, 10);
    if (/^\d{4}-\d{2}-\d{2}$/.test(d)) return d;
  }
  const raw = normalizeDateDigits(String(fault.createdAt || "").trim());
  if (!raw) return null;
  if (/^\d{4}-\d{2}-\d{2}/.test(raw)) return raw.slice(0, 10);
  const ymd = raw.match(/^(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})/);
  if (ymd) {
    const [, year, month, day] = ymd;
    return `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}`;
  }
  const dmy = raw.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})/);
  if (dmy) {
    const [, day, month, year] = dmy;
    return `${year}-${month.padStart(2, "0")}-${day.padStart(2, "0")}`;
  }
  return null;
}

export function getOpenFaultsForDevice(deviceId) {
  return loadFaults().filter(
    (f) => String(f.deviceId) === String(deviceId) && isOpenFaultRecord(f),
  );
}

/**
 * هل الجهاز في صيانة/عطل في تاريخ تقويم محدد؟
 * يشمل الأعطال المجدولة مستقبلاً (من تاريخ العطل حتى الإصلاح).
 */
export function isDeviceInMaintenanceOnDate(deviceId, dateIso) {
  if (deviceId == null || !dateIso) return false;

  const openFaults = getOpenFaultsForDevice(deviceId);
  if (!openFaults.length) return false;

  for (const fault of openFaults) {
    const faultStart = getFaultEffectiveDateIso(fault);
    if (!faultStart) {
      if (isBlockingFault(fault)) return true;
      continue;
    }
    if (dateIso >= faultStart) return true;
  }

  return false;
}

export function getLatestBlockingFaultForDevice(deviceId) {
  const open = loadFaults().filter(
    (f) => String(f.deviceId) === String(deviceId) && isBlockingFault(f),
  );
  if (!open.length) return null;
  return open.reduce((a, b) => ((a.id ?? 0) > (b.id ?? 0) ? a : b));
}

export function getCurrentFaults() {
  const deviceIds = new Set(
    loadDevices()
      .filter((d) => !d.isArchived)
      .map((d) => d.id),
  );
  return loadFaults().filter(
    (f) =>
      !f.archived &&
      (f.status === "pending" || f.status === "in_progress" || f.status === "scheduled") &&
      deviceIds.has(f.deviceId),
  );
}

export function getArchivedFaults() {
  const deviceIds = new Set(loadDevices().map((d) => d.id));
  return loadFaults().filter(
    (f) => f.archived && f.status === "resolved" && deviceIds.has(f.deviceId),
  );
}

export function getLatestPendingFaultForDevice(deviceId) {
  const open = loadFaults().filter(
    (f) =>
      !f.archived &&
      String(f.deviceId) === String(deviceId) &&
      (f.status === "pending" || f.status === "in_progress" || f.status === "scheduled"),
  );
  if (!open.length) return null;
  return open.reduce((a, b) => ((a.id ?? 0) > (b.id ?? 0) ? a : b));
}

export function addFault(payload) {
  const list = loadFaults();
  const fault = normalizeFault({
    id: nextFaultId(list),
    deviceId: payload.deviceId,
    deviceName: payload.deviceName,
    deviceType: payload.deviceType,
    deviceTypeLabel: payload.deviceTypeLabel,
    faultType: payload.faultType,
    faultTypeCustom: payload.faultTypeCustom?.trim() || "",
    status: payload.status || "pending",
    faultDate: payload.faultDate || "",
    applyMaintenanceNow: payload.applyMaintenanceNow !== false,
    createdAt: payload.createdAt || formatFaultDateTime(),
    resolvedAt: payload.resolvedAt || "",
    maintenanceCost: payload.maintenanceCost ?? 0,
    maintenanceEmployeeName: payload.maintenanceEmployeeName || "",
    details: payload.details?.trim() || "",
    archived: false,
  });
  const next = [...list, fault];
  saveFaults(next);
  return fault;
}

export function updateFault(id, patch) {
  const list = loadFaults();
  const next = list.map((f) => (f.id === id ? normalizeFault({ ...f, ...patch }) : f));
  saveFaults(next);
  return next.find((f) => f.id === id) ?? null;
}

export function resolveFault(id) {
  return updateFault(id, {
    status: "resolved",
    resolvedAt: formatFaultDateTime(),
  });
}

export function archiveFault(id) {
  return updateFault(id, {
    archived: true,
    archivedAt: formatFaultDateTime(),
  });
}

export function resolveLatestActiveFaultForDevice(deviceId) {
  const list = loadFaults();
  const pending = list.filter(
    (f) => !f.archived && f.deviceId === deviceId && f.status === "pending",
  );
  if (!pending.length) return null;
  const latest = pending.reduce((a, b) => ((a.id ?? 0) > (b.id ?? 0) ? a : b));
  return updateFault(latest.id, { status: "resolved", resolvedAt: formatFaultDateTime() });
}

/** إنهاء العطل وأرشفته — يُزال الجهاز من المعطلة ويعود متاحاً في التقويم */
export function resolveAndArchiveFaultForDevice(deviceId, maintenanceCost = 0) {
  const list = loadFaults();
  const pending = list.filter(
    (f) =>
      !f.archived &&
      f.deviceId === deviceId &&
      (f.status === "pending" || f.status === "in_progress"),
  );
  if (!pending.length) return null;
  const latest = pending.reduce((a, b) => ((a.id ?? 0) > (b.id ?? 0) ? a : b));
  const now = formatFaultDateTime();
  return updateFault(latest.id, {
    status: "resolved",
    resolvedAt: now,
    maintenanceCost: Number(maintenanceCost) || 0,
    archived: true,
    archivedAt: now,
  });
}
