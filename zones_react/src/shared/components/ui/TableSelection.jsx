import { CheckSquare, RotateCcw, X } from "lucide-react";
import { Checkbox, SelectAllCheckbox } from "@/components/ui/checkbox";
import IconButton from "./IconButton";
import TableActionsGroup from "./TableActionsGroup";
import { SELECT_COL_TD, SELECT_COL_TH } from "./tableActionStyles";

const ACTION_TONE = {
  success: "success",
  danger: "danger",
  dangerOutline: "warning",
  warning: "warning",
  outline: "brand",
  primary: "brand",
  ghost: "muted",
};

export function selectableRowClass(isSelected, base = "transition hover:bg-gray-50 dark:hover:bg-gray-800/50") {
  return `${base}${isSelected ? " bg-[#6B5478]/6 dark:bg-[#6B5478]/12" : ""}`;
}

export function TableSelectHeaderCell({
  selectionMode = true,
  masterChecked,
  toggleSelectAll,
  ariaLabel = "تحديد الكل",
}) {
  if (!selectionMode) return null;

  return (
    <th className={SELECT_COL_TH}>
      <SelectAllCheckbox
        checked={masterChecked}
        onCheckedChange={toggleSelectAll}
        aria-label={ariaLabel}
        className="mx-auto"
      />
    </th>
  );
}

export function TableSelectRowCell({
  selectionMode = true,
  id,
  isSelected,
  toggleRow,
  ariaLabel,
}) {
  if (!selectionMode) return null;

  return (
    <td className={SELECT_COL_TD}>
      <Checkbox
        checked={isSelected(id)}
        onCheckedChange={() => toggleRow(id)}
        aria-label={ariaLabel}
        className="mx-auto"
      />
    </td>
  );
}

/**
 * Toolbar: «تحديد» reveals checkboxes; bulk icon actions match table row actions column.
 */
export function TableSelectionModeBar({
  selectionMode,
  onEnter,
  onExit,
  count = 0,
  totalCount = 0,
  onClear,
  actions = [],
  disabled = false,
  label = "تحديد",
}) {
  if (!selectionMode) {
    return (
      <div className="flex justify-end border-b border-gray-100 px-5 py-2.5 dark:border-gray-800">
        <IconButton
          icon={CheckSquare}
          label={label}
          tone="brand"
          onClick={onEnter}
          disabled={disabled || totalCount === 0}
        />
      </div>
    );
  }

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#6B5478]/25 bg-[#6B5478]/8 px-5 py-3 transition-all duration-300 dark:border-[#6B5478]/35 dark:bg-[#6B5478]/15">
      <p className="text-xs font-bold text-[#6B5478] dark:text-[#c4b0d4]">
        {count > 0 ? `تم تحديد ${count} عنصر` : "اختر العناصر من الجدول"}
      </p>
      <TableActionsGroup className="gap-1">
        {count > 0
          ? actions.map((action) => {
              const Icon = action.icon;
              const tone = action.tone || ACTION_TONE[action.variant] || "brand";
              return (
                <IconButton
                  key={action.label}
                  icon={Icon}
                  label={action.label}
                  tone={tone}
                  onClick={action.onClick}
                />
              );
            })
          : null}
        {count > 0 ? (
          <IconButton icon={RotateCcw} label="إلغاء التحديد" tone="muted" onClick={onClear} />
        ) : null}
        <IconButton icon={X} label="إنهاء التحديد" tone="muted" onClick={onExit} />
      </TableActionsGroup>
    </div>
  );
}

/** @deprecated Prefer TableSelectionModeBar */
export function TableBulkActionBar({ count, onClear, actions = [] }) {
  if (!count) return null;

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-b border-[#6B5478]/25 bg-[#6B5478]/8 px-5 py-3 dark:border-[#6B5478]/35 dark:bg-[#6B5478]/15">
      <p className="text-xs font-bold text-[#6B5478] dark:text-[#c4b0d4]">تم تحديد {count} عنصر</p>
      <TableActionsGroup>
        {actions.map((action) => {
          const Icon = action.icon;
          const tone = action.tone || ACTION_TONE[action.variant] || "brand";
          return (
            <IconButton key={action.label} icon={Icon} label={action.label} tone={tone} onClick={action.onClick} />
          );
        })}
        <IconButton icon={X} label="إلغاء التحديد" tone="muted" onClick={onClear} />
      </TableActionsGroup>
    </div>
  );
}
