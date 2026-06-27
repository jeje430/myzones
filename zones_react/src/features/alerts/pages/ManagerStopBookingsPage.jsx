import { useCallback, useEffect, useMemo, useState } from "react";
import { Ban, Pencil, Play, Trash2 } from "lucide-react";
import { zonesConfirm, zonesToastInfo, zonesToastSuccess } from "../../../shared/utils/zonesAlerts";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import Button from "../../super-admin/components/ui/Button";
import IconButton from "../../../shared/components/ui/IconButton";
import TablePagination from "../../../shared/components/TablePagination";
import {
  BOOKINGS_STOP_EVENT,
  deleteBookingsStopRecord,
  formatBookingsStopCode,
  getActiveBookingsStopRecord,
  isBookingsStopped,
  loadBookingsStopRecords,
  refreshBookingStopsFromApi,
  resumeBookingsStop,
  startBookingsStop,
  updateBookingsStopRecord,
} from "../data/bookingsStopStorage";
import { BOOKINGS_STOP_NAME } from "../data/bookingsStopMessages";
import StopBookingsFormModal from "../components/StopBookingsFormModal";
import { MANAGER_ALERTS_EVENT } from "../data/managerAlertsStorage";

const PAGE_SIZE = 8;

function StatusBadge({ active }) {
  return (
    <span
      className={`inline-flex rounded-full px-2.5 py-0.5 text-[11px] font-bold ${
        active
          ? "bg-red-500/15 text-red-600 dark:text-red-400"
          : "bg-emerald-500/15 text-emerald-600 dark:text-emerald-400"
      }`}
    >
      {active ? "نشط" : "منتهى"}
    </span>
  );
}

