import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";

const BASE_KEY = "zones-package-bookings-v2";
const storageKey = () => hallScopedKey(BASE_KEY);

export const PACKAGE_BOOKINGS_EVENT = "zones-package-bookings-updated";

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new CustomEvent(PACKAGE_BOOKINGS_EVENT));
}

const DEFAULT_BOOKINGS = [];

export function loadPackageBookings() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    return Array.isArray(parsed) && parsed.length ? parsed : [];
  } catch {
    return [];
  }
}

export function savePackageBookings(list) {
  try {
    localStorage.setItem(storageKey(), JSON.stringify(list));
    notifyUpdated();
  } catch {
    /* ignore */
  }
}

function isCurrentMonth(iso) {
  const d = new Date(iso);
  const now = new Date();
  return d.getFullYear() === now.getFullYear() && d.getMonth() === now.getMonth();
}

function formatActivityDate(iso) {
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return "—";
    return d.toLocaleString("ar-LY", {
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    });
  } catch {
    return "—";
  }
}

/** عدد استخدامات الباقة هذا الشهر — من عمليات الحجز */
export function getPackageUsageThisMonth(packageId) {
  return loadPackageBookings().filter(
    (b) => b.packageId === packageId && isCurrentMonth(b.bookedAt),
  ).length;
}

/** تاريخ آخر نشاط للباقة — آخر حجز مسجّل */
export function getPackageLastActivity(packageId) {
  const bookings = loadPackageBookings().filter((b) => b.packageId === packageId);
  if (!bookings.length) return "—";
  const latest = bookings.reduce((a, b) =>
    new Date(a.bookedAt) > new Date(b.bookedAt) ? a : b,
  );
  return formatActivityDate(latest.bookedAt);
}

/** الأكثر طلباً هذا الشهر — يُحسب من عمليات الحجز */
export function getMostRequestedPackageStats(packages = []) {
  const bookings = loadPackageBookings().filter((b) => isCurrentMonth(b.bookedAt));
  const counts = new Map();
  for (const b of bookings) {
    counts.set(b.packageId, (counts.get(b.packageId) ?? 0) + 1);
  }
  let topId = null;
  let topCount = 0;
  for (const [id, count] of counts) {
    if (count > topCount) {
      topCount = count;
      topId = id;
    }
  }
  const pkg = packages.find((p) => p.id === topId);
  return {
    count: topCount,
    name: pkg?.name ?? (topCount > 0 ? "—" : "لا طلبات بعد"),
  };
}
