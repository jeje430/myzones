import { useCallback, useEffect, useMemo, useState } from "react";
import { Button } from "react-bootstrap";
import { ChevronLeft, ChevronRight, Clock } from "lucide-react";
import { zonesToastSuccess, zonesToastWarning } from "../../../shared/utils/zonesAlerts";
import PageHeader from "../../super-admin/components/ui/PageHeader";
import ReceptionCalendarBookModal from "../components/ReceptionCalendarBookModal";
import ReceptionCalendarReservedModal from "../components/ReceptionCalendarReservedModal";
import ReceptionDatePicker from "../components/ReceptionDatePicker";
import { DEVICES_STORAGE_EVENT } from "../../devices-packages/data/devicesStorage";
import { PACKAGES_STORAGE_EVENT } from "../../devices-packages/data/packagesStorage";
import { refreshHallCatalogFromApi } from "../../devices-packages/data/hallCatalogSync";
import { MAINTENANCE_FAULTS_EVENT } from "../../maintenance/data/maintenanceFaultsStorage";
import {
  BOOKINGS_STOP_EVENT,
  getBookingsStopBlockMessage,
  isBookingsStopped,
} from "../../alerts/data/bookingsStopStorage";
import {
  bookCalendarSlot,
  cancelCalendarBooking,
  findCalendarSlot,
  loadCalendarSlots,
  RECEPTION_CALENDAR_EVENT,
  syncReceptionLiveState,
  todayIso,
} from "../data/receptionCalendarStorage";
import {
  buildWorkHourSlots,
  buildCalendarPackageGroups,
  CALENDAR_LEGEND_ORDER,
  CELL_KIND,
  CELL_BTN_VARIANT,
  CELL_LEGEND_CLASS,
  CELL_META,
  formatCalendarDate,
  getCalendarCellLabel,
  getHallWorkHours,
  getReceptionDeviceLabel,
  loadCalendarDevices,
  resolveCellKind,
} from "../utils/receptionCalendarUtils";
import "./ReceptionCalendarPage.css";

import { shiftLocalIsoDate } from "../../../shared/utils/localDateUtils";
import { useReceptionLiveSync } from "../hooks/useReceptionLiveSync";

function shiftDate(iso, deltaDays) {
  return shiftLocalIsoDate(iso, deltaDays);
}

