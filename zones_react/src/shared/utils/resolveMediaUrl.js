import { API_BASE_URL } from "../config/apiConfig";

/** Origin of the Laravel app (without /api). */
export function apiOrigin() {
  return String(API_BASE_URL || "").replace(/\/api\/?$/, "");
}

/**
 * Rewrites Laravel storage URLs so images load when APP_URL is wrong (e.g. localhost on Herd).
 */
export function resolveMediaUrl(url) {
  if (!url || typeof url !== "string") return "";

  const trimmed = url.trim();
  if (!trimmed) return "";

  const origin = apiOrigin();
  if (!origin) return trimmed;

  const localhostRe = /^https?:\/\/localhost(?::\d+)?(\/.*)?$/i;
  const localhostMatch = trimmed.match(localhostRe);
  if (localhostMatch) {
    return `${origin}${localhostMatch[1] || ""}`;
  }

  if (trimmed.startsWith("/storage/")) {
    return `${origin}${trimmed}`;
  }

  const storageIdx = trimmed.indexOf("/storage/");
  if (storageIdx >= 0) {
    return `${origin}${trimmed.slice(storageIdx)}`;
  }

  if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
    const path = trimmed.replace(/^\/+/, "");
    if (path.startsWith("storage/")) return `${origin}/${path}`;
    if (path.startsWith("avatars/")) return `${origin}/storage/${path}`;
  }

  return trimmed;
}
