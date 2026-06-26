import { useParams } from "react-router-dom";
import { getAuthSession } from "../../auth/data/mockUsersStorage";
import { buildMaintenanceWorkspacePath } from "../../auth/data/accountSessionStorage";
import { useEmployeeWorkspaceOptional } from "../../../shared/tenant/EmployeeWorkspaceProvider";

export function getMaintenanceEmployeeRoutes(employeeId) {
  const base = `/employee/maintenance/${employeeId}`;
  return {
    dashboard: base,
    devices: `${base}/devices`,
    faults: `${base}/faults`,
    faultsArchive: `${base}/faults/archive`,
    profile: `${base}/profile`,
    changePassword: `${base}/change-password`,
  };
}

export function useMaintenanceEmployeeRoutes() {
  const ctx = useEmployeeWorkspaceOptional();
  const { employeeId } = useParams();
  const id = ctx?.employeeId ?? employeeId ?? getAuthSession()?.id ?? "0";
  return {
    routes: getMaintenanceEmployeeRoutes(id),
    employeeId: id,
    buildPath: (segment) => buildMaintenanceWorkspacePath(id, segment),
  };
}

export const MAINTENANCE_EMPLOYEE_ROUTES = getMaintenanceEmployeeRoutes(
  typeof window !== "undefined" ? getAuthSession()?.id ?? "0" : "0",
);
