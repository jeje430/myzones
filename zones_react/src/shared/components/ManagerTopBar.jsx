import { Menu } from "lucide-react";
import DashboardProfileChip from "./DashboardProfileChip";
import DashboardTopBarActions from "./DashboardTopBarActions";
import NotificationCenterBell from "../../features/alerts/components/NotificationCenterBell";
import { DASHBOARD_ICON_BTN_CLS } from "./dashboardTopBarUi";
import { useDashboardProfile } from "../hooks/useDashboardProfile";
import { getManagerRoutes } from "../config/managerNavigation";
import { getActiveAccountIdFromUrl } from "../../features/auth/data/accountSessionStorage";

export default function ManagerTopBar({ onMenuClick }) {
  const profile = useDashboardProfile();
  const managerId = getActiveAccountIdFromUrl() || profile.id;
  const profilePath = getManagerRoutes(managerId).profile;

  return (
    <header
      className="sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-gray-200 bg-white px-4 py-2.5 dark:border-gray-800 dark:bg-gray-900"
      dir="rtl"
    >
      <div className="flex items-center gap-3">
        <button
          type="button"
          className={`${DASHBOARD_ICON_BTN_CLS} lg:hidden`}
          onClick={onMenuClick}
          aria-label="فتح القائمة"
        >
          <Menu size={18} />
        </button>
        <p className="hidden text-xs font-bold text-gray-500 sm:block dark:text-gray-400">
          مرحباً، {profile.fullName || "مدير الصالة"}
        </p>
      </div>

      <DashboardTopBarActions
        profile={<DashboardProfileChip roleLabel="مدير صالة" profileTo={profilePath} />}
        notifications={<NotificationCenterBell mode="staff" audience="manager" />}
      />
    </header>
  );
}
