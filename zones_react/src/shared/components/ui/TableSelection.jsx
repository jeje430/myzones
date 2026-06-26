import { X } from "lucide-react";
import { Checkbox } from "@/components/ui/checkbox";
import Button from "../../../features/super-admin/components/ui/Button";
import { SELECT_COL_TD, SELECT_COL_TH } from "./tableActionStyles";

const CHECKBOX_CLASS =
  "mx-auto ring-offset-white data-[state=checked]:shadow-[0_0_0_2px_rgba(107,84,120,0.25)] dark:ring-offset-gray-900";

export function selectableRowClass(isSelected, base = "transition hover:bg-gray-50 dark:hover:bg-gray-800/50") {
  return `${base}${isSelected ? " bg-[#6B5478]/6 dark:bg-[#6B5478]/12" : ""}`;
}

export function TableSelectHeaderCell({ masterChecked, toggleSelectAll, ariaLabel = "تحديد الكل" }) {
  return (
    <th className={SELECT_COL_TH}>
      <Checkbox
        checked={masterChecked}
        onCheckedChange={toggleSelectAll}
        aria-label={ariaLabel}
        className={CHECKBOX_CLASS}
      />
    </th>
  );
}

export function TableSelectRowCell({ id, isSelected, toggleRow, ariaLabel }) {
  return (
    <td className={SELECT_COL_TD}>
      <Checkbox
        checked={isSelected(id)}
        onCheckedChange={() => toggleRow(id)}
        aria-label={ariaLabel}
        className={CHECKBOX_CLASS}
      />
    </td>
  );
}

/**
 * @param {{ count: number, onClear: () => void, actions?: Array<{ label: string, icon?: import('react').ComponentType, onClick: () => void, variant?: string }> }} props
 */
export function TableBulkActionBar({ count, onClear, actions = [] }) {
  if (!count) return null;

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#6B5478]/25 bg-[#6B5478]/8 px-5 py-3 transition-all duration-300 dark:border-[#6B5478]/35 dark:bg-[#6B5478]/15">
      <p className="text-xs font-bold text-[#6B5478] dark:text-[#c4b0d4]">تم تحديد {count} عنصر</p>
      <div className="flex flex-wrap items-center gap-2">
        {actions.map((action) => {
          const Icon = action.icon;
          return (
            <Button key={action.label} size="sm" variant={action.variant || "outline"} onClick={action.onClick}>
              {Icon ? <Icon className="h-4 w-4" /> : null}
              {action.label}
            </Button>
          );
        })}
        <button
          type="button"
          onClick={onClear}
          className="inline-flex items-center gap-1 rounded-lg border border-gray-200 bg-white px-3 py-1.5 text-[11px] font-bold text-gray-600 transition hover:border-gray-300 hover:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-gray-300 dark:hover:bg-gray-800"
        >
          <X className="h-3.5 w-3.5" />
          إلغاء التحديد
        </button>
      </div>
    </div>
  );
}
