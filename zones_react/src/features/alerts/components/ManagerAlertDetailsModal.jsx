import AdminModal from "../../devices-packages/components/AdminModal";
import Button from "../../super-admin/components/ui/Button";
import NotificationCard from "./NotificationCard";
import {
  alertSeverityLabel,
  alertSeverityMeta,
  alertStatusLabel,
  alertTargetLabel,
  formatAlertRecordCode,
} from "../data/alertsMeta";

function MetaChip({ label, children }) {
  return (
    <div className="rounded-lg border border-gray-100 bg-gray-50/60 px-2.5 py-1.5 dark:border-gray-800 dark:bg-gray-800/40">
      <p className="text-[9px] font-bold text-gray-400">{label}</p>
      <div className="mt-0.5 text-[11px] font-bold text-gray-700 dark:text-gray-200">{children}</div>
    </div>
  );
}

export default function ManagerAlertDetailsModal({ open, alert, onClose }) {
  if (!alert) return null;

  const active = alert.status === "active";
  const severity = alertSeverityMeta(alert.severity);

  return (
    <AdminModal open={open} onClose={onClose} title="تفاصيل التنبيه" wide>
      <div className="mt-4 space-y-4" dir="rtl">
        <NotificationCard
          title={alert.name}
          dateTime={alert.startDate}
          description={alert.situationDescription || alert.message}
          instructions={alert.alternativeInstructions}
          severity={alert.severity}
          badge={
            <span
              className={`inline-flex shrink-0 rounded-full px-2 py-0.5 text-[9px] font-bold ${severity.badgeClass}`}
            >
              {alertSeverityLabel(alert.severity)}
            </span>
          }
        />

        <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
          <MetaChip label="رقم السجل">
            <span dir="ltr">{formatAlertRecordCode(alert.id)}</span>
          </MetaChip>
          <MetaChip label="المستهدف">
            {alertTargetLabel(alert.targetAudience ?? alert.targetCategories ?? alert.targetCategory)}
          </MetaChip>
          <MetaChip label="الحالة">{alertStatusLabel(alert.status)}</MetaChip>
          <MetaChip label="تاريخ النهاية">
            <span dir="ltr">{alert.endDate || "—"}</span>
          </MetaChip>
        </div>

        {active ? (
          <p className="text-[11px] font-semibold text-amber-600 dark:text-amber-400">
            التنبيه نشط — سيُسجَّل تاريخ النهاية تلقائياً عند إيقافه.
          </p>
        ) : null}
      </div>

      <div className="mt-5 flex justify-end">
        <Button variant="outline" onClick={onClose}>
          إغلاق
        </Button>
      </div>
    </AdminModal>
  );
}
