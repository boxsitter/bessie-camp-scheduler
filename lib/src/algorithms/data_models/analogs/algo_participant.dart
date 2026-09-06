/// A lightweight, algorithm-specific representation of a participant.
///
/// This class contains the core information about a participant needed for
/// the assignment process.
class AlgoParticipant {
  /// The unique identifier for the participant.
  final String id;

  /// The participant's date of birth, which can be used for age-based constraints.
  final DateTime birthdate;

  /// Creates an instance of [AlgoParticipant].
  AlgoParticipant({
    required this.id,
    required this.birthdate,
  });
}
