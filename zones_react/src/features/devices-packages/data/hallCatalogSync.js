import { getActiveAccountIdFromUrl } from "../../auth/data/accountSessionStorage";
import { getAuthSession, getManagerApiToken } from "../../auth/data/mockUsersStorage";
import { fetchManagerDevices } from "./managerDevicesApi";
import { fetchManagerPackages } from "./managerPackagesApi";
import { fetchStaffHallCatalog } from "./staffHallCatalogApi";

export function getActiveStaffSession() {
  const accountId = getActiveAccountIdFromUrl();
  const session = getAuthSession(accountId) ?? getAuthSession();
  return session;
}

export function isApiStaffSession(session) {
  if (!session || session.source !== "api") return false;
  if (!["manager", "reception", "maintenance"].includes(session.role)) return false;
  return Boolean(getManagerApiToken(session.id));
}

/**
 * يجلب الباقات والأجهزة من Laravel ويحدّث التخزين المحلي حسب الصالة.
 * المدير: endpoints المدير. الاستقبال/الصيانة: staff/hall-catalog.
 */
export async function refreshHallCatalogFromApi() {
  const session = getActiveStaffSession();
  if (!isApiStaffSession(session)) {
    return { ok: false, skipped: true };
  }

  if (session.role === "manager") {
    const [devicesResult, packagesResult] = await Promise.all([
      fetchManagerDevices(),
      fetchManagerPackages(),
    ]);
    if (!devicesResult.ok) return devicesResult;
    if (!packagesResult.ok) return packagesResult;
    const { saveDevices } = await import("./devicesStorage");
    const { savePackages } = await import("./packagesStorage");
    saveDevices(devicesResult.devices);
    savePackages(packagesResult.packages);
    return { ok: true };
  }

  const result = await fetchStaffHallCatalog();
  if (!result.ok) return result;
  const { saveDevices } = await import("./devicesStorage");
  const { savePackages } = await import("./packagesStorage");
  saveDevices(result.devices);
  savePackages(result.packages);
  return { ok: true };
}
