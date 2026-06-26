import { useEffect, useState } from "react";
import { User } from "lucide-react";
import { resolveMediaUrl } from "../utils/resolveMediaUrl";

function initialsFromName(name) {
  const parts = String(name || "")
    .trim()
    .split(/\s+/)
    .filter(Boolean);
  if (!parts.length) return "؟";
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0] || ""}${parts[1][0] || ""}`.toUpperCase();
}

const SIZE_MAP = {
  xs: "h-8 w-8 text-[10px]",
  sm: "h-9 w-9 text-xs",
  md: "h-12 w-12 text-sm",
  lg: "h-24 w-24 text-xl",
  xl: "h-28 w-28 text-2xl",
};

/**
 * Circular user avatar with image or dark-mode fallback (initials / icon).
 */
export default function UserAvatar({
  src,
  name = "",
  size = "sm",
  className = "",
  ring = true,
  rounded = "full",
}) {
  const [broken, setBroken] = useState(false);

  useEffect(() => {
    setBroken(false);
  }, [src]);

  const sizeCls = SIZE_MAP[size] || SIZE_MAP.sm;
  const radiusCls = rounded === "lg" ? "rounded-lg" : "rounded-full";
  const ringCls = ring
    ? "ring-2 ring-[#6B5478]/30 dark:ring-[#c4b5d0]/25"
    : "";

  const showImage = Boolean(src) && !broken;
  const resolvedSrc = resolveMediaUrl(src);

  if (showImage && resolvedSrc) {
    return (
      <img
        src={resolvedSrc}
        alt={name || "صورة المستخدم"}
        className={`shrink-0 object-cover ${radiusCls} ${sizeCls} ${ringCls} ${className}`}
        onError={() => setBroken(true)}
      />
    );
  }

  const label = initialsFromName(name);

  return (
    <span
      className={`inline-flex shrink-0 items-center justify-center bg-[#6B5478]/15 font-bold text-[#6B5478] dark:bg-[#6B5478]/25 dark:text-[#d4c4e0] ${radiusCls} ${sizeCls} ${ringCls} ${className}`}
      aria-hidden={!name}
      title={name || undefined}
    >
      {label !== "؟" ? (
        label
      ) : (
        <User className={size === "lg" || size === "xl" ? "h-10 w-10" : "h-4 w-4"} />
      )}
    </span>
  );
}

export { initialsFromName };
