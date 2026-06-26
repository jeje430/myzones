import { useCallback, useEffect } from "react";
import { getActiveStaffSession, isApiStaffSession } from "../../devices-packages/data/hallCatalogSync";
import { fetchStaffNotifications } from "../data/staffNotificationsApi";
import { HALL_NOTIFICATIONS_EVENT } from "../data/hallNotificationsStorage";

export const STAFF_NOTIFICATIONS_EVENT = "zones-staff-notifications-updated";

const POLL_MS = 5000;

function notifyStaffNotificationsUpdated(notifications, unreadCount) {
  if (typeof window === "undefined") return;
  window.dispatchEvent(
    new CustomEvent(STAFF_NOTIFICATIONS_EVENT, {
      detail: { notifications, unreadCount },
    }),
  );
}

export async function syncStaffNotificationsFromApi() {
  const session = getActiveStaffSession();
  if (!isApiStaffSession(session)) {
    return { ok: false, skipped: true };
  }

  const result = await fetchStaffNotifications();
  if (!result.ok) {
    return result;
  }

  notifyStaffNotificationsUpdated(result.notifications, result.unreadCount);
  window.dispatchEvent(new Event(HALL_NOTIFICATIONS_EVENT));
  return result;
}

export function useStaffNotificationsSync(intervalMs = POLL_MS) {
  const sync = useCallback(async () => {
    await syncStaffNotificationsFromApi();
  }, []);

  useEffect(() => {
    if (intervalMs <= 0) return undefined;
    sync();
    const timer = setInterval(sync, intervalMs);
    window.addEventListener("focus", sync);
    return () => {
      clearInterval(timer);
      window.removeEventListener("focus", sync);
    };
  }, [sync, intervalMs]);

  return sync;
}
