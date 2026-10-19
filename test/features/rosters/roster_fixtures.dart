import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';

Camper makeCamper({
  String? id,
  String first = 'Ada',
  String last = 'Lovelace',
  String? preferred,
  Gender? gender,
  DateTime? birthdate,
  String note = '',
  String? cabinId,
  String? ultracampId,
  bool arrived = false,
  bool canSwim = false,
  double? satisfaction,
  DateTime? preferencesSubmittedAt,
  Map<String, String> assignments = const {},
  Map<String, PreferenceKind> preferences = const {},
}) => Camper(
  id: id ?? '$first-$last'.toLowerCase(),
  sessionId: 'session',
  firstName: first,
  preferredName: preferred,
  lastName: last,
  gender: gender,
  birthdate: birthdate ?? DateTime(2014, 6, 15),
  note: note,
  cabinId: cabinId,
  ultracampId: ultracampId,
  arrived: arrived,
  canSwim: canSwim,
  satisfactionIndex: satisfaction,
  preferencesSubmittedAt: preferencesSubmittedAt,
  assignments: assignments,
  preferences: preferences,
);

Cabin makeCabin(String id, String name, {String? displayName, int position = 0}) =>
    Cabin(id: id, branchId: 'branch', name: name, displayName: displayName, village: 'Village', capacity: 10, position: position);

Block makeBlock(String id, String title, {int dayIndex = 0, int startHour = 9, bool skills = false}) => Block(
  id: id,
  sessionId: 'session',
  dayId: 'day$dayIndex',
  title: title,
  // 2026-07-06 is a Monday.
  date: DateTime(2026, 7, 6 + dayIndex),
  dayIndex: dayIndex,
  startTime: Duration(hours: startHour),
  endTime: Duration(hours: startHour + 1),
  isSkillsRec: skills,
);

Activity makeActivity(
  String id,
  String name, {
  int capacity = 10,
  bool skills = false,
  bool hidden = false,
  bool preferenceRequired = true,
}) => Activity(
  id: id,
  branchId: 'branch',
  name: name,
  description: '',
  capacity: capacity,
  category: ActivityCategory.other,
  isSkillsRec: skills,
  doubleSchedule: false,
  maxAssignments: null,
  isHidden: hidden,
  preferenceRequired: preferenceRequired,
);

/// `scheduled` maps a scheduled activity id to (block id, activity id).
Schedule makeSchedule({
  required List<Block> blocks,
  required List<Activity> activities,
  Map<String, (String, String)> scheduled = const {},
}) => Schedule(
  days: const [],
  blocks: blocks,
  scheduledActivities: [
    for (final entry in scheduled.entries)
      ScheduledActivity(id: entry.key, sessionId: 'session', blockId: entry.value.$1, activityId: entry.value.$2),
  ],
  activitiesById: {for (final activity in activities) activity.id: activity},
);
