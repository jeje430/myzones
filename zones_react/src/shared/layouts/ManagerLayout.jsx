import { Outlet } from "react-router-dom";
import ManagerSidebar from "../components/ManagerSidebar";
import ManagerTopBar from "../components/ManagerTopBar";
import SidebarEdgeToggle from "../components/SidebarEdgeToggle";
import useActiveSessionGuard from "../hooks/useActiveSessionGuard";
import useSidebarOpen from "../hooks/useSidebarOpen";
import { useSidebarMobileClose } from "../hooks/useSidebarMobileClose";

export default function ManagerLayout() {
  useActiveSessionGuard();
  const { sidebarOpen, toggleSidebar, closeSidebar } = useSidebarOpen("zones-manager-sidebar-open");
  const closeSidebarOnMobile = useSidebarMobileClose(closeSidebar);

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
        <ManagerSidebar onNavigate={closeSidebarOnMobile} onMenuToggle={toggleSidebar} />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <ManagerTopBar />
        <main className="flex-1 p-4 md:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
