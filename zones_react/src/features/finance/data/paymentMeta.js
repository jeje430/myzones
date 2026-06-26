export function formatPaymentAmount(amount) {
  const value = Number(amount) || 0;
  return `${value.toLocaleString("ar-LY", { minimumFractionDigits: 0, maximumFractionDigits: 2 })} د.ل`;
}

export function formatPaymentDateTime(iso) {
  if (!iso) return "—";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "—";

  return date.toLocaleString("ar-LY", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function paymentMethodLabel(method) {
  if (method === "electronic") return "إلكتروني";
  if (method === "pay_on_arrival") return "دفع عند الوصول";
  return method || "—";
}

export function formatBookingDetails(row) {
  if (!row.bookingNumber) return "—";

  const details = row.bookingDetails;
  if (!details?.startDate) {
    return row.bookingNumber;
  }

  const time = details.startTime ? details.startTime.slice(0, 5) : "";
  return `${row.bookingNumber} · ${details.startDate}${time ? ` ${time}` : ""}`;
}

export const PAYMENT_METHOD_FILTERS = [
  { key: "all", label: "الكل" },
  { key: "electronic", label: "إلكتروني" },
  { key: "pay_on_arrival", label: "دفع عند الوصول" },
];

export { fetchManagerPayments } from "./paymentsApi";
