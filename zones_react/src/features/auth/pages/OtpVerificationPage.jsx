import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import AuthLayout from "../../../shared/layouts/AuthLayout";
import AuthMessage from "../components/AuthMessage";
import OtpInput from "../components/OtpInput";
import { sendPasswordResetCode } from "../data/passwordResetApi";

export default function OtpVerificationPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const email = location.state?.email || "";
  const [code, setCode] = useState("");
  const [error, setError] = useState("");
  const [info, setInfo] = useState(location.state?.message || "");
  const [submitting, setSubmitting] = useState(false);
  const [resending, setResending] = useState(false);

  useEffect(() => {
    if (!email) {
      navigate("/auth/forgot-password", { replace: true });
    }
  }, [email, navigate]);

  const verify = () => {
    setError("");
    if (code.length !== 6) {
      setError("أدخل الرمز المكوّن من 6 أرقام.");
      return;
    }

    navigate("/auth/reset-password", {
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
    <AuthLayout
      centered
      title="تحقق من بريدك الإلكتروني"
      subtitle={`لقد أرسلنا رمز تحقق من 6 أرقام إلى ${email}`}
      backLink={
        <Link
          to="/auth/forgot-password"
          className="text-xs font-semibold text-[#6B5478] hover:underline"
        >
          تغيير البريد
        </Link>
      }
    >
      <div className="mx-auto w-full max-w-sm space-y-5">
        {info ? <AuthMessage tone="info">{info}</AuthMessage> : null}
        {error ? <AuthMessage tone="error">{error}</AuthMessage> : null}

        <div className="space-y-3">
          <p className="text-center text-[11px] font-semibold text-gray-500 dark:text-gray-400">
            أدخل الرمز المرسل إلى Gmail
          </p>
          <OtpInput
            value={code}
            onChange={setCode}
            disabled={submitting}
            onComplete={() => setError("")}
          />
        </div>

        <Button
          type="button"
          size="lg"
          className="h-11 w-full text-sm"
          disabled={submitting || code.length !== 6}
          onClick={verify}
        >
          تحقق من الرمز
        </Button>

        <p className="text-center text-[11px] text-gray-500 dark:text-gray-400">
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
      </div>
    </AuthLayout>
  );
}
