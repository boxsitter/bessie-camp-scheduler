import 'package:bessie/src/core/errors.dart';
import 'package:bessie/src/features/branch_manager/widgets/number_stepper.dart';
import 'package:bessie/src/features/session_manager/session_setup_logic.dart';
import 'package:bessie/src/features/session_manager/widgets/add_activities_dialog.dart';
import 'package:bessie/src/features/session_manager/widgets/cabins_section.dart';
import 'package:bessie/src/features/session_manager/widgets/limits_section.dart';
import 'package:bessie/src/features/session_manager/widgets/new_session_dialog.dart';
import 'package:bessie/src/features/session_manager/widgets/schedule_section.dart';
import 'package:bessie/src/models/organization.dart';
import 'package:bessie/src/models/schedule.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../branch_manager/support/harness.dart';
import 'support/fixtures.dart';

final soccer = activity('soccer', name: 'Soccer', capacity: 2);
final arts = activity('arts', name: 'Arts', capacity: 14);
final archery = activity('archery-skills', name: 'Archery Skills', skills: true);
final monday = block('mon', dayIndex: 0);
final skillsBlock = block('skills', dayIndex: 1, startHour: 9, skills: true);

SessionSetup setup({List<String> registered = const ['oak', 'fox']}) => SessionSetup(
  session: sessionStarting(DateTime(2026, 7, 6)),
  cabins: [
    cabin('oak', village: 'Pines', position: 1),
    cabin('maple', village: 'Pines', position: 2),
    cabin('fox', village: 'Meadow', position: 3, capacity: 1),
  ],
  registeredCabinIds: registered,
  campers: [
    camper('a', cabinId: 'oak', assignments: {'mon': 'sa-soccer'}),
    camper('b', cabinId: 'oak', assignments: {'mon': 'sa-soccer'}),
    camper('c', cabinId: 'fox', assignments: {'mon': 'sa-soccer'}),
    camper('d', cabinId: 'fox'),
  ],
  schedule: Schedule(
    days: [ScheduleDay(id: 'day0', sessionId: 'session', dayIndex: 0, date: DateTime(2026, 7, 6))],
    blocks: [monday, skillsBlock],
    scheduledActivities: const [
      ScheduledActivity(id: 'sa-soccer', sessionId: 'session', blockId: 'mon', activityId: 'soccer'),
      ScheduledActivity(id: 'sa-arts', sessionId: 'session', blockId: 'mon', activityId: 'arts'),
    ],
    activitiesById: {'soccer': soccer, 'arts': arts},
  ),
  activities: [soccer, arts, archery],
);

