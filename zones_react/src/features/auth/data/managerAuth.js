import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { mapStaffApiUser } from "../../../shared/auth/mapStaffApiUser";
import { getLoginRedirectPath, setApiManagerSession, clearManagerApiToken } from "./mockUsersStorage";

export async function loginManager({ email, password, stationId }) {
  const normalizedEmail = normalizeGmailEmail(email);
  if (!normalizedEmail || !password) {
    return { ok: false, error: "البريد الإلكتروني وكلمة المرور مطلوبان." };
  }
  if (!stationId) {
    return { ok: false, error: "اختر الصالة التي تتبع لها." };
  }

  try {
    const { data } = await apiClient.post("/manager/login", {
      email: normalizedEmail,
      password,
      station_id: Number(stationId),
    });

    const token = data.token;
    if (!token) {
      return { ok: false, error: "لم يُرجع الخادم رمز الدخول." };
    }

    const user = mapStaffApiUser(data.user, "manager");
    if (!user) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }

    if (String(user.hallId) !== String(stationId)) {
      return { ok: false, error: "الصالة المختارة لا تطابق حسابك." };
    }

    setApiManagerSession(user, token);
    return {
      ok: true,
      user,
      token,
      redirectPath: getLoginRedirectPath("manager", user.id),
    };
  } catch (error) {
    const message = mapApiErrorMessage(error);
    if (message.includes("manager accounts only")) {
      return { ok: false, error: "هذا الحساب ليس حساب مدير." };
    }
    if (message.includes("not linked to a station")) {
      return { ok: false, error: "حساب المدير غير مرتبط بصالة. أكمل التسجيل أو تواصل مع الإدارة." };
    }
    if (message.includes("does not belong to this station")) {
      return { ok: false, error: "الصالة المختارة لا تطابق حسابك." };
    }
    if (message.includes("disabled") || message.includes("inactive")) {
      return { ok: false, error: "Your account has been disabled." };
    }
    return { ok: false, error: message };
  }
}

export async function logoutManager() {
  const token = localStorage.getItem("zones-manager-token");
  if (token) {
    try {
      await apiClient.post("/logout", null, {
        headers: { Authorization: `Bearer ${token}` },
      });
    } catch {
      /* ignore */
    }
  }
  clearManagerApiToken();
}
