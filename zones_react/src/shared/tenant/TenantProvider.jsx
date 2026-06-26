import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  AUTH_SESSION_EVENT,
  getAuthSession,
  getLoginRedirectPath,
} from "../../features/auth/data/mockUsersStorage";
import { getActiveHallId } from "../tenant/hallScopedStorage";
import { getActiveAccountIdFromUrl } from "../../features/auth/data/accountSessionStorage";

export const TENANT_CONTEXT_EVENT = "zones-tenant-context-updated";

const TenantContext = createContext(null);

/**
 * سياق Multi-Tenant ديناميكي — يعتمد على الجلسة الحالية (role + hallId).
 * كل مستخدم يرى نفس المكوّنات؛ العزل يتم عبر hallId وليس صفحات منفصلة.
 */
export function TenantProvider({ children }) {
  const readSession = useCallback(() => {
    const accountId = getActiveAccountIdFromUrl();
    return getAuthSession(accountId);
  }, []);

  const [session, setSession] = useState(readSession);

  useEffect(() => {
    const refresh = () => {
      setSession(readSession());
      window.dispatchEvent(new Event(TENANT_CONTEXT_EVENT));
    };

    window.addEventListener(AUTH_SESSION_EVENT, refresh);
    window.addEventListener("focus", refresh);
    return () => {
      window.removeEventListener(AUTH_SESSION_EVENT, refresh);
      window.removeEventListener("focus", refresh);
    };
  }, [readSession]);

  const value = useMemo(() => {
    const accountId = getActiveAccountIdFromUrl();
    const role = session?.role ?? null;
    const hallId = getActiveHallId();
    const isAuthenticated = Boolean(session?.id || session?.email);

    return {
      session,
      user: session,
      role,
      hallId,
      managerId: accountId ?? (session?.id != null ? String(session.id) : null),
      stationId: hallId !== "default" ? hallId : null,
      stationName: session?.stationName ?? null,
      isAuthenticated,
      isApiSession: session?.source === "api",
      dashboardPath: role ? getLoginRedirectPath(role, session?.id) : "/manager/login",
    };
  }, [session]);

  return <TenantContext.Provider value={value}>{children}</TenantContext.Provider>;
}

export function useTenant() {
  const ctx = useContext(TenantContext);
  if (!ctx) {
    throw new Error("useTenant must be used within TenantProvider");
  }
  return ctx;
}

/** آمن خارج Provider — للمكوّنات التي قد تُستدعى قبل التهيئة */
export function useTenantOptional() {
  return useContext(TenantContext);
}
