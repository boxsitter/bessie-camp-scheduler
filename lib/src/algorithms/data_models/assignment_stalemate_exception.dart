import 'assignment_result.dart';

/// Thrown by the engine under `StalemateStrategy.fail` when at least one
/// (participant, period) slot could not be filled.
class AssignmentStalemateException implements Exception {
  /// Every unfillable slot, with the reason for each.
  final List<Stalemate> stalemates;

  AssignmentStalemateException(List<Stalemate> stalemates)
    : stalemates = List.unmodifiable(stalemates);

  @override
  String toString() {
    final buffer = StringBuffer(
      'AssignmentStalemateException: ${stalemates.length} slot(s) could not be filled',
    );
    for (final stalemate in stalemates) {
      buffer.write('\n  - $stalemate');
    }
    return buffer.toString();
  }
}
