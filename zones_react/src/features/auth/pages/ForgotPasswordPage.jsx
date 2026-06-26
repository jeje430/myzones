import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Mail } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import AuthLayout from "../../../shared/layouts/AuthLayout";
import AuthMessage from "../components/AuthMessage";
import { sendPasswordResetCode } from "../data/passwordResetApi";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";

export default function ForgotPasswordPage() {
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

    navigate("/auth/otp", {
      replace: true,
      state: {
        email: result.email || normalizedEmail,
        message: result.message,
      },
    });
  };

  return (
    <AuthLayout
      centered
      title="استرجاع كلمة المرور"
      subtitle="أدخل بريدك الإلكتروني وسنرسل لك رمز تحقق من 6 أرقام"
      backLink={
        <a
          href="/manager/login"
          className="text-xs font-semibold text-[#6B5478] hover:underline"
        >
          العودة لتسجيل الدخول
        </a>
      }
    >
      <form className="mx-auto w-full max-w-sm space-y-5" onSubmit={submit}>
        {error ? <AuthMessage tone="error">{error}</AuthMessage> : null}

        <div className="space-y-2">
          <Label htmlFor="forgot-email" className="text-[11px] text-gray-500 dark:text-gray-400">
            البريد الإلكتروني
          </Label>
          <div className="relative">
            <Mail
              size={18}
              className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-gray-400"
            />
            <Input
              id="forgot-email"
              type="email"
              dir="ltr"
              placeholder="example@gmail.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="h-11 bg-gray-50 pr-10 dark:bg-gray-800/80"
              required
            />
          </div>
        </div>

        <Button type="submit" size="lg" className="h-11 w-full text-sm" disabled={submitting}>
          {submitting ? "جاري الإرسال..." : "إرسال رمز التحقق"}
        </Button>
      </form>
    </AuthLayout>
  );
}
