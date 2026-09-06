
import 'package:bessie/src/models/interfaces/time_interval.dart';

import '../../../ember_core.dart';

class Season extends CoreObject implements Domain, TimeInterval{
  final String name;
  @override
  final DateTime start;
  @override
  final DateTime end;

  Season({
    required this.name,
    required this.start,
    required this.end,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : super(
          domain: 'brn',
          type: 'season',
          idTag: name,
        );

  @override
  String coreToString() {
    return 'Season: $name, Start: $start, End: $end';
  }

  @override
  void purgeRef(String id) {
    Debug.logInfo('Purging $id from ${this.id}');
    Debug.logInfo('unnecessary purge');
    return;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'name': name,
      'start': start,
      'end': end,
    });
    return json;
  }

  factory Season.fromJson(Map<String, dynamic> json) {
    final season = Season(
      name: json['name'] ?? '',
      // --- CHANGED LINES ---
      start: safeParseDateTime(json['start']) ?? (throw ArgumentError('Season.fromJson: "start" is required.')),
      end: safeParseDateTime(json['end']) ?? (throw ArgumentError('Season.fromJson: "end" is required.')),
      // --- END CHANGED LINES ---
    );
    season.overwriteCoreObjectFromJson(json);
    return season;
  }

}