export default function ReceptionCalendarPage() {
  const [selectedDate, setSelectedDate] = useState(todayIso);
  useReceptionLiveSync(selectedDate);
  const [slots, setSlots] = useState(() => loadCalendarSlots());
  const [devices, setDevices] = useState(() => loadCalendarDevices());
  const [packageGroups, setPackageGroups] = useState(() => buildCalendarPackageGroups());
  const [bookTarget, setBookTarget] = useState(null);
  const [reservedTarget, setReservedTarget] = useState(null);
  const [bookingsStopped, setBookingsStopped] = useState(() => isBookingsStopped());
  const hall = useMemo(() => getHallWorkHours(), []);
  const hours = useMemo(() => buildWorkHourSlots(hall.from, hall.to), [hall.from, hall.to]);

  const reloadView = useCallback(() => {
    setSlots(loadCalendarSlots());
    setDevices(loadCalendarDevices());
    setPackageGroups(buildCalendarPackageGroups());
    setBookingsStopped(isBookingsStopped());
  }, []);

  const syncView = useCallback(async () => {
    await syncReceptionLiveState(selectedDate);
    reloadView();
  }, [selectedDate, reloadView]);

  useEffect(() => {
    refreshHallCatalogFromApi().finally(syncView);
    window.addEventListener(RECEPTION_CALENDAR_EVENT, reloadView);
    window.addEventListener(DEVICES_STORAGE_EVENT, syncView);
    window.addEventListener(PACKAGES_STORAGE_EVENT, syncView);
    window.addEventListener(MAINTENANCE_FAULTS_EVENT, syncView);
    window.addEventListener("manager-hall-updated", syncView);
    window.addEventListener(BOOKINGS_STOP_EVENT, syncView);
    window.addEventListener("focus", syncView);
    return () => {
      window.removeEventListener(RECEPTION_CALENDAR_EVENT, reloadView);
      window.removeEventListener(DEVICES_STORAGE_EVENT, syncView);
      window.removeEventListener(PACKAGES_STORAGE_EVENT, syncView);
      window.removeEventListener(MAINTENANCE_FAULTS_EVENT, syncView);
      window.removeEventListener("manager-hall-updated", syncView);
      window.removeEventListener(BOOKINGS_STOP_EVENT, syncView);
      window.removeEventListener("focus", syncView);
    };
  }, [syncView, reloadView]);

  const confirmBook = async (payload) => {
    if (!bookTarget) return { ok: false, error: "لا يوجد موعد محدد" };
    const res = await bookCalendarSlot({
      deviceId: bookTarget.device.id,
      date: selectedDate,
      hour: bookTarget.hour,
      hourTo: payload.hourTo,
      visitorName: payload.visitorName,
      phone: payload.phone,
      email: payload.email,
      notes: payload.notes,
      packageId: payload.packageId,
      packageName: payload.packageName,
      packagePrice: payload.packagePrice,
      paymentType: payload.paymentType,
      isPaid: payload.isPaid,
      bookingCode: payload.bookingCode,
      source: payload.source || "manual",
    });
    if (!res.ok) {
      zonesToastWarning(`لا يمكن الحجز — ${res.error || getBookingsStopBlockMessage()}`);
      return res;
    }
    reloadView();
    zonesToastSuccess(
      `رقم الحجز ${res.slot?.bookingCode || payload.bookingCode} — تم تسجيل الحجز في التقويم وقائمة الحجوزات.`,
      "تم الحجز",
    );
    return res;
  };

  const cancelReservedBooking = async () => {
    if (!reservedTarget?.slot?.id) return;
    await cancelCalendarBooking(reservedTarget.slot.id);
    setReservedTarget(null);
    reloadView();
  };

  const onCellClick = (device, hour) => {
    const kind = resolveCellKind(device, selectedDate, hour, slots);
    const slot = findCalendarSlot(device.id, selectedDate, hour, slots);

    if (kind === CELL_KIND.available) {
      if (bookingsStopped) {
        zonesToastWarning(`الحجوزات متوقفة — ${getBookingsStopBlockMessage()}`);
        return;
      }
      setBookTarget({ device, hour });
      return;
    }

    if (kind === CELL_KIND.reserved && slot) {
      setReservedTarget({ device, hour, slot });
    }
  };

  return (
    <div dir="rtl">
      <PageHeader title="تقويم الحجوزات" />

      {bookingsStopped ? (
        <div className="mb-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-xs font-bold text-red-700 dark:border-red-900/40 dark:bg-red-950/20 dark:text-red-300">
          {getBookingsStopBlockMessage()}
        </div>
      ) : null}

      <section className="rcal-wrap">
        <div className="rcal-toolbar">
          <div className="rcal-date-row">
            <button
              type="button"
              onClick={() => setSelectedDate(todayIso())}
              className="rcal-today-btn"
            >
              اليوم
            </button>
            <button
              type="button"
              onClick={() => setSelectedDate(shiftDate(selectedDate, -1))}
              className="rcal-nav-btn"
              aria-label="اليوم السابق"
            >
              <ChevronRight size={18} strokeWidth={2.5} />
            </button>
            <ReceptionDatePicker value={selectedDate} onChange={setSelectedDate} />
            <button
              type="button"
              onClick={() => setSelectedDate(shiftDate(selectedDate, 1))}
              className="rcal-nav-btn"
              aria-label="اليوم التالي"
            >
              <ChevronLeft size={18} strokeWidth={2.5} />
            </button>
          </div>

          <div className="text-end">
            <p className="rcal-toolbar-date">{formatCalendarDate(selectedDate)}</p>
            <span className="rcal-hours-banner mt-1">
              <Clock size={13} />
              ساعات العمل: {hall.label}
            </span>
          </div>
        </div>

        <div className="rcal-scroll">
          <table className="rcal-table" dir="rtl">
            <colgroup>
              <col className="rcal-col-device" />
              {hours.map((hour) => (
                <col key={hour} className="rcal-col-hour" />
              ))}
            </colgroup>
            <thead>
              <tr>
                <th className="rcal-sticky-device">الجهاز</th>
                {hours.map((hour) => (
                  <th key={hour} className="rcal-hour-head">
                    <span className="rcal-hour-label">{hour}</span>
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {devices.length === 0 ? (
                <tr>
                  <td colSpan={hours.length + 1} className="px-4 py-10 text-center text-gray-400">
                    لا توجد أجهزة مضافة من المدير.
                  </td>
                </tr>
              ) : (
                packageGroups.flatMap((group) => [
                  <tr key={`pkg-${group.package.id ?? "none"}`} className="rcal-package-row">
                    <td className="rcal-sticky-device rcal-package-head" colSpan={hours.length + 1}>
                      <span className="rcal-package-name">{group.package.name}</span>
                      {group.package.price ? (
                        <span className="rcal-package-price">{group.package.price} د.ل / ساعة</span>
                      ) : null}
                      <span className="rcal-package-count">{group.devices.length} جهاز</span>
                    </td>
                  </tr>,
                  ...group.devices.map((device, deviceIndex) => (
                    <tr key={device.id}>
                      <td className="rcal-sticky-device">
                        <span className="rcal-device-name" dir="ltr">
                          {getReceptionDeviceLabel(device, deviceIndex)}
                        </span>
                      </td>
                      {hours.map((hour) => {
                        const kind = resolveCellKind(device, selectedDate, hour, slots);
                        const meta = CELL_META[kind];
                        const short = getCalendarCellLabel(kind);

                        return (
                          <td key={hour} className={`rcal-cell ${meta.className}`}>
                            <Button
                              type="button"
                              variant={CELL_BTN_VARIANT[kind]}
                              size="sm"
                              className={`rcal-cell-btn fw-bold ${
                                kind === CELL_KIND.available ? "btn-rcal-available" : ""
                              } ${kind === CELL_KIND.busy ? "btn-rcal-busy" : ""} ${
                                kind === CELL_KIND.maintenance ? "btn-rcal-maintenance" : ""
                              }`}
                              title={meta.hint}
                              disabled={kind === CELL_KIND.maintenance || kind === CELL_KIND.busy}
                              onClick={() => onCellClick(device, hour)}
                            >
                              {short}
                            </Button>
                          </td>
                        );
                      })}
                    </tr>
                  )),
                ])
              )}
            </tbody>
          </table>
        </div>

        <div className="rcal-legend">
          {CALENDAR_LEGEND_ORDER.map((key) => (
            <span key={key} className="rcal-legend-item">
              <span className={`badge ${CELL_LEGEND_CLASS[key]} rcal-legend-badge`}>
                {CELL_META[key].label}
              </span>
            </span>
          ))}
        </div>
      </section>

      <ReceptionCalendarBookModal
        open={Boolean(bookTarget)}
        device={bookTarget?.device}
        date={selectedDate}
        hour={bookTarget?.hour}
        onClose={() => setBookTarget(null)}
        onConfirm={confirmBook}
      />

      <ReceptionCalendarReservedModal
        open={Boolean(reservedTarget)}
        device={reservedTarget?.device}
        date={selectedDate}
        hour={reservedTarget?.hour}
        slot={reservedTarget?.slot}
        onClose={() => setReservedTarget(null)}
        onCancelBooking={cancelReservedBooking}
      />
    </div>
  );
}
