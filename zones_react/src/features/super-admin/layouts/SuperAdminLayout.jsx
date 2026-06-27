import { useEffect, useState } from "react";
import { Outlet, useLocation } from "react-router-dom";
import SuperAdminSidebar from "../components/SuperAdminSidebar";
import SuperAdminTopBar from "../components/SuperAdminTopBar";
import SidebarEdgeToggle from "../../../shared/components/SidebarEdgeToggle";
import MaintenanceModeBanner from "../components/MaintenanceModeBanner";
import { getSuperAdminSession } from "../data/superAdminAuth";
import { fetchPendingJoinRequestsSummary } from "../data/hallJoinRequestsApi";
import useSidebarOpen from "../../../shared/hooks/useSidebarOpen";
import { useSidebarMobileClose } from "../../../shared/hooks/useSidebarMobileClose";

export default function SuperAdminLayout() {
  const location = useLocation();
  const session = getSuperAdminSession();
  const { sidebarOpen, toggleSidebar, closeSidebar } = useSidebarOpen("zones-super-admin-sidebar-open");
  const closeSidebarOnMobile = useSidebarMobileClose(closeSidebar);
  const [pendingCount, setPendingCount] = useState(0);

  const refreshCounts = async () => {
    const result = await fetchPendingJoinRequestsSummary();
    if (result.ok) {
      setPendingCount(result.pendingCount);
    }
  };

  useEffect(() => {
    refreshCounts();
    const handler = () => refreshCounts();
    window.addEventListener("super-admin-data-updated", handler);
    window.addEventListener("hall-join-requests-updated", handler);
    return () => {
      window.removeEventListener("super-admin-data-updated", handler);
      window.removeEventListener("hall-join-requests-updated", handler);
    };
  }, [location.pathname]);

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
        <SuperAdminSidebar
          pendingCount={pendingCount}
          onNavigate={closeSidebarOnMobile}
          onMenuToggle={toggleSidebar}
        />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <SuperAdminTopBar session={session} />
        <MaintenanceModeBanner />
        <main className="flex-1 p-4 md:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
