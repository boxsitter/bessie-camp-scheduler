import 'package:bessie/src/features/activity_preferences/models/preference_board.dart';
import 'package:bessie/src/models/camp_session.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final archery = activity('archery', name: 'Archery', category: ActivityCategory.sportsAndAthletics);
  final soccer = activity('soccer', name: 'soccer', category: ActivityCategory.sportsAndAthletics);
  final pottery = activity('pottery', name: 'Pottery');
  final drama = activity('drama', name: 'Drama');
  final tieDye = activity('tiedye', name: 'Tie-Dye');
  final kayak = activity('kayak', name: 'Kayaking', category: ActivityCategory.waterfront);
  final swimSkills = activity('swimskills', name: 'Swim Skills', skills: true);
  final climbSkills = activity('climbskills', name: 'Climbing Skills', skills: true);
  final archerySkills = activity('archeryskills', name: 'Archery Skills', skills: true);

  final all = [archery, soccer, pottery, drama, tieDye, kayak, swimSkills, climbSkills, archerySkills];

  PreferenceBoard boardOf({Map<String, PreferenceKind> choices = const {}, PreferenceLimits boardLimits = limits}) =>
      PreferenceBoard(activities: all, limits: boardLimits, choices: choices);

  PreferenceBoard apply(PreferenceBoard board, List<(String, PreferenceKind?)> moves) {
    var current = board;
    for (final (id, kind) in moves) {
      final placement = current.place(all.firstWhere((a) => a.id == id), kind);
      expect(placement.isRejected, isFalse, reason: 'moving $id to $kind');
      current = placement.board;
    }
    return current;
  }

  group('moving activities', () {
    test('everything starts neutral', () {
      final board = boardOf();
      expect(board.isEmpty, isTrue);
      expect(board.neutral(skillsRec: false), hasLength(6));
      expect(board.chosen(PreferenceKind.request, skillsRec: false), isEmpty);
      expect(board.chosen(PreferenceKind.veto, skillsRec: false), isEmpty);
    });

    test('moves between neutral, requested and vetoed', () {
      var board = boardOf();

      var placement = board.place(pottery, PreferenceKind.request);
      expect(placement.changed, isTrue);
      board = placement.board;
      expect(board.kindOf(pottery), PreferenceKind.request);
      expect(board.requestedIds, {'pottery'});
      expect(board.neutral(skillsRec: false), isNot(contains(pottery)));

      board = board.place(pottery, PreferenceKind.veto).board;
      expect(board.kindOf(pottery), PreferenceKind.veto);
      expect(board.requestedIds, isEmpty);
      expect(board.vetoedIds, {'pottery'});

      board = board.place(pottery, null).board;
      expect(board.kindOf(pottery), isNull);
      expect(board.isEmpty, isTrue);
      expect(board.neutral(skillsRec: false), contains(pottery));
    });

    test('putting an activity where it already is changes nothing', () {
      final board = apply(boardOf(), [('pottery', PreferenceKind.request)]);
      final again = board.place(pottery, PreferenceKind.request);
      expect(again.changed, isFalse);
      expect(again.isRejected, isFalse);
      expect(identical(again.board, board), isTrue);

      final neutral = board.place(drama, null);
      expect(neutral.changed, isFalse);
    });

    test('is immutable: placing returns a new board', () {
      final board = boardOf();
      board.place(pottery, PreferenceKind.request);
      expect(board.isEmpty, isTrue);
    });

    test('refuses activities that are not on the board', () {
      final stranger = activity('stranger');
      final placement = boardOf().place(stranger, PreferenceKind.request);
      expect(placement.isRejected, isTrue);
      expect(placement.changed, isFalse);
    });
  });

  group('limits', () {
    test('requests are capped for standard activities', () {
      final board = apply(boardOf(), [
        ('archery', PreferenceKind.request),
        ('pottery', PreferenceKind.request),
        ('drama', PreferenceKind.request),
      ]);
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 0);

      final placement = board.place(tieDye, PreferenceKind.request);
      expect(placement.isRejected, isTrue);
      expect(placement.rejection, 'You can only request 3 activities. Move one back to the library first.');
      expect(placement.changed, isFalse);
      expect(identical(placement.board, board), isTrue);
    });

    test('vetoes are capped independently of requests', () {
      final board = apply(boardOf(), [
        ('archery', PreferenceKind.request),
        ('pottery', PreferenceKind.veto),
        ('drama', PreferenceKind.veto),
      ]);
      expect(board.remaining(PreferenceKind.veto, skillsRec: false), 0);
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 2);

      expect(board.place(tieDye, PreferenceKind.veto).rejection, 'You can only veto 2 activities. Move one back to the library first.');
      expect(board.place(tieDye, PreferenceKind.request).isRejected, isFalse);
    });

    test('skills recs and standard activities are counted separately', () {
      var board = apply(boardOf(), [
        ('swimskills', PreferenceKind.request),
        ('climbskills', PreferenceKind.request),
      ]);
      expect(board.remaining(PreferenceKind.request, skillsRec: true), 0);
      // The skills limit does not eat into the standard allowance.
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 3);

      final rejected = board.place(archerySkills, PreferenceKind.request);
      expect(rejected.rejection, 'You can only request 2 skills recs. Move one back to the library first.');

      board = apply(board, [
        ('archery', PreferenceKind.request),
        ('pottery', PreferenceKind.request),
        ('drama', PreferenceKind.request),
      ]);
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 0);
      expect(board.remaining(PreferenceKind.request, skillsRec: true), 0);
    });

    test('moving a request to a veto frees a request slot', () {
      var board = apply(boardOf(), [
        ('archery', PreferenceKind.request),
        ('pottery', PreferenceKind.request),
        ('drama', PreferenceKind.request),
      ]);
      board = board.place(drama, PreferenceKind.veto).board;
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 1);
      expect(board.remaining(PreferenceKind.veto, skillsRec: false), 1);
      expect(board.place(tieDye, PreferenceKind.request).isRejected, isFalse);
    });

    test('a full veto list blocks a move from requests but keeps the request', () {
      final board = apply(boardOf(), [
        ('archery', PreferenceKind.veto),
        ('pottery', PreferenceKind.veto),
        ('drama', PreferenceKind.request),
      ]);
      final placement = board.place(drama, PreferenceKind.veto);
      expect(placement.isRejected, isTrue);
      expect(placement.board.kindOf(drama), PreferenceKind.request);
    });

    test('remaining never goes below zero when the limits were lowered', () {
      const strict = PreferenceLimits(maxRequests: 1, maxVetoes: 0, maxSkillsRequests: 0, maxSkillsVetoes: 0);
      final board = boardOf(
        choices: {'archery': PreferenceKind.request, 'pottery': PreferenceKind.request},
        boardLimits: strict,
      );
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 0);
      expect(board.count(PreferenceKind.request, skillsRec: false), 2);
    });

    test('a limit of zero says so', () {
      const strict = PreferenceLimits(maxRequests: 3, maxVetoes: 0, maxSkillsRequests: 2, maxSkillsVetoes: 0);
      final board = boardOf(boardLimits: strict);
      expect(board.place(pottery, PreferenceKind.veto).rejection, 'This session doesn\'t allow campers to veto activities.');
      expect(board.place(swimSkills, PreferenceKind.veto).rejection, 'This session doesn\'t allow campers to veto skills recs.');
    });

    test('speaks in the singular for a limit of one', () {
      final board = apply(boardOf(), [('swimskills', PreferenceKind.veto)]);
      expect(board.place(climbSkills, PreferenceKind.veto).rejection, 'You can only veto 1 skills rec. Move one back to the library first.');
    });
  });

  group('counting and listing', () {
    test('counts per kind and per skills-vs-standard', () {
      final board = boardOf(
        choices: {
          'archery': PreferenceKind.request,
          'pottery': PreferenceKind.request,
          'swimskills': PreferenceKind.request,
          'drama': PreferenceKind.veto,
        },
      );
      expect(board.count(PreferenceKind.request, skillsRec: false), 2);
      expect(board.count(PreferenceKind.request, skillsRec: true), 1);
      expect(board.count(PreferenceKind.veto, skillsRec: false), 1);
      expect(board.count(PreferenceKind.veto, skillsRec: true), 0);
      expect(board.remaining(PreferenceKind.request, skillsRec: false), 1);
      expect(board.remaining(PreferenceKind.request, skillsRec: true), 1);
      expect(board.remaining(PreferenceKind.veto, skillsRec: false), 1);
      expect(board.remaining(PreferenceKind.veto, skillsRec: true), 1);
    });

    test('chosen activities are alphabetical, ignoring case', () {
      final board = boardOf(
        choices: {'soccer': PreferenceKind.request, 'archery': PreferenceKind.request, 'pottery': PreferenceKind.request},
      );
      expect(board.chosen(PreferenceKind.request, skillsRec: false).map((a) => a.name), ['Archery', 'Pottery', 'soccer']);
    });

    test('drops choices about activities that are not on the board', () {
      final board = boardOf(choices: {'pottery': PreferenceKind.request, 'gone': PreferenceKind.veto});
      expect(board.choices, {'pottery': PreferenceKind.request});
      expect(board.vetoedIds, isEmpty);
    });

    test('the choices cannot be changed from outside', () {
      final board = boardOf(choices: {'pottery': PreferenceKind.request});
      expect(() => board.choices['drama'] = PreferenceKind.veto, throwsUnsupportedError);
    });
  });

  group('categories', () {
    test('lists only categories of standard activities, in display order', () {
      final board = boardOf();
      expect(board.standardCategories, [
        ActivityCategory.creative,
        ActivityCategory.sportsAndAthletics,
        ActivityCategory.waterfront,
      ]);
    });

    test('groups the library by category and hides what was chosen', () {
      final board = apply(boardOf(), [('pottery', PreferenceKind.request), ('soccer', PreferenceKind.veto)]);
      expect(board.neutral(skillsRec: false, category: ActivityCategory.creative).map((a) => a.name), ['Drama', 'Tie-Dye']);
      expect(board.neutral(skillsRec: false, category: ActivityCategory.sportsAndAthletics).map((a) => a.name), ['Archery']);
      expect(board.neutral(skillsRec: false, category: ActivityCategory.waterfront).map((a) => a.name), ['Kayaking']);
      expect(board.neutral(skillsRec: false, category: ActivityCategory.silly), isEmpty);
    });

    test('skills recs are not split by category', () {
      final board = apply(boardOf(), [('swimskills', PreferenceKind.request)]);
      expect(board.neutral(skillsRec: true).map((a) => a.name), ['Archery Skills', 'Climbing Skills']);
      expect(board.neutral(skillsRec: true, category: ActivityCategory.creative).map((a) => a.name), ['Archery Skills', 'Climbing Skills']);
    });

    test('without a category all standard activities are listed', () {
      expect(boardOf().neutral(skillsRec: false), hasLength(6));
    });

    test('knows whether there is anything of each sort', () {
      expect(boardOf().hasStandardActivities, isTrue);
      expect(boardOf().hasSkillsActivities, isTrue);
      final skillsOnly = PreferenceBoard(activities: [swimSkills], limits: limits);
      expect(skillsOnly.hasStandardActivities, isFalse);
      expect(skillsOnly.standardCategories, isEmpty);
    });
  });
}
