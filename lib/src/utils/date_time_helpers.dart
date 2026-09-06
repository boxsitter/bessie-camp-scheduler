import 'package:intl/intl.dart';

class DateTimeHelpers {
  static String formatDate(DateTime? date, bool includeTime) {
    date ??= DateTime.now();
    final onlyDate = DateFormat('dd/MM/yyyy').format(date);
    final onlyTime = DateFormat('hh:mm').format(date);
    if (includeTime) {
      return '$onlyDate at $onlyTime';
    } else {
      return onlyDate;
    }
  }

  // 1 - monday
  static String weekdayToString(int weekday, [bool? titlecase]) {
    final weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final day = weekdays[weekday - 1];
    // If lowercase is false, capitalize the first letter and add the rest of the string.
    return titlecase == null
        ? day
        : titlecase
        ? '${day[0].toUpperCase()}${day.substring(1)}'
        : day;
  }

  // Dart's DateTime.weekday returns 1 for Monday and 7 for Sunday.
  static int getDayOfWeek(DateTime dateTime) {
    return dateTime.weekday;
  }

  static String dateTimeToWeekdayString(DateTime dateTime, [bool? titlecase]) {
    return weekdayToString(getDayOfWeek(dateTime), titlecase);
  }

  /// Finds the object in a set that has the [DateTime] closest to the current time.
  ///
  /// This generic function works on any object type [T]. You must provide a
  /// [getDateTime] function to specify how to access the [DateTime] from your object.
  ///
  /// - **[items]**: A [Set] of objects of type [T].
  /// - **[getDateTime]**: A function that takes an object of type [T] and returns its [DateTime].
  /// - **[roundDown]**:
  ///   - When `false` (default): Finds the object with the minimum absolute time difference from now.
  ///   - When `true`: Finds the object with the most recent past [DateTime]. If all are in the future, it returns the soonest one.
  ///
  /// Throws an [ArgumentError] if the input set is empty.
  ///
  /// Returns the object of type [T] that meets the criteria.
  static T findClosest<T>({required Set<T> items, required DateTime Function(T item) getDateTime, bool roundDown = false}) {
    if (items.isEmpty) {
      throw ArgumentError('The input set of items cannot be empty.');
    }

    final now = DateTime.now();

    if (roundDown) {
      // Find the most recent item in the past
      final pastItems = items.where((item) => getDateTime(item).isBefore(now));

      if (pastItems.isNotEmpty) {
        // From the past items, return the one with the latest (max) date
        return pastItems.reduce((a, b) => getDateTime(a).isAfter(getDateTime(b)) ? a : b);
      } else {
        // If all items are in the future, return the soonest one (min date)
        return items.reduce((a, b) => getDateTime(a).isBefore(getDateTime(b)) ? a : b);
      }
    } else {
      // Original logic: find the one with the smallest time difference, past or future
      return items.reduce((a, b) {
        final diffA = getDateTime(a).difference(now).abs();
        final diffB = getDateTime(b).difference(now).abs();
        return diffA.compareTo(diffB) < 0 ? a : b;
      });
    }
  }
}
