import { apiClient } from "../../../shared/api/apiClient";

/**
 * Fetch and open booking receipt PDF from Laravel (staff or customer token).
 */
export async function openBookingReceiptPdf(bookingId, { inline = true } = {}) {
  const response = await apiClient.get(`/bookings/${bookingId}/receipt/pdf`, {
    params: { inline: inline ? 1 : 0 },
    responseType: "blob",
    headers: { Accept: "application/pdf" },
  });

  const blob = new Blob([response.data], { type: "application/pdf" });
  const url = URL.createObjectURL(blob);
  window.open(url, "_blank", "noopener,noreferrer");
  setTimeout(() => URL.revokeObjectURL(url), 60_000);
}

/**
 * Download booking receipt PDF from Laravel.
 */
export async function downloadBookingReceiptPdf(bookingId, filename = "booking-receipt.pdf") {
  const response = await apiClient.get(`/bookings/${bookingId}/receipt/pdf`, {
    params: { inline: 0 },
    responseType: "blob",
    headers: { Accept: "application/pdf" },
  });

  const blob = new Blob([response.data], { type: "application/pdf" });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 60_000);
}
