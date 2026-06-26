import { createContext, useContext, useMemo } from "react";
import { Navigate, Outlet, useLocation, useParams } from "react-router-dom";
import { MANAGER_LOGIN_PATH } from "../../features/auth/data/authRoutes";
import { getAuthSession } from "../../features/auth/data/mockUsersStorage";
import { buildManagerWorkspacePath } from "../../features/auth/data/accountSessionStorage";
import { getManagerMenu, getManagerRoutes } from "../config/managerNavigation";

const ManagerWorkspaceContext = createContext(null);

/**
 * يربط المسار /manager/:managerId/* مع جلسة هذا المدير فقط.
 */
export function ManagerWorkspaceProvider({ children }) {
  const { managerId } = useParams();
  const location = useLocation();
  const session = getAuthSession(managerId);

  const value = useMemo(() => {
    const id = String(managerId ?? "");
    return {
      managerId: id,
      routes: getManagerRoutes(id),
      menu: getManagerMenu(id),
      session,
      buildPath: (segment) => buildManagerWorkspacePath(id, segment),
    };
  }, [managerId, session]);

  if (!managerId) {
    return <Navigate to={MANAGER_LOGIN_PATH} replace />;
  }

  if (!session || String(session.id) !== String(managerId)) {
    return (
      <Navigate
        to={MANAGER_LOGIN_PATH}
        replace
        state={{ from: location.pathname, loginError: "سجّل الدخول لهذا الحساب أو افتح رابط لوحتك الخاصة." }}
      />
    );
  }

  return (
    <ManagerWorkspaceContext.Provider value={value}>
      {children ?? <Outlet />}
    </ManagerWorkspaceContext.Provider>
  );
}

export function useManagerWorkspace() {
  const ctx = useContext(ManagerWorkspaceContext);
  if (!ctx) {
    throw new Error("useManagerWorkspace must be used within ManagerWorkspaceProvider");
  }
  return ctx;
}

export function useManagerWorkspaceOptional() {
  return useContext(ManagerWorkspaceContext);
}

/** مسارات لوحة المدير — يعمل داخل أو خارج Provider (يستنتج من URL) */
export function useManagerPaths() {
  const ctx = useManagerWorkspaceOptional();
  const { managerId } = useParams();
  const id = ctx?.managerId ?? managerId ?? getAuthSession()?.id;
  const routes = ctx?.routes ?? getManagerRoutes(id);
  const buildPath = ctx?.buildPath ?? ((segment) => buildManagerWorkspacePath(id, segment));
  return { managerId: id, routes, buildPath };
}
