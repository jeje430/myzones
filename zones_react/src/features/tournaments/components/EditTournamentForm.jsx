import { useEffect, useState } from "react";
import Button from "../../super-admin/components/ui/Button";
import { tournamentToForm, updateManagerTournament } from "../data/managerTournamentsApi";
import { validateRegistrationDeadline } from "../utils/tournamentDeadlineValidation";
import {
  COVER_ASPECT,
  COVER_MAX_FILE_BYTES,
  COVER_OUTPUT_WIDTH,
  processTournamentCoverFile,
} from "../utils/tournamentCoverImage";

const labelCls = "mb-1.5 block text-[11px] font-bold text-gray-500 dark:text-gray-400";
const inputCls =
  "w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-xs text-gray-800 outline-none focus:border-[#6B5478] focus:ring-2 focus:ring-[#6B5478]/20 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100";
const fieldWrap = "rounded-xl border border-gray-100 bg-gray-50/80 p-3 dark:border-gray-800 dark:bg-gray-800/40";
const formGrid4 = "grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4";

export default function EditTournamentForm({
  tournament,
  onSaved,
  onCancel,
  showCancel = true,
  submitLabel = "حفظ التغييرات",
  readOnly = false,
}) {
  const [form, setForm] = useState(null);
  const [coverBusy, setCoverBusy] = useState(false);
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!tournament) return;
    setForm(tournamentToForm(tournament));
    setError("");
    setCoverBusy(false);
    setSaving(false);
  }, [tournament]);

  if (!tournament || !form) return null;

  const set = (key, value) => setForm((f) => ({ ...f, [key]: value }));

  const handleCoverFile = async (e) => {
    if (readOnly) return;
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    setError("");
    if (file.size > COVER_MAX_FILE_BYTES) {
      setError("الملف كبير جداً (الحد الأقصى تقريباً 12 ميجابايت).");
      return;
    }
    setCoverBusy(true);
    try {
      const url = await processTournamentCoverFile(file);
      set("coverDataUrl", url);
    } catch {
      setError("تعذر قراءة الصورة. جرّب ملفاً آخر (JPG أو PNG).");
    } finally {
      setCoverBusy(false);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (readOnly) return;
    const deadlineError = validateRegistrationDeadline(form);
    if (deadlineError) {
      setError(deadlineError);
      return;
    }
    if (!form.rules?.trim()) {
      setError("قوانين البطولة مطلوبة.");
      return;
    }
    setSaving(true);
    setError("");
    const result = await updateManagerTournament(tournament.id, form);
    setSaving(false);
    if (!result.ok) {
      setError(result.error || "تعذر تحديث البطولة.");
      return;
    }
    onSaved?.(result.tournament);
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4" dir="rtl">
      <fieldset disabled={readOnly} className="m-0 space-y-4 border-0 p-0">
      <div className={formGrid4}>
        <div className={fieldWrap}>
          <label className={labelCls}>اسم البطولة *</label>
          <input className={inputCls} required value={form.name} onChange={(e) => set("name", e.target.value)} />
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>اللعبة *</label>
          <input className={inputCls} required value={form.game} onChange={(e) => set("game", e.target.value)} />
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>عدد المشاركين *</label>
          <select className={inputCls} required value={form.participants} onChange={(e) => set("participants", e.target.value)}>
            <option value="8">8 مشاركين</option>
            <option value="16">16 مشارك</option>
          </select>
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>الجائزة</label>
          <input className={inputCls} value={form.prize} onChange={(e) => set("prize", e.target.value)} />
        </div>
      </div>

      <div className={formGrid4}>
        <div className={fieldWrap}>
          <label className={labelCls}>تاريخ البداية *</label>
          <input type="date" className={inputCls} required value={form.startDate} onChange={(e) => set("startDate", e.target.value)} />
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>تاريخ النهاية *</label>
          <input type="date" className={inputCls} required value={form.endDate} onChange={(e) => set("endDate", e.target.value)} />
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>في حالة التأخير *</label>
          <input type="number" min={0} className={inputCls} required value={form.delayMinutes} onChange={(e) => set("delayMinutes", e.target.value)} />
        </div>
        <div className={fieldWrap}>
          <label className={labelCls}>في حالة الانسحاب *</label>
          <input className={inputCls} required value={form.withdrawal} onChange={(e) => set("withdrawal", e.target.value)} />
        </div>
      </div>

      <div className={fieldWrap}>
        <label className={labelCls}>تاريخ انتهاء مهلة المشاركة *</label>
        <input
          type="datetime-local"
          className={inputCls}
          required
          value={form.registrationDeadline}
          onChange={(e) => set("registrationDeadline", e.target.value)}
        />
      </div>

      <div className={fieldWrap}>
        <label className={labelCls}>قوانين البطولة *</label>
        <textarea
          className={`${inputCls} min-h-[120px] resize-y leading-relaxed`}
          required
          value={form.rules}
          onChange={(e) => set("rules", e.target.value)}
          placeholder="• اكتب كل قانون في سطر منفصل"
        />
      </div>

      <div className={fieldWrap}>
        <label className={labelCls}>صورة الغلاف</label>
        {!readOnly ? (
          <>
            <p className="mb-3 text-[10px] text-gray-400">
              نسبة {COVER_ASPECT === 16 / 9 ? "16:9" : COVER_ASPECT.toFixed(2)} — {COVER_OUTPUT_WIDTH}px عرض
            </p>
            <div className="flex flex-wrap gap-2">
              <input id={`et-cover-${tournament.id}`} type="file" accept="image/jpeg,image/png,image/webp,image/gif" className="hidden" disabled={coverBusy} onChange={handleCoverFile} />
              <label htmlFor={`et-cover-${tournament.id}`} className="inline-flex cursor-pointer rounded-xl border border-gray-300 bg-white px-3 py-2 text-xs font-bold dark:border-gray-700 dark:bg-gray-800">
                {coverBusy ? "جاري المعالجة…" : "تغيير الصورة"}
              </label>
              {form.coverDataUrl ? (
                <button type="button" onClick={() => set("coverDataUrl", null)} className="rounded-xl border border-red-200 px-3 py-2 text-xs font-bold text-red-600">
                  إزالة الصورة
                </button>
              ) : null}
            </div>
          </>
        ) : null}
        {form.coverDataUrl ? (
          <div className={`overflow-hidden rounded-xl border border-gray-200 dark:border-gray-700 ${readOnly ? "" : "mt-3"}`}>
            <img src={form.coverDataUrl} alt="" className="aspect-[16/9] w-full max-w-2xl object-cover" />
          </div>
        ) : readOnly ? (
          <p className="text-xs text-gray-400">لا توجد صورة غلاف</p>
        ) : null}
      </div>
      </fieldset>

      {error ? <p className="text-[11px] font-bold text-red-600">{error}</p> : null}

      {!readOnly ? (
      <div className="flex justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
        {showCancel && onCancel ? (
          <Button type="button" variant="outline" size="sm" onClick={onCancel} disabled={saving}>
            إلغاء
          </Button>
        ) : null}
        <Button type="submit" size="sm" disabled={saving || coverBusy}>
          {saving ? "جاري الحفظ..." : submitLabel}
        </Button>
      </div>
      ) : null}
    </form>
  );
}
