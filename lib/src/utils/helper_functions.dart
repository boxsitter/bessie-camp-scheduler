
import '../ember_core.dart';

/// Defines ANSI escape codes for text colors.
class CoreHelperFunctions {
  static DateTime parseDate(dynamic value) {
    if (value == null) {
      throw Exception('Invalid date type: null');
    }

    // Check the type name at runtime, since we can't import Timestamp
    final typeName = value.runtimeType.toString();
    if (typeName == 'Timestamp') {
      // We assume it has a .toDate() method returning a DateTime
      //  Use a dynamic call so we don't need the Timestamp type
      final dt = (value as dynamic).toDate() as DateTime;
      return dt.toUtc();
    } else if (value is DateTime) {
      // If we actually get a DateTime, just print and convert to UTC
      Debug.logInfo('parseDate received a direct DateTime: $value');
      return value.toUtc();
    } else if (value is String) {
      // Possibly an ISO 8601 string
      return DateTime.parse(value).toUtc();
    }

    throw Exception('Invalid date type: ${value.runtimeType}');
  }

  static void updateDocumentTimestamp(Map<String, dynamic> json) {
    // For "updatedAt", we store an ISO 8601 string
    json['updatedAt'] = DateTime.now().toUtc();
  }

}
