/// Conversions between database column values and Dart values.
///
/// Dates and times at camp are wall-clock values without a timezone, so they
/// are kept as such: a `date` becomes a local midnight [DateTime] and a `time`
/// becomes a [Duration] since midnight. Nothing here ever calls `toUtc()`.
library;

/// `2026-07-06` -> local midnight of that day.
DateTime parseDate(String value) {
  final parts = value.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2].substring(0, 2)));
}

/// Local calendar date -> `2026-07-06`.
String formatDbDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// `10:15:00` -> 10h15m.
Duration parseTime(String value) {
  final parts = value.split(':');
  return Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1]));
}

/// 10h15m -> `10:15:00`.
String formatDbTime(Duration time) => '${time.inHours.toString().padLeft(2, '0')}:${(time.inMinutes % 60).toString().padLeft(2, '0')}:00';

DateTime parseTimestamp(String value) => DateTime.parse(value);
