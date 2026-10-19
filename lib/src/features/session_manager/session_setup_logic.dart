import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

import '../../models/activity.dart';
import '../../models/cabin.dart';
import '../../models/camp_session.dart';
import '../../models/camper.dart';
import '../../models/organization.dart';
import '../../models/schedule.dart';

/// Pure logic behind the session setup screen: derived numbers, what a change
/// would affect, and form validation. No widgets, no GetX.

/// Everything the setup screen shows about the current session.
class SessionSetup {
  SessionSetup({
    required this.session,
    required this.cabins,
    required Iterable<String> registeredCabinIds,
    required this.campers,
    required this.schedule,
    required this.activities,
  }) : registeredCabinIds = Set.unmodifiable(registeredCabinIds),
       campersByCabin = camperCountsByCabin(campers),
       enrollment = enrollmentCounts(campers);

  final CampSession session;

  /// Every cabin in the branch, registered or not.
  final List<Cabin> cabins;

  /// The cabins registered for this session.
  final Set<String> registeredCabinIds;
  final List<Camper> campers;
  final Schedule schedule;

  /// The branch's whole catalog.
  final List<Activity> activities;

  /// Campers staying in each cabin id.
  final Map<String, int> campersByCabin;

  /// Campers assigned to each scheduled activity id.
  final Map<String, int> enrollment;

  int get camperCount => campers.length;
  int get blockCount => schedule.blocks.length;
  int get registeredCabinCount => cabins.where((cabin) => registeredCabinIds.contains(cabin.id)).length;
  int get scheduledActivityCount => schedule.scheduledActivities.length;
  Set<String> get branchCabinIds => {for (final cabin in cabins) cabin.id};

  int enrolledIn(ScheduledActivity scheduled) => enrollment[scheduled.id] ?? 0;

  /// What is offered during [block], by activity name.
  List<ScheduledActivity> offeredIn(Block block) {
    String nameOf(ScheduledActivity s) => schedule.activityOf(s)?.name ?? '';
    return schedule.scheduledIn(block.id).sorted((a, b) => compareAsciiLowerCaseNatural(nameOf(a), nameOf(b)));
  }
}

// Counting --------------------------------------------------------------------

/// Campers per cabin id; campers without a cabin are not counted.
Map<String, int> camperCountsByCabin(Iterable<Camper> campers) {
  final counts = <String, int>{};
  for (final camper in campers) {
    final cabinId = camper.cabinId;
    if (cabinId != null) counts[cabinId] = (counts[cabinId] ?? 0) + 1;
  }
  return counts;
}

/// Campers per scheduled activity id (a double-block activity is two
/// scheduled activities, so each block counts its own campers).
Map<String, int> enrollmentCounts(Iterable<Camper> campers) {
  final counts = <String, int>{};
  for (final camper in campers) {
    for (final scheduledId in camper.assignments.values) {
      counts[scheduledId] = (counts[scheduledId] ?? 0) + 1;
    }
  }
  return counts;
}

// Cabins ----------------------------------------------------------------------

/// What saving a cabin selection would change.
class CabinSelectionChange {
  const CabinSelectionChange({required this.added, required this.removed, required this.campersLeftWithoutCabin});

  final Set<String> added;
  final Set<String> removed;

  /// Campers staying in cabins that are being removed; they stay on the
  /// roster without a cabin.
  final int campersLeftWithoutCabin;

  bool get isEmpty => added.isEmpty && removed.isEmpty;
}

CabinSelectionChange diffCabinSelection({
  required Set<String> registered,
  required Set<String> selected,
  required Map<String, int> campersByCabin,
}) {
  final removed = registered.difference(selected);
  return CabinSelectionChange(
    added: selected.difference(registered),
    removed: removed,
    campersLeftWithoutCabin: removed.fold(0, (sum, cabinId) => sum + (campersByCabin[cabinId] ?? 0)),
  );
}

// Schedule --------------------------------------------------------------------

/// The blocks of one day, chronologically.
class DayBlocks {
  const DayBlocks({required this.dayIndex, required this.date, required this.blocks});

  final int dayIndex;
  final DateTime date;
  final List<Block> blocks;

  /// "Day 2 - Tuesday, Jul 7".
  String get heading => 'Day ${dayIndex + 1} - ${DateFormat('EEEE, MMM d').format(date)}';
}

/// Groups blocks by day, days in order and blocks in time order.
List<DayBlocks> groupBlocksByDay(Iterable<Block> blocks) {
  final byDay = groupBy(blocks, (Block block) => block.dayIndex);
  return [
    for (final dayIndex in byDay.keys.sorted((a, b) => a.compareTo(b)))
      DayBlocks(
        dayIndex: dayIndex,
        date: byDay[dayIndex]!.first.date,
        blocks: byDay[dayIndex]!.sorted((a, b) => a.start.compareTo(b.start)),
      ),
  ];
}

/// "10:15 AM".
String formatClock(Duration sinceMidnight) {
  final hours = sinceMidnight.inHours % 24;
  final minutes = sinceMidnight.inMinutes % 60;
  final hour12 = hours % 12 == 0 ? 12 : hours % 12;
  return '$hour12:${minutes.toString().padLeft(2, '0')} ${hours < 12 ? 'AM' : 'PM'}';
}

String formatBlockTimes(Block block) => '${formatClock(block.startTime)} - ${formatClock(block.endTime)}';

/// A titled run of activities in the "add activities" dialog.
class ActivityChoiceGroup {
  const ActivityChoiceGroup(this.title, this.activities);

