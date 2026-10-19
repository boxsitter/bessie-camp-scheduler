import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/branch_manager/catalog_logic.dart';
import 'package:bessie/src/features/branch_manager/widgets/activities_section.dart';
import 'package:bessie/src/features/branch_manager/widgets/activity_form_dialog.dart';
import 'package:bessie/src/features/branch_manager/widgets/cabin_form_dialog.dart';
import 'package:bessie/src/features/branch_manager/widgets/cabins_section.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:bessie/src/models/cabin.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../session_manager/support/fixtures.dart';
import 'support/harness.dart';

/// The n-th text input of a dialog, top to bottom (placeholders disappear once typed over;
/// the activity form's description counts as one).
Finder input(int index) => find.byType(ShadInput).at(index);

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ShadButton, label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('ActivityFormDialog', () {
    testWidgets('shows what is wrong and does not submit an invalid form', (tester) async {
      var submitted = 0;
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(tester, ActivityFormDialog(otherActivityNames: const ['Soccer'], onSubmit: (_) async => submitted++));
      
      await tester.enterText(input(0), ' soccer ');
      await tester.enterText(input(2), '');
      await tapButton(tester, 'Create activity');

      expect(find.text('There is already an activity called "soccer".'), findsOneWidget);
      expect(find.text('Enter how many campers fit.'), findsOneWidget);
      expect(submitted, 0);

      // Fixing a field clears its message as the user types.
      await tester.enterText(input(0), 'Soccer 2');
      await tester.pump();
      expect(find.textContaining('already an activity'), findsNothing);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await dialog.result, isNull);
    });

    testWidgets('submits what was typed and closes', (tester) async {
      ActivityFormInput? received;
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(
        tester,
        ActivityFormDialog(
          otherActivityNames: const [],
          onSubmit: (input) async => received = input,
        ),
      );
      
      await tester.enterText(input(0), 'Archery');
      await tester.enterText(input(2), '12');
      await tester.enterText(input(3), '2');
      await tester.tap(find.widgetWithText(ShadSwitch, 'Double block'));
      await tapButton(tester, 'Create activity');

      expect(await dialog.result, isTrue);
      expect(received?.name, 'Archery');
      expect(received?.capacity, '12');
      expect(received?.maxAssignments, '2');
      expect(received?.doubleSchedule, isTrue);
      expect(received?.isSkillsRec, isFalse);
      expect(received?.preferenceRequired, isTrue);
      expect(find.byType(ActivityFormDialog), findsNothing);
    });

    testWidgets('stays open and explains when the database refuses', (tester) async {
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(
        tester,
        ActivityFormDialog(otherActivityNames: const [], onSubmit: (_) async => throw AppException('That already exists.')),
      );
      
      await tester.enterText(input(0), 'Archery');
      await tapButton(tester, 'Create activity');

      expect(find.text('That already exists.'), findsOneWidget);
      expect(find.byType(ActivityFormDialog), findsOneWidget);
      expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Create activity')).onPressed, isNotNull, reason: 'the user can try again');

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await dialog.result, isNull);
    });

    testWidgets('edits an existing activity', (tester) async {
      final existing = activity('ropes', name: 'Ropes Course', capacity: 8, double: true, hidden: true);
      ActivityFormInput? received;
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(
        tester,
        ActivityFormDialog(activity: existing, otherActivityNames: const ['Soccer'], onSubmit: (input) async => received = input),
      );

      expect(find.text('Edit activity'), findsOneWidget);
      expect(find.widgetWithText(ShadInput, 'Ropes Course'), findsOneWidget);
      expect(tester.widget<ShadSwitch>(find.widgetWithText(ShadSwitch, 'Double block')).value, isTrue);
      expect(tester.widget<ShadSwitch>(find.widgetWithText(ShadSwitch, 'Hidden')).value, isTrue);

      await tester.enterText(input(2), '9');
      await tapButton(tester, 'Save changes');

      expect(await dialog.result, isTrue);
      expect(received?.name, 'Ropes Course');
      expect(received?.capacity, '9');
      expect(received?.category, ActivityCategory.other);
    });
  });

  group('CabinFormDialog', () {
    final existing = [cabin('Oak', village: 'Pines'), cabin('Fox', village: 'Meadow')];

    testWidgets('validates, then submits with a village picked from the existing ones', (tester) async {
      CabinFormInput? received;
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(tester, CabinFormDialog(existingCabins: existing, onSubmit: (input) async => received = input));
      
      await tester.enterText(input(0), 'oak');
      await tapButton(tester, 'Create cabin');
      expect(find.text('There is already a cabin called "oak".'), findsOneWidget);
      expect(received, isNull);

      await tester.enterText(input(0), 'Birch');
      await tester.tap(find.widgetWithText(ShadButton, 'Meadow'));
      await tapButton(tester, 'Create cabin');

      expect(await dialog.result, isTrue);
      expect(received?.name, 'Birch');
      expect(received?.village, 'Meadow');
      expect(received?.capacity, '10');
    });

    testWidgets('shows the database message and stays open', (tester) async {
      await pumpApp(tester, const SizedBox());
      final dialog = await openDialog<bool>(
        tester,
        CabinFormDialog(existingCabins: existing, onSubmit: (_) async => throw AppException('You don\'t have permission to do that.')),
      );
      
      await tester.enterText(input(0), 'Birch');
      await tapButton(tester, 'Create cabin');

      expect(find.text('You don\'t have permission to do that.'), findsOneWidget);
      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await dialog.result, isNull);
    });
  });

  group('ActivitiesSection', () {
    final catalog = [
      activity('soccer', name: 'Soccer', capacity: 20),
      activity('ropes', name: 'Ropes Course', capacity: 10, double: true),
      activity('swim-test', name: 'Swim Test', capacity: 6, hidden: true),
    ];

    Widget section({required bool canEdit, List<Activity>? activities, void Function(Activity)? onEdit, void Function(Activity)? onDelete}) {
      return ActivitiesSection(
        activities: activities ?? catalog,
        canEdit: canEdit,
        onCreate: () {},
        onEdit: onEdit ?? (_) {},
        onDelete: onDelete ?? (_) {},
      );
    }

    testWidgets('groups by category and badges the special ones', (tester) async {
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: true)));

      expect(find.text('OTHER'), findsOneWidget);
      expect(find.text('Soccer'), findsOneWidget);
      expect(find.text('Double block'), findsOneWidget);
      expect(find.text('Hidden'), findsOneWidget);
      expect(find.text('Capacity 20'), findsOneWidget);
      expect(find.text('3 activities in the catalog'), findsOneWidget);
    });

    testWidgets('edit and delete report the row they belong to', (tester) async {
      Activity? edited;
      Activity? deleted;
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: true, onEdit: (a) => edited = a, onDelete: (a) => deleted = a)));

      await tester.tap(find.byTooltip('Edit Soccer'));
      await tester.tap(find.byTooltip('Delete Ropes Course'));

      expect(edited?.id, 'soccer');
      expect(deleted?.id, 'ropes');
    });

    testWidgets('is read only for people who cannot edit', (tester) async {
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: false)));

      expect(find.text('New activity'), findsNothing);
      expect(find.byTooltip('Edit Soccer'), findsNothing);
      expect(find.byTooltip('Delete Soccer'), findsNothing);
      expect(find.text('Soccer'), findsOneWidget);
    });

    testWidgets('says so when there are no activities', (tester) async {
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: true, activities: const [])));
      expect(find.text('No activities yet. Create the first one.'), findsOneWidget);
    });
  });

  group('CabinsCatalogSection', () {
    final cabins = [cabin('Oak', village: 'Pines', position: 1), cabin('Squirt', village: 'Meadow', position: 2, displayName: 'Ernie', capacity: 8)];

    Widget section({required bool canEdit, void Function(Cabin)? onDelete}) =>
        CabinsCatalogSection(cabins: cabins, canEdit: canEdit, onCreate: () {}, onDelete: onDelete ?? (_) {});

    testWidgets('lists cabins by village with their display names', (tester) async {
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: true)));

      expect(find.text('PINES'), findsOneWidget);
      expect(find.text('MEADOW'), findsOneWidget);
      expect(find.text('Ernie'), findsOneWidget);
      expect(find.text('(Squirt)'), findsOneWidget);
      expect(find.text('Sleeps 8'), findsOneWidget);
    });

    testWidgets('delete reports the cabin; read only hides it', (tester) async {
      Cabin? deleted;
      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: true, onDelete: (c) => deleted = c)));
      await tester.tap(find.byTooltip('Delete Ernie'));
      expect(deleted?.name, 'Squirt');

      await pumpApp(tester, SingleChildScrollView(child: section(canEdit: false)));
      expect(find.byTooltip('Delete Ernie'), findsNothing);
      expect(find.text('New cabin'), findsNothing);
    });
  });
}
