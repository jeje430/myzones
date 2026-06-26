import {
  migrateDevicesToCodeNames,
  suggestDeviceName,
  typeLabelFromType,
} from "./deviceNaming";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";
import { getActiveStaffSession, isApiStaffSession, refreshHallCatalogFromApi } from "./hallCatalogSync";
import {
  createManagerDevice,
  deleteManagerDevice,
  updateManagerDevice,
} from "./managerDevicesApi";

const BASE_KEY = "zones-devices-v4";
/** المفتاح الأساس (بدون لاحقة الصالة) — يُستخدم لمطابقة أحداث التخزين عبر التبويبات */
export const DEVICES_STORAGE_KEY = BASE_KEY;
const storageKey = () => hallScopedKey(BASE_KEY);

const LEGACY_DEVICE_KEYS = ["zones-devices-v1", "zones-devices-v2", "zones-devices-v3", "zones-devices-v4"];
const LEGACY_PURGE_FLAG = "zones-devices-legacy-purged-v5";

/** يمسح بيانات الأجهزة العامة القديمة (قبل العزل حسب الصالة) — مرة واحدة */
function purgeLegacyDeviceStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_DEVICE_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyDeviceStorage();

/** يُبث عند أي تغيير على قائمة الأجهزة (مدير أو صيانة) */
export const DEVICES_STORAGE_EVENT = "zones-devices-updated";

function notifyDevicesUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(DEVICES_STORAGE_EVENT));
}

export const DEFAULT_DEVICES = [];

function normalizeDevice(row) {
  const packageId =
    row.packageId != null && row.packageId !== "" ? Number(row.packageId) : null;
  return {
    ...row,
    packageId: Number.isFinite(packageId) ? packageId : null,
    hasFault: Boolean(row.hasFault),
    maintenanceInProgress: Boolean(row.maintenanceInProgress),
    operationalStatus: row.operationalStatus || row.operational_status || (row.isActive !== false ? "active" : "inactive"),
    isActive: row.isActive !== false && (row.operationalStatus || row.operational_status || "active") === "active",
    isMaintenance: Boolean(row.isMaintenance ?? row.is_maintenance ?? (row.operationalStatus || row.operational_status) === "maintenance"),
    isArchived: Boolean(row.isArchived),
    archivedAt: row.archivedAt || null,
    image: row.image || null,
    notes: row.notes ?? "",
    createdAt: row.createdAt || row.updated || "—",
    typeLabel: row.typeLabel || typeLabelFromType(row.type),
  };
}

/** اسم الباقة المرتبطة بالجهاز — يتحدّث تلقائياً عند تعديل الباقات */
export function getDevicePackageLabel(packageId, packages) {
  if (packageId == null) return "—";
  const pkg = (packages || []).find((p) => p.id === packageId);
  if (!pkg) return "باقة غير متوفرة";
  return pkg.name || "—";
}

/** أجهزة مرتبطة بباقة (من packageId على الجهاز في لوحة المدير) */
export function getDevicesLinkedToPackage(packageId, devices) {
  if (packageId == null) return [];
  return (devices || []).filter((d) => d.packageId === packageId && !d.isArchived);
}

export function getPrimaryDeviceNameForPackage(packageId, devices) {
  const linked = getDevicesLinkedToPackage(packageId, devices);
  if (!linked.length) return "—";
  return linked.map((d) => d.name).join("، ");
}

function readRawDeviceList() {
  const raw = localStorage.getItem(storageKey());
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length ? parsed : null;
  } catch {
    return null;
  }
}

function applyDeviceNameMigration(list) {
  const normalized = list.map(normalizeDevice);
  const { devices, idToName, changed } = migrateDevicesToCodeNames(normalized);
  if (changed) {
    try {
      localStorage.setItem(storageKey(), JSON.stringify(devices.map(normalizeDevice)));
    } catch {
      /* ignore */
    }
    syncFaultRecordsDeviceNames(idToName);
    notifyDevicesUpdated();
  }
  return devices.map(normalizeDevice);
}

/** تحديث أسماء الأجهزة في سجل الأعطال بعد الترحيل */
function syncFaultRecordsDeviceNames(idToName) {
  if (!idToName?.size) return;
  try {
    const FAULT_KEY = "zones-maintenance-faults-v4";
    const raw = localStorage.getItem(FAULT_KEY);
    if (!raw) return;
    const faults = JSON.parse(raw);
    if (!Array.isArray(faults)) return;
    const next = faults.map((f) => {
      const newName = idToName.get(f.deviceId);
      return newName ? { ...f, deviceName: newName } : f;
    });
    localStorage.setItem(FAULT_KEY, JSON.stringify(next));
  } catch {
    /* ignore */
  }
}

export function loadDevices() {
  try {
    const stored = readRawDeviceList();
    if (!stored) return [];
    return applyDeviceNameMigration(stored);
  } catch {
    return [];
  }
}

