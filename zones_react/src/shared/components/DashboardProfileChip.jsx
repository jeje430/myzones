import { Link } from "react-router-dom";
import { useDashboardProfile } from "../hooks/useDashboardProfile";
import { DASHBOARD_PROFILE_CHIP_CLS } from "./dashboardTopBarUi";
import UserAvatar from "./UserAvatar";

export default function DashboardProfileChip({ roleLabel, superAdmin = false, profileTo }) {
  const profile = useDashboardProfile({ superAdmin });
  const displayName = profile.fullName || roleLabel;
  const avatar = profile.avatar;

  const inner = (
    <>
      <UserAvatar src={avatar} name={displayName} size="sm" rounded="lg" />
      <div className="min-w-0 text-left">
        <p className="truncate text-xs font-extrabold text-gray-900 dark:text-white">{displayName}</p>
        <p className="truncate text-[10px] font-semibold text-[#6B5478] dark:text-[#c4a8d4]">{roleLabel}</p>
      </div>
    </>
  );

  if (profileTo) {
    return (
      <Link
        to={profileTo}
        className={`${DASHBOARD_PROFILE_CHIP_CLS} transition hover:bg-[#6B5478]/18 hover:ring-2 hover:ring-[#6B5478]/25`}
        aria-label="الملف الشخصي"
      >
        {inner}
      </Link>
    );
  }

  return (
    <div className={DASHBOARD_PROFILE_CHIP_CLS} aria-label="الملف الشخصي">
      {inner}
    </div>
  );
}