export default function ManagerStopBookingsPage() {
  const [records, setRecords] = useState(() => loadBookingsStopRecords());
  const [stopped, setStopped] = useState(() => isBookingsStopped());
  const [modalOpen, setModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState("create");
  const [editRecord, setEditRecord] = useState(null);
  const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    await refreshBookingStopsFromApi();
    setRecords(loadBookingsStopRecords());
    setStopped(isBookingsStopped());
    setLoading(false);
  }, []);

  useEffect(() => {
    refresh();
    window.addEventListener(BOOKINGS_STOP_EVENT, refresh);
    window.addEventListener(MANAGER_ALERTS_EVENT, refresh);
    return () => {
      window.removeEventListener(BOOKINGS_STOP_EVENT, refresh);
      window.removeEventListener(MANAGER_ALERTS_EVENT, refresh);
    };
  }, [refresh]);

  const totalPages = Math.max(1, Math.ceil(records.length / PAGE_SIZE));
  const paged = records.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);
  const activeRecord = useMemo(() => getActiveBookingsStopRecord(), [records, stopped]);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const openCreate = () => {
    setModalMode("create");
    setEditRecord(null);
    setModalOpen(true);
  };

  const openEdit = (row) => {
    setModalMode("edit");
    setEditRecord(row);
    setModalOpen(true);
  };

  const handleSubmitStop = async ({ reasonKey, startsOn, endsOn }) => {
    if (modalMode === "edit" && editRecord) {
      const result = await updateBookingsStopRecord(editRecord.id, { reasonKey, endsOn });
      if (!result.ok) {
        zonesToastInfo(result.error);
        return;
      }
      setModalOpen(false);
      setEditRecord(null);
      await refresh();
      zonesToastSuccess("تم تحديث إيقاف الحجوزات");
      return;
    }

    const result = await startBookingsStop({ reasonKey, startsOn, endsOn });
    if (!result.ok) {
      zonesToastInfo(result.error);
      return;
    }
    setModalOpen(false);
    await refresh();
    zonesToastSuccess("تم إيقاف الحجوزات — سيتم تحديث تطبيق الزبائن تلقائياً.");
  };

  const handleResume = async (row) => {
    const confirmed = await zonesConfirm({
      title: "استئناف الحجوزات؟",
      text: "سيتم فتح الحجز للزبائن والموظفين فوراً.",
      confirmText: "استئناف الحجوزات",
      cancelText: "إلغاء",
    });
    if (!confirmed) return;

    const result = await resumeBookingsStop(row?.id);
    if (!result.ok) {
      zonesToastInfo(result.error);
      return;
    }
    await refresh();
    zonesToastSuccess("تم استئناف الحجوزات");
  };

  const handleDelete = async (row) => {
    const confirmed = await zonesConfirm({
      title: "حذف السجل؟",
      text: "سيتم حذف سجل الإيقاف نهائياً.",
      confirmText: "حذف",
      cancelText: "إلغاء",
      danger: true,
    });
    if (!confirmed) return;

    const result = await deleteBookingsStopRecord(row.id);
    if (!result.ok) {
      zonesToastInfo(result.error);
      return;
    }
    await refresh();
    zonesToastSuccess("تم حذف السجل");
  };

  return (
    <div className="space-y-4" dir="rtl">
        <PageHeader
          title="إيقاف الحجوزات"
        />

        <section className="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm dark:border-gray-800 dark:bg-gray-900">
          <div className="flex flex-wrap items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-gray-800">
            <div>
              <h2 className="text-sm font-extrabold text-gray-900 dark:text-white">سجل إيقاف الحجوزات</h2>
              <p className="mt-0.5 text-[11px] text-gray-500">
                {loading
                  ? "جاري التحديث..."
                  : stopped
                    ? "الحجوزات متوقفة حالياً — لا يمكن للاستقبال حجز زبون."
                    : "الحجوزات متاحة للحجز."}
              </p>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              {!stopped ? (
                <Button size="sm" onClick={openCreate} className="bg-red-600 hover:bg-red-700">
                  <Ban className="h-4 w-4" />
                  إيقاف الحجوزات
                </Button>
              ) : (
                <Button size="sm" onClick={() => handleResume(activeRecord)}>
                  <Play className="h-4 w-4" />
                  استئناف الحجوزات
                </Button>
              )}
            </div>
          </div>

          {activeRecord ? (
            <div className="border-b border-red-100 bg-red-50/60 px-5 py-3 dark:border-red-900/30 dark:bg-red-950/20">
              <p className="text-xs font-bold text-red-700 dark:text-red-300">
                إيقاف نشط — {formatBookingsStopCode(activeRecord.id)} — {activeRecord.reason}
              </p>
            </div>
          ) : null}

          <div className="overflow-x-auto">
            <table className="w-full min-w-[960px] text-right text-xs">
              <thead>
                <tr className="border-b border-gray-100 text-gray-500 dark:border-gray-800 dark:text-gray-400">
                  <th className="px-3 py-2.5 font-bold">الرقم</th>
                  <th className="px-3 py-2.5 font-bold">الاسم</th>
                  <th className="px-3 py-2.5 font-bold">السبب</th>
                  <th className="px-3 py-2.5 font-bold">تاريخ البداية</th>
                  <th className="px-3 py-2.5 font-bold">تاريخ النهاية</th>
                  <th className="px-3 py-2.5 font-bold">الحالة</th>
                  <th className="px-3 py-2.5 font-bold">الإجراءات</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 dark:divide-gray-800">
                {paged.length === 0 ? (
                  <tr>
                    <td colSpan={7} className="px-3 py-10 text-center">
                      <p className="text-gray-400">لا توجد سجلات إيقاف حجوزات بعد.</p>
                    </td>
                  </tr>
                ) : (
                  paged.map((row) => (
                    <tr key={row.id}>
                      <td className="px-3 py-3 font-bold text-[#6B5478]" dir="ltr">
                        {formatBookingsStopCode(row.id)}
                      </td>
                      <td className="px-3 py-3 font-bold text-gray-800 dark:text-gray-100">
                        {BOOKINGS_STOP_NAME}
                      </td>
                      <td className="px-3 py-3 text-gray-600 dark:text-gray-300">{row.reason || "—"}</td>
                      <td className="px-3 py-3 whitespace-nowrap text-gray-500" dir="ltr">
                        {row.startsOn || row.startDate || "—"}
                      </td>
                      <td className="px-3 py-3 whitespace-nowrap text-gray-500" dir="ltr">
                        {row.endsOn || row.endDate || "حتى إشعار آخر"}
                      </td>
                      <td className="px-3 py-3">
                        <StatusBadge active={row.status === "active"} />
                      </td>
                      <td className="px-3 py-3">
                        <div className="flex items-center justify-end gap-1">
                          {row.status === "active" ? (
                            <>
                              <IconButton
                                icon={Pencil}
                                label="تعديل"
                                tone="neutral"
                                size={15}
                                onClick={() => openEdit(row)}
                              />
                              <IconButton
                                icon={Play}
                                label="استئناف الحجوزات"
                                tone="success"
                                size={15}
                                onClick={() => handleResume(row)}
                              />
                            </>
                          ) : null}
                          <IconButton
                            icon={Trash2}
                            label="حذف"
                            tone="danger"
                            size={15}
                            onClick={() => handleDelete(row)}
                          />
                        </div>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          <TablePagination
            page={page}
            totalPages={totalPages}
            totalItems={records.length}
            pageSize={PAGE_SIZE}
            onPageChange={setPage}
          />
        </section>

        <StopBookingsFormModal
          open={modalOpen}
          mode={modalMode}
          recordId={editRecord?.id}
          initialReasonKey={editRecord?.reasonKey || ""}
          initialStartsOn={editRecord?.startsOn || editRecord?.startDate?.slice(0, 10) || ""}
          initialEndsOn={editRecord?.endsOn || editRecord?.endDate?.slice(0, 10) || ""}
          onClose={() => {
            setModalOpen(false);
            setEditRecord(null);
          }}
          onSubmit={handleSubmitStop}
        />
      </div>
  );
}