Future<void> tapButton(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ShadButton, label));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  group('SessionCabinsSection', () {
    Widget section({
      required Set<String> selected,
      bool canEdit = true,
      bool busy = false,
      void Function(String)? onToggle,
      void Function(Iterable<String>, bool)? onSetMany,
      VoidCallback? onSave,
      VoidCallback? onReset,
    }) => SingleChildScrollView(
      child: SessionCabinsSection(
        setup: setup(),
        selected: selected,
        canEdit: canEdit,
        busy: busy,
        onToggle: onToggle ?? (_) {},
        onSetMany: onSetMany ?? (_, __) {},
        onSave: onSave ?? () {},
        onReset: onReset ?? () {},
      ),
    );

    testWidgets('groups cabins by village and shows how full registered ones are', (tester) async {
      await pumpApp(tester, section(selected: {'oak', 'fox'}));

      expect(find.text('PINES'), findsOneWidget);
      expect(find.text('MEADOW'), findsOneWidget);
      expect(find.text('2 of 10 campers'), findsOneWidget);
      expect(find.text('2 of 1 campers'), findsOneWidget, reason: 'over capacity is still shown');
      expect(find.text('Sleeps 10'), findsOneWidget, reason: 'maple is not registered');
      expect(find.text('No changes.'), findsOneWidget);
    });

    testWidgets('unticking a cabin with campers says what would happen and offers saving', (tester) async {
      var saved = 0;
      await pumpApp(tester, section(selected: {'fox'}, onSave: () => saved++));

      expect(find.text('2 campers will lose this cabin'), findsOneWidget);
      expect(find.text('1 cabin removed. 2 campers will be left without a cabin.'), findsOneWidget);

      await tapButton(tester, 'Save cabins');
      expect(saved, 1);
    });

    testWidgets('ticking reports the cabin and a village can be ticked at once', (tester) async {
      final toggled = <String>[];
      final many = <(List<String>, bool)>[];
      await pumpApp(tester, section(selected: {'oak', 'fox'}, onToggle: toggled.add, onSetMany: (ids, on) => many.add((ids.toList(), on))));

      await tester.tap(find.text('maple'));
      expect(toggled, ['maple']);

      await tester.tap(find.widgetWithText(ShadButton, 'Tick all').first);
      expect(many.single.$1, ['oak', 'maple']);
      expect(many.single.$2, isTrue);
    });

    testWidgets('save and reset wait for a change and for other saves to finish', (tester) async {
      await pumpApp(tester, section(selected: {'oak', 'fox'}));
      expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Save cabins')).onPressed, isNull);

      await pumpApp(tester, section(selected: {'oak'}, busy: true));
      expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Saving...')).onPressed, isNull);
    });

    testWidgets('is read only for people who cannot edit', (tester) async {
      await pumpApp(tester, section(selected: {'oak', 'fox'}, canEdit: false));

      expect(find.text('Save cabins'), findsNothing);
      expect(find.text('Tick all'), findsNothing);
      expect(tester.widget<ShadCheckbox>(find.widgetWithText(ShadCheckbox, 'oak')).onChanged, isNull);
    });
  });

  group('LimitsSection', () {
    Widget section({required LimitsDraft draft, bool canEdit = true, ValueChanged<LimitsDraft>? onChanged, VoidCallback? onSave}) =>
        SingleChildScrollView(
          child: LimitsSection(
            draft: draft,
            saved: LimitsDraft.defaults,
            canEdit: canEdit,
            busy: false,
            onChanged: onChanged ?? (_) {},
            onSave: onSave ?? () {},
            onReset: () {},
          ),
        );

    testWidgets('steppers change one limit at a time', (tester) async {
      LimitsDraft? changed;
      await pumpApp(tester, section(draft: LimitsDraft.defaults, onChanged: (d) => changed = d));

      final vetoes = find.byType(NumberStepper).at(1);
      await tester.tap(find.descendant(of: vetoes, matching: find.byType(ShadIconButton)).last);

      expect(changed?.maxVetoes, LimitsDraft.defaults.maxVetoes + 1);
      expect(changed?.maxRequests, LimitsDraft.defaults.maxRequests);
    });

    testWidgets('a stepper stops at zero', (tester) async {
      await pumpApp(tester, section(draft: LimitsDraft.defaults.copyWith(maxSkillsVetoes: 0)));

      final skillsVetoes = find.byType(NumberStepper).at(3);
      final minus = find.descendant(of: skillsVetoes, matching: find.byType(ShadIconButton)).first;
      expect(tester.widget<ShadIconButton>(minus).onPressed, isNull);
    });

    testWidgets('saving is only possible after a change', (tester) async {
      await pumpApp(tester, section(draft: LimitsDraft.defaults));
      expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Save limits')).onPressed, isNull);

      var saved = 0;
      await pumpApp(tester, section(draft: LimitsDraft.defaults.copyWith(maxRequests: 5), onSave: () => saved++));
      await tapButton(tester, 'Save limits');
      expect(saved, 1);
    });

    testWidgets('is read only for people who cannot edit', (tester) async {
      await pumpApp(tester, section(draft: LimitsDraft.defaults, canEdit: false));

      expect(find.text('Save limits'), findsNothing);
      final plus = find.descendant(of: find.byType(NumberStepper).first, matching: find.byType(ShadIconButton)).last;
      expect(tester.widget<ShadIconButton>(plus).onPressed, isNull);
    });
  });

  group('ScheduleSection', () {
    Widget section({bool canEdit = true, void Function(Block)? onAdd, void Function(Block, ScheduledActivity)? onRemove}) =>
        SingleChildScrollView(
          child: ScheduleSection(setup: setup(), canEdit: canEdit, busy: false, onAdd: onAdd ?? (_) {}, onRemove: onRemove ?? (_, __) {}),
        );

    testWidgets('lists each block with its activities and how full they are', (tester) async {
      await pumpApp(tester, section());

      expect(find.text('DAY 1 - MONDAY, JUL 6'), findsOneWidget);
      expect(find.text('Block mon'), findsOneWidget);
      expect(find.text('Skills rec'), findsOneWidget, reason: 'the skills block is marked');
      expect(find.text('3/2'), findsOneWidget, reason: 'soccer has more campers than capacity');
      expect(find.text('0/14'), findsOneWidget);
      expect(find.text('Nothing is offered yet.'), findsOneWidget, reason: 'the skills block is empty');
    });

    testWidgets('removing reports the block and the scheduled activity', (tester) async {
      Block? removedFrom;
      ScheduledActivity? removed;
      await pumpApp(
        tester,
        section(
          onRemove: (block, scheduled) {
            removedFrom = block;
            removed = scheduled;
          },
        ),
      );

      await tester.tap(find.byTooltip('Remove Soccer from this block'));

      expect(removedFrom?.id, 'mon');
      expect(removed?.id, 'sa-soccer');
    });

    testWidgets('adding reports the block', (tester) async {
      final added = <String>[];
      await pumpApp(tester, section(onAdd: (block) => added.add(block.id)));

      await tester.tap(find.widgetWithText(ShadButton, 'Add activities').last);

      expect(added, ['skills']);
    });

    testWidgets('is read only for people who cannot edit', (tester) async {
      await pumpApp(tester, section(canEdit: false));

      expect(find.text('Add activities'), findsNothing);
      expect(find.byTooltip('Remove Soccer from this block'), findsNothing);
      expect(find.text('Soccer'), findsOneWidget);
    });
  });

  group('AddActivitiesDialog', () {
    testWidgets('adds nothing until something is ticked, then returns the chosen ids', (tester) async {
      await pumpApp(tester, const SizedBox());
      final groups = addableActivityGroups(block: monday, catalog: [soccer, arts, archery], offeredActivityIds: const []);
      final dialog = await openDialog<List<String>>(tester, AddActivitiesDialog(block: monday, groups: groups));

      expect(find.text('Monday - Block mon, 10:15 AM - 11:15 AM'), findsOneWidget);
      expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Add')).onPressed, isNull);

      await tester.tap(find.text('Arts'));
      await tester.tap(find.text('Archery Skills'));
      await tester.pump();
      await tapButton(tester, 'Add 2 activities');

      expect(await dialog.result, unorderedEquals(['arts', 'archery-skills']));
    });

    testWidgets('a group can be ticked and cleared at once', (tester) async {
      await pumpApp(tester, const SizedBox());
      final groups = addableActivityGroups(block: monday, catalog: [soccer, arts, archery], offeredActivityIds: const []);
      final dialog = await openDialog<List<String>>(tester, AddActivitiesDialog(block: monday, groups: groups));

      await tester.tap(find.widgetWithText(ShadButton, 'Select all').first);
      await tester.pump();
      expect(find.text('Add 2 activities'), findsOneWidget);

      await tester.tap(find.widgetWithText(ShadButton, 'Clear'));
      await tester.pump();
      expect(find.text('Add'), findsOneWidget);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await dialog.result, isNull);
    });

    testWidgets('lists skills recs first for a skills rec block', (tester) async {
      await pumpApp(tester, const SizedBox());
      final groups = addableActivityGroups(block: skillsBlock, catalog: [soccer, arts, archery], offeredActivityIds: const []);
      await openDialog<List<String>>(tester, AddActivitiesDialog(block: skillsBlock, groups: groups));

      expect(tester.getTopLeft(find.text('SKILLS RECS')).dy, lessThan(tester.getTopLeft(find.text('STANDARD ACTIVITIES')).dy));
    });
  });

  group('NewSessionDialog', () {
    final season = Season(
      id: 'season',
      branchId: 'branch',
      name: 'Summer 2026',
      startsOn: DateTime(2026, 6, 15),
      endsOn: DateTime(2026, 8, 21),
    );

    Widget dialog({List<String> existingNames = const [], Future<void> Function(NewSessionRequest)? onSubmit, DateTime? initialStart}) =>
        NewSessionDialog(
          existingNames: existingNames,
          season: season,
          initialStart: initialStart ?? DateTime(2026, 7, 13),
          initialLimits: LimitsDraft.defaults,
          onSubmit: onSubmit ?? (_) async {},
        );

    testWidgets('needs a name, and a name the season does not have yet', (tester) async {
      var submitted = 0;
      await pumpApp(tester, const SizedBox());
      final open = await openDialog<bool>(tester, dialog(existingNames: ['Session 1'], onSubmit: (_) async => submitted++));

      await tapButton(tester, 'Create session');
      expect(find.text('Enter a name for the session.'), findsOneWidget);

      await tester.enterText(find.byType(ShadInput), 'session 1');
      await tapButton(tester, 'Create session');
      expect(find.text('This season already has a session called "session 1".'), findsOneWidget);
      expect(submitted, 0);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await open.result, isNull);
    });

    testWidgets('submits the name, the suggested date, the limits and the cabin choice', (tester) async {
      NewSessionRequest? request;
      await pumpApp(tester, const SizedBox());
      final open = await openDialog<bool>(tester, dialog(onSubmit: (r) async => request = r));

      await tester.enterText(find.byType(ShadInput), '  Session 3 ');
      await tester.tap(find.descendant(of: find.byType(NumberStepper).first, matching: find.byType(ShadIconButton)).last);
      await tester.tap(find.byType(ShadSwitch));
      await tester.pump();
      await tapButton(tester, 'Create session');

      expect(await open.result, isTrue);
      expect(request?.name, 'Session 3');
      expect(request?.startsOn, DateTime(2026, 7, 13));
      expect(request?.limits.maxRequests, LimitsDraft.defaults.maxRequests + 1);
      expect(request?.registerAllCabins, isFalse);
    });

    testWidgets('keeps the dialog open and shows the database message', (tester) async {
      await pumpApp(tester, const SizedBox());
      final open = await openDialog<bool>(tester, dialog(onSubmit: (_) async => throw AppException('That already exists.')));

      await tester.enterText(find.byType(ShadInput), 'Session 3');
      await tapButton(tester, 'Create session');

      expect(find.text('That already exists.'), findsOneWidget);
      expect(find.byType(NewSessionDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(await open.result, isNull);
    });

    testWidgets('notes a date outside the season without blocking it', (tester) async {
      await pumpApp(tester, const SizedBox());
      await openDialog<bool>(tester, dialog(initialStart: DateTime(2026, 9, 7)));

      expect(find.textContaining('outside the Summer 2026 season'), findsOneWidget);
    });
  });
}
