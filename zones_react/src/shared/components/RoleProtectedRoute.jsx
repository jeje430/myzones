import { Navigate, Outlet, useLocation } from "react-router-dom";
import { EMPLOYEE_LOGIN_PATH, MANAGER_LOGIN_PATH } from "../../features/auth/data/authRoutes";
import {
  getAuthSession,
  getLoginRedirectPath,
  normalizeSessionRole,
} from "../../features/auth/data/mockUsersStorage";
import { parseWorkspaceAccountIdFromPath } from "../../features/auth/data/accountSessionStorage";
/**
 * حارس المسارات حسب الدور (role) — يضمن العزل بين لوحات التحكم.
 * - بدون جلسة → صفحة تسجيل الدخول.
 * - دور غير مسموح → يُعاد توجيهه إلى لوحته الخاصة.
 */
export default function RoleProtectedRoute({ roles, children }) {
  const location = useLocation();
  const accountId = parseWorkspaceAccountIdFromPath(location.pathname);
  const session = getAuthSession(accountId);

  if (!session) {
    const isEmployeePath = location.pathname.startsWith("/employee/reception") ||
      location.pathname.startsWith("/employee/maintenance");
    return (
      <Navigate
        to={isEmployeePath ? EMPLOYEE_LOGIN_PATH : MANAGER_LOGIN_PATH}
        replace
        state={{ from: location.pathname }}
      />
    );
  }

  const role = normalizeSessionRole(session.role);
  if (Array.isArray(roles) && roles.length > 0 && !roles.includes(role)) {
    return <Navigate to={getLoginRedirectPath(role, session.id)} replace />;
  }

  return children ?? <Outlet />;
}