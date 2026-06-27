import { useEffect } from "react";
import { cn } from "@/lib/utils";

const SIZE_CLASS = {
  sm: "max-w-md",
  md: "max-w-lg",
  lg: "max-w-2xl",
  xl: "max-w-4xl",
};

/**
 * غلاف موحّد للنوافذ المنبثقة — UI فقط، بدون منطق أعمال.
 */
export default function ZonesModalShell({
  open,
  onClose,
  title,
  titleId = "zones-modal-title",
  children,
  footer,
  size = "md",
  className,
  panelClassName,
}) {
  useEffect(() => {
    if (!open) return undefined;
    const onKeyDown = (event) => {
      if (event.key === "Escape") onClose?.();
    };
    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-[1200] flex items-center justify-center bg-black/50 p-4 backdrop-blur-[1px]"
      dir="rtl"
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? titleId : undefined}
      onClick={(event) => {
        if (event.target === event.currentTarget) onClose?.();
      }}
    >
      <div
        className={cn(
          "flex max-h-[min(92vh,900px)] w-full flex-col overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl",
          "dark:border-[rgba(167,139,189,0.42)] dark:bg-gray-900",
          SIZE_CLASS[size] || SIZE_CLASS.md,
          panelClassName,
        )}
      >
        {title ? (
          <div className="flex items-center justify-between gap-3 border-b border-gray-100 px-5 py-4 dark:border-[rgba(167,139,189,0.28)]">
            <h2 id={titleId} className="text-sm font-extrabold text-gray-900 dark:text-white">
              {title}
            </h2>
            {onClose ? (
              <button
                type="button"
                onClick={onClose}
                className="zones-modal-close-btn rounded-lg px-2 py-1 text-xs font-bold text-gray-500 transition hover:bg-gray-100 hover:text-gray-800 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#6B5478]/40 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-200"
                aria-label="إغلاق"
              >
                ✕
              </button>
            ) : null}
          </div>
        ) : null}

        <div className={cn("flex-1 overflow-y-auto px-5 py-4", className)}>{children}</div>

        {footer ? (
          <div className="flex flex-wrap items-center justify-end gap-2 border-t border-gray-100 px-5 py-3 dark:border-[rgba(167,139,189,0.28)]">
            {footer}
          </div>
        ) : null}
      </div>
    </div>
  );
}
