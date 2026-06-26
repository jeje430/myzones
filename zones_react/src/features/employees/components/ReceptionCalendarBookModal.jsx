import { useEffect, useMemo, useState } from "react";
import { Download, Eye } from "lucide-react";
import Button from "../../super-admin/components/ui/Button";
import { formatCalendarDate, getHallWorkHours } from "../utils/receptionCalendarUtils";
import {
  calcHourTo,
  generateBookingCode,
  getDevicePackageInfo,
  PAYMENT_TYPES,
} from "../data/receptionCalendarStorage";
import {
  downloadBookingReceiptPdf,
  openBookingReceiptPdf,
} from "../utils/openBookingReceiptPdf";

const TOTAL_STEPS = 3;

const STEP_TITLES = {
  1: "ملخص الحجز",
  2: "بيانات الزبون",
  3: "تأكيد الحجز",
};

function formatDurationHours(hours) {
  const n = Number(hours) || 1;
  if (n === 1) return "ساعة واحدة";
  if (n === 2) return "ساعتان";
  return `${n} ساعات`;
}

function calcTotalPrice(hourlyPrice, hours) {
  const rate = Number.parseFloat(String(hourlyPrice).replace(/[^\d.]/g, "")) || 0;
  const count = Number(hours) || 1;
  return rate * count;
}

