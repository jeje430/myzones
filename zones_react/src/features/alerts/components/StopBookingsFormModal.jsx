import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, Ban } from "lucide-react";
import AdminModal from "../../devices-packages/components/AdminModal";
import { Select, alertFormReadOnlyCls } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import {
  BOOKINGS_STOP_ACTION,
  BOOKINGS_STOP_REASONS,
} from "../data/bookingsStopMessages";
import {
  formatBookingsStopCode,
  nextBookingsStopId,
  loadBookingsStopRecords,
} from "../data/bookingsStopStorage";

const reasonOptions = BOOKINGS_STOP_REASONS.map((item) => ({
  value: item.value,
  label: item.label,
}));

const actionOptions = [
  { value: BOOKINGS_STOP_ACTION.value, label: BOOKINGS_STOP_ACTION.label },
];

function todayYmd() {
  return new Date().toISOString().slice(0, 10);
}

export default function StopBookingsFormModal({
  open,
  mode = "create",
  initialReasonKey = "",
  initialStartsOn = "",
  initialEndsOn = "",
  recordId = null,
  onClose,
  onSubmit,
}) {
  const [reasonKey, setReasonKey] = useState(initialReasonKey);
  const [startsOn, setStartsOn] = useState(initialStartsOn || todayYmd());
  const [endsOn, setEndsOn] = useState(initialEndsOn);

  useEffect(() => {
    if (!open) return;
    setReasonKey(initialReasonKey);
    setStartsOn(initialStartsOn || todayYmd());
    setEndsOn(initialEndsOn || "");
  }, [open, initialReasonKey, initialStartsOn, initialEndsOn]);

  const previewId = useMemo(
    () => (open && mode === "create" ? nextBookingsStopId(loadBookingsStopRecords()) : recordId),
    [open, mode, recordId],
  );

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!reasonKey.trim()) return;
    onSubmit({ reasonKey, startsOn, endsOn: endsOn.trim() || null });
  };

  const isEdit = mode === "edit";

  return (
    <AdminModal
      open={open}
      onClose={onClose}
      title={isEdit ? "تعديل إيقاف الحجوزات" : "إيقاف الحجوزات"}
      wide
    >
      <form className="mt-4 space-y-5" onSubmit={handleSubmit} dir="rtl">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">رقم السجل</Label>
            <p className={`${alertFormReadOnlyCls} font-bold text-[#6B5478]`} dir="ltr">
              {previewId ? formatBookingsStopCode(previewId) : "—"}
            </p>
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">نوع الإجراء</Label>
            <Select value={BOOKINGS_STOP_ACTION.value} onValueChange={() => {}} options={actionOptions} disabled />
          </div>
        </div>

        <div>
          <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">سبب الإيقاف</Label>
          <Select
            value={reasonKey}
            onValueChange={setReasonKey}
            options={reasonOptions}
            placeholder="اختر سبب الإيقاف..."
          />
        </div>

        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">تاريخ البداية *</Label>
            {isEdit ? (
              <p className={alertFormReadOnlyCls} dir="ltr">
                {startsOn}
              </p>
            ) : (
              <input
                type="date"
                value={startsOn}
                onChange={(e) => setStartsOn(e.target.value)}
                required
                className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs dark:border-gray-700 dark:bg-gray-900"
              />
            )}
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">
              تاريخ النهاية (اختياري)
            </Label>
            <input
              type="date"
              value={endsOn}
              min={startsOn}
              onChange={(e) => setEndsOn(e.target.value)}
              className="w-full rounded-xl border border-gray-200 bg-white px-3 py-2 text-xs dark:border-gray-700 dark:bg-gray-900"
            />
            <p className="mt-1 text-[10px] text-gray-500">اتركه فارغاً = حتى إشعار آخر</p>
          </div>
        </div>

        <p className="flex items-start gap-2 rounded-xl border border-amber-500/25 bg-amber-500/10 px-3 py-2.5 text-[11px] font-semibold leading-relaxed text-amber-700 dark:border-amber-500/20 dark:bg-amber-500/10 dark:text-amber-300">
          <AlertTriangle size={14} className="mt-0.5 shrink-0" strokeWidth={2.25} />
          {isEdit
            ? "سيتم تحديث سبب الإيقاف وتاريخ النهاية — الحجوزات تبقى متوقفة حتى الاستئناف أو انتهاء المدة."
            : "عند التأكيد تُوقف الحجوزات في التطبيق فوراً للزبائن والموظفين."}
        </p>

        <div className="flex flex-wrap items-center justify-end gap-3 border-t border-gray-100 pt-4 dark:border-gray-800">
          <button
            type="button"
            onClick={onClose}
            className="px-2 py-2 text-xs font-bold text-gray-500 transition hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
          >
            إلغاء
          </button>
          <button
            type="submit"
            disabled={!reasonKey.trim() || (!isEdit && !startsOn)}
            className="inline-flex items-center gap-1.5 rounded-xl bg-red-900 px-4 py-2.5 text-xs font-bold text-white shadow-sm transition hover:bg-red-950 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-red-950 dark:hover:bg-red-900"
          >
            <Ban size={14} strokeWidth={2.25} />
            {isEdit ? "حفظ التعديل" : "تأكيد إيقاف الحجوزات"}
          </button>
        </div>
      </form>
    </AdminModal>
  );
}
