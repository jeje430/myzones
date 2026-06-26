import {

  DEFAULT_WORK_HOURS_FROM,

  DEFAULT_WORK_HOURS_TO,

  formatHallWorkHours,

  loadManagerHall,

} from "../../lounge/data/managerHallStorage";

import { isDeviceBroken, isDeviceInMaintenanceOnDate, loadSyncedActiveDevices } from "../../devices-packages/utils/deviceFaultSync";

import { isCodeDeviceName, typeLabelFromType, DEVICE_TYPE_PREFIX } from "../../devices-packages/data/deviceNaming";

import { loadActivePackages } from "../../devices-packages/data/packagesStorage";

import {

  findCalendarSlot,

  normalizeSlotStatus,

  SLOT_STATUS,

} from "../data/receptionCalendarStorage";



export const CELL_KIND = {

  maintenance: "maintenance",

  reserved: "reserved",

  available: "available",

  busy: "busy",

};



export const CELL_META = {

  maintenance: {

    label: "صيانة",

    hint: "الجهاز في صيانة أو عطل مجدول لهذا التاريخ — الحجوزات تبقى مسجّلة",

    className: "rcal-cell--maintenance",

  },

  reserved: {

    label: "محجوز",

    hint: "حجز زبون — اضغط لعرض التفاصيل",

    className: "rcal-cell--reserved",

  },

  available: {

    label: "متاح",

    hint: "متاح للحجز — اضغط لحجز زبون",

    className: "rcal-cell--available",

  },

  busy: {

    label: "مشغول",

    hint: "جلسة نشطة — للعرض فقط",

    className: "rcal-cell--busy",

  },

};



/** Bootstrap variants — ألوان واضحة */

export const CELL_BTN_VARIANT = {

  maintenance: "secondary",

  reserved: "danger",

  available: "success",

  busy: "primary",

};



export const CELL_LEGEND_CLASS = {

  maintenance: "text-bg-rcal-maintenance",

  reserved: "text-bg-danger",

  available: "text-bg-success",

  busy: "text-bg-primary",

};



export const CALENDAR_LEGEND_ORDER = ["available", "reserved", "busy", "maintenance"];



/** هل الجهاز في حالة صيانة (مرتبط بمدير الصالة + سجل الأعطال) */

export function isDeviceInMaintenance(device) {

  if (!device) return true;

  return (
    Boolean(device.maintenanceInProgress) ||
    isDeviceBroken(device) ||
    !device.isActive ||
    device.operationalStatus === "maintenance" ||
    device.isMaintenance
  );

}



/** اسم الجهاز في التقويم — PS5-001 وليس نوع الجهاز فقط */

export function getReceptionDeviceLabel(device, indexInPackage = null) {

  if (!device) return "—";



  const name = String(device.name || device.display_name || "").trim();

  const code = String(device.deviceCode || device.device_code || "").trim();

  const typeSlug = String(device.type || "").trim().toLowerCase();



  if (name && isCodeDeviceName(name)) return name.toUpperCase();

  if (code && isCodeDeviceName(code)) return code.toUpperCase();

  if (name && name.toLowerCase() !== typeSlug) return name;

  if (code && !code.startsWith("DEV-")) return code;



  if (indexInPackage != null && Number.isFinite(indexInPackage)) {

    const prefix = DEVICE_TYPE_PREFIX[device.type] || String(device.type || "DEV").toUpperCase();

    return `${prefix}-${String(indexInPackage + 1).padStart(3, "0")}`;

  }



  return name || typeLabelFromType(device.type);

}



export function buildWorkHourSlots(from = DEFAULT_WORK_HOURS_FROM, to = DEFAULT_WORK_HOURS_TO) {

  const fromH = Number.parseInt(String(from).split(":")[0], 10);

  const toH = Number.parseInt(String(to).split(":")[0], 10);

  if (!Number.isFinite(fromH) || !Number.isFinite(toH)) {

    return buildWorkHourSlots(DEFAULT_WORK_HOURS_FROM, DEFAULT_WORK_HOURS_TO);

  }



  const slots = [];

  let h = fromH;

  let guard = 0;



  while (guard < 25) {

    slots.push(`${String(h).padStart(2, "0")}:00`);

    if (h === toH) break;

    h = (h + 1) % 24;

    guard += 1;

  }



  return slots;

}



export function getHallWorkHours() {

  const hall = loadManagerHall();

  const from = hall.workHoursFrom || DEFAULT_WORK_HOURS_FROM;

  const to = hall.workHoursTo || DEFAULT_WORK_HOURS_TO;

  return {

    from,

    to,

    label: formatHallWorkHours(from, to),

    hallName: hall.hallName || "الصالة",

  };

}



export function loadCalendarDevices() {

  return loadSyncedActiveDevices().map((d) => ({

    ...d,

    _maintenance: isDeviceInMaintenance(d),

  }));

}



/** تجميع الأجهزة تحت باقاتها للتقويم — ديناميكي من قاعدة البيانات */

export function buildCalendarPackageGroups() {

  const packages = loadActivePackages()

    .filter((p) => p.isActive !== false && !p.isArchived)

    .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), "ar"));

  const devices = loadCalendarDevices();

  const packageIds = new Set(packages.map((p) => p.id));



  const groups = packages.map((pkg) => ({

    package: pkg,

    devices: devices

      .filter((d) => d.packageId === pkg.id)

      .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), "en", { numeric: true })),

  }));



  const unassigned = devices

    .filter((d) => d.packageId == null || !packageIds.has(d.packageId))

    .sort((a, b) => String(a.name || "").localeCompare(String(b.name || ""), "en", { numeric: true }));



  if (unassigned.length) {

    groups.push({

      package: { id: null, name: "غير مرتبطة بباقة", price: "" },

      devices: unassigned,

    });

  }



  return groups.filter((g) => g.devices.length > 0);

}



export function resolveCellKind(device, date, hour, slots) {

  if (isDeviceInMaintenance(device) || isDeviceInMaintenanceOnDate(device?.id, date)) {
    return CELL_KIND.maintenance;
  }



  const slot = findCalendarSlot(device.id, date, hour, slots);

  if (!slot) return CELL_KIND.available;



  const status = normalizeSlotStatus(slot.status);

  if (status === SLOT_STATUS.busy) return CELL_KIND.busy;

  if (status === SLOT_STATUS.reserved) return CELL_KIND.reserved;

  return CELL_KIND.available;

}



export function getCalendarCellLabel(kind) {

  return CELL_META[kind]?.label ?? "";

}



export function formatCalendarDate(dateStr) {

  try {

    const d = new Date(`${dateStr}T12:00:00`);

    return d.toLocaleDateString("ar-LY", {

      weekday: "long",

      year: "numeric",

      month: "long",

      day: "numeric",

    });

  } catch {

    return dateStr;

  }

}


