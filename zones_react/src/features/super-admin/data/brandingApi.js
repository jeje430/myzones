import { apiClient, mapApiErrorMessage, postMultipart } from "../../../shared/api/apiClient";
import {
  DEFAULT_PLATFORM_NAME,
  ZONES_LOGO_FALLBACK,
} from "../../../shared/branding/brandingConstants";
import { getSuperAdminToken } from "./superAdminAuth";

function authHeaders() {
  const token = getSuperAdminToken();
  return token ? { Authorization: `Bearer ${token}` } : {};
}

export function mapBrandingPayload(payload = {}) {
  const platformName = payload.platform_name || DEFAULT_PLATFORM_NAME;
  const logoUrl = payload.logo_url || null;

  return {
    platformName,
    logoUrl,
    logoSrc: logoUrl || ZONES_LOGO_FALLBACK,
  };
}

export async function fetchPublicBrandingSettings() {
  try {
    const { data } = await apiClient.get("/public/branding-settings");
    return {
      ok: true,
      branding: mapBrandingPayload(data),
    };
  } catch (error) {
    return {
      ok: false,
      error: mapApiErrorMessage(error),
      branding: mapBrandingPayload(),
    };
  }
}

export async function updateBrandingSettings({ platformName }) {
  try {
    const { data } = await apiClient.patch(
      "/super-admin/branding/settings",
      { platform_name: platformName },
      { headers: authHeaders() },
    );

    return {
      ok: true,
      branding: mapBrandingPayload(data.branding),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}

export async function uploadPlatformLogo(file) {
  try {
    const formData = new FormData();
    formData.append("logo", file);

    const { data } = await postMultipart("/super-admin/branding/logo", formData);

    return {
      ok: true,
      branding: mapBrandingPayload(data.branding),
      message: data.message,
    };
  } catch (error) {
    return { ok: false, error: mapApiErrorMessage(error) };
  }
}
