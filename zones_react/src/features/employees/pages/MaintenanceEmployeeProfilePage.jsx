import EmployeeProfileView from "../components/EmployeeProfileView";
import { useEmployeeProfileAccount } from "../hooks/useEmployeeProfileAccount";
import {
  getLinkedEmployeeRecord,
  getMaintenanceProfileBundle,
} from "../data/maintenanceEmployeeProfileData";

export default function MaintenanceEmployeeProfilePage() {
  const profile = useEmployeeProfileAccount({
    getEmployeeRecord: getLinkedEmployeeRecord,
    getHallName: () => getMaintenanceProfileBundle().hallName,
  });

  return <EmployeeProfileView roleBadgeLabel="موظف صيانة" profile={profile} />;
}
