import 'assignment_result.dart';

/// The stalemates recorded so far in a run, indexed by participant so that
/// "does this participant have a stalemate?" is a constant-time question.
class StalemateLog {
  final List<Stalemate> _entries = [];
  final Set<String> _participantIds = {};

  /// All recorded stalemates, in the order they were recorded.
  List<Stalemate> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  bool get isNotEmpty => _entries.isNotEmpty;

  int get length => _entries.length;

  void add(Stalemate stalemate) {
    _entries.add(stalemate);
    _participantIds.add(stalemate.participantId);
  }

  /// Whether any slot of [participantId] is a stalemate. O(1).
  bool hasStalemate(String participantId) =>
      _participantIds.contains(participantId);
}
