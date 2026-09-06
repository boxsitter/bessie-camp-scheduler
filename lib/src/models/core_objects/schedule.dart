

import '../../ember_core.dart';

class Schedule extends CoreObject {
  List<ScheduleDayId> scheduleDayCmps;
  Set<PrincipalActivityId> principalActivityRefs;

  Schedule({
    List<BlockId>? scheduleDayCmps,
    Set<PrincipalActivityId>? principalActivityRefs,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : scheduleDayCmps = scheduleDayCmps ?? [],
        principalActivityRefs = principalActivityRefs ?? {},
        super(
          domain: 'ses',
          type: 'schedule',
          idTag: 'schedule',
        );

  @override
  String coreToString() {
    return 'Schedule with ${scheduleDayCmps.length} block(s)';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'scheduleDayCmps': scheduleDayCmps,
      'principalActivityRefs': principalActivityRefs.toList(),
    });
    return json;
  }

  factory Schedule.fromJson(Map<String, dynamic> json) {
    final schedule = Schedule(
      scheduleDayCmps: (json['scheduleDayCmps'] as List?)?.cast<ScheduleDayId>() ?? <ScheduleDayId>[],
      principalActivityRefs: (json['principalActivityRefs'] as List?)?.cast<PrincipalActivityId>().toSet() ?? <PrincipalActivityId>{},
    );
    schedule.overwriteCoreObjectFromJson(json);
    return schedule;
  }

  @override
  void purgeRef(String id) {
    principalActivityRefs.remove(id);
  }
}
