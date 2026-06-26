import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { getSuperAdminToken } from "../../super-admin/data/superAdminAuth";

function authHeaders() {
  const token = getSuperAdminToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function mapLoyaltySettingsResponse(payload) {
  if (!payload) return null;

  return {
    pointsPerCompletedSession: Number(payload.points_per_completed_session) || 10,
    minimumPointsRequired: Number(payload.minimum_points_required) || 100,
    estimatedSessionsRequired: Number(payload.estimated_sessions_required) || 1,
  };
}

export async function fetchLoyaltySettings() {
  try {
    const { data } = await apiClient.get("/loyalty/settings");
    const settings = mapLoyaltySettingsResponse(data.settings);
    if (!settings) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }
    return { ok: true, settings };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateLoyaltySettings({ pointsPerCompletedSession, minimumPointsRequired }) {
  try {
    const { data } = await apiClient.put(
      "/super-admin/settings/loyalty",
      {
        points_per_completed_session: pointsPerCompletedSession,
        minimum_points_required: minimumPointsRequired,
      },
      { headers: authHeaders() },
    );
    const settings = mapLoyaltySettingsResponse(data.settings);
    if (!settings) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }
    return { ok: true, settings };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export function calculateEstimatedSessions(pointsPerCompletedSession, minimumPointsRequired) {
  const perSession = Math.max(1, Number.parseInt(String(pointsPerCompletedSession), 10) || 1);
  const minimum = Math.max(1, Number.parseInt(String(minimumPointsRequired), 10) || 1);
  return Math.ceil(minimum / perSession);
}
