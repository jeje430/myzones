import { SUPER_ADMIN_ROUTES } from "./superAdminConstants";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

const SESSION_KEY = "zones-super-admin-session";
const TOKEN_KEY = "zones-super-admin-token";
export const SUPER_ADMIN_PROFILE_EVENT = "zones-super-admin-profile-updated";

function mapApiUser(json) {
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
    avatar: json.profile_image || "",
    lastLoginAt: json.last_login_at || null,
  };
}

export function getSuperAdminToken() {
  return localStorage.getItem(TOKEN_KEY) || null;
}

export function setSuperAdminSession(profile, token) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  }
  const session = { ...profile, loggedInAt: new Date().toISOString() };
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return session;
}

export function getSuperAdminSession() {
  try {
    const token = getSuperAdminToken();
    const raw = localStorage.getItem(SESSION_KEY);
    if (!token || !raw) return null;
    const parsed = JSON.parse(raw);
    if (!parsed?.email) return null;
    return {
      ...parsed,
      email: normalizeGmailEmail(parsed.email),
    };
  } catch {
    return null;
  }
}

export function clearSuperAdminSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(SESSION_KEY);
}

function authHeaders() {
  const token = getSuperAdminToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export async function registerSuperAdmin({ fullName, email, phone, password }) {
  const trimmedName = String(fullName || "").trim();
  const normalizedEmail = normalizeGmailEmail(email);
  const trimmedPhone = String(phone || "").trim();

  if (!trimmedName) {
    return { ok: false, error: "الاسم الكامل مطلوب." };
  }
  if (!normalizedEmail) {
    return { ok: false, error: "البريد الإلكتروني غير صالح." };
  }
  if (!trimmedPhone) {
    return { ok: false, error: "رقم الهاتف مطلوب." };
  }
  if (!password || password.length < 8) {
    return { ok: false, error: "كلمة المرور يجب أن تكون 8 أحرف على الأقل." };
  }

  try {
    const { data } = await apiClient.post("/super-admin/register", {
      full_name: trimmedName,
      name: trimmedName,
      phone: trimmedPhone,
      email: normalizedEmail,
      password,
      password_confirmation: password,
    });

    const user = mapApiUser(data.user);
    return { ok: true, user };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function loginSuperAdmin({ email, password }) {
  const normalizedEmail = normalizeGmailEmail(email);
  if (!normalizedEmail || !password) {
    return { ok: false, error: "البريد الإلكتروني وكلمة المرور مطلوبان." };
  }

  try {
    const { data } = await apiClient.post("/super-admin/login", {
      email: normalizedEmail,
      password,
    });

    const token = data.token;
    if (!token) {
      return { ok: false, error: "لم يُرجع الخادم رمز الدخول." };
    }

    const user = mapApiUser(data.user);
    if (!user) {
      return { ok: false, error: "استجابة غير متوقعة من الخادم." };
    }

    setSuperAdminSession(user, token);
    return { ok: true, user };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

/** للتوافق مع مسار تسجيل الدخول العام — يستخدم الجلسة المحلية فقط */
export function authenticateSuperAdmin() {
  return getSuperAdminSession();
}

export async function logoutSuperAdmin() {
  const token = getSuperAdminToken();
  if (token) {
    try {
      await apiClient.post("/logout", null, { headers: authHeaders() });
    } catch {
      // ignore — clear local session anyway
    }
  }
  clearSuperAdminSession();
}

export function updateSuperAdminProfile(patch) {
  const current = getSuperAdminSession();
  if (!current) return null;
  const next = { ...current, ...patch };
  const token = getSuperAdminToken();
  if (token) {
    setSuperAdminSession(next, token);
  }
  if (typeof window !== "undefined") {
    window.dispatchEvent(new Event(SUPER_ADMIN_PROFILE_EVENT));
  }
  return next;
}

export async function syncSuperAdminProfileFromApi() {
  const token = getSuperAdminToken();
  if (!token) return null;

  try {
    const { data } = await apiClient.get("/profile", { headers: authHeaders() });
    const user = mapApiUser(data.user);
    if (!user) return null;
    setSuperAdminSession(user, token);
    if (typeof window !== "undefined") {
      window.dispatchEvent(new Event(SUPER_ADMIN_PROFILE_EVENT));
    }
    return user;
  } catch {
    return getSuperAdminSession();
  }
}

export async function updateSuperAdminProfileOnApi(patch) {
  const token = getSuperAdminToken();
  if (!token) {
    return { ok: false, error: "لا توجد جلسة نشطة." };
  }

  try {
    const { data } = await apiClient.put(
      "/profile/update",
      {
        full_name: patch.fullName,
        name: patch.fullName,
        phone: patch.phone,
      },
      { headers: authHeaders() },
    );
    const user = mapApiUser(data.user);
    if (user) {
      setSuperAdminSession(user, token);
      if (typeof window !== "undefined") {
        window.dispatchEvent(new Event(SUPER_ADMIN_PROFILE_EVENT));
      }
    }
    return { ok: true, user };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function changeSuperAdminPassword(currentPassword, newPassword) {
  const token = getSuperAdminToken();
  if (!token) {
    return { ok: false, error: "لا توجد جلسة نشطة." };
  }
  if (!newPassword || newPassword.length < 8) {
    return { ok: false, error: "كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل." };
  }

  try {
    await apiClient.put(
      "/profile/change-password",
      {
        current_password: currentPassword,
        new_password: newPassword,
        new_password_confirmation: newPassword,
      },
      { headers: authHeaders() },
    );
    return { ok: true };
  } catch (error) {
    const message = mapApiErrorMessage(error);
    if (message.includes("incorrect") || message.includes("Current password")) {
      return { ok: false, error: "كلمة المرور الحالية غير صحيحة." };
    }
    return { ok: false, error: message };
  }
}

export async function deleteSuperAdminAccount() {
  const token = getSuperAdminToken();
  if (!token) {
    return { ok: false, error: "لا توجد جلسة نشطة." };
  }

  try {
    await apiClient.delete("/profile/delete", { headers: authHeaders() });
    clearSuperAdminSession();
    return { ok: true };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export function getSuperAdminLoginRedirect() {
  return SUPER_ADMIN_ROUTES.dashboard;
}
