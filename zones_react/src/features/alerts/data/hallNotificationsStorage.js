import {
  buildBookingsStartNotificationText,
  buildBookingsStopNotificationText,
  getHallDisplayName,
} from "./bookingsStopMessages";
import { formatAlertDateTime, targetAudienceToCategories } from "./alertsMeta";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-hall-notifications-v2";
const storageKey = () => hallScopedKey(BASE_KEY);
export const HALL_NOTIFICATIONS_EVENT = "zones-hall-notifications-updated";

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(HALL_NOTIFICATIONS_EVENT));
}

export function loadHallNotifications() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function saveHallNotifications(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list));
    notifyUpdated();
  } catch {
    /* ignore */
  }
}

function nextNotificationId(list) {
  return list.reduce((max, row) => Math.max(max, row.id ?? 0), 5000) + 1;
}

/** @param {'reception'|'maintenance'|'customer'|'manager'} audience */
export function getNotificationsForAudience(audience) {
  return loadHallNotifications().filter((row) => {
    const audiences = row.audiences ?? [];
    if (audience === "manager") {
      if (audiences.length >= 3) return true;
      if (audiences.length === 1 && audiences[0] === "customer") return false;
      return audiences.some((a) => a === "reception" || a === "maintenance");
    }
    if (audiences.length >= 3) return true;
    return audiences.includes(audience);
  });
}

export function pushManagerAlertNotification(alert) {
  if (!alert) return null;

  const targetCategories = alert.targetCategories ?? [];
  const audiences = alert.targetAudience
    ? targetAudienceToCategories(alert.targetAudience)
    : targetCategories.filter(Boolean);

  const description = alert.situationDescription?.trim() || alert.message?.trim() || "";
  const instructions = alert.alternativeInstructions?.trim() || "";

  const list = loadHallNotifications();
  const row = {
    id: nextNotificationId(list),
    type: "manager_alert",
    alertId: alert.id,
    severity: alert.severity || "medium",
    name: alert.name,
    title: alert.name,
    description,
    message: description,
    instructions,
    audiences: audiences.length ? audiences : ["customer"],
    createdAt: formatAlertDateTime(),
    isRead: false,
  };
  saveHallNotifications([row, ...list]);
  return row;
}

export function pushBookingsStopNotification({ hallName, reason = "" } = {}) {
  const name = hallName || getHallDisplayName();
  const list = loadHallNotifications();
  const row = {
    id: nextNotificationId(list),
    type: "bookings_stop",
    hallName: name,
    reason: reason.trim(),
    message: buildBookingsStopNotificationText(name),
    audiences: ["reception", "maintenance", "customer"],
    createdAt: formatAlertDateTime(),
    isRead: false,
  };
  saveHallNotifications([row, ...list]);
  return row;
}

export function pushBookingsStartNotification({ hallName } = {}) {
  const name = hallName || getHallDisplayName();
  const list = loadHallNotifications();
  const row = {
    id: nextNotificationId(list),
    type: "bookings_start",
    hallName: name,
    reason: "",
    message: buildBookingsStartNotificationText(name),
    audiences: ["reception", "maintenance", "customer"],
    createdAt: formatAlertDateTime(),
    isRead: false,
  };
  saveHallNotifications([row, ...list]);
  return row;
}

function notificationAppliesToAudience(row, audience) {
  const audiences = row.audiences ?? [];
  if (audiences.length >= 3) return true;
  return audiences.includes(audience);
}

export function markHallNotificationRead(id) {
  const list = loadHallNotifications().map((row) =>
    row.id === id ? { ...row, isRead: true } : row,
  );
  saveHallNotifications(list);
}

export function markAllHallNotificationsRead(audience) {
  const list = loadHallNotifications().map((row) =>
    notificationAppliesToAudience(row, audience) ? { ...row, isRead: true } : row,
  );
  saveHallNotifications(list);
}

export function deleteHallNotification(id) {
  const list = loadHallNotifications().filter((row) => row.id !== id);
  saveHallNotifications(list);
}

export function deleteHallNotifications(ids) {
  const idSet = new Set(ids);
  const list = loadHallNotifications().filter((row) => !idSet.has(row.id));
  saveHallNotifications(list);
}

export function clearHallNotificationsForAudience(audience) {
  const list = loadHallNotifications().filter((row) => !notificationAppliesToAudience(row, audience));
  saveHallNotifications(list);
}
