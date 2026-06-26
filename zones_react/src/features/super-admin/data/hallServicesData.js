/** خدمات/منصات الصالة — تظهر كـ chips للزبون في التطبيق */
export const HALL_SERVICE_OPTIONS = [
  { key: "ps5", label: "PlayStation 5", shortLabel: "PS5" },
  { key: "xbox", label: "Xbox", shortLabel: "XBOX" },
  { key: "vr", label: "VR", shortLabel: "VR" },
  { key: "vip", label: "VIP", shortLabel: "VIP" },
  { key: "simulator", label: "Simulator", shortLabel: "SIMULATOR" },
  { key: "racing", label: "Racing", shortLabel: "RACING" },
  { key: "pc", label: "PC Gaming", shortLabel: "PC" },
  { key: "free_wifi", label: "إنترنت مجاني", shortLabel: "Free WiFi" },
  { key: "snacks", label: "سناكس", shortLabel: "سناكس" },
  { key: "cafeteria", label: "كافتيريا", shortLabel: "كافتيريا" },
];

/** @deprecated — لم يعد يُستخدم في واجهة المدير؛ للتوافق مع بيانات قديمة */
export const GAMING_ACCESSORY_OPTIONS = [];

export function createDefaultServicesAvailability() {
  return Object.fromEntries(HALL_SERVICE_OPTIONS.map(({ key }) => [key, false]));
}

export function createDefaultAccessoriesAvailability() {
  return {};
}

export function normalizeServicesAvailability(stored) {
  const base = createDefaultServicesAvailability();
  if (!stored || typeof stored !== "object") return base;
  for (const { key } of HALL_SERVICE_OPTIONS) {
    if (typeof stored[key] === "boolean") {
      base[key] = stored[key];
    }
  }
  return base;
}

export function normalizeAccessoriesAvailability(stored) {
  return {};
}

/** الخدمات المفعّلة فقط — للتطبيق والزبون */
export function getAvailableHallServices(availabilityMap) {
  const normalized = normalizeServicesAvailability(availabilityMap);
  return HALL_SERVICE_OPTIONS
    .filter((service) => normalized[service.key])
    .map((service) => ({ ...service, is_available: true }));
}

export function countAvailableHallServices(availabilityMap) {
  const normalized = normalizeServicesAvailability(availabilityMap);
  return HALL_SERVICE_OPTIONS.filter((service) => normalized[service.key]).length;
}

const LABEL_BY_KEY = Object.fromEntries(HALL_SERVICE_OPTIONS.map((s) => [s.key, s.label]));

export function resolveHallServices(hall) {
  if (Array.isArray(hall?.services) && hall.services.length > 0) {
    return hall.services.filter((key) => LABEL_BY_KEY[key]);
  }
  if (hall?.servicesAvailability) {
    return getAvailableHallServices(hall.servicesAvailability).map((s) => s.key);
  }
  return [];
}

export function hallServiceLabels(hall) {
  return resolveHallServices(hall).map((key) => LABEL_BY_KEY[key] || key);
}

export function formatHallServicesHtml(hall) {
  const labels = hallServiceLabels(hall);
  if (labels.length === 0) {
    return "<span style='color:#9ca3af'>لا توجد خدمات مسجّلة</span>";
  }
  return labels
    .map(
      (label) =>
        `<span style="display:inline-block;margin:0 0 6px 6px;padding:6px 14px;border-radius:999px;background:rgba(107,84,120,0.12);color:#6B5478;font-size:12px;font-weight:700">${label}</span>`,
    )
    .join("");
}

export const DEFAULT_ACTIVE_HALLS = [];
