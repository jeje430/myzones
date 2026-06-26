import { createContext, useContext, useMemo } from "react";
import { Navigate, Outlet, useLocation, useParams } from "react-router-dom";
import { EMPLOYEE_LOGIN_PATH } from "../../features/auth/data/authRoutes";
import { getAuthSession, normalizeSessionRole } from "../../features/auth/data/mockUsersStorage";
import {
  buildMaintenanceWorkspacePath,
  buildReceptionWorkspacePath,
} from "../../features/auth/data/accountSessionStorage";
import { getMaintenanceEmployeeRoutes } from "../../features/employees/data/maintenanceEmployeeRoutes";
import { getReceptionEmployeeRoutes } from "../../features/employees/data/receptionEmployeeRoutes";

const EmployeeWorkspaceContext = createContext(null);

const NUMERIC_ID_RE = /^\d+$/;

/**
 * يربط /employee/reception/:employeeId أو /employee/maintenance/:employeeId مع جلسة هذا الموظف فقط.
 */
export function EmployeeWorkspaceProvider({ role, children }) {
  const { employeeId } = useParams();
  const location = useLocation();
  const normalizedRole = role === "maintenance" ? "maintenance" : "reception";
  const buildPath =
    normalizedRole === "maintenance" ? buildMaintenanceWorkspacePath : buildReceptionWorkspacePath;
  const getRoutes =
    normalizedRole === "maintenance" ? getMaintenanceEmployeeRoutes : getReceptionEmployeeRoutes;

  const idStr = String(employeeId ?? "");

  if (employeeId && !NUMERIC_ID_RE.test(idStr)) {
    const session = getAuthSession();
    if (!session?.id) {
      return (
        <Navigate
          to={EMPLOYEE_LOGIN_PATH}
          replace
          state={{ from: location.pathname, loginError: "سجّل الدخول لفتح لوحتك." }}
        />
      );
    }
    return <Navigate to={buildPath(session.id, employeeId)} replace />;
  }

  const session = getAuthSession(employeeId);

  const value = useMemo(() => {
    const id = idStr;
    return {
      employeeId: id,
      role: normalizedRole,
      routes: getRoutes(id),
      session,
      buildPath: (segment) => buildPath(id, segment),
    };
  }, [idStr, normalizedRole, session, buildPath, getRoutes]);

  if (!employeeId) {
    return <Navigate to={EMPLOYEE_LOGIN_PATH} replace />;
  }

  if (!session || String(session.id) !== idStr) {
    return (
      <Navigate
        to={EMPLOYEE_LOGIN_PATH}
        replace
        state={{
          from: location.pathname,
          loginError: "سجّل الدخول لهذا الحساب أو افتح رابط لوحتك الخاصة.",
        }}
      />
    );
  }

  if (normalizeSessionRole(session.role) !== normalizedRole) {
    const correctPath =
      session.role === "manager"
        ? `/manager/${session.id}/dashboard`
        : session.role === "maintenance"
          ? buildMaintenanceWorkspacePath(session.id)
          : buildReceptionWorkspacePath(session.id);
    return <Navigate to={correctPath} replace />;
  }

  return (
    <EmployeeWorkspaceContext.Provider value={value}>
      {children ?? <Outlet />}
    </EmployeeWorkspaceContext.Provider>
  );
}

export function useEmployeeWorkspace() {
  const ctx = useContext(EmployeeWorkspaceContext);
  if (!ctx) {
    throw new Error("useEmployeeWorkspace must be used within EmployeeWorkspaceProvider");
  }
  return ctx;
}

export function useEmployeeWorkspaceOptional() {
  return useContext(EmployeeWorkspaceContext);
}
