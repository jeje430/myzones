import { cn } from "@/lib/utils";

/**
 * Renders the associated hall for staff rows (assigned branch, global, or unassigned).
 */
export default function AssociatedHallBadge({
  hallName = "",
  hallScope = "",
  hallLabel = "",
  className,
}) {
  const scope = hallScope || (hallName ? "assigned" : "unassigned");
  const label = hallLabel || hallName || "غير مرتبطة";

  if (scope === "global") {
    return (
      <span
        className={cn(
          "inline-flex max-w-[220px] items-center rounded-full border border-amber-400/45 bg-amber-500/10 px-3 py-1 text-xs font-bold text-amber-700 dark:border-amber-300/35 dark:bg-amber-400/10 dark:text-amber-200",
          className,
        )}
      >
        {label}
      </span>
    );
  }

  if (scope === "assigned" && hallName) {
    return (
      <span
        className={cn(
          "inline-flex max-w-[220px] truncate rounded-full bg-slate-500/10 px-3 py-1 text-xs font-semibold text-slate-600 dark:bg-zinc-700/60 dark:text-slate-300",
          className,
        )}
        title={hallName}
      >
        {hallName}
      </span>
    );
  }

  return (
    <span
      className={cn(
        "inline-flex rounded-full bg-gray-500/10 px-3 py-1 text-xs font-medium text-gray-400 dark:bg-zinc-800 dark:text-gray-500",
        className,
      )}
    >
      {label}
    </span>
  );
}
