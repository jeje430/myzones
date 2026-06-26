import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { applyBrandingToDocument } from "../branding/applyBrandingToDocument";
import {
  DEFAULT_PLATFORM_NAME,
  ZONES_LOGO_FALLBACK,
} from "../branding/brandingConstants";
import {
  fetchPublicBrandingSettings,
  mapBrandingPayload,
} from "../../features/super-admin/data/brandingApi";

const BrandingContext = createContext(null);

const INITIAL_BRANDING = mapBrandingPayload();

export function BrandingProvider({ children }) {
  const [platformName, setPlatformName] = useState(INITIAL_BRANDING.platformName);
  const [logoUrl, setLogoUrl] = useState(INITIAL_BRANDING.logoUrl);
  const [loading, setLoading] = useState(true);

  const logoSrc = logoUrl || ZONES_LOGO_FALLBACK;

  const applyBranding = useCallback((payload) => {
    const mapped = mapBrandingPayload(payload);
    setPlatformName(mapped.platformName);
    setLogoUrl(mapped.logoUrl);
    return mapped;
  }, []);

  const refreshBranding = useCallback(async () => {
    setLoading(true);
    const result = await fetchPublicBrandingSettings();
    if (result.ok) {
      applyBranding({
        platform_name: result.branding.platformName,
        logo_url: result.branding.logoUrl,
      });
    }
    setLoading(false);
    return result;
  }, [applyBranding]);

  useEffect(() => {
    refreshBranding();
  }, [refreshBranding]);

  useEffect(() => {
    applyBrandingToDocument({ platformName, logoSrc });
  }, [platformName, logoSrc]);

  const value = useMemo(
    () => ({
      platformName: platformName || DEFAULT_PLATFORM_NAME,
      logoUrl,
      logoSrc,
      loading,
      applyBranding,
      refreshBranding,
    }),
    [platformName, logoUrl, logoSrc, loading, applyBranding, refreshBranding],
  );

  return <BrandingContext.Provider value={value}>{children}</BrandingContext.Provider>;
}

export function useBranding() {
  const context = useContext(BrandingContext);
  if (!context) {
    throw new Error("useBranding must be used within BrandingProvider");
  }
  return context;
}
