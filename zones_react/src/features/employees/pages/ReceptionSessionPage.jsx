import { useCallback, useEffect, useMemo, useState } from "react";
import { Ban, Play, Square } from "lucide-react";
import { zonesConfirm, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import IconButton from "../../../shared/components/ui/IconButton";
import TableActionsGroup from "../../../shared/components/ui/TableActionsGroup";
import { TABLE_ACTIONS_TD, TABLE_ACTIONS_TH } from "../../../shared/components/ui/tableActionStyles";
import {
  TableBulkActionBar,
  TableSelectHeaderCell,
  TableSelectRowCell,
  selectableRowClass,
} from "../../../shared/components/ui/TableSelection";
import {
  filterItemsByIds,
  resolveBulkActionIds,
  useTableSelection,
} from "../../../shared/hooks/useTableSelection";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import {
  cancelCalendarBooking,
  endCalendarSession,
  getSessionBookings,
  loadCalendarSlots,
  RECEPTION_CALENDAR_EVENT,
  SLOT_STATUS,
  startCalendarSession,
  syncReceptionLiveState,
} from "../data/receptionCalendarStorage";
import { getCustomerPointsBalance } from "../../loyalty/data/loyaltyPointsStorage";
import { formatCurrency } from "../../finance/utils/financeData";
import { isAppBooking } from "../utils/receptionBookingsFilters";
import { loadCalendarDevices } from "../utils/receptionCalendarUtils";
import {
  formatSessionDuration,
  getSessionElapsedMs,
} from "../utils/receptionSessionTimer";
import { DEVICES_STORAGE_EVENT } from "../../devices-packages/data/devicesStorage";
import "./ReceptionSessionPage.css";

import { useReceptionLiveSync } from "../hooks/useReceptionLiveSync";

function SessionStatusBadge({ slot }) {
  const isActive = slot.status === SLOT_STATUS.busy;
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
        isActive
          ? "bg-blue-500/15 text-blue-600 dark:text-blue-400"
          : "bg-red-500/15 text-red-600 dark:text-red-400"
      }`}
    >
      {isActive ? "مشغول" : "محجوز"}
    </span>
  );
}

export default function ReceptionSessionPage() {
  useReceptionLiveSync();
  const [slots, setSlots] = useState(() => loadCalendarSlots());
  const [devices, setDevices] = useState(() => loadCalendarDevices());
  const [now, setNow] = useState(() => Date.now());

  const reloadView = useCallback(() => {
    setSlots(loadCalendarSlots());
    setDevices(loadCalendarDevices());
  }, []);

  const syncView = useCallback(async () => {
    await syncReceptionLiveState();
    reloadView();
  }, [reloadView]);

  useEffect(() => {
    syncView();
    window.addEventListener(RECEPTION_CALENDAR_EVENT, reloadView);
    window.addEventListener(DEVICES_STORAGE_EVENT, syncView);
    window.addEventListener("focus", syncView);
    return () => {
      window.removeEventListener(RECEPTION_CALENDAR_EVENT, reloadView);
      window.removeEventListener(DEVICES_STORAGE_EVENT, syncView);
      window.removeEventListener("focus", syncView);
    };
  }, [syncView, reloadView]);

  const deviceMap = useMemo(
    () => new Map(devices.map((d) => [String(d.id), d])),
    [devices],
  );

  const sessions = useMemo(() => getSessionBookings(slots), [slots]);
  const pageIds = useMemo(() => sessions.map((row) => row.id), [sessions]);
  const selection = useTableSelection({ items: sessions, pageIds });

  const hasActiveSession = useMemo(
    () => sessions.some((s) => s.status === SLOT_STATUS.busy),
    [sessions],
  );

  useEffect(() => {
    if (!hasActiveSession) return undefined;
    const id = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(id);
  }, [hasActiveSession]);

  const runStartSession = async (targetIds, rowForMessage) => {
    const isBulk = targetIds.length > 1;
    const targets = filterItemsByIds(sessions, targetIds).filter((s) => s.status !== SLOT_STATUS.busy);

    const confirmed = await zonesConfirm({
      title: isBulk ? `بدء ${targets.length} جلسات؟` : "بدء الجلسة؟",
      text: isBulk ? `بدء ${targets.length} جلسات.` : `بدء جلسة «${rowForMessage.visitorName}».`,
      confirmText: "بدء",
      cancelText: "إلغاء",
    });
    if (!confirmed) return;

    let success = 0;
    for (const slot of targets) {
      const result = await startCalendarSession(slot.deviceId, slot.date, slot.hour);
      if (result.ok) success += 1;
    }

    if (success === 0) return;

    selection.clearSelection();
    reloadView();
    zonesToastSuccess(
      isBulk ? `بدأت ${success} من ${targets.length} جلسات` : "بدأت الجلسة — الجهاز مشغول الآن.",
    );
  };

  const startSession = (slot) => runStartSession(resolveBulkActionIds(slot.id, selection.selectedIds), slot);

  const handleBulkStartSession = () => {
    const targets = filterItemsByIds(sessions, selection.selectedIds).filter(
      (s) => s.status !== SLOT_STATUS.busy,
    );
    if (!targets.length) return;
    runStartSession(
      targets.map((s) => s.id),
      targets[0],
    );
  };

  const runEndSession = async (targetIds, rowForMessage) => {
    const isBulk = targetIds.length > 1;
    const targets = filterItemsByIds(sessions, targetIds).filter((s) => s.status === SLOT_STATUS.busy);

    const confirmed = await zonesConfirm({
      title: isBulk ? `إنهاء ${targets.length} جلسات؟` : "إنهاء الجلسة؟",
      text: isBulk
        ? `سيتم إنهاء ${targets.length} جلسات وتحرير المواعيد.`
        : `سيتم إنهاء جلسة «${rowForMessage.visitorName}» وتحرير الموعد.`,
      confirmText: "إنهاء",
      cancelText: "إلغاء",
    });
    if (!confirmed) return;

    let success = 0;
    let lastResult = null;
    for (const slot of targets) {
      const result = await endCalendarSession(slot.deviceId, slot.date, slot.hour);
      if (result.ok) {
        success += 1;
        lastResult = result;
      }
    }

    if (success === 0) return;

    selection.clearSelection();
    reloadView();
    if (!isBulk && lastResult?.pointsResult?.ok) {
      zonesToastSuccess(
        `لقد حصل الزبون على ${lastResult.pointsResult.earned} نقطة جديدة. الرصيد: ${lastResult.pointsResult.balance}`,
        "نقاط الولاء",
      );
      return;
    }
    if (!isBulk && lastResult?.revenueEntry?.revenue > 0) {
      zonesToastSuccess(
        `تم تسجيل ${formatCurrency(lastResult.revenueEntry.revenue)} في إيرادات اليوم.`,
        "تم إنهاء الجلسة",
      );
      return;
    }
    zonesToastSuccess(
      isBulk ? `تم إنهاء ${success} من ${targets.length} جلسات` : "تم إنهاء الجلسة — الموعد متاح الآن.",
    );
  };

  const endSession = (slot) => runEndSession(resolveBulkActionIds(slot.id, selection.selectedIds), slot);

  const handleBulkEndSession = () => {
    const targets = filterItemsByIds(sessions, selection.selectedIds).filter(
      (s) => s.status === SLOT_STATUS.busy,
    );
    if (!targets.length) return;
    runEndSession(
      targets.map((s) => s.id),
      targets[0],
    );
  };

  const runCancelSession = async (targetIds, rowForMessage) => {
    const isBulk = targetIds.length > 1;
    const targets = filterItemsByIds(sessions, targetIds).filter((s) => s.status !== SLOT_STATUS.busy);

    const confirmed = await zonesConfirm({
      title: isBulk ? `إلغاء ${targets.length} حجوزات؟` : "إلغاء الحجز؟",
      text: isBulk
        ? `سيتم إلغاء ${targets.length} حجوزات وتحرير المواعيد.`
        : `سيتم إلغاء حجز «${rowForMessage.visitorName}» وتحرير الموعد في التقويم.`,
      confirmText: "إلغاء الحجز",
      cancelText: "تراجع",
      icon: "warning",
    });
    if (!confirmed) return;

    for (const slot of targets) {
      await cancelCalendarBooking(slot.id);
    }

    selection.clearSelection();
    reloadView();
    zonesToastSuccess(isBulk ? `تم إلغاء ${targets.length} حجوزات` : "تم إلغاء الحجز.");
  };

  const cancelSession = (slot) => runCancelSession(resolveBulkActionIds(slot.id, selection.selectedIds), slot);

  const handleBulkCancelSession = () => {
    const targets = filterItemsByIds(sessions, selection.selectedIds).filter(
      (s) => s.status !== SLOT_STATUS.busy,
    );
    if (!targets.length) return;
    runCancelSession(
      targets.map((s) => s.id),
      targets[0],
    );
  };

  return (
    <div dir="rtl">
      <PageHeader title="الجلسات" />

      <section className="rsess-wrap">
        <div className="rsess-head">
          <h2 className="rsess-title">إدارة الجلسات</h2>
          <span className="rsess-count">{sessions.length} جلسة</span>
        </div>

        <TableBulkActionBar
          count={selection.count}
          onClear={selection.clearSelection}
          actions={[
            { label: "بدء المحدد", icon: Play, onClick: handleBulkStartSession },
            { label: "إنهاء المحدد", icon: Square, onClick: handleBulkEndSession },
            { label: "إلغاء المحدد", icon: Ban, onClick: handleBulkCancelSession, variant: "danger" },
          ]}
        />

        <div className="overflow-x-auto">
          <table className="rsess-table">
            <thead>
              <tr>
                <TableSelectHeaderCell {...selection} />
                <th>اسم الزبون</th>
                <th>الجهاز</th>
                <th>الباقة</th>
                <th>وقت البدء</th>
                <th>مدة الجلسة</th>
                <th>حالة الجلسة</th>
                <th className={TABLE_ACTIONS_TH}>الإجراء</th>
              </tr>
            </thead>
            <tbody>
              {sessions.length === 0 ? (
                <tr>
                  <td colSpan={8} className="rsess-empty">
                    لا توجد جلسات — سجّل الحضور من جدول الحجوزات.
                  </td>
                </tr>
              ) : (
                sessions.map((slot) => {
                  const device = deviceMap.get(String(slot.deviceId));
                  const isActive = slot.status === SLOT_STATUS.busy;
                  const elapsedMs = isActive
                    ? getSessionElapsedMs(slot.startedAt, now)
                    : (slot.sessionDurationSeconds ?? 0) * 1000;

                  return (
                    <tr
                      key={slot.id}
                      className={`${isActive ? "rsess-row--active" : ""} ${selectableRowClass(selection.isSelected(slot.id), "")}`}
                    >
                      <TableSelectRowCell
                        id={slot.id}
                        ariaLabel={`تحديد جلسة ${slot.visitorName}`}
                        {...selection}
                      />
                      <td className="rsess-guest">{slot.visitorName || "—"}</td>
                      <td className="rsess-device">{device?.name || "—"}</td>
                      <td>{slot.packageName || "—"}</td>
                      <td className="rsess-hour" dir="ltr">
                        {slot.date} {slot.hour}
                      </td>
                      <td>
                        {isActive ? (
                          <span className="rsess-timer" dir="ltr">
                            {formatSessionDuration(elapsedMs)}
                          </span>
                        ) : slot.sessionDurationSeconds != null ? (
                          <span className="rsess-timer rsess-timer--done" dir="ltr">
                            {formatSessionDuration(elapsedMs)}
                          </span>
                        ) : (
                          <span className="rsess-timer rsess-timer--idle" dir="ltr">
                            00:00:00
                          </span>
                        )}
                      </td>
                      <td>
                        <SessionStatusBadge slot={slot} />
                      </td>
                      <td className={TABLE_ACTIONS_TD}>
                        <TableActionsGroup>
                          {!isActive ? (
                            <IconButton
                              icon={Play}
                              label="بدء الجلسة"
                              tone="brand"
                              onClick={() => startSession(slot)}
                            />
                          ) : (
                            <IconButton
                              icon={Square}
                              label="إنهاء الجلسة"
                              tone="warning"
                              onClick={() => endSession(slot)}
                            />
                          )}
                          <IconButton
                            icon={Ban}
                            label="إلغاء"
                            tone="danger"
                            disabled={isActive}
                            onClick={() => cancelSession(slot)}
                          />
                        </TableActionsGroup>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
