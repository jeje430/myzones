import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { PasswordInput } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import AuthLayout from "../../../shared/layouts/AuthLayout";
import AuthMessage from "../components/AuthMessage";
import { resetPasswordWithCode } from "../data/passwordResetApi";

export default function ResetPasswordPage() {
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
      navigate("/auth/forgot-password", { replace: true });
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

    navigate("/manager/login", {
      replace: true,
      state: {
        registeredEmail: email,
        message: result.message || "تم تغيير كلمة المرور. سجّل الدخول الآن.",
      },
    });
  };

  if (!email || !code) return null;

  return (
    <AuthLayout
      centered
      title="إعادة تعيين كلمة المرور"
      subtitle="قم بإنشاء كلمة مرور جديدة وآمنة لحسابك"
      backLink={
        <Link
          to="/manager/login"
          className="text-xs font-semibold text-[#6B5478] hover:underline"
        >
          العودة لتسجيل الدخول
        </Link>
      }
    >
      <form className="mx-auto w-full max-w-sm space-y-5" onSubmit={submit}>
        {error ? <AuthMessage tone="error">{error}</AuthMessage> : null}

        <div className="space-y-2">
          <Label htmlFor="new-password" className="text-[11px] text-gray-500 dark:text-gray-400">
            كلمة المرور الجديدة
          </Label>
          <PasswordInput
            id="new-password"
            value={password}
            onChange={setPassword}
            inputClassName="h-11 bg-gray-50 dark:bg-gray-800/80"
            required
          />
        </div>

        <div className="space-y-2">
          <Label
            htmlFor="confirm-new-password"
            className="text-[11px] text-gray-500 dark:text-gray-400"
          >
            تأكيد كلمة المرور الجديدة
          </Label>
          <PasswordInput
            id="confirm-new-password"
            value={confirmPassword}
            onChange={setConfirmPassword}
            inputClassName="h-11 bg-gray-50 dark:bg-gray-800/80"
            required
          />
        </div>

        <Button type="submit" size="lg" className="h-11 w-full text-sm" disabled={submitting}>
          {submitting ? "جاري الحفظ..." : "حفظ كلمة المرور"}
        </Button>
      </form>
    </AuthLayout>
  );
}
