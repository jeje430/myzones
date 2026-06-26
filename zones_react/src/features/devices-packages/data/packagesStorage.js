import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";
import {
  createManagerPackage,
  deleteManagerPackage,
  updateManagerPackage,
} from "./managerPackagesApi";
import { refreshHallCatalogFromApi, getActiveStaffSession, isApiStaffSession } from "./hallCatalogSync";

const BASE_KEY = "zones-packages-v2";
const storageKey = () => hallScopedKey(BASE_KEY);

export const PACKAGES_STORAGE_EVENT = "zones-packages-updated";

export const DEFAULT_PACKAGES = [];

function notifyPackagesUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(PACKAGES_STORAGE_EVENT));
}

function normalizePackage(row) {
  return {
    id: row.id,
    name: row.name ?? "",
    price: row.price ?? "—",
    deviceLabel: row.deviceLabel ?? "—",
    packageType: row.packageType ?? row.deviceLabel ?? "ps5",
    description: row.description ?? row.extras ?? "",
    minimumHours: Number(row.minimumHours ?? row.minimum_hours ?? 1) || 1,
    maximumHours: row.maximumHours ?? row.maximum_hours ?? null,
    isActive: row.isActive !== false,
    isArchived: Boolean(row.isArchived),
    archivedAt: row.archivedAt || null,
    createdAt: row.createdAt || "—",
  };
}

export function loadPackages() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed) || !parsed.length) return [];
    return parsed.map(normalizePackage);
  } catch {
    return [];
  }
}

export function loadActivePackages() {
  return loadPackages().filter((p) => !p.isArchived);
}

export function loadArchivedPackages() {
  return loadPackages().filter((p) => p.isArchived);
}

export function savePackages(list) {
  try {
    const serialized = JSON.stringify(list.map(normalizePackage));
    const prev = localStorage.getItem(storageKey());
    if (prev === serialized) return;
    localStorage.setItem(storageKey(), serialized);
    notifyPackagesUpdated();
  } catch {
    /* ignore */
  }
}

function getManagerSession() {
  return getActiveStaffSession();
}

function isApiManagerSession(session) {
  return isApiStaffSession(session) && session?.role === "manager";
}

export async function refreshPackagesFromApi() {
  const session = getManagerSession();
  if (!isApiStaffSession(session)) {
    return { ok: false, skipped: true };
  }

  const result = await refreshHallCatalogFromApi();
  if (!result.ok) return result;
  return { ok: true, packages: loadPackages() };
}

export async function persistPackageCreate(patch) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadPackages();
    const nid = Math.max(0, ...list.map((p) => Number(p.id) || 0)) + 1;
    const created = normalizePackage({ ...patch, id: nid, createdAt: new Date().toISOString() });
    savePackages([...list, created]);
    return { ok: true, package: created };
  }

  const result = await createManagerPackage({
    ...patch,
    packageType: patch.packageType || patch.deviceLabel || "ps5",
  });
  if (!result.ok) return result;
  await refreshPackagesFromApi();
  return { ok: true, package: result.package, message: result.message };
}

export async function persistPackageUpdate(id, patch) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadPackages();
    savePackages(list.map((p) => (p.id === id ? normalizePackage({ ...p, ...patch }) : p)));
    return { ok: true };
  }

  const result = await updateManagerPackage(id, patch);
  if (!result.ok) return result;
  await refreshPackagesFromApi();
  return { ok: true, package: result.package, message: result.message };
}

export async function persistPackageArchive(id) {
  const session = getManagerSession();
  if (!isApiManagerSession(session)) {
    const list = loadPackages();
    savePackages(
      list.map((p) =>
        p.id === id
          ? normalizePackage({
              ...p,
              isArchived: true,
              isActive: false,
              archivedAt: new Date().toISOString(),
            })
          : p,
      ),
    );
    return { ok: true };
  }

  const result = await deleteManagerPackage(id);
  if (!result.ok) return result;
  await refreshPackagesFromApi();
  return { ok: true, message: result.message };
}

export async function persistPackageToggleActive(id, isActive) {
  const row = loadPackages().find((p) => p.id === id);
  if (!row) return { ok: false, error: "الباقة غير موجودة" };
  return persistPackageUpdate(id, { ...row, isActive });
}
