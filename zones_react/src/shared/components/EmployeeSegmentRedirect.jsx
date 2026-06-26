import { Navigate, useParams } from "react-router-dom";
import {
  buildMaintenanceWorkspacePath,
  buildReceptionWorkspacePath,
} from "../../features/auth/data/accountSessionStorage";

export function ReceptionReservationsRedirect() {
  const { employeeId } = useParams();
  return <Navigate to={`/employee/reception/${employeeId}/reservations/calendar`} replace />;
}

export function MaintenanceFaultsRedirect() {
  const { employeeId } = useParams();
  return <Navigate to={buildMaintenanceWorkspacePath(employeeId, "faults")} replace />;
}
