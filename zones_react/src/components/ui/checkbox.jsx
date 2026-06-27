import { useEffect, useRef } from "react";
import { cn } from "@/lib/utils";

const CHECKBOX_CLASS =
  "zones-table-checkbox h-[18px] w-[18px] shrink-0 cursor-pointer rounded-[4px] border-2 border-gray-300 bg-white accent-[#6B5478] dark:border-gray-500 dark:bg-gray-900";

export function Checkbox({ className, checked, onCheckedChange, ...props }) {
  return (
    <input
      type="checkbox"
      checked={Boolean(checked)}
      onChange={(event) => onCheckedChange?.(event.target.checked)}
      className={cn(CHECKBOX_CLASS, className)}
      {...props}
    />
  );
}

export function SelectAllCheckbox({ className, checked, onCheckedChange, ...props }) {
  const ref = useRef(null);

  useEffect(() => {
    if (!ref.current) return;
    ref.current.indeterminate = checked === "indeterminate";
    ref.current.checked = checked === true;
  }, [checked]);

  return (
    <input
      ref={ref}
      type="checkbox"
      checked={checked === true}
      onChange={(event) => onCheckedChange?.(event.target.checked)}
      className={cn(CHECKBOX_CLASS, className)}
      {...props}
    />
  );
}
