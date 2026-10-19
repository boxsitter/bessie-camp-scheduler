import 'package:bessie/src/utils/date_time_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDate writes the day first', () {
    expect(DateTimeHelpers.formatDate(DateTime(2026, 7, 6, 15, 30), false), '06/07/2026');
  });

  test('formatDate can add an unambiguous time of day', () {
    expect(DateTimeHelpers.formatDate(DateTime(2026, 7, 6, 15, 30), true), '06/07/2026 at 3:30 PM');
    expect(DateTimeHelpers.formatDate(DateTime(2026, 7, 6, 3, 5), true), '06/07/2026 at 3:05 AM');
  });

  test('formatDate without a date means today', () {
    final now = DateTime.now();
    expect(DateTimeHelpers.formatDate(null, false), startsWith(now.day.toString().padLeft(2, '0')));
  });

  test('weekday names', () {
    expect(DateTimeHelpers.weekdayToString(1), 'monday');
    expect(DateTimeHelpers.weekdayToString(7, true), 'Sunday');
    expect(DateTimeHelpers.weekdayToString(3, false), 'wednesday');
    expect(DateTimeHelpers.dateTimeToWeekdayString(DateTime(2026, 7, 6), true), 'Monday');
  });
}
