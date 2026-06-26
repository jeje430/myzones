import { loadEmployees, EMPLOYEES_STORAGE_EVENT } from "../../employees/data/employeesStorage";
import { loadSyncedActiveDevices, isDeviceBroken } from "../../devices-packages/utils/deviceFaultSync";
import { DEVICES_STORAGE_EVENT } from "../../devices-packages/data/devicesStorage";
import { RECEPTION_CALENDAR_EVENT } from "../../employees/data/receptionCalendarStorage";
import { formatCurrency } from "../../finance/utils/financeData";
import {
  FINANCE_DATA_EVENT,
  ensureTodayRevenue,
  getCachedTodayRevenue,
} from "../../finance/data/financeApiCache";

export const BOOKING_REVENUE_EVENT = FINANCE_DATA_EVENT;

export const MANAGER_DASHBOARD_EVENTS = [
  RECEPTION_CALENDAR_EVENT,
  FINANCE_DATA_EVENT,
  DEVICES_STORAGE_EVENT,
  EMPLOYEES_STORAGE_EVENT,
];

export function formatRevenueDayDelta(deltaPct) {
  if (deltaPct === 0) return "بدون تغيّ عن أمس";
  const sign = deltaPct > 0 ? "+" : "";
  return `${sign}${Math.round(deltaPct)}% عن أمس`;
}

export function getTodayRevenueSummary() {
  const cached = getCachedTodayRevenue();
  if (cached) {
    return cached;
  }
  return { todayTotal: 0, yesterdayTotal: 0, deltaPct: 0 };
}

export function getManagerDashboardKpis() {
  const devices = loadSyncedActiveDevices();
  const availableDevices = devices.filter(
    (d) => d.isActive !== false && !d.isArchived && !isDeviceBroken(d) && !d.maintenanceInProgress,
  ).length;

  const employees = loadEmployees().filter((e) => !e.isArchived).length;
  const { todayTotal, deltaPct } = getTodayRevenueSummary();

  return {
    availableDevices,
    totalDevices: devices.filter((d) => !d.isArchived).length,
    employees,
    todayRevenue: todayTotal,
    todayRevenueLabel: formatCurrency(todayTotal),
    revenueHint: formatRevenueDayDelta(deltaPct),
    devicesHint: availableDevices > 0 ? `${availableDevices} متاح للعب` : "أضف أجهزة من إدارة الأجهزة",
    employeesHint: employees > 0 ? `${employees} موظف نشط` : "أضف موظفين من إدارة الموظفين",
  };
}

export async function refreshManagerDashboardFinance() {
  await ensureTodayRevenue(true);
  return getManagerDashboardKpis();
}
