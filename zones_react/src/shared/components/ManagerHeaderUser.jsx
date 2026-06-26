import { useDashboardProfile } from "../hooks/useDashboardProfile";
import UserAvatar from "./UserAvatar";

export default function ManagerHeaderUser() {
  const profile = useDashboardProfile();

  return (
    <div className="manager-header-user">
      <span className="manager-header-user__name">{profile.fullName || "مدير الصالة"}</span>
      <UserAvatar
        src={profile.avatar}
        name={profile.fullName}
        size="sm"
        className="manager-header-user__avatar"
        ring={false}
      />
    </div>
  );
}
