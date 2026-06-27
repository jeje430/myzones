import { useCallback, useEffect, useState } from "react";

function readStoredOpen(storageKey) {
  try {
    const stored = localStorage.getItem(storageKey);
    if (stored === "0") return false;
    if (stored === "1") return true;
  } catch {
    /* ignore */
  }
  return typeof window !== "undefined" ? window.innerWidth >= 1024 : true;
}

export default function useSidebarOpen(storageKey = "zones-sidebar-open") {
  const [open, setOpen] = useState(() => readStoredOpen(storageKey));

  useEffect(() => {
    try {
      localStorage.setItem(storageKey, open ? "1" : "0");
    } catch {
      /* ignore */
    }
  }, [open, storageKey]);

  const toggleSidebar = useCallback(() => {
    setOpen((value) => !value);
  }, []);

  const closeSidebar = useCallback(() => {
    setOpen(false);
  }, []);

  return { sidebarOpen: open, toggleSidebar, closeSidebar, setSidebarOpen: setOpen };
}
