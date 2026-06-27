import { useEffect } from "react";
import { Outlet, useLocation } from "react-router-dom";
import { zonesClose } from "../utils/zonesAlerts";
import ReceptionEmployeeSidebar from "../../features/employees/components/ReceptionEmployeeSidebar";
import ReceptionEmployeeTopBar from "../../features/employees/components/ReceptionEmployeeTopBar";
import SidebarEdgeToggle from "../components/SidebarEdgeToggle";
import useActiveSessionGuard from "../hooks/useActiveSessionGuard";
import useSidebarOpen from "../hooks/useSidebarOpen";
import { isMobileSidebarViewport, useSidebarMobileClose } from "../hooks/useSidebarMobileClose";

/** إزالة طبقات SweetAlert العالقة التي قد تمنع النقر على الأزرار */
function clearBlockingOverlays() {
  zonesClose();
  document.body.style.overflow = "";
  document.body.style.paddingRight = "";
  document.body.classList.remove("swal2-shown", "swal2-height-auto");
}

export default function EmployeeReceptionLayout() {
  useActiveSessionGuard();
  const location = useLocation();
  const { sidebarOpen, toggleSidebar, closeSidebar } = useSidebarOpen("zones-reception-sidebar-open");
  const closeSidebarOnMobile = useSidebarMobileClose(closeSidebar);

  useEffect(() => {
    if (isMobileSidebarViewport()) {
      closeSidebar();
    }
    clearBlockingOverlays();
    window.scrollTo(0, 0);
  }, [location.pathname, location.search, location.key, closeSidebar]);

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
        <ReceptionEmployeeSidebar onNavigate={closeSidebarOnMobile} onMenuToggle={toggleSidebar} />
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <ReceptionEmployeeTopBar />
        <main className="flex-1 p-4 md:p-6">
          <Outlet key={`${location.pathname}${location.search}${location.key}`} />
        </main>
      </div>
    </div>
  );
}
