import 'titled.dart';

class Cabin implements Titled {
  const Cabin({
    required this.id,
    required this.branchId,
    required this.name,
    required this.displayName,
    required this.village,
    required this.capacity,
    required this.position,
  });

  final String id;
  final String branchId;
  final String name;

  /// Shown instead of [name] when set.
  final String? displayName;
  final String village;
  final int capacity;
  final int position;

  @override
  String get title => displayName ?? name;
  @override
  String get displayTitle => title;

  factory Cabin.fromRow(Map<String, dynamic> row) => Cabin(
    id: row['id'] as String,
    branchId: row['branch_id'] as String,
    name: row['name'] as String,
    displayName: row['display_name'] as String?,
    village: row['village'] as String,
    capacity: row['capacity'] as int,
    position: row['position'] as int,
  );
}
