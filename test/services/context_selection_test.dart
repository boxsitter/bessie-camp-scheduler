import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:flutter_test/flutter_test.dart';

Season season(String name, String from, String to) =>
    Season(id: name, branchId: 'b', name: name, startsOn: DateTime.parse(from), endsOn: DateTime.parse(to));

CampSession session(String name, String start) => CampSession(
  id: name,
  seasonId: 's',
  name: name,
  startsOn: DateTime.parse(start),
  limits: const PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 2, maxSkillsVetoes: 1),
);

void main() {
  group('pickSeason (newest first)', () {
    final seasons = [season('2026', '2026-06-01', '2026-08-31'), season('2025', '2025-06-01', '2025-08-31')];

    test('the season containing today', () {
      expect(ContextService.pickSeason(seasons, DateTime(2025, 7, 4)).name, '2025');
      expect(ContextService.pickSeason(seasons, DateTime(2026, 6, 1, 23, 59)).name, '2026');
    });

    test('between seasons: the most recent one that has started', () {
      expect(ContextService.pickSeason(seasons, DateTime(2026, 1, 15)).name, '2025');
      expect(ContextService.pickSeason(seasons, DateTime(2026, 10, 19)).name, '2026');
    });

    test('before any season: the earliest', () {
      expect(ContextService.pickSeason(seasons, DateTime(2024, 1, 1)).name, '2025');
    });
  });

  group('pickSession', () {
    final sessions = [session('one', '2026-06-29'), session('two', '2026-07-13'), session('three', '2026-07-27')];

    test('the most recent session that has started', () {
      expect(ContextService.pickSession(sessions, DateTime(2026, 7, 20)).name, 'two');
      expect(ContextService.pickSession(sessions, DateTime(2026, 7, 13)).name, 'two');
      expect(ContextService.pickSession(sessions, DateTime(2026, 9, 1)).name, 'three');
    });

    test('before the first session: the soonest', () {
      expect(ContextService.pickSession(sessions, DateTime(2026, 5, 1)).name, 'one');
    });
  });
}
