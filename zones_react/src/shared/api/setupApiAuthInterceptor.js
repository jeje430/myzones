import { apiClient } from "../api/apiClient";
import {
  getActiveAccountIdFromUrl,
  findScopedManagerSession,
  getScopedToken,
} from "../../features/auth/data/accountSessionStorage";

const MANAGER_TOKEN_KEY = "zones-manager-token";
const SUPER_ADMIN_TOKEN_KEY = "zones-super-admin-token";

function pickStaffToken() {
  const urlId = getActiveAccountIdFromUrl();
  if (urlId) {
    const scoped = getScopedToken(urlId);
    if (scoped) return scoped;
  }

  const session = findScopedManagerSession();
  if (session?.id) {
    const scoped = getScopedToken(session.id);
    if (scoped) return scoped;
  }

  return localStorage.getItem(MANAGER_TOKEN_KEY) || null;
}

function pickSuperAdminToken() {
  return localStorage.getItem(SUPER_ADMIN_TOKEN_KEY) || null;
}

/**
 * يضيف Authorization تلقائياً لطلبات API حسب السياق والتبويب الحالي.
 */
export function setupApiAuthInterceptor() {
  apiClient.interceptors.request.use((config) => {
    const url = String(config.url || "");
    const headers = config.headers || {};
    const pathname = typeof window !== "undefined" ? window.location.pathname : "";

    if (headers.Authorization || headers.authorization) {
      return config;
    }

    const isProfileRoute = url.includes("/profile");
    const needsSuperAdmin =
      url.includes("hall-join-requests") ||
      url.includes("/super-admin/") ||
      (isProfileRoute && pathname.startsWith("/super-admin"));

    let token = needsSuperAdmin ? pickSuperAdminToken() : pickStaffToken();
    if (!token && isProfileRoute) {
      token = pickSuperAdminToken() || pickStaffToken();
    }

    if (token) {
      headers.Authorization = `Bearer ${token}`;
    }

    config.headers = headers;
    return config;
  });
}
