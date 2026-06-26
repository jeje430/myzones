import { Navigate } from "react-router-dom";
import { getAuthSession } from "../../features/auth/data/mockUsersStorage";
import { EMPLOYEE_LOGIN_PATH } from "../../features/auth/data/authRoutes";
import {
  buildMaintenanceWorkspacePath,
  buildReceptionWorkspacePath,
} from "../../features/auth/data/accountSessionStorage";

/** يحوّل المسارات القديمة /employee/reception → /employee/reception/:userId */
export default function EmployeeLegacyRedirect({ role = "reception" }) {
  const session = getAuthSession();
  if (!session?.id) {
    return <Navigate to={EMPLOYEE_LOGIN_PATH} replace />;
  }

  const path =
    role === "maintenance"
      ? buildMaintenanceWorkspacePath(session.id)
      : buildReceptionWorkspacePath(session.id);

  return <Navigate to={path} replace />;
}
