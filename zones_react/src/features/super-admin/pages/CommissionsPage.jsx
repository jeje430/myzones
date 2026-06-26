import { useEffect, useMemo, useState } from "react";
import { BarChart3, Loader2, Percent, Save, Smartphone } from "lucide-react";
import { zonesToastError, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import KpiCard from "../components/ui/KpiCard";
import PageHeader from "../components/ui/PageHeader";
import {
  fetchPlatformCommissionSettings,
  fetchPlatformCommissionSummary,
  updatePlatformCommissionSettings,
} from "../data/commissionSettingsApi";
import { Input } from "../../../components/ui/input";

const MAX_COMMISSION_RATE = 100;

export default function CommissionsPage() {
  const now = new Date();
  const [year] = useState(now.getFullYear());
  const [month] = useState(now.getMonth() + 1);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [editing, setEditing] = useState(false);
  const [rate, setRate] = useState(0);
  const [draftRate, setDraftRate] = useState(0);
  const [summary, setSummary] = useState({
    totalCommissions: 0,
    totalAppGrossRevenue: 0,
    totalAppBookings: 0,
  });

  const monthLabel = useMemo(
    () => now.toLocaleDateString("ar-LY", { month: "long", year: "numeric" }),
    [now],
  );

  const load = async () => {
    setLoading(true);
    const [settingsResult, summaryResult] = await Promise.all([
      fetchPlatformCommissionSettings(),
      fetchPlatformCommissionSummary(year, month),
    ]);

    if (settingsResult.ok) {
      setRate(settingsResult.rate);
      setDraftRate(settingsResult.rate);
    }

    if (summaryResult.ok && summaryResult.summary) {
      setSummary(summaryResult.summary);
      if (settingsResult.ok) {
        setRate(summaryResult.summary.globalRate || settingsResult.rate);
      }
    }

    setLoading(false);
  };

  useEffect(() => {
    load();
  }, [year, month]);

  const clampRate = (raw) => {
    let value = Number(raw);
    if (Number.isNaN(value)) value = 0;
    if (value < 0) value = 0;
    if (value > MAX_COMMISSION_RATE) value = MAX_COMMISSION_RATE;
    return Math.round(value * 100) / 100;
  };

  const onSave = async () => {
    const nextRate = clampRate(draftRate);
    setSaving(true);
    const result = await updatePlatformCommissionSettings(nextRate);
    setSaving(false);

    if (!result.ok) {
      zonesToastError(result.error || "تعذّر حفظ نسبة العمولة.");
      return;
    }

    setRate(result.rate);
    setDraftRate(result.rate);
    setEditing(false);
    zonesToastSuccess("تم تحديث عمولة المنصة لجميع الصالات.");
    await load();
  };

  return (
    <div>
      <PageHeader title="المالية والعمولات" />

      <div className="grid gap-4 sm:grid-cols-3">
        <KpiCard
          label="إجمالي عمولات المنصة"
          value={`${summary.totalCommissions.toLocaleString("ar-LY")} د.ل`}
          icon={Percent}
          tone="amber"
        />
        <KpiCard
          label="إيرادات تطبيق الزبون (إجمالي)"
          value={`${summary.totalAppGrossRevenue.toLocaleString("ar-LY")} د.ل`}
          icon={Smartphone}
          tone="green"
        />
        <KpiCard
          label="حجوزات التطبيق هذا الشهر"
          value={String(summary.totalAppBookings)}
          icon={BarChart3}
        />
      </div>

      <section className="mt-6 rounded-2xl border border-gray-200 bg-white p-6 shadow-sm dark:border-gray-800 dark:bg-gray-900">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h2 className="text-base font-extrabold text-gray-900 dark:text-white">عمولة المنصة الموحّدة</h2>
            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
              نسبة واحدة تُطبَّق تلقائياً على جميع الصالات — الحالية والمستقبلية — لحجوزات تطبيق الزبون فقط.
            </p>
            <p className="mt-2 text-[11px] font-semibold text-[#6B5478]">{monthLabel}</p>
          </div>
          {!editing ? (
            <button
              type="button"
              onClick={() => {
                setDraftRate(rate);
                setEditing(true);
              }}
              className="rounded-xl border border-[#6B5478]/30 bg-[#6B5478]/10 px-4 py-2 text-xs font-bold text-[#6B5478] transition hover:bg-[#6B5478]/15"
            >
              تعديل
            </button>
          ) : null}
        </div>

        {loading ? (
          <div className="mt-8 flex items-center justify-center gap-2 py-10 text-sm font-bold text-[#6B5478]">
            <Loader2 size={18} className="animate-spin" />
            جاري التحميل...
          </div>
        ) : (
          <div className="mt-6 flex flex-col items-center justify-center rounded-2xl border border-dashed border-[#6B5478]/35 bg-gradient-to-br from-[#6B5478]/5 via-transparent to-cyan-500/5 px-6 py-10 text-center dark:from-[#6B5478]/10 dark:to-cyan-500/10">
            {!editing ? (
              <>
                <p className="text-sm font-bold text-gray-500 dark:text-gray-400">عمولة المنصة الحالية</p>
                <p className="mt-3 text-5xl font-black tracking-tight text-[#6B5478]">{rate}%</p>
                <p className="mt-3 max-w-md text-xs leading-relaxed text-gray-500 dark:text-gray-400">
                  تُحتسب على الحجوزات القادمة من تطبيق Flutter (الدفع الإلكتروني أو الدفع عند الوصول)، ولا تُطبَّق على
                  الحجوزات اليدوية من الاستقبال.
                </p>
              </>
            ) : (
              <div className="w-full max-w-xs">
                <label className="mb-2 block text-right text-[11px] font-extrabold text-gray-600 dark:text-gray-300">
                  نسبة العمولة %
                </label>
                <div className="relative">
                  <Input
                    type="number"
                    min={0}
                    max={MAX_COMMISSION_RATE}
                    step={0.5}
                    dir="ltr"
                    className="text-center text-2xl font-black"
                    value={draftRate}
                    onChange={(e) => setDraftRate(clampRate(e.target.value))}
                  />
                  <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm font-extrabold text-gray-400">
                    %
                  </span>
                </div>
                <div className="mt-5 flex justify-center gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setDraftRate(rate);
                      setEditing(false);
                    }}
                    className="rounded-xl border border-gray-200 px-4 py-2 text-xs font-bold text-gray-600 dark:border-gray-700 dark:text-gray-300"
                  >
                    إلغاء
                  </button>
                  <button
                    type="button"
                    disabled={saving}
                    onClick={onSave}
                    className="inline-flex items-center gap-2 rounded-xl bg-[#6B5478] px-5 py-2 text-xs font-extrabold text-white transition hover:bg-[#5a4665] disabled:opacity-60"
                  >
                    {saving ? <Loader2 size={14} className="animate-spin" /> : <Save size={14} />}
                    حفظ
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
