import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import SuperAdminAuthShell from "../components/SuperAdminAuthShell";
import OtpInput from "../../auth/components/OtpInput";
import { sendPasswordResetCode } from "../../auth/data/passwordResetApi";
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

export default function SuperAdminOtpPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [info, setInfo] = useState(location.state?.message || "");
  const [resending, setResending] = useState(false);

  useEffect(() => {
    if (!email) {
      navigate(SUPER_ADMIN_ROUTES.forgotPassword, { replace: true });
    }
  }, [email, navigate]);

  const verify = () => {
    setError("");
    if (code.length !== 6) {
      setError("أدخل الرمز المكوّن من 6 أرقام.");
      return;
    }

    navigate(SUPER_ADMIN_ROUTES.resetPassword, {
      replace: true,
      state: { email, code },
    });
  };

  const resend = async () => {
    if (!email) return;
    setError("");
    setInfo("");
    setResending(true);
    const result = await sendPasswordResetCode(email);
    setResending(false);

    if (!result.ok) {
      setError(result.error || "تعذر إعادة إرسال الرمز.");
      return;
    }

    setInfo("تم إرسال رمز جديد إلى بريدك الإلكتروني.");
    setCode("");
  };

  if (!email) return null;

  return (
    <SuperAdminAuthShell
      title="تحقق من بريدك الإلكتروني"
      subtitle={`أدخل الرمز المرسل إلى ${email}`}
    >
      <div className="space-y-4">
        {info ? <Alert tone="info">{info}</Alert> : null}
        {error ? <Alert tone="error">{error}</Alert> : null}

        <p className="text-center text-[11px] font-semibold text-gray-500 dark:text-gray-400">
          رمز التحقق من 6 أرقام — تحقق من Gmail
        </p>

        <OtpInput value={code} onChange={setCode} onComplete={() => setError("")} />

        <button
          type="button"
          disabled={code.length !== 6}
          onClick={verify}
          className="w-full rounded-xl bg-[#6B5478] py-3 text-sm font-extrabold text-white shadow-lg shadow-[#6B5478]/30 transition hover:bg-[#5a4668] disabled:opacity-60"
        >
          تحقق من الرمز
        </button>

        <p className="text-center text-xs text-gray-500">
          لم يصلك الرمز؟{" "}
          <button
            type="button"
            onClick={resend}
            disabled={resending}
            className="font-bold text-[#6B5478] hover:underline disabled:opacity-60"
          >
            {resending ? "جاري الإرسال..." : "أعد الإرسال"}
          </button>
        </p>

        <p className="text-center text-xs text-gray-500">
          <Link to={SUPER_ADMIN_ROUTES.forgotPassword} className="font-bold text-[#6B5478] hover:underline">
            تغيير البريد
          </Link>
        </p>
      </div>
    </SuperAdminAuthShell>
  );
}
