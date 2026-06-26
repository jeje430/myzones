import { getAuthSession, getManagerApiToken } from "../../auth/data/mockUsersStorage";
import { fetchManagerStation, resetManagerStation, updateManagerStation } from "./managerStationApi";
import {
  createDefaultAccessoriesAvailability,
  createDefaultServicesAvailability,
  getAvailableHallServices,
  normalizeAccessoriesAvailability,
  normalizeServicesAvailability,
} from "../../super-admin/data/hallServicesData";
import { hallScopedKey } from "../../../shared/tenant/hallScopedStorage";
import { getActiveAccountIdFromUrl } from "../../auth/data/accountSessionStorage";
import { resolveStationMediaUrl } from "../../../shared/utils/resolveStationMediaUrl";

const HALL_SKIP_API_REFRESH_KEY = "zones-skip-hall-api-refresh";

function getManagerSession() {
  const accountId = getActiveAccountIdFromUrl();
  return getAuthSession(accountId);
}

function isManagerApiSession(session) {
  if (!session || session.role !== "manager") return false;
  if (session.source === "api") return true;
  const accountId = session.id ?? getActiveAccountIdFromUrl();
  return Boolean(getManagerApiToken(accountId));
}

function markHallRefreshSkip() {
  if (typeof window === "undefined") return;
  sessionStorage.setItem(HALL_SKIP_API_REFRESH_KEY, "1");
  window.setTimeout(() => sessionStorage.removeItem(HALL_SKIP_API_REFRESH_KEY), 30000);
}

function writeEmptyHallToStorage(meta) {
  const next = {
    ...DEFAULT_HALL,
    ...meta,
    hallName: "",
    city: "",
    address: "",
    mapLink: "",
    description: "",
    latitude: "",
    longitude: "",
    phone: "",
    image: "",
    status: "pending",
    servicesAvailability: createDefaultServicesAvailability(),
    accessoriesAvailability: createDefaultAccessoriesAvailability(),
  };
  localStorage.setItem(storageKey(), JSON.stringify(next));
  window.dispatchEvent(new CustomEvent("manager-hall-updated"));
  return next;
}

function normalizeHallImage(image) {
  return resolveStationMediaUrl(image);
}

const BASE_KEY = "zones-manager-hall-data-v2";
const storageKey = () => hallScopedKey(BASE_KEY);

const DEFAULT_IMAGE = "";

export const HALL_STATUS = {
  active: { key: "active", label: "نشطة", color: "emerald" },
  disabled: { key: "disabled", label: "معطلة", color: "red" },
  pending: { key: "pending", label: "معلقة", color: "amber" },
};

/** ساعات عمل الصالة الافتراضية: من 2 مساءً إلى 2 صباحاً */
export const DEFAULT_WORK_HOURS_FROM = "14:00";
export const DEFAULT_WORK_HOURS_TO = "02:00";

const DEFAULT_HALL = {
  hallName: "",
  city: "",
  address: "",
  mapLink: "",
  description: "",
  latitude: "",
  longitude: "",
  phone: "",
  email: "",
  managerName: "",
  employeeCount: 0,
  workHoursFrom: DEFAULT_WORK_HOURS_FROM,
  workHoursTo: DEFAULT_WORK_HOURS_TO,
  joinDate: null,
  status: "pending",
  image: DEFAULT_IMAGE,
  servicesAvailability: createDefaultServicesAvailability(),
  accessoriesAvailability: createDefaultAccessoriesAvailability(),
};

function todayIso() {
  return new Date().toISOString().slice(0, 10);
}

function parseCoordinate(value) {
  const n = Number.parseFloat(String(value ?? "").trim());
  return Number.isFinite(n) ? n : null;
}

function readStored() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return null;
    const parsed = JSON.parse(raw);
    return {
      ...DEFAULT_HALL,
      ...parsed,
      image: normalizeHallImage(parsed?.image),
      servicesAvailability: normalizeServicesAvailability(parsed?.servicesAvailability),
      accessoriesAvailability: normalizeAccessoriesAvailability(parsed?.accessoriesAvailability),
    };
  } catch {
    return null;
  }
}

