// lib/core/utils/date_formatter.dart
class DateFormatter {
  static String formatShortTime(DateTime dateTime) {
    final localTime = dateTime.toLocal();
    final hour = localTime.hour == 0 ? 12 : (localTime.hour > 12 ? localTime.hour - 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
