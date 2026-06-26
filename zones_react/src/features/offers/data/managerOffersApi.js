import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";

export function mapApiOffer(row) {
  return {
    id: row.id,
    name: row.title || row.name || "",
    packageId: row.package_id ?? row.packageId ?? null,
    packageName: row.package_name || "",
    discountPercent: Number(row.discount_percent ?? row.discountPercent ?? 0),
    description: row.description || "",
    startDate: (row.valid_from || row.startDate || "").slice(0, 10),
    endDate: (row.expires_at || row.endDate || "").slice(0, 10),
    isActive: row.is_active !== false && row.isActive !== false,
    price: Number(row.discounted_price ?? row.price ?? 0),
    originalPrice: Number(row.original_price ?? 0),
    createdAt: row.created_at || row.createdAt || "—",
    usageCount: Number(row.usage_count ?? row.usageCount ?? 0),
  };
}

function toApiPayload(patch) {
  return {
    title: patch.name?.trim(),
    package_id: patch.packageId,
    discount_percent: Number(patch.discountPercent ?? 0),
    description: patch.description?.trim() || "",
    valid_from: patch.startDate,
    expires_at: patch.endDate,
    is_active: patch.isActive !== false,
  };
}

export async function fetchManagerOffers() {
  try {
    const { data } = await apiClient.get("/manager/offers");
    const list = data.offers || [];
    return { ok: true, offers: list.map(mapApiOffer) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), offers: [] };
  }
}

export async function createManagerOffer(patch) {
  try {
    const { data } = await apiClient.post("/manager/offers", toApiPayload(patch));
    return { ok: true, offer: mapApiOffer(data.offer), message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function updateManagerOffer(id, patch) {
  try {
    const { data } = await apiClient.put(`/manager/offers/${id}`, toApiPayload(patch));
    return { ok: true, offer: mapApiOffer(data.offer), message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function deleteManagerOffer(id) {
  try {
    const { data } = await apiClient.delete(`/manager/offers/${id}`);
    return { ok: true, message: data.message };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
