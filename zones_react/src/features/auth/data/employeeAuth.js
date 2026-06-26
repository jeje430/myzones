import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { mapStaffApiUser } from "../../../shared/auth/mapStaffApiUser";
import { getLoginRedirectPath, setApiManagerSession } from "./mockUsersStorage";

export async function loginEmployee({ email, password, stationId, role }) {
  const normalizedEmail = normalizeGmailEmail(email);
  if (!normalizedEmail || !password) {
    return { ok: false, error: "البريد الإلكتروني وكلمة المرور مطلوبان." };
  }
  if (!stationId) {
    return { ok: false, error: "اختر الصالة." };
  }
  if (!role || (role !== "reception" && role !== "maintenance")) {
    return { ok: false, error: "اختر صلاحية الموظف." };
  }

  try {
    const { data } = await apiClient.post("/employee/login", {
      email: normalizedEmail,
      password,
      station_id: Number(stationId),
      role,
    });

    const token = data.token;
    if (!token) {
      return { ok: false, error: "لم يُرجع الخادم رمز الدخول." };
    }

    const user = mapStaffApiUser(data.user, role);

    if (!user) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }

    if (!user.hallId) {
      return { ok: false, error: "حساب الموظف غير مرتبط بصالة." };
    }

    if (String(user.hallId) !== String(stationId)) {
      return { ok: false, error: "الصالة المختارة لا تطابق حسابك." };
    }

    setApiManagerSession(user, token);
    return {
      ok: true,
      user,
      token,
      role,
      redirectPath: getLoginRedirectPath(role, user.id),
    };
  } catch (error) {
    const message = mapApiErrorMessage(error);
    if (message.includes("employee accounts only")) {
      return { ok: false, error: "هذا الحساب ليس حساب موظف." };
    }
    if (message.includes("not linked to a station")) {
      return { ok: false, error: "حساب الموظف غير مرتبط بصالة." };
    }
    if (message.includes("does not belong to this station")) {
      return { ok: false, error: "الصالة المختارة لا تطابق حسابك." };
    }
    if (message.includes("role does not match")) {
      return { ok: false, error: "الصلاحية المختارة لا تطابق حسابك." };
    }
    if (message.includes("disabled") || message.includes("inactive")) {
      return { ok: false, error: "Your account has been disabled." };
    }
    return { ok: false, error: message };
  }
}
