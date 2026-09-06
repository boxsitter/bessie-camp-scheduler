import '../ember_core.dart';

class HardcodedTestSchedule {
  static final ScheduleDay day1 = ScheduleDay(
    id: '0_wednesday-schedule_day-ses-Nned9WU',
    start: DateTime.now(),
    dayIndex: 0,
  );

  static final AMABlock choiceActivity = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd9WU',
    title: 'Choice Activity 1',
    isTemplate: false,
    start: DateTime.now(),
    end: DateTime.now(),
    isSkillsRec: false,
  );

  // There needs to be a method in the context service or somewhere to create a session because the schedule needs to be created with the session
  static final Schedule schedule = Schedule(
    id: 'schedule-schedule-ses-gDiYskB',
    createdAt: DateTime.parse('2025-03-17T05:35:01.000Z').toUtc(),
  );
}