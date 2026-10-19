import 'row_codec.dart';

class Organization {
  const Organization({required this.id, required this.name});

  final String id;
  final String name;

  factory Organization.fromRow(Map<String, dynamic> row) => Organization(id: row['id'] as String, name: row['name'] as String);
}

class Branch {
  const Branch({required this.id, required this.organizationId, required this.name});

  final String id;
  final String organizationId;
  final String name;

  factory Branch.fromRow(Map<String, dynamic> row) =>
      Branch(id: row['id'] as String, organizationId: row['organization_id'] as String, name: row['name'] as String);
}

class Season {
  const Season({required this.id, required this.branchId, required this.name, required this.startsOn, required this.endsOn});

  final String id;
  final String branchId;
  final String name;
  final DateTime startsOn;
  final DateTime endsOn;

  factory Season.fromRow(Map<String, dynamic> row) => Season(
    id: row['id'] as String,
    branchId: row['branch_id'] as String,
    name: row['name'] as String,
    startsOn: parseDate(row['starts_on'] as String),
    endsOn: parseDate(row['ends_on'] as String),
  );

  bool contains(DateTime day) => !day.isBefore(startsOn) && !day.isAfter(endsOn);
}
