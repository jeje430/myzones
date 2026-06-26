import {
  fetchManagerExpenses,
  fetchManagerFinanceOverview,
  fetchTodayRevenue,
} from "./managerFinanceApi";
import { purgeLegacyBookingRevenueLedger } from "./purgeLegacyFinanceStorage";

export const FINANCE_DATA_EVENT = "zones-finance-data-updated";
export const EXPENSES_STORAGE_EVENT = FINANCE_DATA_EVENT;
export const BOOKING_REVENUE_EVENT = FINANCE_DATA_EVENT;

const overviewCache = new Map();
let expensesCache = [];
let todayRevenueCache = null;
let legacyPurgeDone = false;

function cacheKey(year, month, granularity, packagePeriod = "monthly") {
  return `${year}-${month}-${granularity}-${packagePeriod}`;
}

function overviewForGranularity(year, month, granularity) {
  const prefix = `${year}-${month}-${granularity}-`;
  for (const [key, value] of overviewCache.entries()) {
    if (key.startsWith(prefix)) return value;
  }
  return null;
}

function notifyUpdated() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(FINANCE_DATA_EVENT));
}

export function purgeLegacyFinanceData(force = false) {
  const result = purgeLegacyBookingRevenueLedger(force);
  if (result.removedKeys.length || force) {
    invalidateFinanceCache();
  }
  legacyPurgeDone = true;
  return result;
}

function ensureLegacyFinancePurged() {
  if (legacyPurgeDone) return;
  purgeLegacyFinanceData();
}

export function getCachedOverview(year, month, granularity = "daily", packagePeriod = "monthly") {
  return (
    overviewCache.get(cacheKey(year, month, granularity, packagePeriod)) ||
    overviewForGranularity(year, month, granularity)
  );
}

export function getCachedExpenses() {
  return expensesCache;
}

export function getCachedTodayRevenue() {
  return todayRevenueCache;
}

export function invalidateFinanceCache() {
  overviewCache.clear();
  todayRevenueCache = null;
  notifyUpdated();
}

export async function refetchFinanceData(year, month, granularity = "daily", packagePeriod = "monthly") {
  overviewCache.clear();
  todayRevenueCache = null;
  await Promise.all([
    prefetchFinanceMonth(year, month, granularity, packagePeriod),
    ensureTodayRevenue(true),
    ensureExpensesLoaded(true),
  ]);
}

export async function ensureFinanceOverview(
  year,
  month,
  granularity = "daily",
  packagePeriod = "monthly",
) {
  ensureLegacyFinancePurged();
  const key = cacheKey(year, month, granularity, packagePeriod);
  if (overviewCache.has(key)) {
    return overviewCache.get(key);
  }

  const result = await fetchManagerFinanceOverview(year, month, granularity, packagePeriod);
  if (result.ok && result.overview) {
    overviewCache.set(key, result.overview);
    notifyUpdated();
    return result.overview;
  }

  return null;
}

export async function ensureExpensesLoaded(force = false) {
  if (!force && expensesCache.length) {
    return expensesCache;
  }

  const result = await fetchManagerExpenses();
  if (result.ok) {
    expensesCache = result.expenses;
    notifyUpdated();
  }

  return expensesCache;
}

export async function setExpensesCache(rows) {
  expensesCache = rows;
  notifyUpdated();
}

export async function ensureTodayRevenue(force = false) {
  ensureLegacyFinancePurged();
  if (!force && todayRevenueCache) {
    return todayRevenueCache;
  }

  const result = await fetchTodayRevenue();
  if (result.ok) {
    todayRevenueCache = {
      todayTotal: result.todayTotal,
      yesterdayTotal: result.yesterdayTotal,
      deltaPct: result.deltaPct,
    };
    notifyUpdated();
    return todayRevenueCache;
  }

  return { todayTotal: 0, yesterdayTotal: 0, deltaPct: 0 };
}

export async function prefetchFinanceMonth(
  year,
  month,
  granularity = "daily",
  packagePeriod = "monthly",
) {
  const prevMonth = month === 1 ? 12 : month - 1;
  const prevYear = month === 1 ? year - 1 : year;

  await Promise.all([
    ensureFinanceOverview(year, month, granularity, packagePeriod),
    ensureFinanceOverview(year, month, "daily", packagePeriod),
    ensureFinanceOverview(prevYear, prevMonth, "daily", "monthly"),
    ensureExpensesLoaded(),
  ]);
}
