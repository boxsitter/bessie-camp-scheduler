import '../../ember_core.dart';
class HardcodedSessionA {
  static final sessionA = Session(
    id: 'session_a-session-sea-kfCmxXd',
    name: 'Session A',
    createdAt: DateTime.parse('2025-03-17T05:35:01.000Z').toUtc(),
    start: DateTime.now(),
  );

  static final ScheduleDay monday = ScheduleDay(
    id: '0_monday-schedule_day-ses-Nne19WU',
    start: DateTime(2025, 7, 7).toUtc(),
    dayIndex: 0,
  );

  static final ScheduleDay tuesday = ScheduleDay(
    id: '1_tuesday-schedule_day-ses-Nne19W3',
    start: DateTime(2025, 7, 8).toUtc(),
    dayIndex: 1,
  );

  static final ScheduleDay wednesday = ScheduleDay(
    id: '2_wednesday-schedule_day-ses-Nne19W4',
    start: DateTime(2025, 7, 9).toUtc(),
    dayIndex: 2,
  );

  static final ScheduleDay thursday = ScheduleDay(
    id: '3_thursday-schedule_day-ses-Nne19W5',
    start: DateTime(2025, 7, 10).toUtc(),
    dayIndex: 3,
  );

  static final ScheduleDay friday = ScheduleDay(
    id: '4_friday-schedule_day-ses-Nne19W6',
    start: DateTime(2025, 7, 11).toUtc(),
    dayIndex: 4,
  );

  static final AMABlock choiceActivity1Mon = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd3WU',
    title: 'Choice Activity 1',
    isTemplate: false,
    start: DateTime(2025, 7, 7, 10, 15),
    end: DateTime(2025, 7, 7, 11, 15),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity1Tue = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd3WX',
    title: 'Choice Activity 1',
    isTemplate: false,
    start: DateTime(2025, 7, 8, 10, 15),
    end: DateTime(2025, 7, 8, 11, 15),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity1Wed = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd3WY',
    title: 'Choice Activity 1',
    isTemplate: false,
    start: DateTime(2025, 7, 9, 10, 15),
    end: DateTime(2025, 7, 9, 11, 15),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity1Thu = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd3WZ',
    title: 'Choice Activity 1',
    isTemplate: false,
    start: DateTime(2025, 7, 10, 10, 15),
    end: DateTime(2025, 7, 10, 11, 15),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivityFri = AMABlock(
    id: 'choice_activity_1-ama_block-ses-NnRd3WA',
    title: 'Choice Activity',
    isTemplate: false,
    start: DateTime(2025, 7, 11, 11, 30),
    end: DateTime(2025, 7, 11, 12, 30),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity2Mon = AMABlock(
    id: 'choice_activity_2-ama_block-ses-NnR43WU',
    title: 'Choice Activity 2',
    isTemplate: false,
    start: DateTime(2025, 7, 7, 11, 20),
    end: DateTime(2025, 7, 7, 12, 20),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity2Tue = AMABlock(
    id: 'choice_activity_2-ama_block-ses-NnR33WX',
    title: 'Choice Activity 2',
    isTemplate: false,
    start: DateTime(2025, 7, 8, 11, 20),
    end: DateTime(2025, 7, 8, 12, 20),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity2Wed = AMABlock(
    id: 'choice_activity_2-ama_block-ses-NnR23WY',
    title: 'Choice Activity 2',
    isTemplate: false,
    start: DateTime(2025, 7, 9, 11, 20),
    end: DateTime(2025, 7, 9, 12, 20),
    isSkillsRec: false,
  );

  static final AMABlock choiceActivity2Thu = AMABlock(
    id: 'choice_activity_2-ama_block-ses-NnR13WZ',
    title: 'Choice Activity 2',
    isTemplate: false,
    start: DateTime(2025, 7, 10, 11, 20),
    end: DateTime(2025, 7, 10, 12, 20),
    isSkillsRec: false,
  );

  static final AMABlock skillsRec = AMABlock(
    id: 'skills_rec-ama_block-ses-NnR13WU',
    title: 'Skills Rec',
    isTemplate: false,
    start: DateTime(2025, 7, 8, 9, 15),
    end: DateTime(2025, 7, 8, 10, 10),
    isSkillsRec: true,
  );

  static final AMABlock skillsRecWed = AMABlock(
    id: 'skills_rec-ama_block-ses-NnR23WX',
    title: 'Skills Rec',
    isTemplate: false,
    start: DateTime(2025, 7, 9, 9, 15),
    end: DateTime(2025, 7, 9, 10, 10),
    isSkillsRec: true,
  );

  static final AMABlock skillsRecThu = AMABlock(
    id: 'skills_rec-ama_block-ses-NnR33WY',
    title: 'Skills Rec',
    isTemplate: false,
    start: DateTime(2025, 7, 10, 9, 15),
    end: DateTime(2025, 7, 10, 10, 10),
    isSkillsRec: true,
  );

  // There needs to be a method in the context service or somewhere to create a session because the schedule needs to be created with the session
  static final Schedule sessionASchedule = Schedule(
    id: 'schedule-schedule-ses-gDiY4kB',
    createdAt: DateTime.parse('2025-03-17T05:35:01.000Z').toUtc(),
  );
}