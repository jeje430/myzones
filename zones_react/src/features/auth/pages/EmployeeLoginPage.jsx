import { useEffect, useMemo, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { Input, PasswordInput } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select } from "@/components/ui/select";
import AuthLayout from "../../../shared/layouts/AuthLayout";
import AuthMessage from "../components/AuthMessage";
import { EMPLOYEE_LOGIN_PATH, MANAGER_LOGIN_PATH } from "../data/authRoutes";
import { getLoginRedirectPath, setAuthSession } from "../data/mockUsersStorage";
import { loginEmployee } from "../data/employeeAuth";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";
import { clearSuperAdminSession } from "../../super-admin/data/superAdminAuth";
import { attemptLogin, LOGIN_BLOCK_MESSAGES } from "../data/accountAccess";
import { fetchLoungesCatalog } from "../../customer/data/loungeCatalogApi";
import { getSuperAdminState } from "../../super-admin/data/superAdminStorage";
import { ROLES, normalizeRole } from "../../employees/data/employeeMeta";

function loadLocalHallOptions() {
  const halls = getSuperAdminState().activeHalls || [];
  return halls
    .filter((hall) => hall.status === "active")
    .map((hall) => ({
      value: String(hall.id),
      label: hall.name || hall.hallName || `صالة ${hall.id}`,
    }));
}

