import 'titled.dart';

enum StaffRole {
  root,
  director,
  admin,
  counselor;

  static StaffRole fromDb(String value) => StaffRole.values.byName(value);

  /// Root and directors manage the organization's structure and its people.
  bool get canManageStructure => this == root || this == director;

  /// Everyone but counselors may edit session data.
  bool get canEditSessionData => this != counselor;

  String get title => switch (this) {
    root => 'Root',
    director => 'Director',
    admin => 'Admin',
    counselor => 'Counselor',
  };
}

enum ActivityCategory implements Titled {
  creative('creative', 'Creative'),
  sportsAndAthletics('sports_and_athletics', 'Sports & Athletics'),
  waterfront('waterfront', 'Waterfront'),
  campClassics('camp_classics', 'Camp Classics'),
  silly('silly', 'Silly & Unconventional'),
  skills('skills', 'Skills Recs'),
  other('other', 'Other');

  const ActivityCategory(this.dbValue, this.title);

  final String dbValue;
  @override
  final String title;

  @override
  String get displayTitle => title;

  static ActivityCategory fromDb(String value) => ActivityCategory.values.firstWhere((c) => c.dbValue == value);
}

/// What a camper asked for. Being flexible is the absence of a preference.
enum PreferenceKind {
  request,
  veto;

  static PreferenceKind fromDb(String value) => PreferenceKind.values.byName(value);
}

enum Gender {
  male('M', 'Male'),
  female('F', 'Female'),
  nonBinary('NB', 'Non-binary');

  const Gender(this.code, this.title);

  final String code;
  final String title;

  static Gender? fromDb(String? code) {
    if (code == null) return null;
    for (final gender in Gender.values) {
      if (gender.code == code) return gender;
    }
    return null;
  }
}

enum SortDirection { asc, desc }
