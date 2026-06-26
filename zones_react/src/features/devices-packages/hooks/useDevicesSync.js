import { useEffect } from "react";
import { DEVICES_STORAGE_EVENT, DEVICES_STORAGE_KEY, loadDevices } from "../data/devicesStorage";

/** مزامنة قائمة الأجهزة مع LocalStorage عبر التبويبات والواجهات */
export function useDevicesSync(setDevicesList) {
  useEffect(() => {
    const syncFromStorage = () => setDevicesList(loadDevices());

    const onStorage = (e) => {
      if (e.key == null || e.key.startsWith(DEVICES_STORAGE_KEY)) syncFromStorage();
    };

    window.addEventListener(DEVICES_STORAGE_EVENT, syncFromStorage);
    window.addEventListener("storage", onStorage);
    window.addEventListener("focus", syncFromStorage);

    return () => {
      window.removeEventListener(DEVICES_STORAGE_EVENT, syncFromStorage);
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("focus", syncFromStorage);
    };
  }, [setDevicesList]);
}
