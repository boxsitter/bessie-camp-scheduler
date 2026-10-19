import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';

Activity activity(String id, {String? name, int capacity = 10, bool hidden = false, bool skills = false}) => Activity(
  id: id,
  branchId: 'branch',
  name: name ?? id,
  description: '',
  capacity: capacity,
  category: skills ? ActivityCategory.skills : ActivityCategory.creative,
  isSkillsRec: skills,
  doubleSchedule: false,
  maxAssignments: null,
  isHidden: hidden,
  preferenceRequired: true,
);

/// A camper with `blockId: scheduledActivityId` assignments.
Camper camper(String id, {Map<String, String> assignments = const {}}) => Camper(
  id: id,
  sessionId: 'session',
  firstName: id,
  preferredName: null,
  lastName: 'Camper',
  gender: null,
  birthdate: DateTime(2016, 5, 1),
  note: '',
  cabinId: null,
  ultracampId: null,
  arrived: false,
  canSwim: true,
  satisfactionIndex: null,
  preferencesSubmittedAt: null,
  assignments: assignments,
);

ScheduleDay day(int index, {String? id}) =>
    ScheduleDay(id: id ?? 'day$index', sessionId: 'session', dayIndex: index, date: DateTime(2026, 7, 6 + index));

Block block(
  String id,
  ScheduleDay day, {
  String? title,
  Duration start = const Duration(hours: 10, minutes: 15),
  Duration end = const Duration(hours: 11, minutes: 15),
  bool skills = false,
}) => Block(
  id: id,
  sessionId: 'session',
  dayId: day.id,
  title: title ?? id,
  date: day.date,
  dayIndex: day.dayIndex,
  startTime: start,
  endTime: end,
  isSkillsRec: skills,
);

ScheduledActivity scheduled(String id, Block block, Activity activity) =>
    ScheduledActivity(id: id, sessionId: 'session', blockId: block.id, activityId: activity.id);

Schedule scheduleOf({
  required List<ScheduleDay> days,
  required List<Block> blocks,
  required List<ScheduledActivity> scheduled,
  required List<Activity> activities,
}) => Schedule(days: days, blocks: blocks, scheduledActivities: scheduled, activitiesById: {for (final a in activities) a.id: a});
