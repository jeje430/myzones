import { useCallback } from "react";

const MOBILE_SIDEBAR_QUERY = "(max-width: 1023px)";

export function isMobileSidebarViewport() {
  if (typeof window === "undefined") return false;
  return window.matchMedia(MOBILE_SIDEBAR_QUERY).matches;
}

/** Close sidebar only on mobile overlay — desktop stays open until user toggles. */
export function useSidebarMobileClose(closeSidebar) {
  return useCallback(() => {
    if (isMobileSidebarViewport()) {
      closeSidebar();
    }
  }, [closeSidebar]);
}
