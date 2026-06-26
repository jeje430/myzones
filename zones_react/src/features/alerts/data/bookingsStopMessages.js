import { loadManagerHall } from "../../lounge/data/managerHallStorage";

export const BOOKINGS_STOP_NAME = "إيقاف حجوزات";

export const BOOKINGS_STOP_ACTION = {
  value: "stop_bookings",
  label: BOOKINGS_STOP_NAME,
};

/** Realistic hall-level emergency reasons — mirrors Laravel BookingStopReason. */
export const BOOKINGS_STOP_REASONS = [
  { value: "power_outage", label: "انقطاع التيار" },
  { value: "bad_weather", label: "ظروف جوية سيئة" },
  { value: "hall_maintenance", label: "صيانة الصالة" },
  { value: "road_maintenance", label: "صيانة الطريق" },
  { value: "internet_outage", label: "انقطاع الإنترنت" },
  { value: "technical_issue", label: "خلل تقني" },
  { value: "emergency_closure", label: "إغلاق طارئ" },
  { value: "staff_shortage", label: "نقص في الموظفين" },
  { value: "safety_issue", label: "مشكلة أمنية" },
];

export function reasonLabelForKey(key) {
  return BOOKINGS_STOP_REASONS.find((r) => r.value === key)?.label ?? key;
}

export function getHallDisplayName() {
  const hall = loadManagerHall();
  return hall?.hallName?.trim() || "ZONES Gaming Center";
}

export function buildBookingsStopNotificationText(hallName = getHallDisplayName()) {
  return `تم إيقاف حجوزات في صالة ${hallName}. دمتم سالمين.`;
}

export function buildBookingsStartNotificationText(hallName = getHallDisplayName()) {
  return `الحجز في الصالة ${hallName} متاح الآن، يمكنك الحجز.`;
}
