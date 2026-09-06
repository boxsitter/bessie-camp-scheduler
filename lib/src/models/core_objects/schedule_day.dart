
import '../../ember_core.dart';

typedef ScheduleDayId = String;

class ScheduleDay extends CoreObject {
  int dayIndex;
  DateTime start;
  List<BlockId> blockCmps;

  ScheduleDay({
    required this.dayIndex,
    required this.start,
    List<BlockId>? blockCmps,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : blockCmps = blockCmps ?? [],
        super(
        domain: 'ses',
        type: 'schedule_day',
        idTag: '${dayIndex}_${DateTimeHelpers.weekdayToString(start.weekday, true)}',
      );

  @override
  String coreToString() {
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'dayIndex': dayIndex,
      'start': start,
      'blockCmps': blockCmps,
    });
    return json;
  }

  factory ScheduleDay.fromJson(Map<String, dynamic> json) {
    final scheduleDay = ScheduleDay(
      dayIndex: json['dayIndex'] as int,
      // --- CHANGED LINE ---
      start: safeParseDateTime(json['start']) ?? (throw ArgumentError('ScheduleDay.fromJson: "start" is required.')),
      // --- END CHANGED LINE ---
      blockCmps: (json['blockCmps'] as List?)?.cast<BlockId>() ?? <BlockId>[],
    );
    scheduleDay.overwriteCoreObjectFromJson(json);
    return scheduleDay;
  }

  @override
  void purgeRef(String id) {
    blockCmps.remove(id);
  }
}