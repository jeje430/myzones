import { refreshHallCatalogFromApi } from "../../devices-packages/data/hallCatalogSync";
import { mapApiDevice } from "../../devices-packages/data/managerDevicesApi";
import { saveDevices, loadDevices } from "../../devices-packages/data/devicesStorage";
import { syncReceptionLiveState } from "../../employees/data/receptionCalendarStorage";
import { fetchMaintenanceFaults } from "./maintenanceFaultsApi";
import { saveFaults } from "./maintenanceFaultsStorage";

/**
 * يجلب الأعطال والأجهزة من Laravel ويحدّث التخزين المحلي للمزامنة الفورية.
 */
export async function syncMaintenanceStateFromApi() {
  const [catalogResult, activeResult, archivedResult] = await Promise.all([
    refreshHallCatalogFromApi(),
    fetchMaintenanceFaults({ archived: false }),
    fetchMaintenanceFaults({ archived: true }),
  ]);

  if (!activeResult.ok) {
    return { ok: false, error: activeResult.error };
  }

  const faults = [
    ...(activeResult.faults || []),
    ...(archivedResult.ok ? archivedResult.faults || [] : []),
  ];

  saveFaults(faults);

  if (catalogResult.ok) {
    await syncReceptionLiveState();
    return { ok: true, faults };
  }

  return { ok: true, faults, catalogSkipped: catalogResult.skipped };
}

export function applyApiDevicePatch(apiDevice) {
  if (!apiDevice) return;
  const mapped = mapApiDevice(apiDevice);
  const list = loadDevices();
  const idx = list.findIndex((d) => String(d.id) === String(mapped.id));
  if (idx === -1) {
    saveDevices([...list, mapped]);
    return;
  }
  const next = [...list];
  next[idx] = { ...next[idx], ...mapped };
  saveDevices(next);
}
