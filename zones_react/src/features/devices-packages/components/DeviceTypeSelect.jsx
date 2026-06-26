import { ChevronDown } from "lucide-react";
import { DEVICE_TYPE_SELECT_OPTIONS } from "../data/deviceTypeOptions";

const selectCls =
  "w-full appearance-none rounded-xl border border-gray-300 bg-white py-2.5 pe-9 ps-3 text-xs font-semibold text-gray-800 outline-none focus:border-[#6B5478] focus:ring-2 focus:ring-[#6B5478]/20 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-100";

export default function DeviceTypeSelect({ value, onChange, disabled = false }) {
  const selected = DEVICE_TYPE_SELECT_OPTIONS.find((row) => row.value === value)
    ?? DEVICE_TYPE_SELECT_OPTIONS[0];
  const SelectedIcon = selected.Icon;

  return (
    <div className="relative w-full">
      <span
        className="pointer-events-none absolute right-3 top-1/2 flex -translate-y-1/2 text-[#6B5478]"
        aria-hidden
      >
        <SelectedIcon size={16} strokeWidth={2} />
      </span>
      <ChevronDown
        size={14}
        className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-gray-400"
        aria-hidden
      />
      <select
        className={selectCls}
        value={value}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        dir="rtl"
      >
        {DEVICE_TYPE_SELECT_OPTIONS.map((row) => (
          <option key={row.value} value={row.value}>
            {row.label}
          </option>
        ))}
      </select>
    </div>
  );
}
