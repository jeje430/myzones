import { useEffect, useMemo, useState } from "react";
import AdminModal from "../../devices-packages/components/AdminModal";
import { Select, alertFormFieldCls, alertFormReadOnlyCls, alertFormTextareaCls } from "@/components/ui/select";
import { Label } from "@/components/ui/label";
import Button from "../../super-admin/components/ui/Button";
import { zonesToastWarning } from "../../../shared/utils/zonesAlerts";
import {
  ALERT_SEVERITY_LEVELS,
  NOTIFICATION_TARGET_FORM_OPTIONS,
  alertStatusLabel,
  formatAlertDateTime,
  formatAlertRecordCode,
  isSelectableTargetAudience,
} from "../data/alertsMeta";
import { loadAlerts, nextAlertId } from "../data/managerAlertsStorage";

const targetOptions = NOTIFICATION_TARGET_FORM_OPTIONS.map((item) => ({
  value: item.value,
  label: item.label,
}));

const severityOptions = ALERT_SEVERITY_LEVELS.map((item) => ({
  value: item.value,
  label: item.label,
}));

const EMPTY_FORM = {
  name: "",
  targetAudience: "",
  severity: "medium",
  situationDescription: "",
  alternativeInstructions: "",
};

export default function ManagerAlertFormModal({ open, onClose, onSave }) {
  const [form, setForm] = useState(EMPTY_FORM);
  const previewId = useMemo(() => (open ? nextAlertId(loadAlerts()) : null), [open]);
  const previewStartDate = useMemo(() => (open ? formatAlertDateTime() : ""), [open]);

  useEffect(() => {
    if (open) setForm(EMPTY_FORM);
  }, [open]);

  const setField = (key, value) => setForm((prev) => ({ ...prev, [key]: value }));

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!form.name.trim() || !form.situationDescription.trim()) return;

    if (!isSelectableTargetAudience(form.targetAudience)) {
      zonesToastWarning("يرجى اختيار المستهدف: الجميع، موظف الصيانة، موظف الاستقبال، أو الزبون.");
      return;
    }

    onSave(form);
  };

  return (
    <AdminModal open={open} onClose={onClose} title="إضافة تنبيه" wide>
      <form className="mt-4 space-y-5" onSubmit={handleSubmit} dir="rtl">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">رقم السجل</Label>
            <p className={`${alertFormReadOnlyCls} font-bold text-[#6B5478]`} dir="ltr">
              {previewId ? formatAlertRecordCode(previewId) : "—"}
            </p>
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">تاريخ البداية</Label>
            <p className={alertFormReadOnlyCls} dir="ltr">
              {previewStartDate || "—"}
            </p>
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">المستهدف</Label>
            <Select
              value={form.targetAudience}
              onValueChange={(v) => setField("targetAudience", v)}
              options={targetOptions}
              placeholder="اختر المستهدف..."
              required
            />
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">مستوى الخطورة</Label>
            <Select
              value={form.severity}
              onValueChange={(v) => setField("severity", v)}
              options={severityOptions}
              placeholder="اختر..."
            />
          </div>
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <Label htmlFor="alert-name" className="mb-1.5 block text-[10px] font-bold text-gray-400">
              عنوان التنبيه
            </Label>
            <input
              id="alert-name"
              value={form.name}
              onChange={(e) => setField("name", e.target.value)}
              className={alertFormFieldCls}
              placeholder="عنوان التنبيه"
              required
            />
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">الحالة</Label>
            <div className={alertFormReadOnlyCls}>
              <span className="inline-flex rounded-full bg-emerald-500/15 px-2.5 py-0.5 text-[11px] font-bold text-emerald-600 dark:text-emerald-400">
                {alertStatusLabel("active")}
              </span>
            </div>
          </div>

          <div>
            <Label className="mb-1.5 block text-[10px] font-bold text-gray-400">تاريخ النهاية</Label>
            <p className={alertFormReadOnlyCls} dir="ltr">
              —
            </p>
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="alert-situation" className="mb-1.5 block text-[10px] font-bold text-gray-400">
              وصف التنبيه
            </Label>
            <textarea
              id="alert-situation"
              rows={2}
              value={form.situationDescription}
              onChange={(e) => setField("situationDescription", e.target.value)}
              className={alertFormTextareaCls}
              placeholder="وصف التنبيه..."
              required
            />
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="alert-instructions" className="mb-1.5 block text-[10px] font-bold text-gray-400">
              تعليمات بديلة (اختياري)
            </Label>
            <textarea
              id="alert-instructions"
              rows={2}
              value={form.alternativeInstructions}
              onChange={(e) => setField("alternativeInstructions", e.target.value)}
              className={alertFormTextareaCls}
              placeholder="تعليمات للموظفين أو الزبائن..."
            />
          </div>
        </div>

        <div className="flex flex-wrap justify-end gap-2 border-t border-gray-100 pt-4 dark:border-gray-800">
          <Button type="button" variant="outline" onClick={onClose}>
            إلغاء
          </Button>
          <Button type="submit">حفظ وإرسال</Button>
        </div>
      </form>
    </AdminModal>
  );
}
