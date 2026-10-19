import 'package:bessie/src/features/schedule/schedule_formatting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatClock', () {
    test('uses a 12-hour clock', () {
      expect(formatClock(const Duration(hours: 9, minutes: 5)), '9:05 AM');
      expect(formatClock(const Duration(hours: 13, minutes: 30)), '1:30 PM');
    });

    test('handles midnight and noon', () {
      expect(formatClock(Duration.zero), '12:00 AM');
      expect(formatClock(const Duration(hours: 12)), '12:00 PM');
      expect(formatClock(const Duration(hours: 12, minutes: 45)), '12:45 PM');
      expect(formatClock(const Duration(hours: 23, minutes: 59)), '11:59 PM');
    });
  });

  group('formatTimeRange', () {
    test('writes the period once when both ends share it', () {
      expect(formatTimeRange(const Duration(hours: 10, minutes: 15), const Duration(hours: 11, minutes: 15)), '10:15-11:15 AM');
      expect(formatTimeRange(const Duration(hours: 13), const Duration(hours: 14, minutes: 30)), '1:00-2:30 PM');
    });

    test('writes both periods when the range crosses noon', () {
      expect(formatTimeRange(const Duration(hours: 11, minutes: 30), const Duration(hours: 12, minutes: 15)), '11:30 AM-12:15 PM');
    });
  });

  group('dates', () {
    test('formats a short date', () {
      expect(formatShortDate(DateTime(2026, 7, 6)), 'Jul 6');
      expect(formatShortDate(DateTime(2026, 12, 31)), 'Dec 31');
    });

    test('names the weekday', () {
      expect(weekdayName(DateTime(2026, 7, 6)), 'Monday');
      expect(weekdayName(DateTime(2026, 7, 12)), 'Sunday');
    });

    test('formats a range within a month', () {
      expect(formatDateRange(DateTime(2026, 7, 6), DateTime(2026, 7, 10)), 'Jul 6-10, 2026');
    });

    test('formats a range across months and years', () {
      expect(formatDateRange(DateTime(2026, 6, 29), DateTime(2026, 7, 3)), 'Jun 29 - Jul 3, 2026');
      expect(formatDateRange(DateTime(2026, 12, 29), DateTime(2027, 1, 2)), 'Dec 29, 2026 - Jan 2, 2027');
    });

    test('formats a single day', () {
      expect(formatDateRange(DateTime(2026, 7, 6), DateTime(2026, 7, 6)), 'Jul 6, 2026');
    });
  });
}
