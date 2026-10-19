import 'enums.dart';
import 'titled.dart';

/// An activity in a branch's catalog. See `ScheduledActivity` for an activity
/// offered during a particular block.
class Activity implements Titled {
  const Activity({
    required this.id,
    required this.branchId,
    required this.name,
    required this.description,
    required this.capacity,
    required this.category,
    required this.isSkillsRec,
    required this.doubleSchedule,
    required this.maxAssignments,
    required this.isHidden,
    required this.preferenceRequired,
  });

  final String id;
  final String branchId;
  final String name;
  final String description;
  final int capacity;
  final ActivityCategory category;
  final bool isSkillsRec;

  /// Occupies two consecutive blocks on the same day.
  final bool doubleSchedule;

  /// Most times one camper may be given this activity in a session; null = no limit.
  final int? maxAssignments;

  /// Hidden activities keep campers busy but are never offered or auto-assigned.
  final bool isHidden;

  /// Whether campers are expected to rank this activity.
  final bool preferenceRequired;

  @override
  String get title => name;
  @override
  String get displayTitle => name;

  factory Activity.fromRow(Map<String, dynamic> row) => Activity(
    id: row['id'] as String,
    branchId: row['branch_id'] as String,
    name: row['name'] as String,
    description: row['description'] as String,
    capacity: row['capacity'] as int,
    category: ActivityCategory.fromDb(row['category'] as String),
    isSkillsRec: row['is_skills_rec'] as bool,
    doubleSchedule: row['double_schedule'] as bool,
    maxAssignments: row['max_assignments'] as int?,
    isHidden: row['is_hidden'] as bool,
    preferenceRequired: row['preference_required'] as bool,
  );

  Map<String, dynamic> toInsertRow() => {
    'branch_id': branchId,
    'name': name,
    'description': description,
    'capacity': capacity,
    'category': category.dbValue,
    'is_skills_rec': isSkillsRec,
    'double_schedule': doubleSchedule,
    'max_assignments': maxAssignments,
    'is_hidden': isHidden,
    'preference_required': preferenceRequired,
  };
}
