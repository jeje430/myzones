import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { mapStaffApiUser } from "../../../shared/auth/mapStaffApiUser";
import { buildManagerWorkspacePath } from "./accountSessionStorage";
import { setApiManagerSession, clearAuthSession, clearManagerApiToken } from "./mockUsersStorage";
import {
  clearSuperAdminSession,
  setSuperAdminSession,
  getSuperAdminLoginRedirect,
} from "../../super-admin/data/superAdminAuth";

function mapSuperAdminProfile(json) {
  if (!json) return null;
  const fullName = json.full_name || json.name || "";
  return {
    id: json.id,
    fullName,
    email: json.email || "",
    phone: json.phone || "",
    residence: "ليبيا",
    username: fullName.replace(/\s+/g, "_").toLowerCase().slice(0, 24) || `admin_${json.id}`,
    joinDate: json.created_at ? String(json.created_at).slice(0, 10) : new Date().toISOString().slice(0, 10),
    avatar:
      json.profile_image ||
      `https://api.dicebear.com/7.x/initials/svg?seed=${encodeURIComponent(fullName || "admin")}`,
    lastLoginAt: json.last_login_at || null,
  };
}

/**
 * تسجيل دخول موحّد لكل طاقم المنصة (مدير، موظف، سوبر أدمن).
 * يستخدم كلمة المرور المخزّنة في Laravel بعد OTP / إعادة التعيين.
 */
export async function loginStaff({ email, password }) {
  const normalizedEmail = normalizeGmailEmail(email);
  if (!normalizedEmail || !password) {
    return { ok: false, error: "البريد الإلكتروني وكلمة المرور مطلوبان." };
  }

  try {
    const { data } = await apiClient.post("/staff/login", {
      email: normalizedEmail,
      password,
    });

    const token = data.token;
    if (!token) {
      return { ok: false, error: "لم يُرجع الخادم رمز الدخول." };
    }

    const role =
      data.role ||
      (Array.isArray(data.roles) && data.roles.find((r) =>
        ["super_admin", "manager", "reception", "maintenance"].includes(r),
      )) ||
      "manager";

    if (role === "super_admin") {
      const profile = mapSuperAdminProfile(data.user);
      if (!profile) {
        return { ok: false, error: "استجابة غير متوقعة من الخادم." };
      }
      clearAuthSession();
      clearManagerApiToken();
      setSuperAdminSession(profile, token);
      return {
        ok: true,
        role: "super_admin",
        redirectPath: getSuperAdminLoginRedirect(),
        user: profile,
      };
    }

    const staffRole =
      role === "maintenance" ? "maintenance" : role === "reception" ? "reception" : "manager";
    const user = mapStaffApiUser(data.user, staffRole);
    if (!user) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }

    clearSuperAdminSession();
    setApiManagerSession(user, token);
    const redirectPath =
      staffRole === "manager"
        ? buildManagerWorkspacePath(user.id, "dashboard")
        : null;
    return { ok: true, role: staffRole, user, redirectPath };
  } catch (error) {
    const message = mapApiErrorMessage(error);
    if (message.includes("staff accounts only")) {
      return { ok: false, error: "هذا الحساب ليس حساب طاقم (مدير/موظف/أدمن)." };
    }
    if (message.includes("not linked to a station")) {
      return { ok: false, error: "الحساب غير مرتبط بصالة. تواصل مع الإدارة." };
    }
    if (message.includes("disabled") || message.includes("inactive")) {
      return { ok: false, error: "Your account has been disabled." };
    }
    return { ok: false, error: message };
  }
}
