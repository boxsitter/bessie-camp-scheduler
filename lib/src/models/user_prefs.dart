/// A type-safe key for a user preference that is strictly enforced to be
/// a primitive type.
///
/// It encapsulates the preference's storage key, its default value, and validates
/// that the type `T` is one of the allowed primitives:
/// `String`, `int`, `double`, `bool`, or `List<String>`.
class PreferenceKey<T> {
  final String key;
  final T defaultValue;

  /// Creates a preference key.
  ///
  /// Throws an [ArgumentError] if the [defaultValue] (and by extension, the type T)
  /// is not an allowed primitive type.
  PreferenceKey({required this.key, required this.defaultValue}) {
    if (!_isAllowedPreferenceType(defaultValue)) {
      throw ArgumentError(
        'PreferenceKey can only be created with primitive types (String, num, bool, List<String>). '
        'Received an invalid type: ${defaultValue.runtimeType}',
      );
    }
  }
}

/// Manages user preferences, strictly enforcing the use of primitive types
/// through a [PreferenceKey]-based API.
class UserPreferences {
  final Map<String, dynamic> _preferences;

  // Private constructor for internal use.
  const UserPreferences._(this._preferences);

  /// Creates a [UserPreferences] instance from a JSON map.
  ///
  /// Non-primitive values from the [json] map are filtered out to ensure
  /// robustness against malformed data from the backend.
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final sanitizedMap = <String, dynamic>{};
    for (final entry in json.entries) {
      if (_isAllowedPreferenceType(entry.value)) {
        sanitizedMap[entry.key] = entry.value;
      }
    }
    return UserPreferences._(sanitizedMap);
  }

  /// Converts the preferences to a JSON map for storage.
  Map<String, dynamic> toJson() => _preferences;

  /// Retrieves the value for the given [PreferenceKey].
  ///
  /// If a value is not found or is of the wrong type, the key's
  /// [defaultValue] is returned.
  T get<T>(PreferenceKey<T> prefKey) {
    final value = _preferences[prefKey.key];

    if (value is T) {
      return value;
    }

    // Firestore stores all numbers as `num`, so handle casting to int/double.
    if (T == int && value is num) {
      return value.toInt() as T;
    }
    if (T == double && value is num) {
      return value.toDouble() as T;
    }
    if (T == (List<String>) && value is List) {
      return List<String>.from(value.whereType<String>()) as T;
    }

    return prefKey.defaultValue;
  }

  /// Returns a new [UserPreferences] instance with the updated value for the
  /// given [PreferenceKey].
  UserPreferences set<T>(PreferenceKey<T> prefKey, T value) {
    // This assertion provides an extra layer of safety, though the
    // PreferenceKey constructor is the primary guard.
    assert(_isAllowedPreferenceType(value), "The value to set must be a primitive type.");

    final newMap = Map<String, dynamic>.from(_preferences);
    newMap[prefKey.key] = value;
    return UserPreferences._(newMap);
  }
}

/// Helper function to check if a value is of an allowed primitive type.
bool _isAllowedPreferenceType(dynamic value) {
  return value is String ||
      value is num || // Covers int and double
      value is bool ||
      (value is List && value.every((item) => item is String));
}
