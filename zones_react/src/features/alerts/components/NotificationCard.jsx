import { cn } from "@/lib/utils";
import { alertSeverityMeta } from "../data/alertsMeta";

/**
 * بطاقة تنبيه — تخطيط RTL واسع للعرض في النوافذ والسجلات.
 */
export default function NotificationCard({
  title,
  dateTime,
  description,
  instructions,
  severity,
  badge,
  className = "",
  compact = false,
}) {
  const severityMeta = severity ? alertSeverityMeta(severity) : null;

  return (
    <article
      className={cn(
        "rounded-2xl border border-gray-200/80 bg-white/90 shadow-sm dark:border-gray-700/80 dark:bg-gray-900/80",
        compact ? "px-5 py-4" : "px-6 py-[18px]",
        className,
      )}
      dir="rtl"
    >
      <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-x-5 gap-y-3">
        <div className="min-w-0 space-y-2 text-right">
          <h3
            className={cn(
              "font-bold leading-snug tracking-tight text-gray-900 dark:text-white",
              compact ? "text-base" : "text-[1.1rem]",
            )}
          >
            {title || "—"}
          </h3>

          {description ? (
            <p
              className={cn(
                "font-medium leading-relaxed text-gray-500 dark:text-gray-400",
                compact ? "text-sm" : "text-[0.95rem]",
              )}
            >
              {description}
            </p>
          ) : null}

          {instructions ? (
            <div className="rounded-xl border border-amber-500/25 bg-amber-500/10 px-4 py-3 dark:border-amber-500/30 dark:bg-amber-500/10">
              <p className="text-xs font-bold text-amber-800 dark:text-amber-300">التعليمات</p>
              <p className="mt-1.5 text-sm leading-relaxed text-amber-900/90 dark:text-amber-100/90">
                {instructions}
              </p>
            </div>
          ) : null}
        </div>

        <div className="flex shrink-0 flex-col items-end gap-2.5">
          {dateTime ? (
            <p className="text-xs font-semibold text-gray-500 dark:text-gray-400" dir="ltr">
              {dateTime}
            </p>
          ) : null}

          {badge ?? (severityMeta ? (
            <span
              className={cn(
                "inline-flex shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold",
                severityMeta.badgeClass,
              )}
            >
              {severityMeta.label}
            </span>
          ) : null)}
        </div>
      </div>
    </article>
  );
}
