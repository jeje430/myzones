import DashboardProfileChip from "./DashboardProfileChip";
import DashboardTopBarActions from "./DashboardTopBarActions";
import NotificationCenterBell from "../../features/alerts/components/NotificationCenterBell";
import { useDashboardProfile } from "../hooks/useDashboardProfile";
import { getManagerRoutes } from "../config/managerNavigation";
import { getActiveAccountIdFromUrl } from "../../features/auth/data/accountSessionStorage";

export default function ManagerTopBar() {
  const profile = useDashboardProfile();
  const managerId = getActiveAccountIdFromUrl() || profile.id;
  const profilePath = getManagerRoutes(managerId).profile;

  return (
    <header
      className="sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-gray-200 bg-white/95 px-4 py-2.5 backdrop-blur supports-[backdrop-filter]:bg-white/80 dark:border-gray-800 dark:bg-gray-900/95 dark:supports-[backdrop-filter]:bg-gray-900/80"
      dir="rtl"
    >
      <p className="hidden text-xs font-bold text-gray-500 sm:block dark:text-gray-400">
        مرحباً، {profile.fullName || "مدير الصالة"}
      </p>

      <DashboardTopBarActions
        profile={<DashboardProfileChip roleLabel="مدير صالة" profileTo={profilePath} />}
        notifications={<NotificationCenterBell mode="staff" audience="manager" />}
      />
    </header>
  );
}
