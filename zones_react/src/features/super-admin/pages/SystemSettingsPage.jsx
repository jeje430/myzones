import { useEffect, useMemo, useRef, useState } from "react";
import {
  DatabaseBackup,
  FolderOpen,
  Globe,
  Loader2,
  Save,
  Sparkles,
  Upload,
  Wrench,
} from "lucide-react";
import { zonesConfirm, zonesSwal, zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import ToggleSwitch from "../components/ui/ToggleSwitch";
import PageHeader from "../components/ui/PageHeader";
import {
  getSuperAdminState,
  runDatabaseBackup,
  updateSystemSettings,
} from "../data/superAdminStorage";
import {
  activateMaintenanceMode,
  countActiveBookingsToday,
  deactivateMaintenanceMode,
} from "../data/maintenanceModeData";
import { ZONES_LOGO_SRC } from "../data/superAdminDashboardData";
import { Input } from "../../../components/ui/input";
import {
  DEFAULT_MINIMUM_POINTS_REQUIRED,
  DEFAULT_POINTS_PER_SESSION,
} from "../../loyalty/data/loyaltyPointsStorage";
import {
  calculateEstimatedSessions,
  fetchLoyaltySettings,
  updateLoyaltySettings,
} from "../../loyalty/data/loyaltySettingsApi";

const labelClass = "mb-2 block text-right text-[11px] font-extrabold text-gray-600 dark:text-gray-300";
const helperClass = "mt-1.5 text-[10px] font-semibold leading-relaxed text-gray-500 dark:text-gray-400";

function Card({ title, icon: Icon, children, className = "" }) {
  return (
    <div
      className={`rounded-2xl border border-gray-200 bg-white p-5 shadow-sm dark:border-gray-800 dark:bg-gray-900 ${className}`}
    >
      <h2 className="mb-5 flex items-center justify-end gap-2 text-sm font-extrabold text-gray-900 dark:text-white">
        {title}
        <Icon size={16} className="text-[#6B5478]" />
      </h2>
      {children}
    </div>
  );
}

function syncLoyaltyToLocalStorage({ pointsPerCompletedSession, minimumPointsRequired }) {
  updateSystemSettings({
    loyaltyPointsPerSession: pointsPerCompletedSession,
    loyaltyMinimumPointsRequired: minimumPointsRequired,
    loyaltyRedemptionThreshold: minimumPointsRequired,
  });
}

export default function SystemSettingsPage() {
  const [form, setForm] = useState(getSuperAdminState().systemSettings);
  const [backingUp, setBackingUp] = useState(false);
  const [loyaltyLoading, setLoyaltyLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const fileRef = useRef(null);

  useEffect(() => {
    const refresh = () => setForm(getSuperAdminState().systemSettings);
    window.addEventListener("super-admin-data-updated", refresh);
    return () => window.removeEventListener("super-admin-data-updated", refresh);
  }, []);

  useEffect(() => {
    let cancelled = false;

    (async () => {
      setLoyaltyLoading(true);
      const result = await fetchLoyaltySettings();
      if (cancelled) return;

      if (result.ok) {
        const { pointsPerCompletedSession, minimumPointsRequired } = result.settings;
        syncLoyaltyToLocalStorage({ pointsPerCompletedSession, minimumPointsRequired });
        setForm((current) => ({
          ...current,
          loyaltyPointsPerSession: pointsPerCompletedSession,
          loyaltyMinimumPointsRequired: minimumPointsRequired,
          loyaltyRedemptionThreshold: minimumPointsRequired,
        }));
      }

      setLoyaltyLoading(false);
    })();

    return () => {
      cancelled = true;
    };
  }, []);

  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }));

  const onLogoPick = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      if (typeof reader.result === "string") set("platformLogo", reader.result);
    };
    reader.readAsDataURL(file);
  };

  const onMaintenanceToggle = async (next) => {
    if (next) {
      const activeCount = countActiveBookingsToday();
      const result = await zonesSwal({
        icon: "warning",
        title: "تفعيل وضع الصيانة؟",
        html: `<div style="text-align:right;line-height:2;font-size:13px">
          <p>يوجد <strong>${activeCount}</strong> حجوزات نشطة اليوم.</p>
          <p>الحجوزات السابقة <strong>لن تُحذف</strong> وتبقى محفوظة في النظام.</p>
          <p>سيتم قفل الزبائن وموظفي الاستقبال. الأدمن فقط يبقى وصوله كاملاً.</p>
          <p style="margin-top:8px">هل تريد إرسال إشعار للزبائن المتأثرين؟</p>
        </div>`,
        showCancelButton: true,
        showDenyButton: true,
        confirmButtonText: "تفعيل مع إشعار",
        denyButtonText: "تفعيل بدون إشعار",
        cancelButtonText: "إلغاء",
      });

      if (result.isConfirmed) {
        const res = activateMaintenanceMode({ notifyCustomers: true });
        setForm(getSuperAdminState().systemSettings);
        zonesToastSuccess(
          res.notifiedCount > 0
            ? `تم تفعيل وضع الصيانة وإشعار ${res.notifiedCount} زبون`
            : "تم تفعيل وضع الصيانة (لا توجد حجوزات تطبيق لإشعارها)",
        );
      } else if (result.isDenied) {
        activateMaintenanceMode({ notifyCustomers: false });
        setForm(getSuperAdminState().systemSettings);
        zonesToastSuccess("تم تفعيل وضع الصيانة");
      }
      return;
    }

    const ok = await zonesConfirm({
      title: "إيقاف وضع الصيانة؟",
      text: "سيعود النظام للعمل الطبيعي لجميع المستخدمين.",
      confirmText: "نعم، إيقاف",
    });
    if (!ok) return;
    deactivateMaintenanceMode();
    setForm(getSuperAdminState().systemSettings);
    zonesToastSuccess("تم إيقاف وضع الصيانة");
  };

  const setLoyaltyInt = (key, raw, fallback) => {
    let v = Number.parseInt(String(raw), 10);
    if (!Number.isFinite(v) || v < 1) v = fallback;
    setForm((f) => ({
      ...f,
      [key]: v,
      ...(key === "loyaltyMinimumPointsRequired" ? { loyaltyRedemptionThreshold: v } : {}),
    }));
  };

  const pointsPerSession = form.loyaltyPointsPerSession ?? DEFAULT_POINTS_PER_SESSION;
  const minimumPointsRequired =
    form.loyaltyMinimumPointsRequired ??
    form.loyaltyRedemptionThreshold ??
    DEFAULT_MINIMUM_POINTS_REQUIRED;

  const estimatedSessions = useMemo(
    () => calculateEstimatedSessions(pointsPerSession, minimumPointsRequired),
    [pointsPerSession, minimumPointsRequired],
  );

  const save = async () => {
    if (!pointsPerSession || pointsPerSession < 1) {
      zonesToastError("نقاط كل جلسة يجب أن تكون 1 على الأقل.");
      return;
    }
    if (!minimumPointsRequired || minimumPointsRequired < 1) {
      zonesToastError("الحد الأدنى للمكافآت يجب أن يكون 1 على الأقل.");
      return;
    }

    setSaving(true);

    const loyaltyResult = await updateLoyaltySettings({
      pointsPerCompletedSession: pointsPerSession,
      minimumPointsRequired,
    });

    if (!loyaltyResult.ok) {
      setSaving(false);
      zonesToastError(loyaltyResult.error || "تعذّر حفظ إعدادات نقاط الولاء.");
      return;
    }

    syncLoyaltyToLocalStorage({
      pointsPerCompletedSession: loyaltyResult.settings.pointsPerCompletedSession,
      minimumPointsRequired: loyaltyResult.settings.minimumPointsRequired,
    });

    const { loyaltyPointsPerSession, loyaltyMinimumPointsRequired, loyaltyRedemptionThreshold, ...rest } =
      form;
    updateSystemSettings({
      ...rest,
      loyaltyPointsPerSession: loyaltyResult.settings.pointsPerCompletedSession,
      loyaltyMinimumPointsRequired: loyaltyResult.settings.minimumPointsRequired,
      loyaltyRedemptionThreshold: loyaltyResult.settings.minimumPointsRequired,
    });

    setForm(getSuperAdminState().systemSettings);
    setSaving(false);
    zonesToastSuccess("تم حفظ التغييرات");
  };

  const backup = async () => {
    setBackingUp(true);
    const res = await runDatabaseBackup();
    setBackingUp(false);
    setForm(getSuperAdminState().systemSettings);
    zonesSwal({
      icon: "success",
      title: "اكتمل النسخ الاحتياطي",
      text: new Date(res.at).toLocaleString("ar-LY"),
    });
  };

  const logoSrc = form.platformLogo || ZONES_LOGO_SRC;

  return (
    <div className="text-right" style={{ fontFamily: "Cairo, Tajawal, sans-serif" }}>
      <PageHeader title="إعدادات النظام" />

      <form
        onSubmit={(e) => {
          e.preventDefault();
          save();
        }}
      >
        <Card title="الإعدادات العامة" icon={Globe} className="mb-4">
          <div className="grid gap-6 lg:grid-cols-10 lg:items-stretch">
            <div className="grid gap-4 sm:grid-cols-2 lg:col-span-7">
              <div>
                <label className={labelClass}>اسم المنصة</label>
                <Input
                  className="text-right"
                  value={form.platformName}
                  onChange={(e) => set("platformName", e.target.value)}
                />
              </div>
              <div>
                <label className={labelClass}>البريد الإلكتروني للأدمن</label>
                <Input
                  dir="ltr"
                  className="text-left"
                  type="email"
                  value={form.adminEmail}
                  onChange={(e) => set("adminEmail", e.target.value)}
                />
              </div>
              <div>
                <label className={labelClass}>رابط المنصة</label>
                <Input
                  dir="ltr"
                  className="text-left"
                  value={form.platformUrl}
                  onChange={(e) => set("platformUrl", e.target.value)}
                />
              </div>
              <div>
                <label className={labelClass}>العملة</label>
                <Input
                  className="text-right"
                  value={form.currency || "د.ل"}
                  onChange={(e) => set("currency", e.target.value)}
                />
              </div>
            </div>

            <div className="flex flex-col items-center justify-center rounded-2xl border border-gray-200 bg-gray-50/90 p-5 dark:border-gray-700 dark:bg-gray-800/50 lg:col-span-3">
              <p className={labelClass}>شعار المنصة</p>
              <div className="flex h-28 w-28 items-center justify-center overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-900">
                <img src={logoSrc} alt="شعار المنصة" className="h-full w-full object-contain p-2" />
              </div>
              <input
                ref={fileRef}
                type="file"
                accept="image/png,image/jpeg,image/svg+xml"
                onChange={onLogoPick}
                className="hidden"
              />
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                className="mt-4 flex items-center gap-2 rounded-xl border border-[#6B5478]/30 bg-[#6B5478]/10 px-4 py-2 text-xs font-bold text-[#6B5478] transition hover:bg-[#6B5478]/15"
              >
                <Upload size={14} /> تحديث الصورة
              </button>
            </div>
          </div>
        </Card>

        <div className="mb-4 grid gap-4 lg:grid-cols-2">
          <Card title="النسخ الاحتياطي" icon={DatabaseBackup}>
            <div className="flex min-h-[168px] flex-col justify-between">
              <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">
                آخر نسخة:
                <span className="mt-1 block font-extrabold text-gray-800 dark:text-gray-100" dir="ltr">
                  {form.lastBackupAt ? new Date(form.lastBackupAt).toLocaleString("ar-LY") : "لا يوجد"}
                </span>
              </p>
              <button
                type="button"
                onClick={backup}
                disabled={backingUp}
                className="mt-4 flex w-full items-center justify-center gap-2 rounded-xl bg-[#6B5478] py-3 text-xs font-extrabold text-white shadow-sm transition hover:bg-[#5a4665] disabled:opacity-60"
              >
                {backingUp ? <Loader2 size={15} className="animate-spin" /> : <FolderOpen size={15} />}
                {backingUp ? "جاري النسخ..." : "إنشاء نسخة احتياطية الآن"}
              </button>
            </div>
          </Card>

          <Card title="وضع الصيانة" icon={Wrench}>
            <div className="flex min-h-[168px] flex-col items-end justify-between">
              <div className="w-full text-right">
                <p className={labelClass}>حالة النظام</p>
                <span
                  className={`inline-block rounded-full px-3 py-1 text-[11px] font-bold ${
                    form.maintenanceMode
                      ? "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
                      : "bg-gray-200 text-gray-600 dark:bg-gray-800 dark:text-gray-400"
                  }`}
                >
                  {form.maintenanceMode ? "مفعّل" : "غير مفعل"}
                </span>
              </div>
              <div className="flex w-full items-center justify-between gap-3 rounded-xl border border-gray-200 bg-gray-50/80 px-4 py-3 dark:border-gray-700 dark:bg-gray-800/40">
                <ToggleSwitch checked={form.maintenanceMode} onChange={onMaintenanceToggle} />
                <p className="text-xs font-extrabold text-gray-900 dark:text-white">تفعيل وضع الصيانة</p>
              </div>
            </div>
          </Card>
        </div>

        <Card
          title="نظام نقاط الولاء"
          icon={Sparkles}
          className="border-[#6B5478]/25 bg-gradient-to-br from-white via-white to-[#6B5478]/5 shadow-[0_0_24px_rgba(107,84,120,0.08)] dark:from-gray-900 dark:via-gray-900 dark:to-[#6B5478]/10 dark:shadow-[0_0_32px_rgba(107,84,120,0.15)]"
        >
          {loyaltyLoading ? (
            <div className="flex min-h-[180px] items-center justify-center gap-2 text-sm font-bold text-[#6B5478]">
              <Loader2 size={18} className="animate-spin" />
              جاري تحميل إعدادات الولاء...
            </div>
          ) : (
            <div className="grid gap-5 lg:grid-cols-3">
              <div>
                <label className={labelClass}>نقاط لكل جلسة مكتملة</label>
                <Input
                  type="number"
                  min={1}
                  step={1}
                  dir="ltr"
                  className="border-[#6B5478]/20 bg-white/80 text-left focus-visible:ring-[#6B5478]/40 dark:bg-gray-950/60"
                  value={pointsPerSession}
                  onChange={(e) =>
                    setLoyaltyInt("loyaltyPointsPerSession", e.target.value, DEFAULT_POINTS_PER_SESSION)
                  }
                />
                <p className={helperClass}>يكسب الزبائن نقاط ولاء تلقائياً بعد إتمام الجلسات.</p>
              </div>

              <div>
                <label className={labelClass}>الحد الأدنى للمكافآت</label>
                <Input
                  type="number"
                  min={1}
                  step={1}
                  dir="ltr"
                  className="border-[#6B5478]/20 bg-white/80 text-left focus-visible:ring-[#6B5478]/40 dark:bg-gray-950/60"
                  value={minimumPointsRequired}
                  onChange={(e) =>
                    setLoyaltyInt(
                      "loyaltyMinimumPointsRequired",
                      e.target.value,
                      DEFAULT_MINIMUM_POINTS_REQUIRED,
                    )
                  }
                />
                <p className={helperClass}>تصبح المكافآت متاحة بعد الوصول إلى الحد الأدنى المطلوب من النقاط.</p>
              </div>

              <div>
                <label className={labelClass}>الجلسات التقديرية المطلوبة</label>
                <div
                  className="flex h-10 items-center justify-end rounded-xl border border-[#6B5478]/30 bg-[#6B5478]/10 px-4 text-sm font-extrabold text-[#6B5478] shadow-[inset_0_0_12px_rgba(107,84,120,0.08)] dark:bg-[#6B5478]/15 dark:text-[#c4a8d4]"
                  aria-live="polite"
                >
                  {estimatedSessions} جلسة
                </div>
                <p className={helperClass}>
                  يُحسب تلقائياً: {minimumPointsRequired} ÷ {pointsPerSession} = {estimatedSessions} جلسة
                </p>
              </div>
            </div>
          )}
        </Card>

        <div className="mt-6 flex justify-center">
          <button
            type="submit"
            disabled={saving || loyaltyLoading}
            className="flex items-center gap-2 rounded-xl bg-[#6B5478] px-10 py-3 text-xs font-extrabold text-white shadow-sm transition hover:bg-[#5a4665] disabled:opacity-60"
          >
            {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
            {saving ? "جاري الحفظ..." : "حفظ التغييرات"}
          </button>
        </div>
      </form>
    </div>
  );
}
