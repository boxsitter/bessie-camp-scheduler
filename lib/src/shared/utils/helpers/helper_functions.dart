import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';


class BessHelperFunctions {
  static DateTime getStartOfWeek(DateTime date) {
    final int daysUntilMonday = date.weekday - 1;
    final DateTime startOfWeek = date.subtract(Duration(days: daysUntilMonday));
    return DateTime(
        startOfWeek.year, startOfWeek.month, startOfWeek.day, 0, 0, 0, 0, 0);
  }

  static Color? getColor(String value) {
    /// Define your product specific colors here and it will match the attribute colors and show specific 🟠🟡🟢🔵🟣🟤

    if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Green') {
      return Colors.green;
    } else if (value == 'Red') {
      return Colors.red;
    } else if (value == 'Blue') {
      return Colors.blue;
    } else if (value == 'Pink') {
      return Colors.pink;
    } else if (value == 'Grey') {
      return Colors.grey;
    } else if (value == 'Purple') {
      return Colors.purple;
    } else if (value == 'Black') {
      return Colors.black;
    } else if (value == 'White') {
      return Colors.white;
    } else if (value == 'Yellow') {
      return Colors.yellow;
    } else if (value == 'Orange') {
      return Colors.deepOrange;
    } else if (value == 'Brown') {
      return Colors.brown;
    } else if (value == 'Teal') {
      return Colors.teal;
    } else if (value == 'Indigo') {
      return Colors.indigo;
    } else {
      return null;
    }
  }

  static void navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(DateTime date,
      {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowChildren = widgets.sublist(
          i, i + rowSize > widgets.length ? widgets.length : i + rowSize);
      wrappedList.add(Row(children: rowChildren));
    }
    return wrappedList;
  }

  static Map<V, K> transposeMap<K, V>(Map<K, V> originalMap) {
    final transposedMap = <V, K>{};
    originalMap.forEach((key, value) {
      // Be cautious: If the original map has duplicate values,
      // only the last key associated with that value will be kept in the transposed map.
      transposedMap[value] = key;
    });
    return transposedMap;
  }

  static Color blendColors(Color color1, Color color2, int alpha) {
    final int effectiveAlphaInt = alpha.clamp(0, 255);
    final double foregroundOpacity = effectiveAlphaInt / 255.0; // Opacity 0.0-1.0

    // Use the doubles directly, assuming they are [0.0, 1.0]
    final double backgroundAlpha = color1.a;
    final double backgroundRed = color1.r;
    final double backgroundGreen = color1.g;
    final double backgroundBlue = color1.b;

    final double foregroundRed = color2.r;
    final double foregroundGreen = color2.g;
    final double foregroundBlue = color2.b;

    // Blend using [0.0, 1.0] doubles
    final double resultRedNorm = foregroundRed * foregroundOpacity + backgroundRed * (1.0 - foregroundOpacity);
    final double resultGreenNorm = foregroundGreen * foregroundOpacity + backgroundGreen * (1.0 - foregroundOpacity);
    final double resultBlueNorm = foregroundBlue * foregroundOpacity + backgroundBlue * (1.0 - foregroundOpacity);
    final double resultAlphaNorm = foregroundOpacity + backgroundAlpha * (1.0 - foregroundOpacity);

    // Convert results [0.0, 1.0] back to ints [0, 255]
    final int resultAlphaInt = (resultAlphaNorm * 255.0).round().clamp(0, 255);
    final int resultRedInt = (resultRedNorm * 255.0).round().clamp(0, 255);
    final int resultGreenInt = (resultGreenNorm * 255.0).round().clamp(0, 255);
    final int resultBlueInt = (resultBlueNorm * 255.0).round().clamp(0, 255);

    // Construct color using ints
    return Color.fromARGB(
      resultAlphaInt,
      resultRedInt,
      resultGreenInt,
      resultBlueInt,
    );
  }

  /// Adjusts the HSL (Hue, Saturation, Lightness) values of a given color.
  ///
  /// Takes a [Color] and optional double values for HSL adjustments.
  /// - [hue]: The amount to adjust the hue by (e.g., 15.5 or -20). This value wraps around the 360-degree color wheel.
  /// - [saturation]: The amount to adjust the saturation by (e.g., 0.1 for 10% more saturation). The final value is clipped between 0.0 and 1.0.
  /// - [luminance]: The amount to adjust the lightness/luminance by (e.g., -0.1 for 10% less luminance). The final value is clipped between 0.0 and 1.0.
  ///
  /// Returns a new [Color] with the transformations applied.
  static Color adjustHSL(
      Color color, {
        double? hue,
        double? saturation,
        double? luminance,
      }) {
    HSLColor hslColor = HSLColor.fromColor(color);

    if (hue != null) {
      // Add the hue adjustment and wrap the value around the 360 degrees.
      double newHue = (hslColor.hue + hue) % 360.0;
      if (newHue < 0) newHue += 360.0;
      hslColor = hslColor.withHue(newHue);
    }

    if (saturation != null) {
      // Add the saturation adjustment and clamp the value between 0.0 and 1.0.
      final double newSaturation = (hslColor.saturation + saturation).clamp(0.0, 1.0);
      hslColor = hslColor.withSaturation(newSaturation);
    }

    if (luminance != null) {
      // Add the luminance adjustment and clamp the value between 0.0 and 1.0.
      final double newLuminance = (hslColor.lightness + luminance).clamp(0.0, 1.0);
      hslColor = hslColor.withLightness(newLuminance);
    }

    return hslColor.toColor();
  }

  static String toTitleCase(String text) {
    if (text.isEmpty) {
      return '';
    }

    // Split the string into words. Handles multiple spaces between words.
    final List<String> words = text.split(' ').where((word) => word.isNotEmpty).toList();

    if (words.isEmpty) {
      return ''; // Handles cases where the string might only contain spaces.
    }

    final List<String> titleCasedWords = words.map((word) {
      if (word.isEmpty) { // Should not happen due to the .where() filter above, but good for safety.
        return '';
      }
      final String firstLetter = word[0].toUpperCase();
      final String restOfWord = word.substring(1).toLowerCase();
      return '$firstLetter$restOfWord';
    }).toList();

    return titleCasedWords.join(' ');
  }

  /// Finds the key of a time interval from a map based on the following priority:
  ///
  /// 1. An interval currently occurring.
  /// 2. The next interval that will occur (based on the soonest start time).
  /// 3. If all intervals are in the past, the last one that occurred (based on the most recent end time).
  ///
  /// The `intervals` map should have a `String` key and a `List<DateTime>` value.
  /// It is assumed the list always contains two elements: `[startTime, endTime]`.
  ///
  /// Returns the `String` key of the found interval, or `null` if the map is empty
  /// or no valid intervals are found.
  static String? findNextOrCurrentInterval(Map<String, List<DateTime>> intervals) {
    if (intervals.isEmpty) {
      return null;
    }

    final DateTime now = DateTime.now();
    final List<MapEntry<String, List<DateTime>>> currentIntervals = [];
    final List<MapEntry<String, List<DateTime>>> futureIntervals = [];
    final List<MapEntry<String, List<DateTime>>> pastIntervals = [];

    // Categorize each interval in a single pass
    for (final entry in intervals.entries) {
      if (entry.value.length != 2) {
      continue; // Skip invalid entries
      }

      final DateTime start = entry.value[0];
      final DateTime end = entry.value[1];

    // --- More Robust "Current" Check ---
    // A block is current if 'now' is within [start, end).
    final bool isCurrentDuringDuration = !now.isBefore(start) && now.isBefore(end);
    // A block is also current if it's instantaneous (start == end) and happening right now.
    final bool isCurrentInstantaneous = start == end && now.isAtSameMomentAs(start);

    if (isCurrentDuringDuration || isCurrentInstantaneous) {
        currentIntervals.add(entry);
      } else if (start.isAfter(now)) {
        futureIntervals.add(entry);
      } else {
        pastIntervals.add(entry);
      }
    }

    // Priority 1: Check for and return a currently occurring interval
    if (currentIntervals.isNotEmpty) {
    // Sort by start time to be deterministic if multiple are current
    currentIntervals.sort((a, b) => a.value[0].compareTo(b.value[0]));
      return currentIntervals.first.key;
    }

    // Priority 2: Find and return the next interval to occur
    if (futureIntervals.isNotEmpty) {
      futureIntervals.sort((a, b) => a.value[0].compareTo(b.value[0]));
      return futureIntervals.first.key;
    }

    // Priority 3: Find and return the last interval that occurred
    if (pastIntervals.isNotEmpty) {
      pastIntervals.sort((a, b) => b.value[1].compareTo(a.value[1]));
      return pastIntervals.first.key;
    }

    return null; // No valid intervals were found
  }

  /// Linearly interpolates between a list of colors.
  ///
  /// - [colors]: The list of colors to interpolate between.
  /// - [t]: The interpolation factor, typically from 0.0 to 1.0.
  ///
  /// Returns the interpolated [Color].
  static Color lerpColorList(List<Color> colors, double t) {
    if (colors.isEmpty) {
      // Return a default color if the list is empty, or you could throw an error.
      return Colors.transparent;
    }
    if (colors.length == 1) {
      return colors.first;
    }

    // Clamp t to the valid range [0.0, 1.0]
    final double clampedT = t.clamp(0.0, 1.0);

    // Calculate the overall position in the list.
    final double position = clampedT * (colors.length - 1);

    // Determine the two colors to lerp between.
    final int startIndex = position.floor();
    final int endIndex = position.ceil();

    // The 'local' t value for the lerp between the two selected colors.
    final double localT = position - startIndex;

    return Color.lerp(colors[startIndex], colors[endIndex], localT)!;
  }
}
