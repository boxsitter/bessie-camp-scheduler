import 'enums.dart';
import 'row_codec.dart';

/// How many activities a camper may request or veto in a session.
class PreferenceLimits {
  const PreferenceLimits({
    required this.maxRequests,
    required this.maxVetoes,
    required this.maxSkillsRequests,
    required this.maxSkillsVetoes,
  });

  final int maxRequests;
  final int maxVetoes;
  final int maxSkillsRequests;
  final int maxSkillsVetoes;

  int maxFor(PreferenceKind kind, {required bool skillsRec}) => switch ((kind, skillsRec)) {
    (PreferenceKind.request, false) => maxRequests,
    (PreferenceKind.request, true) => maxSkillsRequests,
    (PreferenceKind.veto, false) => maxVetoes,
    (PreferenceKind.veto, true) => maxSkillsVetoes,
  };
}

class CampSession {
  const CampSession({
    required this.id,
    required this.seasonId,
    required this.name,
    required this.startsOn,
    required this.limits,
  });

  final String id;
  final String seasonId;
  final String name;
  final DateTime startsOn;
  final PreferenceLimits limits;

  factory CampSession.fromRow(Map<String, dynamic> row) => CampSession(
    id: row['id'] as String,
    seasonId: row['season_id'] as String,
    name: row['name'] as String,
    startsOn: parseDate(row['starts_on'] as String),
    limits: PreferenceLimits(
      maxRequests: row['max_requests'] as int,
      maxVetoes: row['max_vetoes'] as int,
      maxSkillsRequests: row['max_skills_requests'] as int,
      maxSkillsVetoes: row['max_skills_vetoes'] as int,
    ),
  );
}
