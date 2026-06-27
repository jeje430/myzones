import { useEffect, useId, useRef, useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";
import { cn } from "@/lib/utils";
import SearchBar from "../../features/super-admin/components/ui/SearchBar";
import "../../features/employees/components/ReceptionBookingsDateNav.css";

export function RoleCycleFilter({ options = [], value, onChange, ariaLabel = "تصفية حسب النوع" }) {
  const listId = useId();
  const rootRef = useRef(null);
  const [open, setOpen] = useState(false);

  const selectedIndex = Math.max(0, options.findIndex((o) => o.value === value));
  const selected = options[selectedIndex] || options[0];

  const shift = (delta) => {
    if (!options.length) return;
    const next = (selectedIndex + delta + options.length) % options.length;
    onChange(options[next].value);
    setOpen(false);
  };

  useEffect(() => {
    if (!open) return undefined;
    const onDoc = (e) => {
      if (!rootRef.current?.contains(e.target)) setOpen(false);
    };
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  if (!options.length) return null;

  return (
    <div className="rb-date-nav rb-date-nav--inline shrink-0" ref={rootRef}>
      <div className="rb-date-nav-bar rb-source-filter-bar">
        <button type="button" className="rb-date-nav-arrow" onClick={() => shift(-1)} aria-label="الخيار السابق">
          <ChevronRight size={15} strokeWidth={2.25} />
        </button>
        <button
          type="button"
          className="rb-date-nav-trigger rb-source-filter-trigger"
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          aria-haspopup="listbox"
          aria-controls={listId}
        >
          <span className="rb-date-nav-label">{selected?.label}</span>
        </button>
        <button type="button" className="rb-date-nav-arrow" onClick={() => shift(1)} aria-label="الخيار التالي">
          <ChevronLeft size={15} strokeWidth={2.25} />
        </button>
      </div>
      {open ? (
        <ul id={listId} role="listbox" className="rb-source-filter-menu" aria-label={ariaLabel}>
          {options.map((item) => {
            const active = item.value === value;
            return (
              <li key={item.value} role="option" aria-selected={active}>
                <button
                  type="button"
                  className={cn("rb-source-filter-option", active && "rb-source-filter-option--active")}
                  onClick={() => {
                    onChange(item.value);
                    setOpen(false);
                  }}
                >
                  {item.label}
                </button>
              </li>
            );
          })}
        </ul>
      ) : null}
    </div>
  );
}

/** شريط موحّد — بحث + فلتر بأسهم (+ إجراءات) مثل صفحة حجوزات الاستقبال. */
export default function StaffFilterSearchToolbar({
  filters = [],
  activeFilter,
  onFilterChange,
  search,
  onSearchChange,
  searchPlaceholder = "بحث...",
  filterAriaLabel = "تصفية حسب النوع",
  actions = null,
  className = "",
  embedded = false,
}) {
  const filterOptions = filters.map((item) => ({ value: item.key, label: item.label }));
  const showFilter = filterOptions.length > 0 && typeof onFilterChange === "function";

  return (
    <div
      className={cn(
        "flex w-full flex-wrap items-center gap-3",
        embedded ? "border-b border-gray-100 px-5 py-3 dark:border-gray-800" : "mb-6",
        className,
      )}
    >
      {search !== undefined && onSearchChange ? (
        <SearchBar
          value={search}
          onChange={onSearchChange}
          placeholder={searchPlaceholder}
          containerClassName="min-w-[180px] flex-1 max-w-md"
        />
      ) : null}

      {showFilter ? (
        <RoleCycleFilter
          options={filterOptions}
          value={activeFilter}
          onChange={onFilterChange}
          ariaLabel={filterAriaLabel}
        />
      ) : null}

      {actions ? <div className="ms-auto flex shrink-0 items-center gap-2">{actions}</div> : null}
    </div>
  );
}
