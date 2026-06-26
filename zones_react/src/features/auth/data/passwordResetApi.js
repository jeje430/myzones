import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";

export async function sendPasswordResetCode(email) {
  const normalizedEmail = normalizeGmailEmail(email);
  if (!normalizedEmail) {
    return { ok: false, error: "البريد الإلكتروني مطلوب." };
  }

  try {
    const { data } = await apiClient.post("/forgot-password", { email: normalizedEmail });
    return {
      ok: true,
      message: data.message || "تم إرسال رمز التحقق إلى بريدك الإلكتروني.",
      email: normalizedEmail,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function resetPasswordWithCode({ email, code, password }) {
  const normalizedEmail = normalizeGmailEmail(email);
  const trimmedCode = String(code || "").trim();

  if (!normalizedEmail || !trimmedCode || !password) {
    return { ok: false, error: "يرجى تعبئة جميع الحقول." };
  }

  try {
    const { data } = await apiClient.post("/reset-password", {
      email: normalizedEmail,
      code: trimmedCode,
      password,
      password_confirmation: password,
    });
    return { ok: true, message: data.message || "تم تغيير كلمة المرور بنجاح." };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
