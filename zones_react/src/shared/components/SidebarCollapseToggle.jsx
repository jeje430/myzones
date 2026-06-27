import { ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";

export default function SidebarCollapseToggle({ sidebarOpen, onClick, className }) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-label={sidebarOpen ? "إغلاق القائمة" : "فتح القائمة"}
      title={sidebarOpen ? "إغلاق القائمة" : "فتح القائمة"}
      className={cn(
        "sidebar-collapse-toggle inline-flex h-8 w-8 min-h-8 min-w-8 shrink-0 items-center justify-center rounded-full border border-[#5a4668]/50 bg-[#6B5478] p-0 text-[#e8dff0] shadow-sm transition hover:bg-[#5a4668] hover:text-white",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[#e8dff0]/50 focus-visible:ring-offset-2 focus-visible:ring-offset-[#6B5478]",
        className,
      )}
    >
      {sidebarOpen ? (
        <ChevronRight size={14} strokeWidth={2.5} aria-hidden />
      ) : (
        <ChevronLeft size={14} strokeWidth={2.5} aria-hidden />
      )}
    </button>
  );
}
