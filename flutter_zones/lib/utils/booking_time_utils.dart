/// Compact Arabic hour label — e.g. "8 م", "9 ص".
String formatArabicHourCompact(int hour24) {
  final isPm = hour24 >= 12;
  var h = hour24 % 12;
  if (h == 0) h = 12;
  return '$h ${isPm ? 'م' : 'ص'}';
}

/// Beautiful Arabic range — e.g. "من ساعة 8 م إلى 9 م".
String formatArabicHourRange({
  required int startHour24,
  required int endHour24,
}) {
  return 'من ساعة ${formatArabicHourCompact(startHour24)} إلى '
      '${formatArabicHourCompact(endHour24)}';
}

/// One-hour lounge slot label from 24h start hour.
String formatHourlySlotLabel(int startHour24) {
  final endHour24 = (startHour24 + 1) % 24;
  return formatArabicHourRange(
    startHour24: startHour24,
    endHour24: endHour24,
  );
}

/// Parses Arabic time slot strings into DateTime (start of slot).
/// Supports "من ساعة 8 م إلى 9 م" and legacy "من 5:00 م إلى 8:00 م".
DateTime? parseSlotStartDateTime(String timeRange, {DateTime? onDate}) {
  var match = RegExp(r'من\s+ساعة\s+(\d{1,2})\s+(ص|م)').firstMatch(timeRange);
  if (match != null) {
    var hour = int.parse(match.group(1)!);
    final period = match.group(2)!;
    if (period == 'م' && hour != 12) hour += 12;
    if (period == 'ص' && hour == 12) hour = 0;
    final base = onDate ?? DateTime.now();
    return DateTime(base.year, base.month, base.day, hour, 0);
  }

  match = RegExp(r'من\s+(\d{1,2}):(\d{2})\s+(ص|م)').firstMatch(timeRange);
  if (match == null) return null;

  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)!;

  if (period == 'م' && hour != 12) hour += 12;
  if (period == 'ص' && hour == 12) hour = 0;

  final base = onDate ?? DateTime.now();
  return DateTime(base.year, base.month, base.day, hour, minute);
}
