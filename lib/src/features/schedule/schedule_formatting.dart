/// Wall-clock and calendar text for the printed schedule.
library;

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String weekdayName(DateTime date) => _weekdayNames[date.weekday - 1];

/// `Jul 6`.
String formatShortDate(DateTime date) => '${_monthNames[date.month - 1]} ${date.day}';

/// `Jul 6-10, 2026`, `Jun 29 - Jul 3, 2026` or `Dec 29, 2026 - Jan 2, 2027`.
String formatDateRange(DateTime first, DateTime last) {
  if (first.year != last.year) return '${formatShortDate(first)}, ${first.year} - ${formatShortDate(last)}, ${last.year}';
  if (first.month != last.month) return '${formatShortDate(first)} - ${formatShortDate(last)}, ${first.year}';
  if (first.day == last.day) return '${formatShortDate(first)}, ${first.year}';
  return '${formatShortDate(first)}-${last.day}, ${first.year}';
}

/// A time of day as a 12-hour clock, e.g. `9:15 AM`.
String formatClock(Duration timeOfDay) => '${_clockDigits(timeOfDay)} ${_meridiem(timeOfDay)}';

String _clockDigits(Duration timeOfDay) {
  final hours = timeOfDay.inHours % 24;
  final minutes = timeOfDay.inMinutes % 60;
  final hour12 = hours % 12 == 0 ? 12 : hours % 12;
  return '$hour12:${minutes.toString().padLeft(2, '0')}';
}

String _meridiem(Duration timeOfDay) => timeOfDay.inHours % 24 < 12 ? 'AM' : 'PM';

/// `10:15-11:15 AM`, or `11:30 AM-12:15 PM` when the range crosses noon.
String formatTimeRange(Duration start, Duration end) {
  if (_meridiem(start) == _meridiem(end)) return '${_clockDigits(start)}-${_clockDigits(end)} ${_meridiem(end)}';
  return '${formatClock(start)}-${formatClock(end)}';
}
