import { cn } from "@/lib/utils";
import ReceptionBookingsDateNav from "../../employees/components/ReceptionBookingsDateNav";
import "../../employees/components/ReceptionBookingsDateNav.css";

export default function PaymentsDateFilter({
  selectedDate,
  showAll,
  onDateChange,
  onShowAll,
}) {
  return (
    <div className="flex shrink-0 items-center gap-2">
      {showAll ? (
        <div className="rb-date-nav rb-date-nav--inline">
          <div className="rb-date-nav-bar rb-source-filter-bar">
            <span className="rb-date-nav-label px-3 py-2">كل الأيام</span>
          </div>
        </div>
      ) : (
        <ReceptionBookingsDateNav
          inline
          value={selectedDate}
          onChange={onDateChange}
          className="shrink-0"
        />
      )}

      <button
        type="button"
        onClick={onShowAll}
        className={cn(
          "rb-date-nav-bar rb-source-filter-bar inline-flex h-10 items-center px-3 text-[11px] font-bold transition",
          showAll
            ? "text-[#6B5478] dark:text-[#d8b4fe]"
            : "text-gray-600 hover:bg-[#6B5478]/5 dark:text-gray-300",
        )}
      >
        {showAll ? "اليوم" : "الكل"}
      </button>
    </div>
  );
}

export { localTodayIso, shiftLocalIsoDate } from "../../../shared/utils/localDateUtils";