export function loadActiveDevices() {
  return loadDevices().filter((d) => !d.isArchived);
}

/** نفس منطق جدول المدير: غير مؤرشف + مفعّل (isActive) */
export function loadManagerEnabledDevices() {
  return loadDevices()
    .filter((d) => !d.isArchived && d.isActive !== false)
    .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), "en", { numeric: true }));
}

export function loadArchivedDevices() {
  return loadDevices().filter((d) => d.isArchived);
}

export function saveDevices(list) {
  try {
    const serialized = JSON.stringify(list.map(normalizeDevice));
    const prev = localStorage.getItem(storageKey());
    if (prev === serialized) return;
    localStorage.setItem(storageKey(), serialized);
    notifyDevicesUpdated();
  } catch {
    /* ignore */
  }
}

export function nextDeviceId(list) {
  return list.reduce((max, d) => Math.max(max, d.id ?? 0), 0) + 1;
}

export function setDeviceFault(deviceId, hasFault) {
  const list = loadDevices();
  const next = list.map((d) =>
    d.id === deviceId
      ? { ...d, hasFault, maintenanceInProgress: hasFault ? d.maintenanceInProgress : false }
      : d,
  );
  saveDevices(next);
  return next;
}

export function setDeviceActive(deviceId, isActive) {
  const list = loadDevices();
  const next = list.map((d) => (d.id === deviceId ? { ...d, isActive } : d));
  saveDevices(next);
  return next;
}

/** تحديث حالة التشغيل والعطل في عملية حفظ واحدة — يمنع فقدان البيانات بين استدعاءين */
export function setMaintenanceDeviceStatus(deviceId, isActive, { hasPendingFault = false } = {}) {
  const list = loadDevices();
  const next = list.map((d) => {
    if (d.id !== deviceId) return d;
    if (!isActive) {
      return { ...d, isActive: false, hasFault: true, maintenanceInProgress: false };
    }
    if (hasPendingFault) {
      return { ...d, isActive: true, hasFault: true };
    }
    return { ...d, isActive: true, hasFault: false, maintenanceInProgress: false };
  });
  saveDevices(next);
  return next;
}

export function startDeviceMaintenance(deviceId) {
  const list = loadDevices();
  const next = list.map((d) =>
    d.id === deviceId
      ? { ...d, isActive: false, hasFault: true, maintenanceInProgress: true }
      : d,
  );
  saveDevices(next);
  return next;
}

export function endDeviceMaintenance(deviceId) {
  const list = loadDevices();
  const next = list.map((d) =>
    d.id === deviceId
      ? { ...d, isActive: true, hasFault: false, maintenanceInProgress: false }
      : d,
  );
  saveDevices(next);
  return next;
}

function getManagerSession() {
  return getActiveStaffSession();
}

/** يجلب الأجهزة من Laravel للمدير أو موظف الاستقبال/الصيانة */
export async function refreshDevicesFromApi() {
  const session = getManagerSession();
  if (!isApiStaffSession(session)) {
    return { ok: false, skipped: true };
  }

  const result = await refreshHallCatalogFromApi();
  if (!result.ok) return result;
  return { ok: true, devices: loadDevices() };
}

function isApiManagerSession(session) {
  return isApiStaffSession(session) && session?.role === "manager";
}

export async function persistDeviceCreate(patch) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadDevices();
    const created = normalizeDevice({
      ...patch,
      id: nextDeviceId(list),
      createdAt: new Date().toISOString(),
    });
    saveDevices([...list, created]);
    return { ok: true, device: created };
  }

  const result = await createManagerDevice({
    ...patch,
    deviceCode: patch.name,
  });
  if (!result.ok) return result;
  await refreshDevicesFromApi();
  return { ok: true, device: result.device, message: result.message };
}

export async function persistDeviceUpdate(id, patch) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadDevices();
    saveDevices(list.map((d) => (d.id === id ? normalizeDevice({ ...d, ...patch }) : d)));
    return { ok: true };
  }

  const result = await updateManagerDevice(id, patch);
  if (!result.ok) return result;
  await refreshDevicesFromApi();
  return { ok: true, device: result.device, message: result.message };
}

export async function persistDeviceArchive(id) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadDevices();
    saveDevices(
      list.map((d) =>
        d.id === id
          ? normalizeDevice({
              ...d,
              isArchived: true,
              isActive: false,
              archivedAt: new Date().toISOString(),
            })
          : d,
      ),
    );
    return { ok: true };
  }

  const result = await deleteManagerDevice(id);
  if (!result.ok) return result;
  await refreshDevicesFromApi();
  return { ok: true, message: result.message };
}

export async function persistDeviceToggleActive(id, isActive, extra = {}) {
  const row = loadDevices().find((d) => d.id === id);
  if (!row) return { ok: false, error: "الجهاز غير موجود" };
  return persistDeviceUpdate(id, { ...row, isActive, ...extra });
}

export { suggestDeviceName, typeLabelFromType };
