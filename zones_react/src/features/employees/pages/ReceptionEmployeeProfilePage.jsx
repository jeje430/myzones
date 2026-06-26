import EmployeeProfileView from "../components/EmployeeProfileView";
import { useEmployeeProfileAccount } from "../hooks/useEmployeeProfileAccount";
import {
  getLinkedReceptionEmployeeRecord,
  getReceptionProfileBundle,
} from "../data/receptionEmployeeProfileData";

export default function ReceptionEmployeeProfilePage() {
  const profile = useEmployeeProfileAccount({
    getEmployeeRecord: getLinkedReceptionEmployeeRecord,
    getHallName: () => getReceptionProfileBundle().hallName,
  });

  return <EmployeeProfileView roleBadgeLabel="موظف استقبال" profile={profile} />;
}
