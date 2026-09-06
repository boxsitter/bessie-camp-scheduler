
import '../../../ember_core.dart';
import '../../interfaces/elevated.dart';

typedef DependentId = String;
typedef PrincipalId = String;

class Session extends CoreObject implements Domain, Elevated {
  final String name;
  final DateTime start;
  final Map<String, Set<String>> refTracker;
  final Map<PrincipalId, Set<DependentId>>
  principalDependentLinkTracker; //TODO: On init, check the integrity of all principals. If one is missing, call delete on all its dependents and purge references to it
  final int maxRequests;
  final int maxVetoes;
  final int maxSkillsRequests;
  final int maxSkillsVetoes;


  Session({
    required this.name,
    required this.start,
    Map<String, Set<String>>? refTracker,
    Map<String, Set<String>>? principalDependentLinkTracker,
    this.maxRequests = 0,
    this.maxVetoes = 0,
    this.maxSkillsRequests = 0,
    this.maxSkillsVetoes = 0,
    super.id,
    super.createdAt,
    super.updatedAt,
  }) : refTracker = refTracker ?? {},
       principalDependentLinkTracker = principalDependentLinkTracker ?? {},
       super(domain: 'sea', type: 'session', idTag: name);

  @override
  String coreToString() {
    return 'Session: $name';
  }

  @override
  Map<String, dynamic> toJson() {
    final json = toJsonSuper();
    json.addAll({
      'name': name,
      'start': start,
      'refTracker': refTracker.map((key, value) => MapEntry(key, value.toList())),
      'principalDependentLinkTracker': principalDependentLinkTracker.map((key, value) => MapEntry(key, value.toList())),
      'maxRequests': maxRequests,
      'maxVetoes': maxVetoes,
      'maxSkillsRequests': maxSkillsRequests,
      'maxSkillsVetoes': maxSkillsVetoes,
    });
    return json;
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    final session = Session(
      name: json['name'] as String,
      // --- CHANGED LINE ---
      start: safeParseDateTime(json['start']) ?? (throw ArgumentError('Session.fromJson: "start" is required.')),
      // --- END CHANGED LINE ---
      refTracker:
          (json['refTracker'] as Map<String, dynamic>?)?.map((key, value) => MapEntry(key, Set<String>.from(value ?? []))) ?? {},
      principalDependentLinkTracker:
          (json['principalDependentLinkTracker'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, Set<String>.from(value ?? [])),
          ) ??
          {},
      maxRequests: (json['maxRequests'] ?? 0) as int,
      maxVetoes: (json['maxVetoes'] ?? 0) as int,
      maxSkillsRequests: (json['maxSkillsRequests'] ?? 0) as int,
      maxSkillsVetoes: (json['maxSkillsVetoes'] ?? 0) as int,
    );
    session.overwriteCoreObjectFromJson(json);
    return session;
  }

  @override
  void purgeRef(String id) {
    Debug.logInfo('Purging $id from ${this.id}');
    refTracker.remove(id);

    for (Set<String> set in refTracker.values) {
      set.remove(id);
      if (set.isEmpty) {
        refTracker.removeWhere((key, value) => value == set);
      }
    }

    principalDependentLinkTracker.remove(id);

    for (Set<String> set in principalDependentLinkTracker.values) {
      set.remove(id);
      if (set.isEmpty) {
        principalDependentLinkTracker.removeWhere((key, value) => value == set);
      }
    }
  }
}
