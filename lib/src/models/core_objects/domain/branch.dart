

import '../../../ember_core.dart';
import '../../interfaces/elevated.dart';

class Branch extends CoreObject implements Domain, Elevated{
  final String name;

  Branch({
    required this.name,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : super(
          domain: 'org',
          type: 'branch',
          idTag: name,
        );

  @override
  String coreToString() {
    return 'Branch: $name';
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

  factory Branch.fromJson(Map<String, dynamic> json) {
    final branch = Branch(
      name: json['name'] as String,
    );
    branch.overwriteCoreObjectFromJson(json);
    return branch;
  }
}
