/// A lightweight, engine-specific representation of a camper.
class AlgoParticipant {
  /// The unique identifier of the participant.
  final String id;

  /// The participant's date of birth. Only used to derive an age on the
  /// context's `now`; the engine never reads the system clock.
  final DateTime birthdate;

  const AlgoParticipant({required this.id, required this.birthdate});

  /// The participant's age in whole years on [now].
  int ageOn(DateTime now) {
    var age = now.year - birthdate.year;
    if (now.month < birthdate.month || (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  @override
  String toString() => 'AlgoParticipant($id)';
}
