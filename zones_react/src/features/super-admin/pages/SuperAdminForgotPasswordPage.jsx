import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Mail } from "lucide-react";
import { Input } from "@/components/ui/input";
import SuperAdminAuthShell from "../components/SuperAdminAuthShell";
import { sendPasswordResetCode } from "../../auth/data/passwordResetApi";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { SUPER_ADMIN_ROUTES } from "../data/superAdminConstants";

function Alert({ tone, children }) {
  return (
    <div
      className={
        tone === "error"
          ? "rounded-xl border border-red-300 bg-red-50 px-3 py-2 text-xs font-bold text-red-700 dark:border-red-800 dark:bg-red-950 dark:text-red-300"
          : "rounded-xl border border-[#6B5478]/25 bg-[#6B5478]/10 px-3 py-2 text-xs font-bold text-[#6B5478] dark:border-[#6B5478]/35 dark:bg-[#6B5478]/15 dark:text-[#d4c4de]"
      }
    >
      {children}
    </div>
  );
}

export default function SuperAdminForgotPasswordPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const submit = async (event) => {
    event.preventDefault();
    setError("");

    const normalizedEmail = normalizeGmailEmail(email);
    if (!normalizedEmail) {
      setError("أدخل بريدك الإلكتروني.");
      return;
    }

    setSubmitting(true);
    const result = await sendPasswordResetCode(normalizedEmail);
    setSubmitting(false);

    if (!result.ok) {
      setError(result.error || "تعذر إرسال رمز التحقق.");
      return;
    }

    navigate(SUPER_ADMIN_ROUTES.otp, {
      replace: true,
      state: {
        email: result.email || normalizedEmail,
        message: result.message,
      },
    });
  };

  return (
    <SuperAdminAuthShell
      title="استرجاع كلمة المرور"
      subtitle="أدخل بريد الأدمن العام وسنرسل رمز تحقق من 6 أرقام إلى Gmail"
    >
      <form onSubmit={submit} className="space-y-4">
        {error ? <Alert tone="error">{error}</Alert> : null}

        <div>
          <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">
            البريد الإلكتروني
          </label>
          <div className="relative">
            <Mail
              size={16}
              className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <Input
              type="email"
              dir="ltr"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="superadmin@gmail.com"
              required
              className="pr-10 font-semibold dark:border-gray-600"
            />
          </div>
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-[#6B5478] py-3 text-sm font-extrabold text-white shadow-lg shadow-[#6B5478]/30 transition hover:bg-[#5a4668] disabled:opacity-60"
        >
          {submitting ? "جاري الإرسال..." : "إرسال رمز التحقق"}
        </button>

        <p className="text-center text-xs text-gray-500">
          <Link
            to={SUPER_ADMIN_ROUTES.login}
            className="font-bold text-[#6B5478] hover:underline"
          >
            العودة لتسجيل الدخول
          </Link>
        </p>
      </form>
    </SuperAdminAuthShell>
  );
}
