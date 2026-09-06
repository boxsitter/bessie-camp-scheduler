

import '../../../ember_core.dart';

class ActivityDependent extends CoreObject implements Dependent{
  @override
  final String principalPar;
  final Set<String> camperRefs;
  final String blockRef;

  ActivityDependent({
    required this.principalPar,
    required this.blockRef,
    Set<String>? camperRefs,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : camperRefs = camperRefs ?? {},
        super(
          domain: 'ses',
          type: 'activity_dependent',
          idTag: IdFunctions.getIdPart(principalPar, 0), // inherits tag from parent
        );

  @override
  String coreToString() {
    return id;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'principalPar': principalPar,
      'camperRefs': camperRefs.toList(),
      'blockRef': blockRef,
    });
    return json;
  }

  factory ActivityDependent.fromJson(Map<String, dynamic> json) {
    ActivityDependent activity = ActivityDependent(
      principalPar: json['principalPar'] as String,
      camperRefs: (json['camperRefs'] as List?)?.cast<String>().toSet() ?? <String>{},
      blockRef: json['blockRef'] as String,
    );
    activity.overwriteCoreObjectFromJson(json);
    return activity;
  }

  @override
  void purgeRef(String id) {
    Debug.logInfo('Purging $id from ${this.id}');
    // TODO: implement purgeRef
  }
}
