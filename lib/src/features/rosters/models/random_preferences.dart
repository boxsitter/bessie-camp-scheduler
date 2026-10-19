import 'dart:math';

import '../../../models/activity.dart';
import '../../../models/camp_session.dart';
import '../../../models/enums.dart';
import '../../../models/schedule.dart';

/// A random set of requests and vetoes (activity ids) for one camper.
class RandomPreferences {
  const RandomPreferences({required this.requests, required this.vetoes});

  final List<String> requests;
  final List<String> vetoes;
}

/// Picks random preferences that respect a session's [limits] and only use
/// activities a camper is allowed to rank (offered in the session, not hidden,
/// and expected to be ranked). Nothing is requested and vetoed at once.
///
/// A testing aid: it fills each limit completely, so a run exercises the
/// auto-assignment as hard as the data allows.
RandomPreferences pickRandomPreferences({required Schedule schedule, required PreferenceLimits limits, required Random random}) {
  final rankable =
      schedule.offeredActivities.where((a) => !a.isHidden && a.preferenceRequired).toList()
        ..sort((a, b) => a.id.compareTo(b.id)); // a stable base for the shuffle

  final requests = <String>[];
  final vetoes = <String>[];
  for (final skillsRec in const [false, true]) {
    final pool = rankable.where((Activity a) => a.isSkillsRec == skillsRec).toList()..shuffle(random);
    final wantedRequests = limits.maxFor(PreferenceKind.request, skillsRec: skillsRec);
    final wantedVetoes = limits.maxFor(PreferenceKind.veto, skillsRec: skillsRec);
    requests.addAll(pool.take(wantedRequests).map((a) => a.id));
    vetoes.addAll(pool.skip(wantedRequests).take(wantedVetoes).map((a) => a.id));
  }
  return RandomPreferences(requests: requests, vetoes: vetoes);
}
