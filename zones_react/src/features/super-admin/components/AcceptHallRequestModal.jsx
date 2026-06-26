import { useEffect, useState } from "react";
import { Send, X } from "lucide-react";
import IconButton from "../../../shared/components/ui/IconButton";

const inputCls =
  "w-full rounded-xl border border-gray-300 bg-white px-3 py-2.5 text-xs text-gray-800 outline-none focus:border-[#6B5478] focus:ring-2 focus:ring-[#6B5478]/20 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100";

export default function AcceptHallRequestModal({ request, onClose, onSubmit }) {
  const [adminNotes, setAdminNotes] = useState("");
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (!request) return;
    setAdminNotes("");
    setSubmitting(false);
  }, [request]);

  if (!request) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (submitting) return;
    setSubmitting(true);
    await onSubmit({
      adminNotes: adminNotes.trim(),
    });
    setSubmitting(false);
  };

  return (
    <div className="fixed inset-0 z-[10000] flex items-center justify-center bg-black/50 p-4" dir="rtl">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-2xl border border-gray-200 bg-white shadow-2xl dark:border-gray-700 dark:bg-gray-900">
        <div className="sticky top-0 flex items-center justify-between border-b border-gray-100 bg-white px-5 py-4 dark:border-gray-800 dark:bg-gray-900">
          <div>
            <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">قبول الطلب وإرسال دعوة</h2>
            <p className="mt-0.5 text-[11px] text-gray-500 dark:text-gray-400">{request.hallName}</p>
          </div>
          <IconButton icon={X} label="إغلاق" tone="muted" onClick={onClose} />
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 p-5">
          <div>
            <label className="mb-1 block text-[11px] font-bold text-gray-500 dark:text-gray-400">إيميل المدير</label>
            <input type="email" value={request.managerEmail} readOnly className={`${inputCls} opacity-80`} dir="ltr" />
          </div>

          <div>
            <label className="mb-1 block text-[11px] font-bold text-gray-500 dark:text-gray-400">اسم المدير</label>
            <input type="text" value={request.managerName} readOnly className={`${inputCls} opacity-80`} />
          </div>

          <div>
            <label className="mb-1 block text-[11px] font-bold text-gray-500 dark:text-gray-400">ملاحظات</label>
            <textarea
              value={adminNotes}
              onChange={(e) => setAdminNotes(e.target.value)}
              rows={3}
              placeholder="ملاحظات داخلية للأدمن (اختياري)"
              className={`${inputCls} resize-none`}
            />
          </div>

          <button
            type="submit"
            disabled={submitting}
            className="flex w-full items-center justify-center gap-2 rounded-xl bg-[#6B5478] py-2.5 text-xs font-bold text-white transition hover:bg-[#5a4665] disabled:opacity-60"
          >
            <Send size={15} />
            {submitting ? "جاري الإرسال..." : "إرسال دعوة الانضمام"}
          </button>
        </form>
      </div>
    </div>
  );
}
