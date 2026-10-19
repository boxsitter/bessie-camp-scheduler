import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'environment.dart';
import 'fakes.dart';
import 'fixtures.dart';

void main() {
  final env = PreferencesEnvironment();
  final archery = env.archery;
  final pottery = env.pottery;
  final drama = env.drama;
  final tieDye = env.tieDye;
  final kayak = env.kayak;
  final swimSkills = env.swimSkills;

  late FakeRosterRepository roster;
  late FakeSessionRepository sessions;
  late ContextService context;
  late ActivityPreferencesController controller;

  setUp(() {
    env.register();
    roster = env.roster;
    sessions = env.sessions;
    context = env.context;
    controller = Get.put(ActivityPreferencesController());
  });

  tearDown(Get.reset);

  Future<void> openPage() async {
    controller.onNavigateTo('/activity-preferences', null);
    await pumpEventQueue();
  }

  Future<void> openCabin(String key) async {
    controller.selectCabinGroup(controller.cabinGroups.firstWhere((g) => g.key == key));
    await pumpEventQueue();
  }

  group('loading', () {
    test('groups the session\'s campers by cabin with their progress', () async {
      await openPage();

      expect(controller.isLoading, isFalse);
      expect(controller.loadError, isNull);
      expect(controller.showingCabins, isTrue);
      expect(controller.cabinGroups.map((g) => (g.title, g.submitted, g.total)), [('Oak', 1, 2), ('Fox', 0, 1)]);
      expect(roster.watched, ['s1']);
    });

    test('offers only visible activities that campers are asked to rank', () async {
      await openPage();
      await openCabin('oak');

      final offered = controller.board!.activities.map((a) => a.id);
      expect(offered, unorderedEquals(['archery', 'pottery', 'drama', 'tiedye', 'kayak', 'swimskills']));
      expect(controller.categories, [ActivityCategory.creative, ActivityCategory.sportsAndAthletics, ActivityCategory.waterfront]);
    });

    test('opens the first camper of the cabin with what is stored for them', () async {
      await openPage();
      await openCabin('oak');

      expect(controller.showingCabins, isFalse);
      expect(controller.selectedCamper?.id, 'amy');
      expect(controller.board!.isEmpty, isTrue);

      controller.selectCamper(controller.campersInSelectedCabin.last);
      expect(controller.selectedCamper?.id, 'bo');
      expect(controller.board!.requestedIds, {'pottery'});
    });

    test('shows the error when loading fails', () async {
      Get.replace<SessionRepository>(_ThrowingSessions(newClient()));
      final broken = Get.put(ActivityPreferencesController(), tag: 'broken');

      broken.onNavigateTo('/activity-preferences', null);
      await pumpEventQueue();

      expect(broken.isLoading, isFalse);
      expect(broken.loadError, 'The server rejected that request.');
      expect(broken.hasCampers, isFalse);
    });

    test('reloads when the session changes', () async {
      await openPage();
      await openCabin('oak');
      roster.campers = [camper('zed', first: 'Zed', last: 'Zimmer', cabinId: 'fox')];

      context.session.value = campSession('s2');
      await pumpEventQueue();

      expect(sessions.scheduleRequests, ['s1', 's2']);
      expect(roster.watched, ['s1', 's2']);
      expect(controller.showingCabins, isTrue);
      expect(controller.selectedCamper, isNull);
      expect(controller.cabinGroups.map((g) => g.title), ['Fox']);
    });

    test('knows when the session offers nothing to rank', () async {
      await openPage();
      expect(controller.hasActivities, isTrue);

      sessions.schedule = Schedule(days: const [], blocks: const [], scheduledActivities: const [], activitiesById: const {});
      await controller.reload();
      expect(controller.hasActivities, isFalse);
    });

    test('rebuilds the open camper\'s board from the new schedule when reloading', () async {
      await openPage();
      await openCabin('oak');
      expect(controller.board!.activities.map((a) => a.id), contains('kayak'));

      sessions.schedule = Schedule(
        days: const [],
        blocks: const [],
        scheduledActivities: [ScheduledActivity(id: 'sa-1', sessionId: 's1', blockId: 'block', activityId: 'archery')],
        activitiesById: {'archery': archery},
      );
      await controller.reload();

      expect(controller.selectedCamper?.id, 'amy', reason: 'the selection is kept');
      expect(controller.board!.activities.map((a) => a.id), ['archery']);
    });

    test('does not load while the page has never been opened', () async {
      context.session.value = campSession('s2');
      await pumpEventQueue();
      expect(sessions.scheduleRequests, isEmpty);
    });
  });

  group('editing and saving', () {
    setUp(() async {
      await openPage();
      await openCabin('oak');
    });

    test('keeps a draft and saves it on flush, marking the camper as done', () async {
      controller.place(archery, PreferenceKind.request);
      controller.place(kayak, PreferenceKind.veto);

      expect(controller.hasUnsavedChanges, isTrue);
      expect(controller.isPending('amy'), isTrue);
      expect(roster.saves, isEmpty);

      expect(await controller.flush(), isTrue);

      expect(roster.saves, hasLength(1));
      expect(roster.saves.single.camperId, 'amy');
      expect(roster.saves.single.requested, {'archery'});
      expect(roster.saves.single.vetoed, {'kayak'});
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.isPending('amy'), isFalse);
      expect(controller.selectedCamper!.preferencesSubmitted, isTrue);
      expect(controller.selectedCamper!.preferences, {'archery': PreferenceKind.request, 'kayak': PreferenceKind.veto});
      expect(controller.cabinGroups.first.submitted, 2);
    });

    test('saves a camper who wants nothing as done', () async {
      expect(controller.selectedCamper!.preferencesSubmitted, isFalse);
      await controller.markSelectedDone();

      expect(roster.saves.single.requested, isEmpty);
      expect(roster.saves.single.vetoed, isEmpty);
      expect(controller.selectedCamper!.preferencesSubmitted, isTrue);
    });

    test('moving an activity back to the library removes it from the saved lists', () async {
      controller.selectCamper(controller.campersInSelectedCabin.last); // Bo requested pottery
      controller.place(pottery, null);
      await controller.flush();

      expect(roster.saves.single.camperId, 'bo');
      expect(roster.saves.single.requested, isEmpty);
    });

    test('refuses a move over the limit without queuing a save', () async {
      controller.place(archery, PreferenceKind.request);
      controller.place(pottery, PreferenceKind.request);
      controller.place(drama, PreferenceKind.request);
      await controller.flush();
      roster.saves.clear();

      controller.place(tieDye, PreferenceKind.request);

      expect(controller.board!.kindOf(tieDye), isNull);
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.remaining(PreferenceKind.request), 0);
      expect(roster.saves, isEmpty);
    });

    test('counts skills recs apart from standard activities', () async {
      controller.setSkillsMode(true);
      expect(controller.skillsMode, isTrue);
      expect(controller.libraryActivities.map((a) => a.name), ['Swim Skills']);
      expect(controller.remaining(PreferenceKind.request), 2);

      controller.place(swimSkills, PreferenceKind.request);
      expect(controller.chosenActivities(PreferenceKind.request).map((a) => a.name), ['Swim Skills']);
      expect(controller.remaining(PreferenceKind.request), 1);

      controller.setSkillsMode(false);
      expect(controller.remaining(PreferenceKind.request), 3);
      expect(controller.chosenActivities(PreferenceKind.request), isEmpty);
    });

    test('saves the draft of the camper being left, and shows it again when coming back', () async {
      roster.autoComplete = false;
      controller.place(archery, PreferenceKind.request);

      controller.selectCamper(controller.campersInSelectedCabin.last);
      await pumpEventQueue();

      expect(roster.saves.single.camperId, 'amy');
      expect(controller.board!.requestedIds, {'pottery'}, reason: 'now showing Bo');

      // Back to Amy while her save is still running: her draft, not stale data.
      controller.selectCamper(controller.campersInSelectedCabin.first);
      expect(controller.board!.requestedIds, {'archery'});
      expect(controller.isPending('amy'), isTrue);

      roster.saves.single.gate.complete();
      await pumpEventQueue();
      expect(controller.isPending('amy'), isFalse);
      expect(controller.board!.requestedIds, {'archery'});
      expect(controller.selectedCamper!.preferencesSubmitted, isTrue);
    });

    test('an edit made while a save is running is saved next, never lost', () async {
      roster.autoComplete = false;
      controller.place(archery, PreferenceKind.request);
      final firstFlush = controller.flush();
      await pumpEventQueue();
      expect(roster.saves, hasLength(1));
      expect(controller.isSaving, isTrue);

      controller.place(pottery, PreferenceKind.request);
      expect(controller.board!.requestedIds, {'archery', 'pottery'});

      roster.saves[0].gate.complete();
      await pumpEventQueue();
      expect(roster.saves, hasLength(2), reason: 'the newer draft follows the first save');
      expect(roster.saves[1].requested, {'archery', 'pottery'});

      roster.saves[1].gate.complete();
      expect(await firstFlush, isTrue);
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.isSaving, isFalse);
      expect(controller.selectedCamper!.preferences.keys, unorderedEquals(['archery', 'pottery']));
      expect(controller.board!.requestedIds, {'archery', 'pottery'});
    });

    test('saves several campers one after the other', () async {
      controller.place(archery, PreferenceKind.request);
      controller.selectCamper(controller.campersInSelectedCabin.last);
      controller.place(drama, PreferenceKind.veto);

      expect(await controller.flush(), isTrue);

      expect(roster.saves.map((s) => s.camperId), unorderedEquals(['amy', 'bo']));
      expect(roster.saves.firstWhere((s) => s.camperId == 'bo').vetoed, {'drama'});
      expect(roster.saves.firstWhere((s) => s.camperId == 'bo').requested, {'pottery'});
    });

    test('a refused save is reported and the camper goes back to what is stored', () async {
      roster.failing['amy'] = AppException('You can request at most 3 activities');
      controller.place(archery, PreferenceKind.request);

      expect(await controller.flush(), isFalse);

      expect(roster.saves, hasLength(1));
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.isPending('amy'), isFalse);
      expect(controller.board!.isEmpty, isTrue, reason: 'back to the stored (empty) preferences');
      expect(controller.selectedCamper!.preferencesSubmitted, isFalse);
    });

    test('a failure does not stop the other campers from being saved', () async {
      roster.failing['amy'] = AppException('Nope');
      controller.place(archery, PreferenceKind.request);
      controller.selectCamper(controller.campersInSelectedCabin.last);
      controller.place(drama, PreferenceKind.veto);

      expect(await controller.flush(), isFalse);

      expect(roster.saves.map((s) => s.camperId), unorderedEquals(['amy', 'bo']));
      expect(controller.hasUnsavedChanges, isFalse);
      final saved = controller.campersInSelectedCabin.last;
      expect(saved.preferences, {'pottery': PreferenceKind.request, 'drama': PreferenceKind.veto});
      expect(controller.campersInSelectedCabin.first.preferences, isEmpty, reason: 'Amy\'s refused draft was dropped');
    });

    test('a failed save keeps a newer draft that was made meanwhile', () async {
      roster.autoComplete = false;
      controller.place(archery, PreferenceKind.request);
      final flushed = controller.flush();
      await pumpEventQueue();

      controller.place(pottery, PreferenceKind.request);
      roster.saves[0].gate.completeError(AppException('Boom'));
      await pumpEventQueue();

      expect(roster.saves, hasLength(2));
      expect(roster.saves[1].requested, {'archery', 'pottery'});
      roster.saves[1].gate.complete();
      expect(await flushed, isFalse);
      expect(controller.board!.requestedIds, {'archery', 'pottery'});
    });

    test('saves by itself a moment after the last edit', () async {
      controller.place(archery, PreferenceKind.request);
      await Future<void>.delayed(ActivityPreferencesController.autosaveDelay + const Duration(milliseconds: 300));
      expect(roster.saves, hasLength(1));
      expect(controller.hasUnsavedChanges, isFalse);
    });

    test('leaving the page saves the draft', () async {
      controller.place(archery, PreferenceKind.request);
      controller.onNavigateFrom('/activity-preferences', '/schedule-page');
      await pumpEventQueue();
      expect(roster.saves.single.requested, {'archery'});
    });

    test('saving after the session changed still saves the drafts of the previous session', () async {
      roster.autoComplete = false;
      controller.place(archery, PreferenceKind.request);

      context.session.value = campSession('s2');
      await pumpEventQueue();

      expect(roster.saves.single.camperId, 'amy');
      roster.saves.single.gate.complete();
      await pumpEventQueue();
      expect(controller.hasUnsavedChanges, isFalse);
      expect(controller.isSaving, isFalse);
    });
  });

  group('live updates', () {
    setUp(() async {
      await openPage();
      await openCabin('oak');
    });

    test('a change by someone else shows up for the selected camper', () async {
      await roster.emit([
        camper('amy', first: 'Amy', last: 'Adams', cabinId: 'oak', preferences: {'kayak': PreferenceKind.veto}, submittedAt: DateTime(2026, 7, 2)),
        ...roster.campers.skip(1),
      ]);

      expect(controller.board!.vetoedIds, {'kayak'});
      expect(controller.cabinGroups.first.submitted, 2);
    });

    test('an unsaved draft is not overwritten by an update', () async {
      controller.place(archery, PreferenceKind.request);

      await roster.emit([
        camper('amy', first: 'Amy', last: 'Adams', cabinId: 'oak', preferences: {'kayak': PreferenceKind.veto}),
        ...roster.campers.skip(1),
      ]);

      expect(controller.board!.requestedIds, {'archery'});
      expect(controller.board!.vetoedIds, isEmpty);
    });

    test('the selection survives updates', () async {
      controller.selectCamper(controller.campersInSelectedCabin.last);
      await roster.emit([...roster.campers]);

      expect(controller.selectedCamper?.id, 'bo');
      expect(controller.showingCabins, isFalse);
    });

    test('moves to another camper when the selected one leaves the cabin', () async {
      await roster.emit([
        camper('amy', first: 'Amy', last: 'Adams', cabinId: 'fox'),
        ...roster.campers.skip(1),
      ]);

      expect(controller.selectedCamper?.id, 'bo');
      expect(controller.campersInSelectedCabin.map((c) => c.id), ['bo']);
    });

    test('goes back to the cabins when the selected cabin empties', () async {
      await roster.emit([camper('cy', first: 'Cy', last: 'Clark', cabinId: 'fox')]);

      expect(controller.showingCabins, isTrue);
      expect(controller.selectedCamper, isNull);
      expect(controller.board, isNull);
    });
  });

  group('navigation state', () {
    test('toggles between the cabins overview and the cabin', () async {
      await openPage();
      controller.toggleCabins();
      expect(controller.showingCabins, isTrue, reason: 'nothing selected yet');

      await openCabin('oak');
      controller.toggleCabins();
      expect(controller.showingCabins, isTrue);
      controller.toggleCabins();
      expect(controller.showingCabins, isFalse);

      controller.toggleCampersPane();
      expect(controller.campersPaneOpen, isFalse);
    });

    test('dragging an activity shows its category tab', () async {
      await openPage();
      await openCabin('oak');
      expect(controller.selectedCategory, ActivityCategory.creative);

      controller.onDragStarted(kayak);
      expect(controller.selectedCategory, ActivityCategory.waterfront);
      expect(controller.libraryActivities.map((a) => a.name), ['Kayaking']);
    });
  });
}

/// A session repository whose reads fail like a server error would.
class _ThrowingSessions extends SessionRepository {
  _ThrowingSessions(super.client);

  @override
  Future<List<Cabin>> listSessionCabins(String sessionId) => guarded(() async => throw PostgrestException(message: 'boom', code: 'XX000'));

  @override
  Future<Schedule> fetchSchedule(String sessionId) => guarded(() async => throw PostgrestException(message: 'boom', code: 'XX000'));
}