function formatHourAr(time) {
  const h = Number.parseInt(String(time).split(":")[0], 10);
  if (!Number.isFinite(h)) return time;
  if (h === 0) return "12:00 صباحاً";
  if (h === 12) return "12:00 ظهراً";
  if (h < 12) return `${h}:00 صباحاً`;
  if (h === 13) return "1:00 مساءً";
  if (h === 14) return "2:00 مساءً";
  return `${h - 12}:00 مساءً`;
}

/** نص عربي لساعات عمل الصالة */
export function formatHallWorkHours(from, to) {
  const start = from || DEFAULT_WORK_HOURS_FROM;
  const end = to || DEFAULT_WORK_HOURS_TO;
  return `من ${formatHourAr(start)} إلى ${formatHourAr(end)}`;
}

export function loadManagerHall() {
  const session = getManagerSession();
  const stored = readStored();
  let data = {
    ...DEFAULT_HALL,
    ...(stored || {}),
    servicesAvailability: normalizeServicesAvailability(stored?.servicesAvailability),
    accessoriesAvailability: normalizeAccessoriesAvailability(stored?.accessoriesAvailability),
  };
  let shouldPersist = false;

  if (data.workHoursFrom === "09:00" || data.workHoursFrom === "12:00") {
    data.workHoursFrom = DEFAULT_WORK_HOURS_FROM;
    shouldPersist = true;
  }
  if (!data.workHoursTo) {
    data.workHoursTo = DEFAULT_WORK_HOURS_TO;
    shouldPersist = true;
  }

  if (!data.joinDate) {
    data.joinDate = session?.joinDate || todayIso();
    shouldPersist = true;
  }
  if (!readStored() && session?.fullName && session.role === "manager") {
    data.managerName = session.fullName;
    data.email = session.email || data.email;
    shouldPersist = true;
  }

  if (shouldPersist) {
    localStorage.setItem(storageKey(), JSON.stringify(data));
  }

  data.image = normalizeHallImage(data.image);

  return data;
}

export function saveManagerHall(patch) {
  const current = readStored() || { ...DEFAULT_HALL, joinDate: todayIso() };
  const next = {
    ...current,
    ...patch,
    servicesAvailability: patch.servicesAvailability
      ? normalizeServicesAvailability(patch.servicesAvailability)
      : current.servicesAvailability,
    accessoriesAvailability: patch.accessoriesAvailability
      ? normalizeAccessoriesAvailability(patch.accessoriesAvailability)
      : current.accessoriesAvailability,
  };
  localStorage.setItem(storageKey(), JSON.stringify(next));
  window.dispatchEvent(new CustomEvent("manager-hall-updated"));
  return next;
}

/** يجلب من Laravel ثم يحدّث التخزين المحلي */
export async function refreshManagerHallFromApi() {
  if (typeof window !== "undefined" && sessionStorage.getItem(HALL_SKIP_API_REFRESH_KEY)) {
    return { ok: true, hall: loadManagerHall(), skipped: true };
  }

  const session = getManagerSession();
  if (!isManagerApiSession(session)) {
    return { ok: false, skipped: true };
  }

  const result = await fetchManagerStation();
  if (!result.ok || !result.hall) {
    return result;
  }

  const current = readStored() || { ...DEFAULT_HALL };
  saveManagerHall({
    ...result.hall,
    joinDate: current.joinDate || session.joinDate || todayIso(),
    managerName: current.managerName || session.fullName,
    email: current.email || session.email,
  });

  return { ok: true, hall: loadManagerHall() };
}

