import '../../../ember_core.dart';
import '../../interfaces/elevated.dart';

class Organization extends CoreObject implements Domain, Elevated{
  final String name;

  Organization({
    required this.name,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : super(
          domain: 'rot',
          type: 'organization',
          idTag: name,
        );

  @override
  String coreToString() {
    return 'Organization: $name';
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
    });
    return json;
  }

  factory Organization.fromJson(Map<String, dynamic> json,
      [bool clone = false]) {
    final org = Organization(
      name: json['name'] as String,
    );
    org.overwriteCoreObjectFromJson(json);
    return org;
  }


}
