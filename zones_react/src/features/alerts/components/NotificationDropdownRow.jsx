import { Check, Square, SquareCheck, Trash2 } from "lucide-react";
import { cn } from "@/lib/utils";
import { alertSeverityMeta } from "../data/alertsMeta";
import { resolveNotificationTypeMeta } from "../notifications/notificationTypes";

function formatTimestampParts(value) {
  const text = String(value || "").trim();
  if (!text) return { date: "", time: "" };
  const segments = text.split(/\s+/);
  if (segments.length <= 1) return { date: text, time: "" };
  return { date: segments[0], time: segments.slice(1).join(" ") };
}

export default function NotificationDropdownRow({
  item,
  selectionMode,
  selected,
  onToggleSelect,
  onOpen,
  onDelete,
  onMarkRead,
}) {
  const meta = resolveNotificationTypeMeta(item.type);
  const Icon = meta.Icon;
  const severityMeta = item.severity ? alertSeverityMeta(item.severity) : null;
  const showSeverity = severityMeta && item.type.includes("manager");
  const { date, time } = formatTimestampParts(item.createdAt);

  return (
    <article
      dir="rtl"
      className={cn(
        "group relative rounded-2xl border transition-colors",
        "px-6 py-[18px]",
        item.isRead
          ? cn("border-gray-200/50 bg-gray-50/30 dark:border-gray-800/60 dark:bg-gray-900/25", meta.readClass)
          : cn("border-gray-200/70 shadow-sm dark:border-gray-700/70 dark:shadow-none", meta.unreadClass),
      )}
    >
      <div className="grid grid-cols-[minmax(0,1fr)_auto] items-start gap-x-5 gap-y-3">
        {selectionMode ? (
          <button
            type="button"
            onClick={() => onToggleSelect(item.id)}
            className="absolute start-3 top-3 text-[#6B5478] dark:text-[#c4b5d0]"
            aria-label={selected ? "إلغاء التحديد" : "تحديد الإشعار"}
          >
            {selected ? <SquareCheck size={18} /> : <Square size={18} />}
          </button>
        ) : null}

        {/* Start (RTL right): icon + title stack */}
        <div className={cn("flex min-w-0 items-start gap-4", selectionMode && "pe-7")}>
          <div className="relative shrink-0">
            <span
              className={cn(
                "flex h-11 w-11 items-center justify-center rounded-2xl bg-white/80 shadow-sm dark:bg-gray-900/70",
                item.isRead && "opacity-70",
              )}
            >
              <Icon size={20} className={meta.iconClass} />
            </span>
            {!item.isRead ? (
              <span
                className="absolute -top-0.5 -start-0.5 h-2.5 w-2.5 rounded-full border-2 border-white bg-red-500 shadow-sm dark:border-gray-950"
                aria-hidden
              />
            ) : null}
          </div>

          <button
            type="button"
            onClick={() => onOpen(item)}
            className="min-w-0 flex-1 text-right"
          >
            <div className="flex items-start gap-2">
              <h4
                className={cn(
                  "text-[1.1rem] font-bold leading-snug tracking-tight",
                  item.isRead
                    ? "text-gray-500 dark:text-gray-400"
                    : "text-gray-900 dark:text-gray-50",
                )}
              >
                {item.title || "إشعار"}
              </h4>
            </div>

            {item.body ? (
              <p
                className={cn(
                  "mt-2 text-sm font-medium leading-relaxed",
                  item.isRead
                    ? "text-gray-400 dark:text-gray-500"
                    : "text-gray-500 dark:text-gray-400",
                )}
              >
                {item.body}
              </p>
            ) : null}

            {item.instructions ? (
              <p className="mt-2 text-sm leading-relaxed text-gray-500 dark:text-gray-400">
                {item.instructions}
              </p>
            ) : null}
          </button>
        </div>

        {/* End (RTL left): timestamp, badge, actions */}
        <div className="flex min-w-[6.75rem] shrink-0 flex-col items-end justify-start gap-3 ps-1">
          {item.createdAt ? (
            <div className="text-end leading-tight" dir="ltr">
              {date ? (
                <p className="text-xs font-semibold text-gray-500 dark:text-gray-400">{date}</p>
              ) : null}
              {time ? (
                <p className="mt-0.5 text-[11px] font-medium text-gray-400 dark:text-gray-500">{time}</p>
              ) : null}
            </div>
          ) : null}

          {showSeverity ? (
            <span
              className={cn(
                "inline-flex shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold",
                severityMeta.badgeClass,
              )}
            >
              {severityMeta.label}
            </span>
          ) : null}

          {!selectionMode ? (
            <div
              className={cn(
                "flex flex-row items-center gap-3 transition-opacity duration-200",
                "opacity-100 md:opacity-0 md:group-hover:opacity-100 md:group-focus-within:opacity-100",
              )}
            >
              {!item.isRead ? (
                <button
                  type="button"
                  onClick={() => onMarkRead(item)}
                  className="inline-flex h-9 w-9 items-center justify-center rounded-xl text-gray-400 transition hover:bg-gray-100 hover:text-[#6B5478] dark:hover:bg-gray-800 dark:hover:text-[#c4b5d0]"
                  title="تعليم كمقروء"
                  aria-label="تعليم كمقروء"
                >
                  <Check size={17} />
                </button>
              ) : null}
              <button
                type="button"
                onClick={() => onDelete(item)}
                className="inline-flex h-9 w-9 items-center justify-center rounded-xl text-gray-400 transition hover:bg-red-500/10 hover:text-red-500 dark:hover:bg-red-950/30 dark:hover:text-red-400"
                title="حذف"
                aria-label="حذف الإشعار"
              >
                <Trash2 size={17} />
              </button>
            </div>
          ) : null}
        </div>
      </div>
    </article>
  );
}