  final String title;
  final List<Activity> activities;
}

const String standardActivitiesTitle = 'Standard activities';
const String skillsRecsTitle = 'Skills recs';

/// The activities that could still be added to [block]: everything in the
/// [catalog] that [offeredActivityIds] does not already contain, split into
/// standard activities and skills recs. A skills rec block lists the skills
/// recs first (any activity may still be added). Empty groups are left out.
List<ActivityChoiceGroup> addableActivityGroups({
  required Block block,
  required Iterable<Activity> catalog,
  required Iterable<String> offeredActivityIds,
}) {
  final offered = offeredActivityIds.toSet();
  final addable = catalog
      .where((activity) => !offered.contains(activity.id))
      .sorted((a, b) => compareAsciiLowerCaseNatural(a.name, b.name));
  final groups = [
    ActivityChoiceGroup(standardActivitiesTitle, addable.where((a) => !a.isSkillsRec).toList()),
    ActivityChoiceGroup(skillsRecsTitle, addable.where((a) => a.isSkillsRec).toList()),
  ];
  return [
    for (final group in block.isSkillsRec ? groups.reversed : groups)
      if (group.activities.isNotEmpty) group,
  ];
}

// Preference limits -----------------------------------------------------------

/// The four preference limits being edited.
class LimitsDraft {
  const LimitsDraft({required this.maxRequests, required this.maxVetoes, required this.maxSkillsRequests, required this.maxSkillsVetoes});

  factory LimitsDraft.fromLimits(PreferenceLimits limits) => LimitsDraft(
    maxRequests: limits.maxRequests,
    maxVetoes: limits.maxVetoes,
    maxSkillsRequests: limits.maxSkillsRequests,
    maxSkillsVetoes: limits.maxSkillsVetoes,
  );

  /// What a new session starts with.
  static const LimitsDraft defaults = LimitsDraft(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1);

  /// The highest value the steppers allow.
  static const int highest = 20;

  final int maxRequests;
  final int maxVetoes;
  final int maxSkillsRequests;
  final int maxSkillsVetoes;

  PreferenceLimits toLimits() => PreferenceLimits(
    maxRequests: maxRequests,
    maxVetoes: maxVetoes,
    maxSkillsRequests: maxSkillsRequests,
    maxSkillsVetoes: maxSkillsVetoes,
  );

  LimitsDraft copyWith({int? maxRequests, int? maxVetoes, int? maxSkillsRequests, int? maxSkillsVetoes}) => LimitsDraft(
    maxRequests: _clamp(maxRequests ?? this.maxRequests),
    maxVetoes: _clamp(maxVetoes ?? this.maxVetoes),
    maxSkillsRequests: _clamp(maxSkillsRequests ?? this.maxSkillsRequests),
    maxSkillsVetoes: _clamp(maxSkillsVetoes ?? this.maxSkillsVetoes),
  );

  static int _clamp(int value) => value.clamp(0, highest);

  @override
  bool operator ==(Object other) =>
      other is LimitsDraft &&
      other.maxRequests == maxRequests &&
      other.maxVetoes == maxVetoes &&
      other.maxSkillsRequests == maxSkillsRequests &&
      other.maxSkillsVetoes == maxSkillsVetoes;

  @override
  int get hashCode => Object.hash(maxRequests, maxVetoes, maxSkillsRequests, maxSkillsVetoes);
}

// New session -----------------------------------------------------------------

/// What the user chose in the "new session" dialog.
class NewSessionRequest {
  const NewSessionRequest({required this.name, required this.startsOn, required this.limits, required this.registerAllCabins});

  final String name;
  final DateTime startsOn;
  final LimitsDraft limits;
  final bool registerAllCabins;
}

class NewSessionErrors {
  const NewSessionErrors({this.name, this.startsOn});

  final String? name;
  final String? startsOn;

  bool get hasErrors => name != null || startsOn != null;
}

const int maxSessionNameLength = 80;

/// [existingNames] are the names of the season's sessions. The database
/// enforces the uniqueness too; checking here gives a clearer message.
NewSessionErrors validateNewSession({required String name, required DateTime? startsOn, Iterable<String> existingNames = const []}) {
  final trimmed = name.trim();
  String? nameError;
  if (trimmed.isEmpty) {
    nameError = 'Enter a name for the session.';
  } else if (trimmed.length > maxSessionNameLength) {
    nameError = 'Keep the name under $maxSessionNameLength characters.';
  } else if (existingNames.any((existing) => existing.trim().toLowerCase() == trimmed.toLowerCase())) {
    nameError = 'This season already has a session called "$trimmed".';
  }
  return NewSessionErrors(name: nameError, startsOn: startsOn == null ? 'Pick the day the session starts.' : null);
}

/// A gentle note (not an error) when a session starts outside its season.
String? outsideSeasonWarning(DateTime startsOn, Season? season) {
  if (season == null || season.contains(startsOn)) return null;
  final format = DateFormat.MMMd();
  return 'This is outside the ${season.name} season (${format.format(season.startsOn)} - ${format.format(season.endsOn)}).';
}

/// Where a new session most likely begins: a week after the latest one, else
/// the start of the season.
DateTime suggestedSessionStart({required Iterable<CampSession> sessions, required Season? season, required DateTime today}) {
  if (sessions.isNotEmpty) {
    final latest = sessions.map((s) => s.startsOn).reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime(latest.year, latest.month, latest.day + 7);
  }
  final start = season?.startsOn ?? today;
  return DateTime(start.year, start.month, start.day);
}
