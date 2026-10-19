import 'package:collection/collection.dart';

import 'activity.dart';
import 'row_codec.dart';
import 'titled.dart';

class ScheduleDay {
  const ScheduleDay({required this.id, required this.sessionId, required this.dayIndex, required this.date});

  final String id;
  final String sessionId;
  final int dayIndex;
  final DateTime date;

  factory ScheduleDay.fromRow(Map<String, dynamic> row) => ScheduleDay(
    id: row['id'] as String,
    sessionId: row['session_id'] as String,
    dayIndex: row['day_index'] as int,
    date: parseDate(row['date'] as String),
  );
}

const _weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

/// A slot in a day that campers are given an activity for.
class Block implements Titled {
  const Block({
    required this.id,
    required this.sessionId,
    required this.dayId,
    required this.title,
    required this.date,
    required this.dayIndex,
    required this.startTime,
    required this.endTime,
    required this.isSkillsRec,
  });

  final String id;
  final String sessionId;
  final String dayId;
  @override
  final String title;

  /// The calendar day of the block (local midnight) and its position in the session.
  final DateTime date;
  final int dayIndex;

  /// Wall-clock times, as durations since midnight.
  final Duration startTime;
  final Duration endTime;
  final bool isSkillsRec;

  DateTime get start => DateTime(date.year, date.month, date.day, startTime.inHours, startTime.inMinutes % 60);
  DateTime get end => DateTime(date.year, date.month, date.day, endTime.inHours, endTime.inMinutes % 60);

  String get weekdayName => _weekdayNames[date.weekday - 1];

  @override
  String get displayTitle => '$weekdayName - $title';

  factory Block.fromRow(Map<String, dynamic> row, ScheduleDay day) => Block(
    id: row['id'] as String,
    sessionId: row['session_id'] as String,
    dayId: row['day_id'] as String,
    title: row['title'] as String,
    date: day.date,
    dayIndex: day.dayIndex,
    startTime: parseTime(row['start_time'] as String),
    endTime: parseTime(row['end_time'] as String),
    isSkillsRec: row['is_skills_rec'] as bool,
  );
}

/// An activity offered during a specific block.
class ScheduledActivity {
  const ScheduledActivity({required this.id, required this.sessionId, required this.blockId, required this.activityId});

  final String id;
  final String sessionId;
  final String blockId;
  final String activityId;

  factory ScheduledActivity.fromRow(Map<String, dynamic> row) => ScheduledActivity(
    id: row['id'] as String,
    sessionId: row['session_id'] as String,
    blockId: row['block_id'] as String,
    activityId: row['activity_id'] as String,
  );
}

/// Everything scheduled in one session, with lookups.
class Schedule {
  Schedule({
    required List<ScheduleDay> days,
    required List<Block> blocks,
    required List<ScheduledActivity> scheduledActivities,
    required Map<String, Activity> activitiesById,
  }) : days = List.unmodifiable(days.sorted((a, b) => a.dayIndex.compareTo(b.dayIndex))),
       blocks = List.unmodifiable(blocks.sorted((a, b) => a.start.compareTo(b.start))),
       scheduledActivities = List.unmodifiable(scheduledActivities),
       activitiesById = Map.unmodifiable(activitiesById),
       _blocksById = {for (final b in blocks) b.id: b},
       _scheduledById = {for (final s in scheduledActivities) s.id: s};

  final List<ScheduleDay> days;

  /// Chronological.
  final List<Block> blocks;
  final List<ScheduledActivity> scheduledActivities;

  /// The catalog entries for every activity scheduled in this session.
  final Map<String, Activity> activitiesById;

  final Map<String, Block> _blocksById;
  final Map<String, ScheduledActivity> _scheduledById;

  Block? blockById(String id) => _blocksById[id];
  ScheduledActivity? scheduledActivityById(String id) => _scheduledById[id];

  /// The catalog activity behind a scheduled activity.
  Activity? activityOf(ScheduledActivity scheduled) => activitiesById[scheduled.activityId];

  List<ScheduledActivity> scheduledIn(String blockId) => scheduledActivities.where((s) => s.blockId == blockId).toList();

  /// Distinct activities offered anywhere in the session.
  Set<Activity> get offeredActivities => {
    for (final s in scheduledActivities)
      if (activitiesById[s.activityId] != null) activitiesById[s.activityId]!,
  };

  bool get isEmpty => blocks.isEmpty;
}
