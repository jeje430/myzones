import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { getSuperAdminToken } from "./superAdminAuth";

function authHeaders() {
  const token = getSuperAdminToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function fetchPlatformCommissionSettings() {
  try {
    const { data } = await apiClient.get("/super-admin/settings/commission", {
      headers: authHeaders(),
    });
    return {
      ok: true,
      rate: Number(data.settings?.platform_commission_rate) || 0,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), rate: 0 };
  }
}

export async function updatePlatformCommissionSettings(rate) {
  try {
    const { data } = await apiClient.put(
      "/super-admin/settings/commission",
      { platform_commission_rate: rate },
      { headers: authHeaders() },
    );
    return {
      ok: true,
      rate: Number(data.settings?.platform_commission_rate) || rate,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function fetchPlatformCommissionSummary(year, month) {
  try {
    const { data } = await apiClient.get("/super-admin/finance/commissions", {
      params: { year, month },
      headers: authHeaders(),
    });
    return {
      ok: true,
      summary: {
        globalRate: Number(data.global_rate) || 0,
        year: Number(data.year) || year,
        month: Number(data.month) || month,
        totalCommissions: Number(data.total_commissions) || 0,
        totalAppGrossRevenue: Number(data.total_app_gross_revenue) || 0,
        totalAppBookings: Number(data.total_app_bookings) || 0,
      },
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), summary: null };
  }
}
