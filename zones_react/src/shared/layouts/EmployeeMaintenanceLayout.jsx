import { useCallback, useEffect, useState } from "react";
import { Outlet } from "react-router-dom";
import MaintenanceEmployeeSidebar from "../../features/employees/components/MaintenanceEmployeeSidebar";
import MaintenanceEmployeeTopBar from "../../features/employees/components/MaintenanceEmployeeTopBar";
import SidebarEdgeToggle from "../components/SidebarEdgeToggle";
import { getMaintenancePendingBadgeCount } from "../../features/employees/data/maintenanceDashboardData";
import { DEVICES_STORAGE_EVENT } from "../../features/devices-packages/data/devicesStorage";
import { MAINTENANCE_FAULTS_EVENT } from "../../features/maintenance/data/maintenanceFaultsStorage";
import useActiveSessionGuard from "../hooks/useActiveSessionGuard";
import useSidebarOpen from "../hooks/useSidebarOpen";
import { useSidebarMobileClose } from "../hooks/useSidebarMobileClose";

export default function EmployeeMaintenanceLayout() {
  useActiveSessionGuard();
  const { sidebarOpen, toggleSidebar, closeSidebar } = useSidebarOpen("zones-maintenance-sidebar-open");
  const closeSidebarOnMobile = useSidebarMobileClose(closeSidebar);
  const [pendingCount, setPendingCount] = useState(getMaintenancePendingBadgeCount);

  const refreshPendingCount = useCallback(() => {
    setPendingCount(getMaintenancePendingBadgeCount());
  }, []);

  useEffect(() => {
    refreshPendingCount();
    window.addEventListener(MAINTENANCE_FAULTS_EVENT, refreshPendingCount);
    window.addEventListener(DEVICES_STORAGE_EVENT, refreshPendingCount);
    window.addEventListener("focus", refreshPendingCount);
    return () => {
      window.removeEventListener(MAINTENANCE_FAULTS_EVENT, refreshPendingCount);
      window.removeEventListener(DEVICES_STORAGE_EVENT, refreshPendingCount);
      window.removeEventListener("focus", refreshPendingCount);
    };
  }, [refreshPendingCount]);

  return (
    <div
      className="flex min-h-screen bg-gray-50 text-xs dark:bg-[#0b1020]"
      style={{ fontFamily: "Cairo, 'Segoe UI', Tahoma, sans-serif" }}
      dir="rtl"
    >
      {sidebarOpen ? (
        <button
          type="button"
          className="fixed inset-0 z-40 bg-black/50 backdrop-blur-[1px] lg:hidden"
          onClick={closeSidebar}
          aria-label="إغلاق القائمة"
        />
      ) : null}

      {!sidebarOpen ? <SidebarEdgeToggle onMenuToggle={toggleSidebar} /> : null}

      <aside
        className={`relative overflow-visible fixed inset-y-0 end-0 z-50 w-64 shrink-0 transform transition-transform duration-300 ease-in-out lg:static lg:translate-x-0 ${
          sidebarOpen ? "translate-x-0" : "translate-x-full lg:hidden"
        }`}
      >
        <MaintenanceEmployeeSidebar
          pendingCount={pendingCount}
          onNavigate={closeSidebarOnMobile}
          onMenuToggle={toggleSidebar}
        />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <MaintenanceEmployeeTopBar />
        <main className="flex-1 p-4 md:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