/** يحفظ في Laravel + localStorage للمدير API */
export async function persistManagerHall(patch) {
  const session = getManagerSession();

  if (isManagerApiSession(session)) {
    const apiPatch = { ...patch };
    if (patch.removeCoverImage) {
      apiPatch.removeCoverImage = true;
      delete apiPatch.image;
      delete apiPatch.imageFile;
    }
    if (patch.imageFile instanceof File) {
      delete apiPatch.image;
    }
    const result = patch.resetStation
      ? await resetManagerStation()
      : await updateManagerStation(apiPatch);
    if (!result.ok) {
      return result;
    }

    const current = readStored() || { ...DEFAULT_HALL };
    const patchImage =
      patch.image && String(patch.image).trim().startsWith("data:image") ? patch.image : undefined;

    const merged = saveManagerHall({
      ...result.hall,
      joinDate: current.joinDate,
      managerName: current.managerName,
      employeeCount: current.employeeCount,
      ...patch,
      ...(patchImage ? { image: patchImage } : {}),
      image: patch.removeCoverImage
        ? ""
        : normalizeHallImage(result.hall?.image || current.image),
      servicesAvailability: patch.servicesAvailability ?? result.hall?.servicesAvailability,
      status: result.hall?.status ?? (result.published ? "active" : "pending"),
      isPublished: result.published ?? result.hall?.isPublished ?? false,
      setupCompleted: result.setupCompleted ?? result.hall?.setupCompleted ?? false,
    });

    if (patch.removeCoverImage) {
      merged.image = "";
    }

    return { ok: true, hall: merged, message: result.message };
  }

  const hall = saveManagerHall(patch);
  return { ok: true, hall, message: "تم الحفظ محلياً" };
}

/** مسح كل بيانات الصالة والعودة لنموذج فارغ */
export async function clearManagerHall() {
  const session = getManagerSession();
  const current = readStored() || { ...DEFAULT_HALL };
  const keepMeta = {
    joinDate: current.joinDate || session?.joinDate || todayIso(),
    managerName: current.managerName || session?.fullName || "",
    email: current.email || session?.email || "",
    employeeCount: current.employeeCount ?? 0,
  };

  if (isManagerApiSession(session)) {
    const result = await resetManagerStation();
    if (!result.ok) {
      return result;
    }

    markHallRefreshSkip();

    const empty = writeEmptyHallToStorage({
      ...keepMeta,
      hallName: "",
      city: "",
      address: "",
      mapLink: "",
      description: "",
      latitude: "",
      longitude: "",
      phone: "",
      image: "",
      status: "pending",
      workHoursFrom: result.hall?.workHoursFrom || DEFAULT_WORK_HOURS_FROM,
      workHoursTo: result.hall?.workHoursTo || DEFAULT_WORK_HOURS_TO,
      servicesAvailability: createDefaultServicesAvailability(),
      accessoriesAvailability: createDefaultAccessoriesAvailability(),
    });

    return {
      ok: true,
      hall: empty,
      message: result.message || "تم مسح بيانات الصالة",
      published: false,
    };
  }

  markHallRefreshSkip();
  const empty = writeEmptyHallToStorage(keepMeta);

  return { ok: true, hall: empty, message: "تم مسح البيانات محلياً", published: false };
}

/** بيانات الصالة كاملة لتطبيق الزبون (Flutter) */
export function fetchCustomerHallProfile() {
  const hall = loadManagerHall();
  const lat = parseCoordinate(hall.latitude);
  const lng = parseCoordinate(hall.longitude);

  return {
    id: hallScopedKey(BASE_KEY),
    hallName: hall.hallName,
    city: hall.city,
    address: hall.address,
    mapLink: hall.mapLink,
    latitude: lat,
    longitude: lng,
    phone: hall.phone,
    workHoursFrom: hall.workHoursFrom,
    workHoursTo: hall.workHoursTo,
    workHoursLabel: formatHallWorkHours(hall.workHoursFrom, hall.workHoursTo),
    image: hall.image,
    status: hall.status,
    services: getAvailableHallServices(hall.servicesAvailability),
  };
}

/** محاكاة استعلام Backend للزبون: الخدمات المفعّلة فقط */
export function fetchCustomerHallServices() {
  const profile = fetchCustomerHallProfile();
  return {
    hallName: profile.hallName,
    city: profile.city,
    address: profile.address,
    image: profile.image,
    phone: profile.phone,
    mapLink: profile.mapLink,
    latitude: profile.latitude,
    longitude: profile.longitude,
    workHoursLabel: profile.workHoursLabel,
    services: profile.services,
  };
}

/** الحالة والانضمام — يحددهما النظام/الأدمن فقط */
export function setHallStatusByAdmin(status) {
  if (!HALL_STATUS[status]) return loadManagerHall();
  return saveManagerHall({ status });
}

export function getHallStatusMeta(status) {
  return HALL_STATUS[status] || HALL_STATUS.pending;
}
