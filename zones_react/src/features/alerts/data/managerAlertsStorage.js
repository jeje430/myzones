import { formatAlertDateTime, normalizeTargetCategories, targetAudienceToCategories } from "./alertsMeta";
import { pushManagerAlertNotification } from "./hallNotificationsStorage";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-manager-alerts-v2";
const storageKey = () => hallScopedKey(BASE_KEY);
export const MANAGER_ALERTS_EVENT = "zones-manager-alerts-updated";

const LEGACY_KEYS = ["zones-manager-alerts-v1", "zones-manager-alerts-v2", "zones-hall-notifications-v1"];
const LEGACY_PURGE_FLAG = "zones-manager-alerts-legacy-purged-v3";

function purgeLegacyAlertStorage() {
  if (typeof window === "undefined") return;
  if (localStorage.getItem(LEGACY_PURGE_FLAG)) return;
  for (const key of LEGACY_KEYS) {
    localStorage.removeItem(key);
  }
  localStorage.setItem(LEGACY_PURGE_FLAG, "1");
}

purgeLegacyAlertStorage();

function normalizeAlert(row) {
  const situationDescription =
    row.situationDescription?.trim() || row.message?.trim() || "";
  const targetAudience = row.targetAudience || row.target_audience || null;
  const targetCategories = normalizeTargetCategories(
    targetAudience ? targetAudienceToCategories(targetAudience) : row.targetCategories ?? row.targetCategory,
  );
  return {
    ...row,
    status: row.status === "active" ? "active" : "stopped",
    endDate: row.endDate || "",
    severity: row.severity || "medium",
    targetAudience: targetAudience || null,
    targetCategories,
    targetCategory: targetCategories.includes("all") ? "all" : targetCategories[0] || "all",
    situationDescription,
    alternativeInstructions: row.alternativeInstructions?.trim() || "",
    message: situationDescription,
    source: row.source || "manual",
  };
}

export function loadAlerts() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.length) return [];
    return parsed.map(normalizeAlert);
  } catch {
    return [];
  }
}

export function saveAlerts(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list.map(normalizeAlert)));
    window.dispatchEvent(new Event(MANAGER_ALERTS_EVENT));
  } catch {
    /* ignore */
  }
}

export function nextAlertId(list = loadAlerts()) {
  const base = list.reduce((max, row) => Math.max(max, row.id ?? 0), 1000);
  return base + 1;
}

export function addAlert(payload) {
  const list = loadAlerts();
  const situationDescription =
    payload.situationDescription?.trim() || payload.message?.trim() || "";
  const targetAudience = payload.targetAudience || null;
  const targetCategories = normalizeTargetCategories(
    targetAudience
      ? targetAudienceToCategories(targetAudience)
      : payload.targetCategories ?? payload.targetCategory ?? "customers_only",
  );
  const alert = normalizeAlert({
    id: nextAlertId(list),
    name: payload.name?.trim() || "تنبيه",
    targetAudience,
    targetCategories,
    severity: payload.severity || "medium",
    situationDescription,
    alternativeInstructions: payload.alternativeInstructions?.trim() || "",
    message: situationDescription,
    status: "active",
    source: payload.source || "manual",
    startDate: formatAlertDateTime(),
    endDate: "",
  });
  const next = [alert, ...list];
  saveAlerts(next);
  pushManagerAlertNotification(alert);
  return alert;
}

export function loadActiveAlerts() {
  return loadAlerts().filter((row) => row.status === "active");
}

export function loadArchivedAlerts() {
  return loadAlerts().filter((row) => row.status === "stopped");
}

/** إيقاف التنبيه — لا يمكن إعادة تفعيله؛ يُنقل إلى الأرشيف */
export function stopAlert(id) {
  const list = loadAlerts();
  const next = list.map((row) =>
    row.id === id && row.status === "active"
      ? { ...row, status: "stopped", endDate: formatAlertDateTime() }
      : row,
  );
  saveAlerts(next);
  return next.find((row) => row.id === id) ?? null;
}
