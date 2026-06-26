import { SHIFTS } from "../data/employeeMeta";
import { SegmentedControl } from "./employeeFormUi";

const OPTIONS = SHIFTS.map((shift) => ({
  value: shift.value,
  label: shift.value === "morning" ? "2م–8م" : "8م–2ص",
}));

export default function ShiftToggleGroup({ value, onChange, disabled }) {
  return (
    <SegmentedControl
      options={OPTIONS}
      value={value}
      onChange={onChange}
      disabled={disabled}
      ariaLabel="توقيت الدوام"
    />
  );
}
