import { formatHallWorkHours, loadManagerHall } from "../../lounge/data/managerHallStorage";

export function getWorkHoursCaption() {
  const hall = loadManagerHall();
  return `السبت — الخميس · ${formatHallWorkHours(hall.workHoursFrom, hall.workHoursTo)}`;
}

/** بيانات الرسم — فارغة حتى تُسجَّل جلسات لعب فعلية */
export function getWorkHoursChartData() {
  return [];
}
