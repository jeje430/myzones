import axios from "axios";
import { API_BASE_URL } from "../config/apiConfig";

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
  timeout: 20000,
});

/** Multipart upload — strips JSON Content-Type so the browser sets the boundary. */
export async function postMultipart(path, formData) {
  return apiClient.post(path, formData, {
    transformRequest: [
      (data, headers) => {
        if (data instanceof FormData) {
          delete headers["Content-Type"];
        }
        return data;
      },
    ],
  });
}

export function mapApiErrorMessage(error) {
  const response = error?.response;
  const body = response?.data;

  const sanitize = (message) => {
    if (typeof message !== "string" || !message.trim()) {
      return "حدث خطأ من الخادم، حاول مرة أخرى.";
    }
    if (
      message.length > 300 ||
      message.includes("data:image") ||
      message.includes("iVBORw0KGgo") ||
      message.includes("SQLSTATE")
    ) {
      if (message.includes("cover_image") || message.includes("Data too long")) {
        return "تعذر حفظ بيانات الصالة بسبب حجم الصور. حاول مجدداً.";
      }
      if (message.includes("Connection could not be established") || message.includes("mail")) {
        return "تعذر إرسال البريد. تحقق من إعدادات Gmail في الخادم.";
      }
      return "حدث خطأ من الخادم، حاول مرة أخرى.";
    }
    return message;
  };

  if (body?.message && typeof body.message === "string") {
    const message = body.message;
    if (message.includes("deleted")) {
      return "تم حذف هذا الحساب. يرجى إنشاء حساب جديد.";
    }
    if (message.includes("super admin accounts only")) {
      return "هذا الحساب ليس حساب أدمن عام.";
    }
    if (message.includes("staff accounts only")) {
      return "هذا الحساب ليس حساب طاقم (مدير/موظف/أدمن).";
    }
    if (message.includes("not linked to a station")) {
      return "الحساب غير مرتبط بصالة. تواصل مع الإدارة.";
    }
    if (message.includes("رمز التحقق")) {
      return message;
    }
    if (message.includes("لا يوجد حساب")) {
      return message;
    }
    if (message.includes("customer accounts only")) {
      return "هذا الحساب ليس حساب زبون.";
    }
    return sanitize(message);
  }

  const errors = body?.errors;
  if (errors && typeof errors === "object") {
    if (errors.email?.[0]) {
      const emailError = errors.email[0];
      if (emailError.includes("taken") || emailError.includes("unique")) {
        return "هذا البريد الإلكتروني مسجّل مسبقاً.";
      }
      if (emailError.includes("Invalid credentials")) {
        return "البريد الإلكتروني أو كلمة المرور غير صحيحة.";
      }
      return emailError;
    }
    if (errors.phone?.[0]) {
      const phoneError = errors.phone[0];
      if (phoneError.includes("taken") || phoneError.includes("unique")) {
        return "رقم الهاتف مسجّل مسبقاً.";
      }
      return phoneError;
    }
    if (errors.cover_image?.[0]) {
      return "تعذر رفع الصورة. استخدم JPG أو PNG أو WebP بحجم أقل من 5 ميجابايت.";
    }
    if (errors.avatar?.[0]) {
      const avatarError = errors.avatar[0];
      if (avatarError.includes("max")) {
        return "حجم الصورة يجب ألا يتجاوز 5 ميجابايت.";
      }
      if (avatarError.includes("mimes") || avatarError.includes("image")) {
        return "نوع الصورة غير مدعوم. استخدم JPG أو PNG أو WebP.";
      }
      return avatarError;
    }
    const firstKey = Object.keys(errors)[0];
    if (firstKey && Array.isArray(errors[firstKey]) && errors[firstKey][0]) {
      return errors[firstKey][0];
    }
  }

  if (response?.status === 401 || response?.status === 422) {
    return "البريد الإلكتروني أو كلمة المرور غير صحيحة.";
  }

  if (!response) {
    return "تعذر الاتصال بالخادم. تأكد أن Laravel يعمل وأن عنوان API صحيح.";
  }

  const requestUrl = String(error?.config?.url || "");
  if (requestUrl.includes("/manager/station/reset")) {
    return sanitize(body?.message) || "تعذر مسح بيانات الصالة. حاول مرة أخرى.";
  }

  return sanitize(body?.message) || "حدث خطأ من الخادم، حاول مرة أخرى.";
}
