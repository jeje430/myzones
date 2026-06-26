import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Input } from "@/components/ui/input";
import SuperAdminAuthShell from "../components/SuperAdminAuthShell";
import { resetPasswordWithCode } from "../../auth/data/passwordResetApi";
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

export default function SuperAdminResetPasswordPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";
  const code = location.state?.code || "";
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!email || !code) {
      navigate(SUPER_ADMIN_ROUTES.forgotPassword, { replace: true });
    }
  }, [email, code, navigate]);

  const submit = async (event) => {
    event.preventDefault();
    setError("");

    if (password.length < 6) {
      setError("كلمة المرور يجب أن تكون 6 أحرف على الأقل.");
      return;
    }
    if (password !== confirmPassword) {
      setError("كلمة المرور وتأكيدها غير متطابقين.");
      return;
    }

    setSubmitting(true);
    const result = await resetPasswordWithCode({ email, code, password });
    setSubmitting(false);

    if (!result.ok) {
      setError(result.error || "تعذر تغيير كلمة المرور.");
      return;
    }

    navigate(SUPER_ADMIN_ROUTES.login, {
      replace: true,
      state: {
        registeredEmail: email,
        message: result.message || "تم تغيير كلمة المرور. سجّل الدخول الآن.",
      },
    });
  };

  if (!email || !code) return null;

  return (
    <SuperAdminAuthShell
      title="إعادة تعيين كلمة المرور"
      subtitle="أنشئ كلمة مرور جديدة لحساب الأدمن العام"
    >
      <form onSubmit={submit} className="space-y-4">
        {error ? <Alert tone="error">{error}</Alert> : null}

        <div>
          <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">
            كلمة المرور الجديدة
          </label>
          <Input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="••••••••"
            required
            minLength={6}
            className="font-semibold dark:border-gray-600"
          />
        </div>

        <div>
          <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">
            تأكيد كلمة المرور
          </label>
          <Input
            type="password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            placeholder="••••••••"
            required
            minLength={6}
            className="font-semibold dark:border-gray-600"
          />
        </div>

        <button
          type="submit"
          disabled={submitting}
          className="w-full rounded-xl bg-[#6B5478] py-3 text-sm font-extrabold text-white shadow-lg shadow-[#6B5478]/30 transition hover:bg-[#5a4668] disabled:opacity-60"
        >
          {submitting ? "جاري الحفظ..." : "حفظ كلمة المرور"}
        </button>

        <p className="text-center text-xs text-gray-500">
          <Link to={SUPER_ADMIN_ROUTES.login} className="font-bold text-[#6B5478] hover:underline">
            العودة لتسجيل الدخول
          </Link>
        </p>
      </form>
    </SuperAdminAuthShell>
  );
}
