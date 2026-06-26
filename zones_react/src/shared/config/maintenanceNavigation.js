import { getMaintenanceEmployeeRoutes } from "../../features/employees/data/maintenanceEmployeeRoutes";

export function getMaintenanceSidebarItems(employeeId) {
  const R = getMaintenanceEmployeeRoutes(employeeId);
  return [
    { label: "لوحة التحكم", path: R.dashboard, enabled: true, end: true },
    { label: "الأعطال", path: R.faults, enabled: true, end: true, badgeKey: "pending" },
    { label: "السجل", path: R.faultsArchive, enabled: true, end: true },
    { label: "الملف الشخصي", path: R.profile, enabled: true, end: true },
    { label: "تغيير كلمة المرور", path: R.changePassword, enabled: true, end: true },
  ];
}
