import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/camper.dart';
import 'package:bessie/src/models/enums.dart';

Activity activity(
  String id, {
  String? name,
  ActivityCategory category = ActivityCategory.creative,
  bool skills = false,
  bool hidden = false,
  bool preferenceRequired = true,
  int capacity = 10,
}) => Activity(
  id: id,
  branchId: 'branch',
  name: name ?? id,
  description: '',
  capacity: capacity,
  category: skills ? ActivityCategory.skills : category,
  isSkillsRec: skills,
  doubleSchedule: false,
  maxAssignments: null,
  isHidden: hidden,
  preferenceRequired: preferenceRequired,
);

Camper camper(
  String id, {
  String first = 'Sam',
  String last = 'Smith',
  String? cabinId,
  Map<String, PreferenceKind> preferences = const {},
  DateTime? submittedAt,
}) => Camper(
  id: id,
  sessionId: 'session',
  firstName: first,
  preferredName: null,
  lastName: last,
  gender: null,
  birthdate: DateTime(2016, 5, 1),
  note: '',
  cabinId: cabinId,
  ultracampId: null,
  arrived: false,
  canSwim: true,
  satisfactionIndex: null,
  preferencesSubmittedAt: submittedAt,
  preferences: preferences,
);

Cabin cabin(String id, {String? name, String? displayName, int position = 0}) =>
    Cabin(id: id, branchId: 'branch', name: name ?? id, displayName: displayName, village: '', capacity: 10, position: position);

const limits = PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1);

CampSession campSession(String id, {PreferenceLimits sessionLimits = limits}) =>
    CampSession(id: id, seasonId: 'season', name: 'Session $id', startsOn: DateTime(2026, 7, 6), limits: sessionLimits);
