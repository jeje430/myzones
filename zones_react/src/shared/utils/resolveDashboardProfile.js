import { getAuthSession, getUserById } from "../../features/auth/data/mockUsersStorage";
import { getSuperAdminSession } from "../../features/super-admin/data/superAdminAuth";

/** اسم وصورة الشريط العلوي — من حساب المستخدم فقط */
export function resolveDashboardProfile(_sessionInput, { superAdmin = false } = {}) {
  if (superAdmin) {
    const admin = getSuperAdminSession();
    return {
      fullName: admin?.fullName?.trim() || "مدير النظام",
      avatar: admin?.avatar?.trim() || "",
    };
  }

  const session = getAuthSession();
  if (!session?.id) {
    return { fullName: "", avatar: "" };
  }

  const user = getUserById(session.id);
  if (user) {
    return {
      fullName: user.fullName?.trim() || "",
      avatar: user.avatar?.trim() || "",
    };
  }

  return {
    fullName: session.fullName?.trim() || "",
    avatar: session.avatar?.trim() || "",
  };
}

export function resolveDashboardAvatar(options) {
  return resolveDashboardProfile(null, options).avatar;
}
