import DashboardProfileChip from "../../../shared/components/DashboardProfileChip";
import DashboardTopBarActions from "../../../shared/components/DashboardTopBarActions";
import { useDashboardProfile } from "../../../shared/hooks/useDashboardProfile";
import { useReceptionEmployeeRoutes } from "../data/receptionEmployeeRoutes";
import HallNotificationsBell from "./HallNotificationsBell";

export default function ReceptionEmployeeTopBar() {
  const profile = useDashboardProfile();
  const { routes } = useReceptionEmployeeRoutes();

  return (
    <header
      className="sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-gray-200 bg-white/95 px-4 py-2.5 backdrop-blur supports-[backdrop-filter]:bg-white/80 dark:border-gray-800 dark:bg-gray-900/95 dark:supports-[backdrop-filter]:bg-gray-900/80"
      dir="rtl"
    >
      <p className="hidden text-xs font-bold text-gray-500 sm:block dark:text-gray-400">
        مرحباً، {profile.fullName || "موظف الاستقبال"}
      </p>

      <DashboardTopBarActions
        profile={<DashboardProfileChip roleLabel="استقبال" profileTo={routes.profile} />}
        notifications={<HallNotificationsBell audience="reception" />}
      />
    </header>
  );
}
