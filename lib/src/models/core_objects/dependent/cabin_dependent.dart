

import '../../../ember_core.dart';

class CabinDependent extends CoreObject implements Dependent{
  @override
  final String principalPar;
  final Set<CamperId> camperRefs;

  CabinDependent({
    required this.principalPar,
    Set<String>? camperRefs,
    super.id,
    super.createdAt,
    super.updatedAt,
  })  : camperRefs = camperRefs ?? {},
        super(
          domain: 'ses',
          type: 'cabin_dependent',
          idTag: IdFunctions.getIdPart(principalPar, 0), // inherits tag from parent
        );

  @override
  String coreToString() {
    return id;
  }

  @override
  void purgeRef(String id) {
    Debug.logInfo('Purging $id from ${this.id}');
    if (IdFunctions.getIdPart(id, 1) == 'camper') {
      camperRefs.remove(id);
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'principalPar': principalPar,
      'camperRefs': camperRefs.toList(),
    });
    return json;
  }

  factory CabinDependent.fromJson(Map<String, dynamic> json) {
    final cabinDependent = CabinDependent(
      principalPar: json['principalPar'] as String,
      camperRefs: (json['camperRefs'] as List?)?.cast<String>().toSet() ?? <String>{},
    );
    cabinDependent.overwriteCoreObjectFromJson(json);
    return cabinDependent;
  }
}
