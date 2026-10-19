import 'enums.dart';
import 'row_codec.dart';
import 'titled.dart';

class Camper implements Titled {
  const Camper({
    required this.id,
    required this.sessionId,
    required this.firstName,
    required this.preferredName,
    required this.lastName,
    required this.gender,
    required this.birthdate,
    required this.note,
    required this.cabinId,
    required this.ultracampId,
    required this.arrived,
    required this.canSwim,
    required this.satisfactionIndex,
    required this.preferencesSubmittedAt,
    this.assignments = const {},
    this.preferences = const {},
  });

  final String id;
  final String sessionId;
  final String firstName;
  final String? preferredName;
  final String lastName;
  final Gender? gender;
  final DateTime birthdate;
  final String note;
  final String? cabinId;
  final String? ultracampId;
  final bool arrived;
  final bool canSwim;

  /// 0-1 score of how well the auto-assignment honored this camper's wishes.
  final double? satisfactionIndex;

  /// When a counselor last saved this camper's preferences; null if never.
  final DateTime? preferencesSubmittedAt;

  /// block id -> scheduled activity id.
  final Map<String, String> assignments;

  /// activity id -> what the camper asked for. Activities not listed are neutral.
  final Map<String, PreferenceKind> preferences;

  /// The name the camper goes by.
  String get name => (preferredName?.isNotEmpty ?? false) ? preferredName! : firstName;
  String get fullName => '$firstName $lastName';
  String get fullNamePreferred => '$name $lastName';
  String get lastInitial => lastName.isEmpty ? '' : lastName[0];
  @override
  String get title => fullName;
  @override
  String get displayTitle => '$name $lastInitial';

  bool get preferencesSubmitted => preferencesSubmittedAt != null;

  Set<String> get requestedActivityIds => {
    for (final e in preferences.entries)
      if (e.value == PreferenceKind.request) e.key,
  };
  Set<String> get vetoedActivityIds => {
    for (final e in preferences.entries)
      if (e.value == PreferenceKind.veto) e.key,
  };

  /// Age in whole years on [on] (defaults to today).
  int ageOn([DateTime? on]) {
    final today = on ?? DateTime.now();
    var years = today.year - birthdate.year;
    if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) years--;
    return years < 0 ? 0 : years;
  }

  int get age => ageOn();

  Camper copyWith({
    bool? arrived,
    bool? canSwim,
    String? cabinId,
    bool clearCabin = false,
    Map<String, String>? assignments,
    Map<String, PreferenceKind>? preferences,
    DateTime? preferencesSubmittedAt,
    bool clearPreferencesSubmitted = false,
  }) => Camper(
    id: id,
    sessionId: sessionId,
    firstName: firstName,
    preferredName: preferredName,
    lastName: lastName,
    gender: gender,
    birthdate: birthdate,
    note: note,
    cabinId: clearCabin ? null : (cabinId ?? this.cabinId),
    ultracampId: ultracampId,
    arrived: arrived ?? this.arrived,
    canSwim: canSwim ?? this.canSwim,
    satisfactionIndex: satisfactionIndex,
    preferencesSubmittedAt: clearPreferencesSubmitted ? null : (preferencesSubmittedAt ?? this.preferencesSubmittedAt),
    assignments: assignments ?? this.assignments,
    preferences: preferences ?? this.preferences,
  );

  /// Builds a camper from a `campers` row selected with its `assignments`
  /// and `camper_preferences` embedded.
  factory Camper.fromRow(Map<String, dynamic> row) {
    final assignments = <String, String>{
      for (final a in (row['assignments'] as List? ?? const []).cast<Map<String, dynamic>>())
        a['block_id'] as String: a['scheduled_activity_id'] as String,
    };
    final preferences = <String, PreferenceKind>{
      for (final p in (row['camper_preferences'] as List? ?? const []).cast<Map<String, dynamic>>())
        p['activity_id'] as String: PreferenceKind.fromDb(p['kind'] as String),
    };
    return Camper(
      id: row['id'] as String,
      sessionId: row['session_id'] as String,
      firstName: row['first_name'] as String,
      preferredName: row['preferred_name'] as String?,
      lastName: row['last_name'] as String,
      gender: Gender.fromDb(row['gender'] as String?),
      birthdate: parseDate(row['birthdate'] as String),
      note: row['note'] as String,
      cabinId: row['cabin_id'] as String?,
      ultracampId: row['ultracamp_id'] as String?,
      arrived: row['arrived'] as bool,
      canSwim: row['can_swim'] as bool,
      satisfactionIndex: (row['activity_satisfaction_index'] as num?)?.toDouble(),
      preferencesSubmittedAt: row['preferences_submitted_at'] == null ? null : parseTimestamp(row['preferences_submitted_at'] as String),
      assignments: assignments,
      preferences: preferences,
    );
  }
}

/// One row of a roster import, before it reaches the database.
class CamperImportRow {
  const CamperImportRow({
    required this.firstName,
    required this.lastName,
    required this.birthdate,
    this.preferredName,
    this.gender,
    this.cabinName,
    this.ultracampId,
    this.note,
  });

  final String firstName;
  final String lastName;
  final DateTime birthdate;
  final String? preferredName;
  final Gender? gender;
  final String? cabinName;
  final String? ultracampId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'first_name': firstName,
    'last_name': lastName,
    'birthdate': formatDbDate(birthdate),
    'preferred_name': preferredName,
    'gender': gender?.code,
    'cabin': cabinName,
    'ultracamp_id': ultracampId,
    'note': note,
  };
}

class CamperImportResult {
  const CamperImportResult({required this.inserted, required this.duplicates, required this.unknownCabins});

  final int inserted;
  final int duplicates;
  final List<String> unknownCabins;

  factory CamperImportResult.fromJson(Map<String, dynamic> json) => CamperImportResult(
    inserted: json['inserted'] as int,
    duplicates: json['duplicates'] as int,
    unknownCabins: (json['unknown_cabins'] as List).cast<String>(),
  );
}
