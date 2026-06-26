import { useState } from "react";
import { Link, Navigate, useNavigate } from "react-router-dom";
import { Shield } from "lucide-react";
import ThemeToggle from "../../../shared/components/ThemeToggle";
import { Input } from "../../../components/ui/input";
import {
  getSuperAdminSession,
  registerSuperAdmin,
} from "../data/superAdminAuth";
import { SUPER_ADMIN_ROUTES } from "../data/superAdminConstants";

export default function SuperAdminRegisterPage() {
  const navigate = useNavigate();
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  if (getSuperAdminSession()) {
    return <Navigate to={SUPER_ADMIN_ROUTES.dashboard} replace />;
  }

  const submit = async (e) => {
    e.preventDefault();
    setError("");

    if (password !== confirmPassword) {
      setError("تأكيد كلمة المرور غير متطابق.");
      return;
    }

    setLoading(true);
    const result = await registerSuperAdmin({ fullName, email, phone, password });
    setLoading(false);

    if (!result.ok) {
      setError(result.error);
      return;
    }

    navigate(SUPER_ADMIN_ROUTES.login, {
      replace: true,
      state: {
        registeredEmail: result.user.email,
        message: "تم إنشاء حساب الأدمن العام بنجاح. يمكنك تسجيل الدخول الآن.",
      },
    });
  };

  return (
    <div
      className="relative flex min-h-screen items-center justify-center bg-gradient-to-br from-gray-100 via-white to-[#6B5478]/10 p-4 dark:from-gray-950 dark:via-gray-900 dark:to-[#6B5478]/20"
      style={{ fontFamily: "Cairo, 'Segoe UI', Tahoma, sans-serif" }}
      dir="rtl"
    >
      <div className="absolute start-4 top-4">
        <ThemeToggle compact />
      </div>
      <div className="w-full max-w-md rounded-3xl border border-gray-200 bg-white p-8 shadow-2xl dark:border-gray-700 dark:bg-gray-900">
        <div className="mb-6 text-center">
          <Shield size={28} className="mx-auto mb-3 text-[#6B5478]" />
          <h1 className="text-lg font-extrabold text-gray-900 dark:text-white">تسجيل حساب الأدمن العام</h1>
          <p className="mt-1 text-xs text-gray-500">إنشاء حساب جديد لإدارة منصة ZONES</p>
        </div>
        <form onSubmit={submit} className="space-y-4">
          {error ? (
            <div className="rounded-xl border border-red-300 bg-red-50 px-3 py-2 text-xs font-bold text-red-700 dark:border-red-800 dark:bg-red-950 dark:text-red-300">
              {error}
            </div>
          ) : null}
          <div>
            <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">الاسم الكامل</label>
            <Input
              type="text"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="الاسم الكامل"
              required
              className="font-semibold dark:border-gray-600"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">البريد الإلكتروني</label>
            <Input
              type="email"
              dir="ltr"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="superadmin@gmail.com"
              required
              className="font-semibold dark:border-gray-600"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">رقم الهاتف</label>
            <Input
              type="tel"
              dir="ltr"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+218 91 234 5678"
              required
              className="font-semibold dark:border-gray-600"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">كلمة المرور</label>
            <Input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={8}
              className="font-semibold dark:border-gray-600"
            />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-gray-600 dark:text-gray-300">تأكيد كلمة المرور</label>
            <Input
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="••••••••"
              required
              minLength={8}
              className="font-semibold dark:border-gray-600"
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-xl bg-[#6B5478] py-3 text-sm font-extrabold text-white shadow-lg shadow-[#6B5478]/30 transition hover:bg-[#5a4668] disabled:opacity-60"
          >
            {loading ? "جاري إنشاء الحساب..." : "إنشاء الحساب"}
          </button>
        </form>
        <p className="mt-4 text-center text-xs text-gray-500">
          لديك حساب بالفعل؟{" "}
          <Link
            to={SUPER_ADMIN_ROUTES.login}
            className="font-bold text-[#6B5478] transition hover:text-[#5a4668] hover:underline"
          >
            تسجيل الدخول
          </Link>
        </p>
      </div>
    </div>
  );
}