export default function EmployeeLoginPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [hallId, setHallId] = useState("");
  const [employeeRole, setEmployeeRole] = useState("");
  const [hallOptions, setHallOptions] = useState([]);
  const [hallsLoading, setHallsLoading] = useState(true);
  const [error, setError] = useState("");
  const [info, setInfo] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const roleOptions = useMemo(
    () => ROLES.map((item) => ({ value: item.value, label: item.label })),
    [],
  );

  useEffect(() => {
    let cancelled = false;

    const loadHalls = async () => {
      setHallsLoading(true);
      const result = await fetchLoungesCatalog();
      if (cancelled) return;

      const apiOptions = result.ok
        ? result.lounges.map((lounge) => ({
            value: lounge.id,
            label: lounge.name || lounge.hallName,
          }))
        : [];

      const merged = apiOptions.length > 0 ? apiOptions : loadLocalHallOptions();
      setHallOptions(merged);
      setHallsLoading(false);
    };

    loadHalls();

    return () => {
      cancelled = true;
    };
  }, []);

  useEffect(() => {
    const state = location.state;
    if (state?.registeredEmail) {
      setEmail(state.registeredEmail);
    }
    if (state?.loginError) {
      setError(state.loginError);
    } else if (state?.message) {
      setInfo(state.message);
    }
  }, [location.state]);

  const submit = async (e) => {
    e.preventDefault();
    setError("");
    setInfo("");

    if (!hallId) {
      setError("اختر الصالة.");
      return;
    }
    if (!employeeRole) {
      setError("اختر صلاحية الموظف.");
      return;
    }

    setSubmitting(true);

    const normalizedEmail = normalizeGmailEmail(email);
    const apiResult = await loginEmployee({
      email: normalizedEmail,
      password,
      stationId: hallId,
      role: employeeRole,
    });

    if (apiResult.ok) {
      const from = location.state?.from;
      const fallback =
        apiResult.redirectPath || getLoginRedirectPath(apiResult.role, apiResult.user?.id);
      const target =
        typeof from === "string" && from.startsWith("/employee/") && !from.startsWith("/auth")
          ? from
          : fallback;
      setSubmitting(false);
      navigate(target, { replace: true });
      return;
    }

    const isEmployeeOnlyError = apiResult.error?.includes("ليس حساب موظف");
    const isInvalidCredentials =
      apiResult.error?.includes("غير صحيحة") || apiResult.error?.includes("Invalid credentials");

    if (!isEmployeeOnlyError && apiResult.error && !isInvalidCredentials) {
      setSubmitting(false);
      setError(apiResult.error);
      return;
    }

    const mockResult = attemptLogin(normalizedEmail, password);
    setSubmitting(false);

    if (!mockResult.ok) {
      setError(
        isInvalidCredentials && apiResult.error
          ? apiResult.error
          : LOGIN_BLOCK_MESSAGES[mockResult.code] || LOGIN_BLOCK_MESSAGES.invalid,
      );
      return;
    }

    const role = normalizeRole(mockResult.user.role);
    if (role !== "reception" && role !== "maintenance") {
      setError("هذا الحساب ليس حساب موظف. استخدم صفحة دخول المدير.");
      return;
    }

    if (String(mockResult.user.hallId ?? "") !== String(hallId)) {
      setError("الصالة المختارة لا تطابق حسابك.");
      return;
    }

    if (role !== employeeRole) {
      setError("الصلاحية المختارة لا تطابق حسابك.");
      return;
    }

    clearSuperAdminSession();
    setAuthSession(mockResult.user);
    const from = location.state?.from;
    const fallback = getLoginRedirectPath(role, mockResult.user.id);
    const target =
      typeof from === "string" && from.startsWith("/employee/") && !from.startsWith("/auth")
        ? from
        : fallback;
    navigate(target, { replace: true });
  };

  return (
    <AuthLayout
      centered
      title="دخول الموظفين"
      subtitle="اختر صالتك وصلاحيتك ثم سجّل الدخول"
    >
      <form className="mx-auto w-full max-w-sm space-y-5" onSubmit={submit}>
        {info ? <AuthMessage tone="info">{info}</AuthMessage> : null}
        {error ? <AuthMessage tone="error">{error}</AuthMessage> : null}

        <div className="space-y-2">
          <Label htmlFor="employee-login-email" className="text-[11px] text-gray-500 dark:text-gray-400">
            البريد الإلكتروني
          </Label>
          <Input
            id="employee-login-email"
            type="email"
            dir="ltr"
            placeholder="example@gmail.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="h-11 bg-gray-50 dark:bg-gray-800/80"
            required
          />
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between gap-2">
            <Label
              htmlFor="employee-login-password"
              className="text-[11px] text-gray-500 dark:text-gray-400"
            >
              كلمة المرور
            </Label>
            <Link
              className="text-[11px] font-semibold text-[#6B5478] transition hover:text-[#5a4668] hover:underline"
              to="/auth/forgot-password"
              state={{ returnTo: EMPLOYEE_LOGIN_PATH }}
            >
              نسيت كلمة المرور؟
            </Link>
          </div>
          <PasswordInput
            id="employee-login-password"
            value={password}
            onChange={setPassword}
            inputClassName="h-11 bg-gray-50 dark:bg-gray-800/80"
            required
          />
        </div>

        <div className="space-y-2">
          <Label className="text-[11px] text-gray-500 dark:text-gray-400">الصالة</Label>
          <Select
            value={hallId}
            onValueChange={setHallId}
            options={hallOptions}
            placeholder={hallsLoading ? "جاري تحميل الصالات..." : "اختر الصالة"}
            disabled={hallsLoading || hallOptions.length === 0}
            triggerClassName="h-11 bg-gray-50 dark:bg-gray-800/80"
          />
          {!hallsLoading && hallOptions.length === 0 ? (
            <p className="text-[11px] text-amber-600 dark:text-amber-400">
              لا توجد صالات متاحة حالياً.
            </p>
          ) : null}
        </div>

        <div className="space-y-2">
          <Label className="text-[11px] text-gray-500 dark:text-gray-400">صلاحية الموظف</Label>
          <Select
            value={employeeRole}
            onValueChange={setEmployeeRole}
            options={roleOptions}
            placeholder="اختر الصلاحية"
            triggerClassName="h-11 bg-gray-50 dark:bg-gray-800/80"
          />
        </div>

        <Button
          type="submit"
          size="lg"
          className="h-11 w-full text-sm"
          disabled={submitting || hallsLoading}
        >
          {submitting ? "جاري الدخول..." : "تسجيل الدخول"}
        </Button>

        <p className="text-center text-[11px] text-gray-500 dark:text-gray-400">
          مدير صالة؟{" "}
          <Link to={MANAGER_LOGIN_PATH} className="font-bold text-[#6B5478] hover:underline">
            دخول المدير
          </Link>
        </p>
      </form>
    </AuthLayout>
  );
}
