import { cn } from "@/lib/utils";

export default function WorkingHoursBadge({ hours, className }) {
  const label = hours?.trim() || "غير محدد";
  const isUnset = label === "غير محدد";

  return (
    <span
      className={cn(
        "inline-flex max-w-[240px] rounded-full border px-3 py-1 text-[11px] font-semibold leading-relaxed",
        isUnset
          ? "border-gray-300/40 bg-gray-500/10 text-gray-400 dark:border-gray-700 dark:bg-zinc-800 dark:text-gray-500"
          : "border-cyan-500/25 bg-cyan-500/10 text-cyan-800 dark:border-cyan-400/30 dark:bg-cyan-500/10 dark:text-cyan-200",
        className,
      )}
      title={label}
    >
      {label}
    </span>
  );
}
