import 'package:collection/collection.dart';

import '../../../models/activity.dart';
import '../../../models/camp_session.dart';
import '../../../models/enums.dart';

/// What happened when an activity was dropped on a [PreferenceBoard].
class Placement {
  const Placement._(this.board, {required this.changed, this.rejection});

  /// Nothing to do: the activity was already where it was dropped.
  const Placement.unchanged(PreferenceBoard board) : this._(board, changed: false);

  const Placement.moved(PreferenceBoard board) : this._(board, changed: true);

  /// The move is not allowed; [reason] is ready to show to the user.
  const Placement.rejected(PreferenceBoard board, String reason) : this._(board, changed: false, rejection: reason);

  /// The board after the move (the same board when nothing changed).
  final PreferenceBoard board;
  final bool changed;
  final String? rejection;

  bool get isRejected => rejection != null;
}

/// One camper's requests and vetoes while a counselor is editing them.
///
/// Every rankable activity is in exactly one of three places: requested,
/// vetoed, or neutral (the camper is open to it). Requests and vetoes are
/// limited per session, counted separately for standard activities and skills
/// recs. A board is immutable; [place] returns the next board.
class PreferenceBoard {
  PreferenceBoard._(this._activitiesById, this._sorted, this.limits, this.choices);

  /// A board over [activities], starting from [choices]. Choices about
  /// activities that are not in [activities] are dropped.
  factory PreferenceBoard({
    required Iterable<Activity> activities,
    required PreferenceLimits limits,
    Map<String, PreferenceKind> choices = const {},
  }) {
    final byId = {for (final a in activities) a.id: a};
    final sorted = byId.values.sortedBy((a) => a.name.toLowerCase());
    return PreferenceBoard._(
      Map.unmodifiable(byId),
      List.unmodifiable(sorted),
      limits,
      Map.unmodifiable({
        for (final e in choices.entries)
          if (byId.containsKey(e.key)) e.key: e.value,
      }),
    );
  }

  final Map<String, Activity> _activitiesById;

  /// Every activity on the board, alphabetical.
  final List<Activity> _sorted;

  final PreferenceLimits limits;

  /// activity id -> what was chosen. Activities not listed are neutral.
  final Map<String, PreferenceKind> choices;

  bool get isEmpty => choices.isEmpty;

  List<Activity> get activities => _sorted;

  bool get hasStandardActivities => _sorted.any((a) => !a.isSkillsRec);
  bool get hasSkillsActivities => _sorted.any((a) => a.isSkillsRec);

  PreferenceKind? kindOf(Activity activity) => choices[activity.id];

  Set<String> get requestedIds => _idsOf(PreferenceKind.request);
  Set<String> get vetoedIds => _idsOf(PreferenceKind.veto);

  Set<String> _idsOf(PreferenceKind kind) => {
    for (final e in choices.entries)
      if (e.value == kind) e.key,
  };

  /// The categories of the standard (non skills rec) activities, in display
  /// order, leaving out categories without any activity.
  List<ActivityCategory> get standardCategories => [
    for (final category in ActivityCategory.values)
      if (_sorted.any((a) => !a.isSkillsRec && a.category == category)) category,
  ];

  /// The activities the camper is open to, optionally narrowed to one
  /// [category] (ignored for skills recs, which are not split by category).
  List<Activity> neutral({required bool skillsRec, ActivityCategory? category}) => [
    for (final a in _sorted)
      if (a.isSkillsRec == skillsRec && choices[a.id] == null && (skillsRec || category == null || a.category == category)) a,
  ];

  /// The activities chosen as [kind] among standard activities or skills recs.
  List<Activity> chosen(PreferenceKind kind, {required bool skillsRec}) => [
    for (final a in _sorted)
      if (a.isSkillsRec == skillsRec && choices[a.id] == kind) a,
  ];

  int count(PreferenceKind kind, {required bool skillsRec}) => chosen(kind, skillsRec: skillsRec).length;

  /// How many more of [kind] may still be chosen.
  int remaining(PreferenceKind kind, {required bool skillsRec}) {
    final left = limits.maxFor(kind, skillsRec: skillsRec) - count(kind, skillsRec: skillsRec);
    return left < 0 ? 0 : left;
  }

  /// Moves [activity] to [kind], or back to neutral when [kind] is null.
  /// Nothing moves when the limit for that kind is already reached.
  Placement place(Activity activity, PreferenceKind? kind) {
    final known = _activitiesById[activity.id];
    if (known == null) return Placement.rejected(this, 'That activity isn\'t available for preferences.');
    if (choices[known.id] == kind) return Placement.unchanged(this);

    if (kind != null && remaining(kind, skillsRec: known.isSkillsRec) == 0) {
      return Placement.rejected(this, _limitMessage(kind, known.isSkillsRec, limits.maxFor(kind, skillsRec: known.isSkillsRec)));
    }

    final next = Map.of(choices);
    if (kind == null) {
      next.remove(known.id);
    } else {
      next[known.id] = kind;
    }
    return Placement.moved(PreferenceBoard._(_activitiesById, _sorted, limits, Map.unmodifiable(next)));
  }

  static String _limitMessage(PreferenceKind kind, bool skillsRec, int max) {
    final verb = kind == PreferenceKind.request ? 'request' : 'veto';
    final things = skillsRec ? (max == 1 ? 'skills rec' : 'skills recs') : (max == 1 ? 'activity' : 'activities');
    if (max == 0) return 'This session doesn\'t allow campers to $verb $things.';
    return 'You can only $verb $max $things. Move one back to the library first.';
  }
}
