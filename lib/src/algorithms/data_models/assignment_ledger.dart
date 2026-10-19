import 'analogs/algo_scheduled_activity.dart';
import 'assignment_context.dart';
import 'assignment_result.dart';
import 'potential_assignment.dart';

/// The single source of truth for who holds which seat during a run.
///
/// It starts out containing everything that already exists (the existing
/// assignments of the run's participants, hidden activities included, plus the
/// seats taken by campers outside the run) and then records every placement
/// the run makes. Existing assignments are therefore counted exactly once, and
/// every query the constraints and scorers need is answered from indexes:
///  * busy / free in a period: O(1)
///  * seats taken in a scheduled activity: O(1)
///  * occurrences of an activity by a participant: O(1)
///  * periods in which a participant holds an activity: O(assignments of that
///    participant for that activity)
///
/// "Hidden" (non-assignable) activities are first-class here: they keep their
/// holders busy and occupy seats; they just never become candidates.
class AssignmentLedger {
  final AssignmentContext context;

  final Map<String, _ParticipantBook> _books = {};
  final Map<String, int> _seatsTaken = {};
  final List<NewPlacement> _newPlacements = [];

  AssignmentLedger(this.context) {
    for (final participant in context.participants) {
      _books[participant.id] = _ParticipantBook(context.periods.length);
    }

    // Seats held by campers who are not part of this run.
    context.externalEnrollment.forEach((scheduledActivityId, seats) {
      if (context.scheduledActivityById(scheduledActivityId) != null && seats > 0) {
        _seatsTaken[scheduledActivityId] = seats;
      }
    });

    // Existing assignments of the run's participants.
    for (final entry in context.existingAssignments.entries) {
      final book = _books[entry.key];
      if (book == null) continue; // Not part of this run; see externalEnrollment.
      for (final scheduledActivityId in entry.value) {
        final scheduled = context.scheduledActivityById(scheduledActivityId);
        if (scheduled == null) continue;
        final periodIndex = context.periodIndex(scheduled.periodId);
        // Tolerate inconsistent input (two assignments in one period): the
        // first one defines what the participant is busy with, but every seat
        // is still counted.
        book.slots[periodIndex] ??= scheduled;
        _seatsTaken[scheduled.id] = (_seatsTaken[scheduled.id] ?? 0) + 1;
        _insertSorted(
            book.periodIndicesByActivity.putIfAbsent(scheduled.activityId, () => []),
            periodIndex);
      }
    }
    for (final book in _books.values) {
      book.periodIndicesByActivity.forEach((activityId, indices) {
        final activity = context.activityById(activityId)!;
        book.occurrences[activityId] =
            activity.doubleSchedule ? _countBlocks(indices) : indices.length;
      });
    }
  }

  /// Everything placed by this run so far, in placement order.
  List<NewPlacement> get newPlacements => List.unmodifiable(_newPlacements);

  /// Whether the participant already holds something in the period.
  bool isBusy(String participantId, int periodIndex) =>
      _books[participantId]?.slots[periodIndex] != null;

  /// What the participant holds in the period, if anything.
  AlgoScheduledActivity? heldIn(String participantId, int periodIndex) =>
      _books[participantId]?.slots[periodIndex];

  /// Whether the participant is free in every period [candidate] would occupy.
  bool isFree(PotentialAssignment candidate) {
    final id = candidate.participant.id;
    if (isBusy(id, context.periodIndex(candidate.period.id))) return false;
    final linked = candidate.linkedPeriod;
    return linked == null || !isBusy(id, context.periodIndex(linked.id));
  }

  /// The seats taken so far in a scheduled activity: external enrollment,
  /// existing assignments of the run's participants and new placements.
  int seatsTaken(String scheduledActivityId) =>
      _seatsTaken[scheduledActivityId] ?? 0;

  /// How many times the participant holds the activity this week. A
  /// double-schedule block counts once.
  int occurrences(String participantId, String activityId) =>
      _books[participantId]?.occurrences[activityId] ?? 0;

  /// Whether the participant holds the activity at least once (existing or
  /// new).
  bool holds(String participantId, String activityId) =>
      (_books[participantId]?.periodIndicesByActivity[activityId]?.isNotEmpty) ??
      false;

  /// The chronological indexes of the periods in which the participant holds
  /// the activity.
  List<int> periodIndicesOf(String participantId, String activityId) =>
      _books[participantId]?.periodIndicesByActivity[activityId] ?? const [];

  /// The activity ids of the participant's whole week (existing + new), one per
  /// filled period, in chronological order. A double block therefore appears
  /// once per period.
  Iterable<String> weekActivityIds(String participantId) sync* {
    final book = _books[participantId];
    if (book == null) return;
    for (final scheduled in book.slots) {
      if (scheduled != null) yield scheduled.activityId;
    }
  }

  /// Records an accepted candidate: both halves of a double block, atomically.
  ///
  /// Throws a [StateError] if the participant is already busy in a period the
  /// candidate occupies; double-booking is never silently allowed.
  void place(PotentialAssignment candidate) {
    final participantId = candidate.participant.id;
    final book = _books[participantId];
    if (book == null) {
      throw StateError('Participant $participantId is not part of this run.');
    }
    final scheduledActivities = candidate.scheduledActivities;
    final periods = candidate.periods;
    final indices = [for (final p in periods) context.periodIndex(p.id)];
    for (var i = 0; i < indices.length; i++) {
      if (book.slots[indices[i]] != null) {
        throw StateError('Participant $participantId is already busy in '
            'period ${periods[i].id}.');
      }
    }
    final activityId = candidate.activity.id;
    final held = book.periodIndicesByActivity.putIfAbsent(activityId, () => []);
    for (var i = 0; i < indices.length; i++) {
      final scheduled = scheduledActivities[i];
      book.slots[indices[i]] = scheduled;
      _seatsTaken[scheduled.id] = (_seatsTaken[scheduled.id] ?? 0) + 1;
      _insertSorted(held, indices[i]);
      _newPlacements.add(NewPlacement(
          participantId: participantId, scheduledActivityId: scheduled.id));
    }
    book.occurrences[activityId] = (book.occurrences[activityId] ?? 0) + 1;
  }

  /// Counts the double-schedule blocks in the chronological [indices] of one
  /// activity: a held period directly followed (same day) by another held
  /// period forms one block, anything else is an occurrence of its own.
  int _countBlocks(List<int> indices) {
    var blocks = 0;
    var i = 0;
    while (i < indices.length) {
      blocks++;
      final pairs = i + 1 < indices.length &&
          indices[i + 1] == indices[i] + 1 &&
          context.periods[indices[i]].dayId == context.periods[indices[i + 1]].dayId;
      i += pairs ? 2 : 1;
    }
    return blocks;
  }

  static void _insertSorted(List<int> sorted, int value) {
    var i = sorted.length;
    while (i > 0 && sorted[i - 1] > value) {
      i--;
    }
    sorted.insert(i, value);
  }
}

/// Everything the ledger knows about one participant.
class _ParticipantBook {
  /// What the participant holds, per chronological period index.
  final List<AlgoScheduledActivity?> slots;

  /// activityId -> sorted period indexes in which the participant holds it.
  final Map<String, List<int>> periodIndicesByActivity = {};

  /// activityId -> occurrences (double blocks count once).
  final Map<String, int> occurrences = {};

  _ParticipantBook(int periodCount) : slots = List.filled(periodCount, null);
}
