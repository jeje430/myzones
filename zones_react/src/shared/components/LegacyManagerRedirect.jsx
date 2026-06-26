import { Navigate, useLocation } from "react-router-dom";
import {
  buildManagerWorkspacePath,
  findScopedManagerSession,
} from "../../features/auth/data/accountSessionStorage";

/** يحوّل المسارات القديمة إلى مسار المدير المعزول */
export default function LegacyManagerRedirect({ segment }) {
  const location = useLocation();
  const session = findScopedManagerSession();

  if (!session?.id) {
    return <Navigate to="/manager/login" replace />;
  }

  const pathSuffix =
    segment ??
    (location.pathname.replace(/^\//, "").replace(/\/$/, "") || "dashboard");

  const target = buildManagerWorkspacePath(session.id, pathSuffix);
  const withSearch = location.search ? `${target}${location.search}` : target;

  return <Navigate to={withSearch} replace />;
}
