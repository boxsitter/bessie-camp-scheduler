import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller.dart';
import 'package:bessie/src/features/activity_preferences/views/activity_preferences_desktop.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'environment.dart';
import 'inter_font.dart';

void main() {
  final env = PreferencesEnvironment();
  late ActivityPreferencesController controller;

  setUpAll(loadInterFont);

  setUp(() {
    env.register();
    controller = Get.put(ActivityPreferencesController());
  });

  tearDown(Get.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GetBuilder<ActivityPreferencesController>(
            initState: (_) => Get.find<ActivityPreferencesController>().ensureLoaded(),
            builder: (controller) => ActivityPreferencesDesktop(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openOak(WidgetTester tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Oak'));
    await tester.pumpAndSettle();
  }

  /// Drags an activity card onto the zone with [zoneTitle].
  Future<void> dragTo(WidgetTester tester, String activity, String zoneTitle) async {
    final from = tester.getCenter(find.text(activity).first);
    final to = tester.getCenter(find.text(zoneTitle));
    await tester.timedDrag(find.text(activity).first, to - from, const Duration(milliseconds: 300));
    // Not pumpAndSettle: the saving spinner keeps frames coming until the autosave has run.
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('cabins', () {
    testWidgets('lists the cabins with how many campers are done', (tester) async {
      await pumpPage(tester);

      expect(find.text('Cabins'), findsOneWidget);
      expect(find.text('Oak'), findsOneWidget);
      expect(find.text('1/2 campers completed'), findsOneWidget);
      expect(find.text('Fox'), findsOneWidget);
      expect(find.text('0/1 campers completed'), findsOneWidget);
    });

    testWidgets('opens the first camper of a cabin', (tester) async {
      await openOak(tester);

      // The camper list and the camper being edited.
      expect(find.text('Amy A'), findsOneWidget);
      expect(find.text('Bo B'), findsOneWidget);
      expect(find.text('Amy Adams'), findsOneWidget);
      expect(find.text('Oak · Not saved yet'), findsOneWidget);
      expect(find.text('Yes Please'), findsOneWidget);
      expect(find.text('No Thanks'), findsOneWidget);
      expect(find.text('3 remaining'), findsOneWidget);
      expect(find.text('2 remaining'), findsOneWidget);
    });
  });

  group('the library', () {
    testWidgets('shows the first category, with tabs for the others', (tester) async {
      await openOak(tester);

      expect(find.text('Creative'), findsOneWidget);
      expect(find.text('Sports & Athletics'), findsOneWidget);
      expect(find.text('Waterfront'), findsOneWidget);
      expect(find.text('Drama'), findsOneWidget);
      expect(find.text('Pottery'), findsOneWidget);
      expect(find.text('Tie-Dye'), findsOneWidget);
      expect(find.text('Archery'), findsNothing);

      await tester.tap(find.text('Sports & Athletics'));
      await tester.pumpAndSettle();
      expect(find.text('Archery'), findsOneWidget);
      expect(find.text('Drama'), findsNothing);
    });

    testWidgets('switches to skills recs, which have their own limits', (tester) async {
      await openOak(tester);

      await tester.tap(find.text('Skills Recs'));
      await tester.pumpAndSettle();

      expect(find.text('Swim Skills'), findsOneWidget);
      expect(find.text('Teen Skills'), findsNothing, reason: 'not asked to be ranked');
      expect(find.text('Swim Test'), findsNothing, reason: 'hidden');
      expect(find.text('Creative'), findsNothing, reason: 'skills recs are not split into categories');
      expect(find.text('2 remaining'), findsOneWidget);
      expect(find.text('1 remaining'), findsOneWidget);

      await tester.tap(find.text('Standard Activities'));
      await tester.pumpAndSettle();
      expect(find.text('Pottery'), findsOneWidget);
    });
  });

  group('choosing', () {
    testWidgets('dragging an activity into Yes Please requests it', (tester) async {
      await openOak(tester);

      await dragTo(tester, 'Pottery', 'Yes Please');

      expect(controller.board!.kindOf(env.pottery), PreferenceKind.request);
      expect(find.text('Pottery'), findsOneWidget, reason: 'now in the Yes Please list, no longer in the library');
      expect(find.text('2 remaining'), findsNWidgets(2), reason: 'requests left, and vetoes left');
      expect(find.text('Drag And Drop Here'), findsOneWidget, reason: 'only No Thanks is still empty');
      expect(controller.hasUnsavedChanges, isTrue);

      await tester.runAsync(controller.flush);
      await tester.pumpAndSettle();
      expect(find.text('Oak · Saved'), findsOneWidget);
      expect(env.roster.saves.single.requested, {'pottery'});
    });

    testWidgets('dragging into No Thanks vetoes, and back into the library undoes it', (tester) async {
      await openOak(tester);

      await dragTo(tester, 'Drama', 'No Thanks');
      expect(controller.board!.kindOf(env.drama), PreferenceKind.veto);
      expect(find.text('1 remaining'), findsOneWidget);

      await dragTo(tester, 'Drama', 'Activity Library (I\'d Be Open To Trying It)');
      expect(controller.board!.kindOf(env.drama), isNull);
      expect(find.text('3 remaining'), findsOneWidget);
      expect(find.text('2 remaining'), findsOneWidget);

      await tester.pump(ActivityPreferencesController.autosaveDelay); // lets the autosave run
    });

    testWidgets('refuses a request beyond the limit', (tester) async {
      await openOak(tester);

      for (final name in ['Drama', 'Pottery', 'Tie-Dye']) {
        await dragTo(tester, name, 'Yes Please');
      }
      expect(find.text('0 remaining'), findsOneWidget);

      await tester.tap(find.text('Sports & Athletics'));
      await tester.pumpAndSettle();
      await dragTo(tester, 'Archery', 'Yes Please');

      expect(controller.board!.kindOf(env.archery), isNull);
      expect(find.text('Archery'), findsOneWidget, reason: 'still in the library');
    });

    testWidgets('switching camper shows what that camper asked for', (tester) async {
      await openOak(tester);

      await tester.tap(find.text('Bo B'));
      await tester.pumpAndSettle();

      expect(find.text('Bo Brown'), findsOneWidget);
      expect(find.text('Oak · Saved'), findsOneWidget);
      expect(find.text('2 remaining'), findsNWidgets(2));
      expect(find.text('Pottery'), findsOneWidget, reason: 'in Bo\'s Yes Please list');
    });

    testWidgets('marks a camper who wants nothing as done', (tester) async {
      await openOak(tester);

      expect(find.text('No preferences - mark as done'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('No preferences - mark as done'));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();

      expect(env.roster.saves.single.camperId, 'amy');
      expect(find.text('No preferences - mark as done'), findsNothing);
      expect(find.text('Oak · Saved'), findsOneWidget);
    });

    testWidgets('does not offer to mark a saved camper as done', (tester) async {
      await openOak(tester);
      await tester.tap(find.text('Bo B'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as done'), findsNothing);
      expect(find.text('No preferences - mark as done'), findsNothing);
    });
  });

  group('when there is nothing to show', () {
    testWidgets('says when the session has no campers', (tester) async {
      env.roster.campers = [];
      await pumpPage(tester);

      expect(find.text('No campers yet'), findsOneWidget);
      expect(find.text('Cabins'), findsNothing);
    });

    testWidgets('says when no session is selected', (tester) async {
      env.context.session.value = null;
      await pumpPage(tester);

      expect(find.text('No session selected'), findsOneWidget);
    });

    testWidgets('says when the session offers no activities', (tester) async {
      env.sessions.schedule = Schedule(days: const [], blocks: const [], scheduledActivities: const [], activitiesById: const {});
      await pumpPage(tester);

      expect(find.text('No activities to rank'), findsOneWidget);
    });

    testWidgets('shows a failure with a way to try again', (tester) async {
      env.sessions.failWith = PostgrestException(message: 'boom', code: 'XX000');
      await pumpPage(tester);

      expect(find.text('Couldn\'t load the campers'), findsOneWidget);
      expect(find.text('The server rejected that request.'), findsOneWidget);

      env.sessions.failWith = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Cabins'), findsOneWidget);
      expect(find.text('Oak'), findsOneWidget);
    });
  });
}
