import { useEffect } from "react";
import { loadPackages, PACKAGES_STORAGE_EVENT } from "../data/packagesStorage";

const PACKAGES_KEY_PREFIX = "zones-packages-";

/** مزامنة قائمة الباقات مع LocalStorage عبر التبويبات والواجهات */
export function usePackagesSync(setPackagesList) {
  useEffect(() => {
    const syncFromStorage = () => setPackagesList(loadPackages());

    const onStorage = (e) => {
      if (e.key == null || e.key.startsWith(PACKAGES_KEY_PREFIX)) syncFromStorage();
    };

    window.addEventListener(PACKAGES_STORAGE_EVENT, syncFromStorage);
    window.addEventListener("storage", onStorage);
    window.addEventListener("focus", syncFromStorage);

    return () => {
      window.removeEventListener(PACKAGES_STORAGE_EVENT, syncFromStorage);
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("focus", syncFromStorage);
    };
  }, [setPackagesList]);
}
