import { useCallback, useEffect } from "react";
import {
  RECEPTION_CALENDAR_EVENT,
  syncReceptionLiveState,
  todayIso,
} from "../data/receptionCalendarStorage";

/** Default live polling interval for reception dashboard (ms). */
export const RECEPTION_LIVE_SYNC_MS = 5_000;

/**
 * Polls Laravel calendar APIs and refreshes local reception state.
 * Use in layout + individual pages for near-real-time sync.
 */
export function useReceptionLiveSync(selectedDate = todayIso(), intervalMs = RECEPTION_LIVE_SYNC_MS) {
  const refresh = useCallback(async () => {
    await syncReceptionLiveState(selectedDate);
  }, [selectedDate]);

  useEffect(() => {
    refresh();

    const timer = setInterval(refresh, intervalMs);
    const onFocus = () => {
      refresh();
    };
    const onVisibility = () => {
      if (document.visibilityState === "visible") refresh();
    };

    window.addEventListener("focus", onFocus);
    window.addEventListener(RECEPTION_CALENDAR_EVENT, refresh);
    document.addEventListener("visibilitychange", onVisibility);

    return () => {
      clearInterval(timer);
      window.removeEventListener("focus", onFocus);
      window.removeEventListener(RECEPTION_CALENDAR_EVENT, refresh);
      document.removeEventListener("visibilitychange", onVisibility);
    };
  }, [refresh, intervalMs]);

  return refresh;
}
