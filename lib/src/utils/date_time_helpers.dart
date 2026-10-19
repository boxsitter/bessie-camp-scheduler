import 'package:intl/intl.dart';

class DateTimeHelpers {
  const DateTimeHelpers._();

  static const _weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  /// `06/07/2026`, or `06/07/2026 at 3:30 PM` with [includeTime] (day first).
  /// Today when [date] is null.
  static String formatDate(DateTime? date, bool includeTime) {
    final value = date ?? DateTime.now();
    final day = DateFormat('dd/MM/yyyy').format(value);
    return includeTime ? '$day at ${DateFormat('h:mm a').format(value)}' : day;
  }

  /// The name of [weekday] (1 is Monday, 7 is Sunday): `monday`, or `Monday` when [titlecase] is true.
  static String weekdayToString(int weekday, [bool? titlecase]) {
    final name = _weekdays[weekday - 1];
    return titlecase == true ? '${name[0].toUpperCase()}${name.substring(1)}' : name;
  }

  static String dateTimeToWeekdayString(DateTime dateTime, [bool? titlecase]) => weekdayToString(dateTime.weekday, titlecase);
}
