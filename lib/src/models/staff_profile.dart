import 'enums.dart';

class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.organizationId,
    required this.firstName,
    required this.lastName,
    required this.preferredName,
    required this.role,
    required this.active,
    required this.preferences,
  });

  final String id;
  final String organizationId;
  final String firstName;
  final String lastName;
  final String? preferredName;
  final StaffRole role;
  final bool active;

  /// Per-user UI settings, stored as JSON.
  final Map<String, dynamic> preferences;

  String get name => (preferredName?.isNotEmpty ?? false) ? preferredName! : firstName;
  String get fullName => '$name $lastName';
  String get initials => '${name.isEmpty ? '' : name[0]}${lastName.isEmpty ? '' : lastName[0]}'.toUpperCase();

  factory StaffProfile.fromRow(Map<String, dynamic> row) => StaffProfile(
    id: row['id'] as String,
    organizationId: row['organization_id'] as String,
    firstName: row['first_name'] as String,
    lastName: row['last_name'] as String,
    preferredName: row['preferred_name'] as String?,
    role: StaffRole.fromDb(row['role'] as String),
    active: row['active'] as bool,
    preferences: Map<String, dynamic>.from(row['preferences'] as Map? ?? const {}),
  );
}
