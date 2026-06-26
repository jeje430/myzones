import { apiClient, mapApiErrorMessage } from "../../../shared/api/apiClient";
import { resolveStationMediaUrl } from "../../../shared/utils/resolveStationMediaUrl";

function mapLounge(item) {
  if (!item) return null;

  const services = Array.isArray(item.services)
    ? item.services
    : Object.values(item.services || {});

  return {
    id: String(item.id),
    name: item.name || item.hallName || "",
    hallName: item.name || item.hallName || "",
    city: item.city || "",
    address: item.address || "",
    location: item.location || item.address || item.city || "",
    description: item.description || "",
    phone: item.phone || "",
    mapLink: item.map_link || item.mapLink || "",
    image: resolveStationMediaUrl(item.image_url || item.cover_image || item.image || ""),
    latitude: item.latitude,
    longitude: item.longitude,
    opensAt: item.opens_at || item.opensAt,
    closesAt: item.closes_at || item.closesAt,
    averageRating: Number(item.average_rating ?? item.averageRating ?? 0),
    reviewsCount: Number(item.reviews_count ?? item.reviewsCount ?? 0),
    isOpen: Boolean(item.is_open ?? item.isOpen),
    services,
    devices: item.devices || [],
    reviews: item.reviews || [],
  };
}

export async function fetchLoungesCatalog(params = {}) {
  try {
    const { data } = await apiClient.get("/lounges", { params });
    const list = Array.isArray(data) ? data : data?.data || [];
    return { ok: true, lounges: list.map(mapLounge).filter(Boolean) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error), lounges: [] };
  }
}

export async function fetchLoungeById(loungeId) {
  try {
    const { data } = await apiClient.get(`/lounges/${loungeId}`);
    return { ok: true, lounge: mapLounge(data) };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
