import { apiClient } from "../api/apiClient";
import {
  getActiveAccountIdFromUrl,
  findScopedManagerSession,
  getScopedToken,
} from "../../features/auth/data/accountSessionStorage";
import { clearAuthSession } from "../../features/auth/data/mockUsersStorage";
import { logoutSuperAdmin } from "../../features/super-admin/data/superAdminAuth";
import { MANAGER_LOGIN_PATH, EMPLOYEE_LOGIN_PATH } from "../../features/auth/data/authRoutes";

const MANAGER_TOKEN_KEY = "zones-manager-token";
const SUPER_ADMIN_TOKEN_KEY = "zones-super-admin-token";

let handlingUnauthorized = false;

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

function resolveLoginPath() {
  const pathname = typeof window !== "undefined" ? window.location.pathname : "";
  if (pathname.startsWith("/super-admin")) return "/super-admin/login";
  if (pathname.startsWith("/employee")) return EMPLOYEE_LOGIN_PATH;
  return MANAGER_LOGIN_PATH;
}

function clearSessionForCurrentArea() {
  const pathname = typeof window !== "undefined" ? window.location.pathname : "";
  if (pathname.startsWith("/super-admin")) {
    logoutSuperAdmin();
    return;
  }

  const accountId = getActiveAccountIdFromUrl();
  if (accountId) {
    clearAuthSession(accountId);
    return;
  }

  const session = findScopedManagerSession();
  if (session?.id) {
    clearAuthSession(session.id);
  }
}

function redirectToLogin() {
  if (typeof window === "undefined") return;
  const loginPath = resolveLoginPath();
  if (window.location.pathname.startsWith(loginPath)) return;
  window.location.replace(loginPath);
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

  apiClient.interceptors.response.use(
    (response) => response,
    (error) => {
      const status = error?.response?.status;
      if (status !== 401 || handlingUnauthorized) {
        return Promise.reject(error);
      }

      handlingUnauthorized = true;
      try {
        clearSessionForCurrentArea();
        redirectToLogin();
      } finally {
        setTimeout(() => {
          handlingUnauthorized = false;
        }, 1500);
      }

      return Promise.reject(error);
    },
  );
}