export default function ReceptionCalendarBookModal({
  open,
  device,
  date,
  hour,
  onClose,
  onConfirm,
}) {
  const [step, setStep] = useState(1);
  const [visitorName, setVisitorName] = useState("");
  const [phone, setPhone] = useState("");
  const [notes, setNotes] = useState("");
  const [bookingCode, setBookingCode] = useState("");
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState("");
  const [confirmedBooking, setConfirmedBooking] = useState(null);

  const pkg = device ? getDevicePackageInfo(device) : null;
  const hourTo = hour && pkg ? calcHourTo(hour, pkg.hours) : hour;
  const hallName = getHallWorkHours().hallName;
  const totalPrice = useMemo(
    () => calcTotalPrice(pkg?.packagePrice, pkg?.hours),
    [pkg?.packagePrice, pkg?.hours],
  );

  useEffect(() => {
    if (!open) return;
    setStep(1);
    setVisitorName("");
    setPhone("");
    setNotes("");
    setBookingCode(generateBookingCode("manual"));
    setIsSaving(false);
    setSaveError("");
    setConfirmedBooking(null);
  }, [open, device?.id, date, hour]);

  if (!open || !device) return null;

  const summary = {
    deviceName: device.name,
    packageName: pkg?.packageName || "—",
    date,
    hour,
    hourTo,
    durationHours: pkg?.hours || 1,
    durationLabel: formatDurationHours(pkg?.hours),
    hourlyPrice: pkg?.packagePrice || "—",
    totalPrice,
    totalPriceLabel: totalPrice > 0 ? `${totalPrice} د.ل` : pkg?.packagePrice || "—",
    paymentLabel: "الدفع عند الوصول",
  };

  const buildPayload = () => ({
    bookingCode,
    visitorName: visitorName.trim(),
    phone: phone.trim(),
    email: "",
    notes: notes.trim(),
    paymentType: PAYMENT_TYPES.cash.value,
    isPaid: false,
    packageId: pkg?.packageId ?? null,
    packageName: pkg?.packageName || "—",
    packagePrice: pkg?.packagePrice || "—",
    hourTo,
    source: "manual",
  });

  const canGoNext = () => {
    if (step === 2) {
      return Boolean(visitorName.trim() && phone.trim());
    }
    return true;
  };

  const goNext = async () => {
    if (!canGoNext()) return;

    if (step < TOTAL_STEPS) {
      setStep((s) => s + 1);
      setSaveError("");
      return;
    }

    setIsSaving(true);
    setSaveError("");
    try {
      const res = await onConfirm(buildPayload());
      if (res?.ok === false) {
        setSaveError(res.error || "تعذر إتمام الحجز");
        return;
      }
      setConfirmedBooking({
        id: res?.slot?.id,
        bookingCode: res?.slot?.bookingCode || bookingCode,
        receiptPdfUrl: res?.slot?.receiptPdfUrl || null,
      });
    } catch {
      setSaveError("تعذر إتمام الحجز");
    } finally {
      setIsSaving(false);
    }
  };

  const goPrevious = () => {
    if (step <= 1 || confirmedBooking) return;
    setStep((s) => s - 1);
    setSaveError("");
  };

  const handleViewReceipt = async () => {
    if (!confirmedBooking?.id) return;
    try {
      await openBookingReceiptPdf(confirmedBooking.id);
    } catch {
      setSaveError("تعذر فتح الإيصال");
    }
  };

  const handleDownloadReceipt = async () => {
    if (!confirmedBooking?.id) return;
    try {
      await downloadBookingReceiptPdf(
        confirmedBooking.id,
        `${confirmedBooking.bookingCode}-receipt.pdf`,
      );
    } catch {
      setSaveError("تعذر تنزيل الإيصال");
    }
  };

  const handleDone = () => {
    onClose();
  };

  const handleOverlayClick = () => {
    if (confirmedBooking) {
      handleDone();
      return;
    }
    onClose();
  };

  const isSuccess = Boolean(confirmedBooking);

  return (
    <div className="rcal-modal-overlay" onClick={handleOverlayClick} role="presentation">
      <div
        className="rcal-modal rcal-modal--wide"
        role="dialog"
        aria-modal="true"
        aria-label="حجز موعد"
        onClick={(e) => e.stopPropagation()}
      >
        {!isSuccess ? <StepIndicator current={step} /> : null}

        <div className="rcal-modal-body">
          {isSuccess ? (
            <StepSuccess
              bookingCode={confirmedBooking.bookingCode}
              summary={summary}
              visitorName={visitorName.trim()}
              phone={phone.trim()}
              hallName={hallName}
            />
          ) : null}

          {!isSuccess && step === 1 ? (
            <StepReservationSummary summary={summary} bookingCode={bookingCode} />
          ) : null}

          {!isSuccess && step === 2 ? (
            <StepCustomerDetails
              visitorName={visitorName}
              phone={phone}
              notes={notes}
              onVisitorNameChange={setVisitorName}
              onPhoneChange={setPhone}
              onNotesChange={setNotes}
            />
          ) : null}

          {!isSuccess && step === 3 ? (
            <StepConfirmation
              summary={summary}
              visitorName={visitorName.trim()}
              phone={phone.trim()}
              notes={notes.trim()}
              bookingCode={bookingCode}
              hallName={hallName}
            />
          ) : null}

          {saveError ? (
            <p className="rcal-modal-hint mt-2 text-red-600">{saveError}</p>
          ) : null}
        </div>

        <div className="rcal-modal-footer">
          {isSuccess ? (
            <div className="rcal-modal-actions">
              <Button type="button" variant="outline" size="md" onClick={handleViewReceipt}>
                <Eye size={16} />
                عرض الإيصال
              </Button>
              <Button type="button" variant="outline" size="md" onClick={handleDownloadReceipt}>
                <Download size={16} />
                تنزيل PDF
              </Button>
              <Button type="button" size="md" onClick={handleDone}>
                تم
              </Button>
            </div>
          ) : (
            <div className="rcal-modal-actions">
              {step > 1 ? (
                <Button
                  type="button"
                  variant="outline"
                  size="md"
                  onClick={goPrevious}
                  disabled={isSaving}
                >
                  السابق
                </Button>
              ) : (
                <Button type="button" variant="outline" size="md" onClick={onClose}>
                  إلغاء
                </Button>
              )}
              <Button
                type="button"
                size="md"
                onClick={goNext}
                disabled={!canGoNext() || isSaving}
              >
                {step === TOTAL_STEPS
                  ? isSaving
                    ? "جاري الحفظ…"
                    : "تأكيد الحجز"
                  : "التالي"}
              </Button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

function StepIndicator({ current }) {
  return (
    <>
      <p className="rcal-modal-step-label">
        {STEP_TITLES[current]} — الخطوة {current} من {TOTAL_STEPS}
      </p>
      <div className="rcal-modal-steps" aria-hidden="true">
        {Array.from({ length: TOTAL_STEPS }, (_, i) => {
          const n = i + 1;
          const cls =
            n === current
              ? "rcal-modal-step-dot is-active"
              : n < current
                ? "rcal-modal-step-dot is-done"
                : "rcal-modal-step-dot";
          return <span key={n} className={cls} />;
        })}
      </div>
    </>
  );
}

function StepReservationSummary({ summary, bookingCode }) {
  return (
    <>
      <h3 className="rcal-modal-title">{STEP_TITLES[1]}</h3>
      <p className="mb-4 text-[11px] font-semibold text-gray-500">
        تفاصيل الموعد المحدد من التقويم
      </p>
      <div className="rcal-modal-info">
        <InfoRow label="الجهاز" value={summary.deviceName} ltr />
        <InfoRow label="الباقة" value={summary.packageName} />
        <InfoRow label="التاريخ" value={formatCalendarDate(summary.date)} />
        <InfoRow label="من ساعة" value={summary.hour} ltr />
        <InfoRow label="إلى ساعة" value={summary.hourTo} ltr />
        <InfoRow label="المدة" value={summary.durationLabel} />
        <InfoRow label="السعر" value={summary.totalPriceLabel} />
        <InfoRow label="طريقة الدفع" value={summary.paymentLabel} />
        <InfoRow label="رقم الحجز" value={bookingCode} ltr />
      </div>
    </>
  );
}

function StepCustomerDetails({
  visitorName,
  phone,
  notes,
  onVisitorNameChange,
  onPhoneChange,
  onNotesChange,
}) {
  return (
    <>
      <h3 className="rcal-modal-title">{STEP_TITLES[2]}</h3>
      <label className="rcal-modal-field">
        <span className="rcal-modal-label">
          اسم الزبون <span className="text-red-500">*</span>
        </span>
        <input
          type="text"
          className="rcal-modal-input"
          value={visitorName}
          onChange={(e) => onVisitorNameChange(e.target.value)}
          required
          placeholder="الاسم الكامل"
        />
      </label>

      <label className="rcal-modal-field">
        <span className="rcal-modal-label">
          رقم الهاتف <span className="text-red-500">*</span>
        </span>
        <input
          type="tel"
          className="rcal-modal-input"
          value={phone}
          onChange={(e) => onPhoneChange(e.target.value)}
          required
          dir="ltr"
          placeholder="09xxxxxxxx"
        />
      </label>

      <label className="rcal-modal-field">
        <span className="rcal-modal-label">ملاحظات (اختياري)</span>
        <textarea
          className="rcal-modal-input min-h-[72px] resize-y"
          value={notes}
          onChange={(e) => onNotesChange(e.target.value)}
          placeholder="ملاحظات إضافية للحجز"
        />
      </label>
    </>
  );
}

function StepConfirmation({ summary, visitorName, phone, notes, bookingCode, hallName }) {
  return (
    <>
      <h3 className="rcal-modal-title">{STEP_TITLES[3]}</h3>
      <p className="mb-3 text-[11px] font-semibold text-gray-500">
        راجع تفاصيل الحجز قبل التأكيد — الدفع عند الوصول فقط
      </p>
      <div className="rcal-modal-info">
        <InfoRow label="رقم الحجز" value={bookingCode} ltr />
        <InfoRow label="اسم الزبون" value={visitorName} />
        <InfoRow label="رقم الهاتف" value={phone} ltr />
        {notes ? <InfoRow label="ملاحظات" value={notes} /> : null}
        <InfoRow label="الجهاز" value={summary.deviceName} ltr />
        <InfoRow label="الباقة" value={summary.packageName} />
        <InfoRow label="التاريخ" value={formatCalendarDate(summary.date)} />
        <InfoRow label="من ساعة" value={summary.hour} ltr />
        <InfoRow label="إلى ساعة" value={summary.hourTo} ltr />
        <InfoRow label="المدة" value={summary.durationLabel} />
        <InfoRow label="السعر" value={summary.totalPriceLabel} />
        <InfoRow label="طريقة الدفع" value={summary.paymentLabel} />
        <InfoRow label="الصالة" value={hallName} />
      </div>
    </>
  );
}

function StepSuccess({ bookingCode, summary, visitorName, phone, hallName }) {
  return (
    <>
      <h3 className="rcal-modal-title">تم الحجز بنجاح</h3>
      <p className="mb-4 text-center text-[11px] font-semibold text-emerald-700">
        تم تسجيل الحجز في التقويم وقائمة الحجوزات — الدفع عند الوصول
      </p>
      <div className="rcal-modal-info">
        <InfoRow label="رقم الحجز" value={bookingCode} ltr />
        <InfoRow label="اسم الزبون" value={visitorName} />
        <InfoRow label="رقم الهاتف" value={phone} ltr />
        <InfoRow label="الجهاز" value={summary.deviceName} ltr />
        <InfoRow label="الباقة" value={summary.packageName} />
        <InfoRow label="التاريخ" value={formatCalendarDate(summary.date)} />
        <InfoRow label="من ساعة" value={summary.hour} ltr />
        <InfoRow label="إلى ساعة" value={summary.hourTo} ltr />
        <InfoRow label="السعر" value={summary.totalPriceLabel} />
        <InfoRow label="الصالة" value={hallName} />
      </div>
    </>
  );
}

function InfoRow({ label, value, ltr }) {
  return (
    <div className="rcal-modal-info-row">
      <span className="rcal-modal-info-label">{label}</span>
      <span className="rcal-modal-info-value" dir={ltr ? "ltr" : undefined}>
        {value}
      </span>
    </div>
  );
}
