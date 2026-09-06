
import '../../ember_core.dart';

abstract class Rosterable implements Titled, CoreObject {
  @override
  String get id;
  String get firstName;
  String get preferredName;
  String get lastName;
  String get fullName;
  String get gender;
  DateTime get birthdate;
  int get age;
  String get note;
  String? get cabinName;
  String? get ultracampId;
  Map<AMABlockId, ActivityDependentId?> get activityAssignmentRefs;
  bool? get arrived;
  bool? get canSwim;
  bool? get preferencesCompleted;
  double? get activitySatisfactionIndex;

  String getFieldAsString(RosterField field);
}