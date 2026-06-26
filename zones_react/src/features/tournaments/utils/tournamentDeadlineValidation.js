/**
 * Validates manager participation deadline against tournament start date.
 * Customers can subscribe in the ZONEZ app until this exact date/time (server-side).
 */
export function validateRegistrationDeadline(form) {
  if (!form.registrationDeadline?.trim()) {
    return "تاريخ انتهاء مهلة المشاركة مطلوب.";
  }
  if (!form.startDate?.trim()) {
    return null;
  }

  const deadline = new Date(form.registrationDeadline);
  const startEnd = new Date(`${form.startDate}T23:59:59`);

  if (Number.isNaN(deadline.getTime())) {
    return "تاريخ انتهاء مهلة المشاركة غير صالح.";
  }
  if (deadline > startEnd) {
    return "يجب أن يكون موعد انتهاء المشاركة في أو قبل يوم بداية البطولة.";
  }

  return null;
}
