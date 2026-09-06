

import '../../ember_core.dart';

typedef CabinId = String;
typedef AMABlockId = String;
typedef ActivityDependentId = String;
typedef CamperId = String;

class Camper extends CoreObject implements Rosterable, Titled {
  @override
  String firstName;
  @override
  String preferredName;
  @override
  String lastName;
  @override
  String gender;
  @override
  DateTime birthdate;
  @override
  String note;
  CabinId? cabinRef;
  @override
  String? cabinName;
  @override
  String? ultracampId;
  @override
  bool? arrived;
  @override
  bool? canSwim;
  @override
  double? activitySatisfactionIndex;
  final Map<PrincipalActivityId, double?> preferenceRefs;
  final Map<PrincipalActivityId, double> preferenceWeightRefs;
  @override
  Map<AMABlockId, ActivityDependentId?> activityAssignmentRefs;

  Camper({
    required this.firstName,
    required this.lastName,
    this.preferredName = '',
    this.gender = '',
    required this.birthdate,
    this.note = '',
    this.cabinRef,
    this.cabinName,
    this.ultracampId,
    this.arrived,
    this.canSwim,
    this.activitySatisfactionIndex,
    Map<PrincipalActivityId, double?>? preferenceRefs,
    Map<PrincipalActivityId, double>? preferenceWeightRefs,
    Map<AMABlockId, ActivityDependentId?>? activityAssignmentRefs,
    super.id,
    super.createdAt,
    super.updatedAt,
  }) : preferenceRefs = preferenceRefs ?? {},
       preferenceWeightRefs = preferenceWeightRefs ?? {},
       activityAssignmentRefs = activityAssignmentRefs ?? {},
       super(domain: 'ses', type: 'camper', idTag: '${firstName}_${lastName[0]}');

  /// returns preferred name if set, first name if not
  String get name => preferredName.isNotEmpty ? preferredName : firstName;
  @override
  String get fullName => '$firstName $lastName';
  @override
  String get title => fullName;
  @override
  String get displayTitle => '$name $lastInitial';
  String get fullNamePreferred => '$name $lastName';
  String get lastInitial => lastName[0];
  String get formattedBirthdate => DateTimeHelpers.formatDate(birthdate, false);
  @override
  bool? get preferencesCompleted => ModelHelperFunctions.simplePreferencesCompleted(this);
  int? get preferencesCompletedCount => preferenceRefs.entries.where((element) => element.value != null).length;
  bool get preferencesStarted => preferenceRefs.values.where((element) => element != null).isNotEmpty;

    int? getRelevantCompletedCount(Set<PrincipalActivityId> relevantActivities) {
      if (preferenceRefs.isEmpty) return null;
      return preferenceRefs.entries.where((element) => element.value != null && relevantActivities.contains(element.key)).length;
    }

  bool relevantPrefsCompleted(Set<PrincipalActivityId> relevantActivities) {
    bool output = true;
    for (var element in relevantActivities) {
      if (preferenceRefs[element] == null) {
        output = false;
      }
    }
    return output;
  }

  @override
  int get age =>
      (() {
        final DateTime today = DateTime.now();
        int years = (today.year - birthdate.year);
        if (today.month < birthdate.month || (today.month == birthdate.month && today.day < birthdate.day)) {
          years--;
        }
        return years < 0 ? 0 : years;
      })();

  @override
  String getFieldAsString(RosterField field) {
    switch (field) {
      case RosterField.coreId:
        return id;
      case RosterField.firstName:
        return firstName;
      case RosterField.preferredName:
        return preferredName;
      case RosterField.lastName:
        return lastName;
      case RosterField.fullName:
        return fullNamePreferred;
      case RosterField.gender:
        return gender;
      case RosterField.age:
        return age.toString();
      case RosterField.birthdate:
        return formattedBirthdate.toString();
      case RosterField.cabinName:
        return cabinName ?? 'N/A';
      case RosterField.ultracampId:
        return ultracampId.toString();
      case RosterField.note:
        return note.toString();
      case RosterField.arrived:
        return arrived == null ? 'N/A' : arrived == true ? 'Yes' : 'No';
      case RosterField.canSwim:
        return arrived == null ? 'N/A' : arrived == true ? 'Yes' : 'No';
      case RosterField.preferencesCompleted:
        return preferencesCompleted == null ? 'N/A' : preferencesCompleted! ? 'Yes' : 'No';
      case RosterField.activitySatisfactionIndex:
        return activitySatisfactionIndex != null ? activitySatisfactionIndex.toString() : 'N/A';
      default:
        if (field is AMABlock) { // TODO: This sucks
          return activityAssignmentRefs[field.dataId] ?? '';
        } else {
          return '';
        }
    }
  }

  @override
  String coreToString() {
    // TODO: implement coreToString
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'firstName': firstName,
      'lastName': lastName,
      'preferredName': preferredName,
      'gender': gender,
      'birthdate': birthdate,
      'note': note,
      'cabinRef': cabinRef,
      'cabinName': cabinName,
      'ultracampId': ultracampId,
      'preferenceRefs': preferenceRefs.map((key, value) => MapEntry(key, value?.clamp(0.0, 1.0))),
      'preferenceWeightRefs': preferenceWeightRefs.map((key, value) => MapEntry(key, value.clamp(0.0, 1.0))),
      'activityAssignmentRefs': activityAssignmentRefs,
      'arrived': arrived,
      'canSwim': canSwim,
      'activitySatisfactionIndex': activitySatisfactionIndex,
    });
    return json;
  }

  factory Camper.fromJson(Map<String, dynamic> json) {
    Camper camper = Camper(
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      preferredName: json['preferredName'] ?? '',
      gender: json['gender'] ?? '',
      // --- CHANGED LINE ---
      birthdate: safeParseDateTime(json['birthdate']) ?? (throw ArgumentError('Camper.fromJson: "birthdate" is required.')),
      // --- END CHANGED LINE ---
      note: json['note'] ?? '',
      cabinRef: json['cabinRef'],
      cabinName: json['cabinName'],
      ultracampId: json['ultracampId'],
      preferenceRefs: (json['preferenceRefs'] as Map?)?.cast<String, double?>() ?? {},
      preferenceWeightRefs: (json['preferenceWeightRefs'] as Map?)?.cast<String, double>() ?? {},
      activityAssignmentRefs: (json['activityAssignmentRefs'] as Map?)?.cast<String, String?>() ?? {},
      arrived: json['arrived'],
      canSwim: json['canSwim'],
      activitySatisfactionIndex: json['activitySatisfactionIndex'],
    );
    camper.overwriteCoreObjectFromJson(json);
    return camper;
  }

  @override
  void purgeRef(String id) {
    if (IdFunctions.getIdPart(id, 1) == 'cabin_dependent') {
      if (cabinRef == id) {
        cabinRef == null;
        cabinName == null;
      }
    }

    if (IdFunctions.getIdPart(id, 1) == 'AMA_Block') {
      activityAssignmentRefs.remove(id);
    }

    if (IdFunctions.getIdPart(id, 1) == 'activity_dependent') {
      activityAssignmentRefs.removeWhere((key, value) => value == id);
    }

    if (IdFunctions.getIdPart(id, 1) == 'principal_activity') {
      preferenceRefs.remove(id);
      preferenceWeightRefs.remove(id);
    }
  }

}
