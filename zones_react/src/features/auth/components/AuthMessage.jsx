import { cn } from "@/lib/utils";

export default function AuthMessage({ tone, children }) {
  return (
    <div
      className={cn(
        "rounded-xl border px-3 py-2.5 text-xs font-semibold leading-relaxed",
        tone === "error"
          ? "border-red-200/80 bg-red-50 text-red-700 dark:border-red-900/50 dark:bg-red-950/40 dark:text-red-300"
          : "border-[#6B5478]/25 bg-[#6B5478]/10 text-[#6B5478] dark:border-[#6B5478]/35 dark:bg-[#6B5478]/15 dark:text-[#d4c4de]",
      )}
      role={tone === "error" ? "alert" : "status"}
    >
      {children}
    </div>
  );
}
