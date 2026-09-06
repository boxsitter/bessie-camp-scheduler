
import '../../../ember_core.dart';
import '../../interfaces/elevated.dart';

class PrincipalCabin extends CoreObject implements Principal, Elevated, Titled{
  final String name;
  final String village;
  final int index;
  final int capacity;

  PrincipalCabin({
    required this.name,
    required this.capacity,
    required this.village,
    required this.index,
    super.id,
    super.createdAt,
    super.updatedAt,
  }) : super(
    domain: 'brn',
    type: 'principal_cabin',
    idTag: name,
  );

  @override
  String coreToString() {
    return 'Branch cabin: $name, Capacity: $capacity}';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'name': name,
      'capacity': capacity,
      'village': village,
      'index': index,
    });
    return json;
  }

  factory PrincipalCabin.fromJson(Map<String, dynamic> json) {
    final branchCabin = PrincipalCabin(
      name: json['name'] as String,
      capacity: json['capacity'] as int,
      village: json['village'] as String,
      index: json['index'] as int,
    );
    branchCabin.overwriteCoreObjectFromJson(json);
    return branchCabin;
  }

  @override
  void purgeRef(String id) {
    Debug.logInfo('Purging $id from ${this.id}');
    Debug.logInfo('unnecessary purge');
  }

  @override
  // TODO: implement displayTitle
  String get displayTitle => name == 'Squirt' ? 'Ernie' : name;

  @override
  // TODO: implement title
  String get title => name == 'Squirt' ? 'Ernie' : name;
}
