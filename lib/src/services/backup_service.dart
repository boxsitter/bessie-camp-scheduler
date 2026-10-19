import 'dart:convert';

import '../models/camper.dart';
import '../models/schedule.dart';

/// A readable snapshot of assignments and preferences, for keeping a copy
/// before trying something drastic.
class BackupService {
  const BackupService();

  static const _encoder = JsonEncoder.withIndent('  ');

  /// If [blockIds] is given, only those blocks' assignments are included.
  String assignmentsBackup({
    required String sessionId,
    required List<Camper> campers,
    required Schedule schedule,
    Set<String>? blockIds,
    DateTime? now,
  }) {
    String blockLabel(String id) => schedule.blockById(id)?.displayTitle ?? id;
    String activityLabel(String scheduledId) {
      final scheduled = schedule.scheduledActivityById(scheduledId);
      return (scheduled == null ? null : schedule.activitiesById[scheduled.activityId]?.name) ?? scheduledId;
    }

    final data = {
      'sessionId': sessionId,
      'exportedAt': (now ?? DateTime.now()).toIso8601String(),
      'campers': [
        for (final camper in campers)
          {
            'id': camper.id,
            'name': camper.fullName,
            'assignments': {
              for (final entry in camper.assignments.entries)
                if (blockIds == null || blockIds.contains(entry.key))
                  entry.key: {'block': blockLabel(entry.key), 'scheduledActivityId': entry.value, 'activity': activityLabel(entry.value)},
            },
            'requests': camper.requestedActivityIds.toList(),
            'vetoes': camper.vetoedActivityIds.toList(),
          },
      ],
    };
    return _encoder.convert(data);
  }
}
