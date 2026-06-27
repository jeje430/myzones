import { Link } from "react-router-dom";
import { AlertTriangle } from "lucide-react";
import DashboardProfileChip from "../../../shared/components/DashboardProfileChip";
import DashboardTopBarActions from "../../../shared/components/DashboardTopBarActions";
import { isMaintenanceModeEnabled } from "../data/maintenanceModeData";
import { SUPER_ADMIN_ROUTES } from "../data/superAdminConstants";
import SuperAdminNotificationsDropdown from "./SuperAdminNotificationsDropdown";

export default function SuperAdminTopBar({ session }) {
  const maintenanceActive = isMaintenanceModeEnabled();

  return (
    <header
      className="sticky top-0 z-30 flex items-center justify-between gap-3 border-b border-gray-200 bg-white/95 px-4 py-2.5 backdrop-blur supports-[backdrop-filter]:bg-white/80 dark:border-gray-800 dark:bg-gray-900/95 dark:supports-[backdrop-filter]:bg-gray-900/80"
      dir="rtl"
    >
      <p className="hidden text-xs font-bold text-gray-500 sm:block dark:text-gray-400">
        مرحباً، {session?.fullName || "مدير النظام"}
      </p>

      <DashboardTopBarActions
        profile={<DashboardProfileChip superAdmin roleLabel="مدير النظام" />}
        notifications={
          <>
            {maintenanceActive ? (
              <Link
                to={SUPER_ADMIN_ROUTES.settings}
                className="hidden items-center gap-1.5 rounded-full bg-amber-500/15 px-3 py-1.5 text-[10px] font-extrabold text-amber-700 transition hover:bg-amber-500/20 dark:text-amber-400 sm:inline-flex"
                title="وضع الصيانة مفعّل"
              >
                <AlertTriangle size={13} />
                وضع الصيانة
              </Link>
            ) : null}
            <SuperAdminNotificationsDropdown />
          </>
        }
      />
    </header>
  );
}
