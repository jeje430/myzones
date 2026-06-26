import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { mapApiDevice } from "./managerDevicesApi";
import { mapApiPackage } from "./managerPackagesApi";

export async function fetchStaffHallCatalog() {
  try {
    const { data } = await apiClient.get("/staff/hall-catalog");
    const packages = (data.packages || []).map(mapApiPackage);
    const devices = (data.devices || []).map(mapApiDevice);
    return { ok: true, packages, devices };
  } catch (error) {
    return {
      ok: false,
      error: mapApiErrorMessage(error),
      packages: [],
      devices: [],
    };
  }
}
