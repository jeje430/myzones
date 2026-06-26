import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { normalizeGmailEmail } from "../../../shared/utils/normalizeGmailEmail";

export function notifyHallJoinRequestsUpdated() {
  if (typeof window !== "undefined") {
    window.dispatchEvent(new CustomEvent("hall-join-requests-updated"));
  }
}

export async function submitHallJoinRequest({
  hallName,
  address,
  mapLink,
  email,
  managerName,
  commercialPhone,
  images = [],
}) {
  const trimmedHall = String(hallName || "").trim();
  const trimmedAddress = String(address || "").trim();
  const trimmedMap = String(mapLink || "").trim();
  const normalizedEmail = normalizeGmailEmail(email);
  const trimmedManagerName = String(managerName || "").trim();
  const trimmedPhone = String(commercialPhone || "").trim();

  if (!trimmedHall || !trimmedAddress || !trimmedMap || !normalizedEmail || !trimmedManagerName || !trimmedPhone) {
    return { ok: false, error: "يرجى تعبئة جميع الحقول المطلوبة." };
  }

  try {
    const { data } = await apiClient.post("/hall-join-requests", {
      hall_name: trimmedHall,
      address: trimmedAddress,
      map_link: trimmedMap,
      email: normalizedEmail,
      manager_name: trimmedManagerName,
      commercial_phone: trimmedPhone,
      images: images.slice(0, 5),
    });

    notifyHallJoinRequestsUpdated();
    return { ok: true, request: data.request };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
