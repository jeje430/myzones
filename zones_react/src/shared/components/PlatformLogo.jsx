import { useBranding } from "../context/BrandingContext";

const VARIANT_CLASS = {
  default: "object-contain",
  avatar: "h-full w-full object-cover scale-[1.18]",
};

export default function PlatformLogo({
  alt,
  className = "",
  style,
  variant = "default",
  ...imgProps
}) {
  const { logoSrc, platformName } = useBranding();
  const fitClass = VARIANT_CLASS[variant] || VARIANT_CLASS.default;

  return (
    <img
      src={logoSrc}
      alt={alt || platformName}
      className={[fitClass, className].filter(Boolean).join(" ")}
      style={style}
      {...imgProps}
    />
  );
}
