import { fetchHallJoinRequests } from "./hallJoinRequestsApi";
import { fetchPlatformCommissionSummary, fetchPlatformCommissionSettings } from "./commissionSettingsApi";
import { HALL_REQUEST_STATUS, HALL_REQUEST_STATUS_LABELS } from "./hallRequestStatus";

export { ZONES_LOGO_SRC } from "../../../shared/branding/brandingConstants";

/** بيانات احتياطية عند فشل API */
export function getLocalDashboardData() {
  const now = new Date();
  return {
    kpis: { activeHalls: 0, pendingRequests: 0 },
    platformSummary: {
      activeManagers: 0,
      activeReception: 0,
      activeMaintenance: 0,
      activeHallCount: 0,
      expectedCommission: 0,
      globalRate: 0,
      monthLabel: now.toLocaleDateString("ar-LY", { month: "long", year: "numeric" }),
    },
    recentRequests: [],
  };
}

function mapRecentRequest(r) {
  return {
    id: r.id,
    hallName: r.hallName || r.hall_name,
    city: r.city || r.address?.split("—")[0]?.trim() || r.address,
    phone: r.commercialPhone || r.commercial_phone,
    employeeCount: r.employeeCount,
    status: HALL_REQUEST_STATUS_LABELS.pending,
  };
}

/** ملخص لوحة التحكم — يجمع طلبات الانضمام وعمولات المنصة من API */
export async function fetchDashboardView() {
  const now = new Date();
  const year = now.getFullYear();
  const month = now.getMonth() + 1;

  const [requestsResult, commissionSettings, commissionSummary] = await Promise.all([
    fetchHallJoinRequests(),
    fetchPlatformCommissionSettings(),
    fetchPlatformCommissionSummary(year, month),
  ]);

  const pending = requestsResult.ok
    ? requestsResult.requests.filter((r) => r.status === HALL_REQUEST_STATUS.pending)
    : [];

  const globalRate = commissionSettings.ok ? commissionSettings.rate : 0;
  const expectedCommission =
    commissionSummary.ok && commissionSummary.summary
      ? commissionSummary.summary.totalCommissions
      : 0;

  return {
    kpis: {
      activeHalls: requestsResult.ok
        ? requestsResult.requests.filter((r) => r.status === HALL_REQUEST_STATUS.accepted).length
        : 0,
      pendingRequests: pending.length,
    },
    platformSummary: {
      activeManagers: 0,
      activeReception: 0,
      activeMaintenance: 0,
      activeHallCount: requestsResult.ok
        ? requestsResult.requests.filter((r) => r.status === HALL_REQUEST_STATUS.accepted).length
        : 0,
      expectedCommission,
      globalRate,
      monthLabel: now.toLocaleDateString("ar-LY", { month: "long", year: "numeric" }),
    },
    recentRequests: pending.slice(0, 4).map(mapRecentRequest),
  };
}

/** @deprecated استخدم fetchDashboardView */
export function getDashboardView() {
  return fetchDashboardView();
}
