import { API_BASE_URL } from "../config/apiConfig";

/** يحوّل مسار الغلاف من Laravel إلى URL كامل يعمل في المتصفح */
export function resolveStationMediaUrl(pathOrUrl) {
  if (!pathOrUrl || typeof pathOrUrl !== "string") return "";

  const value = pathOrUrl.trim();
  if (!value) return "";

  if (value.startsWith("data:")) return value;

  const apiOrigin = API_BASE_URL.replace(/\/api\/?$/, "");

  if (value.startsWith("http://") || value.startsWith("https://")) {
    if (value.includes("/storage/") && apiOrigin && !value.startsWith(apiOrigin)) {
      const storagePath = value.split("/storage/")[1];
      if (storagePath) return `${apiOrigin}/storage/${storagePath}`;
    }
    return value;
  }

  const path = value.replace(/^\//, "");
  if (path.startsWith("storage/")) {
    return `${apiOrigin}/${path}`;
  }

  return `${apiOrigin}/storage/${path}`;
}
