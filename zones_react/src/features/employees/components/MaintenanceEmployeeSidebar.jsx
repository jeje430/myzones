import { useState } from "react";
import { NavLink, useLocation, useNavigate } from "react-router-dom";
import {
  Archive,
  ChevronDown,
  ClipboardList,
  Home,
  LogOut,
  User,
} from "lucide-react";
import { zonesConfirm } from "../../../shared/utils/zonesAlerts";
import SidebarBrandHeader from "../../../shared/components/SidebarBrandHeader";
import { clearAuthSession, getAuthSession } from "../../auth/data/mockUsersStorage";
import { EMPLOYEE_LOGIN_PATH } from "../../auth/data/authRoutes";
import { getActiveAccountIdFromUrl } from "../../auth/data/accountSessionStorage";
import { useMaintenanceEmployeeRoutes } from "../data/maintenanceEmployeeRoutes";

const linkClass = ({ isActive }) =>
  `flex items-center justify-between gap-2 rounded-xl px-3 py-2.5 text-[13px] font-bold transition ${
    isActive
      ? "bg-[#6B5478] text-white shadow-sm shadow-[#6B5478]/30"
      : "text-gray-600 hover:bg-[#6B5478]/8 dark:text-gray-300 dark:hover:bg-[#6B5478]/15"
  }`;

function pathMatches(pathname, path) {
  return pathname === path;
}

function groupContainsActive(group, pathname) {
  return group.children.some((c) => c.path && pathMatches(pathname, c.path));
}

export default function MaintenanceEmployeeSidebar({
  pendingCount = 0,
  onNavigate,
  onMenuToggle,
}) {
  const { routes, employeeId } = useMaintenanceEmployeeRoutes();
  const location = useLocation();
  const navigate = useNavigate();
  const pathname = location.pathname;

  const ACCOUNT_GROUP = {
    id: "account",
    label: "حسابي",
    icon: User,
    children: [
      { label: "الملف الشخصي", path: routes.profile },
      { label: "تغيير كلمة المرور", path: routes.changePassword },
      { label: "تسجيل الخروج", action: "logout" },
    ],
  };

  const [accountOpen, setAccountOpen] = useState(() => groupContainsActive(ACCOUNT_GROUP, pathname));

  const handleLogout = async () => {
    const confirmed = await zonesConfirm({
      title: "تسجيل الخروج؟",
      text: "سيتم إنهاء جلستك الحالية والعودة إلى صفحة الدخول.",
      confirmText: "تسجيل الخروج",
      cancelText: "إلغاء",
      danger: true,
    });
    if (!confirmed) return;
    clearAuthSession(employeeId ?? getActiveAccountIdFromUrl() ?? getAuthSession()?.id);
    onNavigate?.();
    navigate(EMPLOYEE_LOGIN_PATH, { replace: true });
  };

  return (
    <aside
      className="relative flex h-full w-64 shrink-0 flex-col overflow-visible border-s border-gray-200 bg-white dark:border-gray-800 dark:bg-gray-900"
      dir="rtl"
    >
      <SidebarBrandHeader subtitle="لوحة الصيانة" onMenuToggle={onMenuToggle} />

      <nav className="flex-1 space-y-1 overflow-y-auto px-3 py-4">
        <NavLink
          to={routes.dashboard}
          end
          onClick={onNavigate}
          className={linkClass}
        >
          <span className="flex items-center gap-2.5">
            <Home size={17} />
            لوحة التحكم
          </span>
        </NavLink>

        <NavLink
          to={routes.faults}
          end
          onClick={onNavigate}
          className={linkClass}
        >
          <span className="flex items-center gap-2.5">
            <ClipboardList size={17} />
            الأعطال
          </span>
          {pendingCount > 0 ? (
            <span className="rounded-full bg-red-500 px-2 py-0.5 text-[10px] font-extrabold text-white">
              {pendingCount}
            </span>
          ) : null}
        </NavLink>

        <NavLink
          to={routes.faultsArchive}
          end
          onClick={onNavigate}
          className={linkClass}
        >
          <span className="flex items-center gap-2.5">
            <Archive size={17} />
            السجل
          </span>
        </NavLink>

        <div>
          <button
            type="button"
            onClick={() => setAccountOpen((open) => !open)}
            className={`flex w-full items-center justify-between gap-2 rounded-xl px-3 py-2.5 text-[13px] font-bold transition ${
              groupContainsActive(ACCOUNT_GROUP, pathname)
                ? "text-[#6B5478]"
                : "text-gray-600 hover:bg-[#6B5478]/8 dark:text-gray-300 dark:hover:bg-[#6B5478]/15"
            }`}
          >
            <span className="flex items-center gap-2.5">
              <User size={17} />
              حسابي
            </span>
            <ChevronDown size={15} className={`transition ${accountOpen ? "rotate-180" : ""}`} />
          </button>
          {accountOpen ? (
            <div className="mt-1 space-y-1 pe-4">
              {ACCOUNT_GROUP.children.map((child) =>
                child.action === "logout" ? (
                  <button
                    key="logout"
                    type="button"
                    onClick={handleLogout}
                    className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-xs font-bold text-red-600 transition hover:bg-red-50 dark:text-red-400 dark:hover:bg-red-950/30"
                  >
                    <LogOut size={14} />
                    {child.label}
                  </button>
                ) : (
                  <NavLink
                    key={child.path}
                    to={child.path}
                    end
                    onClick={onNavigate}
                    className={({ isActive }) =>
                      `flex items-center gap-2 rounded-lg px-3 py-2 text-xs font-bold transition ${
                        isActive
                          ? "bg-[#6B5478]/12 text-[#6B5478]"
                          : "text-gray-500 hover:bg-[#6B5478]/8 dark:text-gray-400"
                      }`
                    }
                  >
                    <span className="h-1.5 w-1.5 rounded-full bg-current opacity-60" />
                    {child.label}
                  </NavLink>
                ),
              )}
            </div>
          ) : null}
        </div>
      </nav>
    </aside>
  );
}
