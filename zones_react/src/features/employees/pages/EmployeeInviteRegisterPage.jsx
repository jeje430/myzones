import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { Eye, EyeOff, Lock, Phone } from "lucide-react";
import AuthLayout from "../../../shared/layouts/AuthLayout";
import {
  completeEmployeeRegistrationApi,
  getEmployeeInvitationByToken,
} from "../data/employeeInvitationsApi";

const readOnlyCls =
  "w-full rounded-xl border border-gray-200 bg-gray-100 px-3 py-2.5 text-xs text-gray-600 dark:border-gray-700 dark:bg-gray-800/60 dark:text-gray-300";

export default function EmployeeInviteRegisterPage() {
  const { token } = useParams();
  const navigate = useNavigate();
  const [invite, setInvite] = useState(null);
  const [loadError, setLoadError] = useState("");
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPass, setShowPass] = useState(false);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      const result = await getEmployeeInvitationByToken(token);
      if (cancelled) return;

      if (!result.ok) {
        setLoadError(result.error || "رابط غير صالح أو منتهي الصلاحية.");
        return;
      }

      if (result.invite.alreadyUsed) {
        setLoadError("تم استخدام هذا الرابط مسبقاً. يمكنك تسجيل الدخول مباشرة.");
        return;
      }

      if (result.invite.expired) {
        setLoadError("انتهت صلاحية الرابط. تواصل مع مدير الصالة.");
        return;
      }

      setInvite(result.invite);
    };

    load();

    return () => {
      cancelled = true;
    };
  }, [token]);

  const submit = async (e) => {
    e.preventDefault();
    setError("");

    if (!phone.trim()) {
      setError("رقم الهاتف مطلوب.");
      return;
    }
    if (!password || password.length < 6) {
      setError("كلمة المرور (6 أحرف على الأقل).");
      return;
    }
    if (password !== confirmPassword) {
      setError("كلمة المرور وتأكيدها غير متطابقين.");
      return;
    }

    setSubmitting(true);
    const result = await completeEmployeeRegistrationApi(token, {
      phone: phone.trim(),
      password,
    });
    setSubmitting(false);

    if (!result.ok) {
      setError(result.error || "تعذر إكمال التسجيل.");
      return;
    }

    navigate("/employee/login", {
      replace: true,
      state: { message: result.message || "تم إنشاء الحساب — سجّل الدخول الآن" },
    });
  };

  if (loadError) {
    return (
      <AuthLayout>
        <div className="mx-auto max-w-md text-center" dir="rtl">
          <p className="mb-4 text-sm text-red-400">{loadError}</p>
          <Link to="/employee/login" className="text-sm font-bold text-[#a855f7]">
            الذهاب لتسجيل الدخول
          </Link>
        </div>
      </AuthLayout>
    );
  }

  if (!invite) {
    return (
      <AuthLayout>
        <div className="text-center text-slate-400" dir="rtl">جاري التحميل...</div>
      </AuthLayout>
    );
  }

  return (
    <AuthLayout>
      <div className="mx-auto w-full max-w-md" dir="rtl">
        <h1 className="mb-1 text-lg font-bold text-white">إكمال تسجيل الموظف</h1>
        <p className="mb-6 text-sm text-slate-400">
          أكمل بياناتك لإنشاء حسابك في ZONES.
        </p>

        <form onSubmit={submit} className="space-y-4">
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400">اسم الموظف</label>
            <input className={readOnlyCls} readOnly value={invite.name} />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400">البريد الإلكتروني</label>
            <input className={readOnlyCls} readOnly dir="ltr" value={invite.email} />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400">الصلاحية</label>
            <input className={readOnlyCls} readOnly value={invite.roleLabel || invite.role} />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400">توقيت الدوام</label>
            <input className={readOnlyCls} readOnly value={invite.shiftLabel || "—"} />
          </div>
          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400">الصالة</label>
            <input className={readOnlyCls} readOnly value={invite.hallName || "—"} />
          </div>

          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400" htmlFor="phone">
              رقم الهاتف
            </label>
            <div className="relative">
              <Phone size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                id="phone"
                className="w-full rounded-xl border border-gray-700 bg-gray-900 py-2.5 pe-3 ps-10 text-xs text-white outline-none focus:border-[#6B5478]"
                dir="ltr"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                required
              />
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400" htmlFor="password">
              كلمة المرور
            </label>
            <div className="relative">
              <Lock size={16} className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500" />
              <input
                id="password"
                type={showPass ? "text" : "password"}
                className="w-full rounded-xl border border-gray-700 bg-gray-900 py-2.5 pe-10 ps-3 text-xs text-white outline-none focus:border-[#6B5478]"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <button
                type="button"
                className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-500"
                onClick={() => setShowPass((v) => !v)}
              >
                {showPass ? <EyeOff size={16} /> : <Eye size={16} />}
              </button>
            </div>
          </div>

          <div>
            <label className="mb-1 block text-xs font-bold text-slate-400" htmlFor="confirm">
              تأكيد كلمة المرور
            </label>
            <input
              id="confirm"
              type={showPass ? "text" : "password"}
              className="w-full rounded-xl border border-gray-700 bg-gray-900 px-3 py-2.5 text-xs text-white outline-none focus:border-[#6B5478]"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              required
            />
          </div>

          {error ? <p className="text-xs font-semibold text-red-400">{error}</p> : null}

          <button
            type="submit"
            disabled={submitting}
            className="w-full rounded-xl bg-[#6B5478] py-3 text-sm font-bold text-white disabled:opacity-60"
          >
            {submitting ? "جاري التسجيل..." : "إنشاء الحساب"}
          </button>
        </form>
      </div>
    </AuthLayout>
  );
}
