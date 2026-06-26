import PlatformLogo from "./PlatformLogo";
import { useBranding } from "../context/BrandingContext";

export default function Logo() {
  const { platformName } = useBranding();

  return (
    <div className="zones-logo">
      <PlatformLogo />
      <span>{platformName}</span>
    </div>
  );
}
