import PaymentsCalendarPicker from "./PaymentsCalendarPicker";

export default function PaymentsDateFilter({
  selectedDate,
  showAll,
  onDateChange,
  onShowAll,
  onPrevDay,
  onNextDay,
}) {
  return (
    <PaymentsCalendarPicker
      value={selectedDate}
      showAll={showAll}
      onChange={onDateChange}
      onPrevDay={onPrevDay}
      onNextDay={onNextDay}
      onShowAll={onShowAll}
    />
  );
}

export { localTodayIso, shiftLocalIsoDate } from "../../../shared/utils/localDateUtils";
