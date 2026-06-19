import 'package:intl/intl.dart';

const _arabicDays = [
  'الاثنين',
  'الثلاثاء',
  'الأربعاء',
  'الخميس',
  'الجمعة',
  'السبت',
  'الأحد',
];

const _arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatArabicDay(DateTime date) => _arabicDays[date.weekday - 1];

String formatArabicDate(DateTime date) {
  return '${formatArabicDay(date)} ${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';
}

String formatArabicDateShort(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}

String formatHourLabel(DateTime dateTime) {
  final hour = dateTime.hour;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final isPm = hour >= 12;
  var displayHour = hour % 12;
  if (displayHour == 0) displayHour = 12;
  final period = isPm ? 'م' : 'ص';
  return '$displayHour:$minute $period';
}

String formatHourSlotRange(DateTime start) {
  final end = start.add(const Duration(hours: 1));
  return '${formatHourLabel(start)} - ${formatHourLabel(end)}';
}

String formatIsoDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

DateTime combineDateAndTime(DateTime date, DateTime time) {
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
