import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

function mapApiPayment(row) {
  return {
    id: row.id,
    transactionRef: row.transaction_ref || "",
    customerName: row.customer_name || "—",
    bookingId: row.booking_id,
    bookingNumber: row.booking_number || "",
    bookingDetails: row.booking_details
      ? {
          startDate: row.booking_details.start_date || "",
          startTime: row.booking_details.start_time || "",
          endTime: row.booking_details.end_time || "",
          hoursCount: row.booking_details.hours_count || 0,
        }
      : null,
    amount: Number(row.amount) || 0,
    paymentMethod: row.payment_method || "",
    status: row.status || "",
    paidAt: row.paid_at || "",
  };
}

export async function fetchManagerPayments({ paymentMethod = null, date = null, showAll = false } = {}) {
  try {
    const params = {};
    if (paymentMethod && paymentMethod !== "all") {
      params.payment_method = paymentMethod;
    }
    if (showAll) {
      params.show_all = 1;
    } else if (date) {
      params.date = date;
    }

    const { data } = await apiClient.get("/manager/finance/payments", { params });

    return {
      ok: true,
      payments: (data.payments || []).map(mapApiPayment),
      filter: {
        date: data.filter?.date || null,
        showAll: Boolean(data.filter?.show_all),
      },
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), payments: [] };
  }
}
