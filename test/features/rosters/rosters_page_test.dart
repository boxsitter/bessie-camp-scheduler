import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/rosters.dart';
import 'package:bessie/src/features/rosters/widgets/activity_switcher.dart';
import 'package:bessie/src/features/rosters/widgets/column_config.dart';
import 'package:bessie/src/features/rosters/widgets/header_builders.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'roster_fixtures.dart';
import 'roster_harness.dart';

void main() {
  late RostersHarness h;

  final ada = makeCamper(first: 'Ada', last: 'Lovelace', cabinId: 'c1');
  final bo = makeCamper(first: 'Bo', last: 'Brown', arrived: true);
  final cy = makeCamper(first: 'Cy', last: 'Green');

  setUp(() => h = RostersHarness());
  tearDown(() => h.dispose());

  Future<void> show(WidgetTester tester, Widget Function(RostersHarness) body) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: GetBuilder(init: h.controller, builder: (_) => body(h))),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the campers in the sorted order and selects a row on tap', (tester) async {
    await h.start(campers: [ada, bo, cy]);
    await show(tester, (h) => RostersBody(controller: h.controller));

    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Bo Brown'), findsOneWidget);
    expect(find.text('Eagles'), findsOneWidget, reason: 'the cabin column shows the cabin title');
    expect(find.text('No cabin'), findsNWidgets(2));
    final names = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
    expect(names.indexOf('Bo Brown'), lessThan(names.indexOf('Cy Green')));
    expect(names.indexOf('Cy Green'), lessThan(names.indexOf('Ada Lovelace')));

    await tester.tap(find.text('Ada Lovelace'));
    await tester.pump();
    expect(h.controller.selectedIds, {ada.id});
  });

  testWidgets('shows a loader until the roster arrives', (tester) async {
    h.auth.profile.value = fakeProfile(StaffRole.director);
    h.context.session.value = fakeSession('s1');
    h.controller.onNavigateTo('/', null);
    await show(tester, (h) => RostersBody(controller: h.controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    h.roster.latest.add([ada]);
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('says so when a search matches nobody or the roster is empty', (tester) async {
    await h.start(role: StaffRole.counselor, campers: []);
    await show(tester, (h) => RostersBody(controller: h.controller));
    expect(find.text('There are no campers in this session yet.'), findsOneWidget);
    expect(find.text('Import From UltraCamp'), findsNothing, reason: 'counselors cannot import');
  });

  testWidgets('grouped by cabin it shows a collapsible table per cabin', (tester) async {
    await h.start(campers: [ada, bo, cy]);
    h.controller.setGroupBy(const FieldColumn(RosterField.cabin));
    await show(tester, (h) => RostersBody(controller: h.controller));

    expect(find.text('Cabin - Eagles'), findsOneWidget);
    expect(find.text('Cabin - No cabin'), findsOneWidget);
    expect(find.text('Bo Brown'), findsNothing, reason: 'groups start collapsed');

    final noCabin = h.controller.groups.last;
    h.controller.toggleGroupExpanded(noCabin);
    await tester.pump();
    expect(find.text('Bo Brown'), findsOneWidget);
    expect(find.text('Cy Green'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);
  });

  testWidgets('the column settings list visible and hidden columns, including blocks', (tester) async {
    await h.start(campers: [ada]);
    await show(tester, (h) => ColumnConfig(controller: h.controller));

    expect(find.text('Visible Columns'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Hidden Camper Data'), findsOneWidget);
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text('Monday - AM1'), findsOneWidget, reason: 'blocks can be added as columns');
  });

  testWidgets('the activity switcher lists the blocks and the activities with their seats', (tester) async {
    await h.start(
      campers: [makeCamper(first: 'Ada', last: 'Lovelace', assignments: {'s1-b1': 's1-b1-a1'})],
    );
    h.controller.toggleSelection(h.controller.campers.single);
    h.controller.selectBlock(h.controller.schedule.blocks.single);
    await show(tester, (h) => ActivitySwitcher(controller: h.controller));

    expect(find.text('Monday - AM1'), findsOneWidget);
    expect(find.text('Archery'), findsWidgets);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('Ada L'), findsOneWidget);
  });

  group('toolbar', () {
    test('counselors only get the read-only controls', () async {
      await h.start(campers: [ada]);
      final editorActions = buildRostersCenterActions(controller: h.controller).length;
      final editorMenu = buildRostersMenuBar(controller: h.controller);
      expect(editorMenu.fileItems!.length, greaterThan(2));
      expect(editorMenu.editItems!.length, greaterThan(10));

      h.auth.profile.value = fakeProfile(StaffRole.counselor);
      final counselorMenu = buildRostersMenuBar(controller: h.controller);
      expect(counselorMenu.editItems, hasLength(1), reason: 'just Invert Selection');
      expect(counselorMenu.fileItems, hasLength(2), reason: 'exports only');
      expect(
        buildRostersCenterActions(controller: h.controller).length,
        lessThan(editorActions),
        reason: 'no activity switcher and no arrived button',
      );
    });
  });
}
