import 'dart:math';

import 'package:bessie/src/features/rosters/models/random_preferences.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';

void main() {
  const limits = PreferenceLimits(maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 1, maxSkillsVetoes: 1);

  final regular = [for (var i = 0; i < 10; i++) makeActivity('act$i', 'Activity $i')];
  final skills = [for (var i = 0; i < 4; i++) makeActivity('skill$i', 'Skill $i', skills: true)];
  final hidden = makeActivity('hidden', 'Free Time', hidden: true);
  final unranked = makeActivity('unranked', 'Meeting', preferenceRequired: false);
  final everything = [...regular, ...skills, hidden, unranked];

  final schedule = makeSchedule(
    blocks: [makeBlock('b1', 'AM1')],
    activities: everything,
    scheduled: {for (final a in everything) 's-${a.id}': ('b1', a.id)},
  );

  test('fills every limit with distinct activities', () {
    final picks = pickRandomPreferences(schedule: schedule, limits: limits, random: Random(1));
    final skillIds = skills.map((a) => a.id).toSet();
    expect(picks.requests.where((id) => !skillIds.contains(id)), hasLength(3));
    expect(picks.requests.where(skillIds.contains), hasLength(1));
    expect(picks.vetoes.where((id) => !skillIds.contains(id)), hasLength(2));
    expect(picks.vetoes.where(skillIds.contains), hasLength(1));
    expect({...picks.requests, ...picks.vetoes}, hasLength(picks.requests.length + picks.vetoes.length));
  });

  test('never uses hidden activities or ones that need no preference', () {
    for (var seed = 0; seed < 30; seed++) {
      final picks = pickRandomPreferences(schedule: schedule, limits: limits, random: Random(seed));
      expect([...picks.requests, ...picks.vetoes], isNot(contains('hidden')));
      expect([...picks.requests, ...picks.vetoes], isNot(contains('unranked')));
    }
  });

  test('is repeatable for a seed and varies between seeds', () {
    final a = pickRandomPreferences(schedule: schedule, limits: limits, random: Random(7));
    final b = pickRandomPreferences(schedule: schedule, limits: limits, random: Random(7));
    expect(a.requests, b.requests);
    expect(a.vetoes, b.vetoes);
    final others = {
      for (var seed = 0; seed < 10; seed++)
        pickRandomPreferences(schedule: schedule, limits: limits, random: Random(seed)).requests.join(','),
    };
    expect(others.length, greaterThan(1));
  });

  test('uses what there is when the schedule offers fewer activities than the limits', () {
    final small = makeSchedule(
      blocks: [makeBlock('b1', 'AM1')],
      activities: [regular[0], regular[1]],
      scheduled: {'s0': ('b1', 'act0'), 's1': ('b1', 'act1')},
    );
    final picks = pickRandomPreferences(schedule: small, limits: limits, random: Random(3));
    expect(picks.requests, hasLength(2));
    expect(picks.vetoes, isEmpty);
  });
}
