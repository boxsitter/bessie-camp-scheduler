
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../ember_core.dart';

typedef CoreObjectObjId = String;
typedef JsonFactory<T> = T Function(Map<String, dynamic> json);

// ADD THIS HELPER FUNCTION
/// Safely parses a dynamic value into a UTC DateTime.
///
/// Handles Firestore Timestamps, existing DateTime objects, and nulls.
DateTime? safeParseDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate().toUtc();
  }
  if (value is DateTime) {
    return value.toUtc();
  }
  return null;
}


abstract class CoreObject{
  CoreObjectObjId id;
  DateTime createdAt;
  DateTime updatedAt;

  final String domain;
  final String type;
  final String idTag;

  CoreObject({
    required this.domain,
    required this.type,
    required this.idTag,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? IdFunctions.generateCoreId( domain, type, idTag),
        createdAt = (createdAt ?? DateTime.now()).toUtc(),
        updatedAt = (updatedAt ?? DateTime.now()).toUtc();

  @override
  bool operator == (Object other) => identical(this, other) || (other is CoreObject && runtimeType == other.runtimeType && id == other.id);

  @override
  int get hashCode => id.hashCode;

  String get formattedCreatedAt => DateTimeHelpers.formatDate(createdAt.toLocal(), true);
  String get formattedUpdatedAt => DateTimeHelpers.formatDate(updatedAt.toLocal(), true);

  String coreToString();
  Map<String, dynamic> toJson();
  void purgeRef(String id);

  Map<String, dynamic> toJsonSuper() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  void overwriteCoreObjectFromJson(Map<String, dynamic> json) {
    id = json['id'] as String;
    createdAt = safeParseDateTime(json['createdAt']) ?? DateTime.now().toUtc();
    updatedAt = safeParseDateTime(json['updatedAt']) ?? DateTime.now().toUtc();
  }

  String toStringSuper() {
    return '[$id]';
  }

  void updateTimestamp() {
    updatedAt = DateTime.now().toUtc();
  }

  static final Map<String, JsonFactory> _fromJsons = {
    'cabin_dependent': (json) => CabinDependent.fromJson(json),
    'activity_dependent': (json) => ActivityDependent.fromJson(json),

    'branch': (json) => Branch.fromJson(json),
    'organization': (json) => Organization.fromJson(json),
    'season': (json) => Season.fromJson(json),
    'session': (json) => Session.fromJson(json),

    'principal_activity': (json) => PrincipalActivity.fromJson(json),
    'principal_cabin': (json) => PrincipalCabin.fromJson(json),

    'ama_block': (json) => AMABlock.fromJson(json),
    'camper': (json) => Camper.fromJson(json),
    'schedule': (json) => Schedule.fromJson(json),
    'schedule_day': (json) => ScheduleDay.fromJson(json),
    'core_user': (json) => CoreUser.fromJson(json),
  };

  static T fromJson<T>(Map<String, dynamic> json) {
    JsonFactory<dynamic>? fromJsonFunction = _fromJsons[IdFunctions.getIdPart(json['id'], 1)];
    if (fromJsonFunction == null) {
      throw StateError('NEED TO ADD ${json['id']} TO FROMJSONS LIST IN COREOBJECT!');
    }
    return fromJsonFunction(json) as T;
  }
}
