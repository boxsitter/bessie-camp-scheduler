import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/widgets/roster_body.dart';
import 'package:bessie/src/features/rosters/widgets/activity_switcher.dart';
import 'package:bessie/src/features/rosters/widgets/column_config.dart';
import 'package:bessie/src/features/rosters/widgets/header_builders.dart';
import 'package:bessie/src/models/camper.dart';
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

  /// The harness uses real asynchrony (streams, futures), which only runs
  /// outside the widget tester's fake clock.
  Future<void> start(WidgetTester tester, {StaffRole role = StaffRole.director, required List<Camper> campers}) async {
    await tester.runAsync(() => h.start(role: role, campers: campers));
  }

  Future<void> show(WidgetTester tester, Widget Function(RostersHarness) body, {Size size = const Size(1600, 1000)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: GetBuilder(init: h.controller, builder: (_) => body(h)))));
    await tester.pump();
  }

  testWidgets('shows the campers in the sorted order and selects a row on tap', (tester) async {
    await start(tester, campers: [ada, bo, cy]);
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
    await tester.runAsync(pumpEventQueue);
    await show(tester, (h) => RostersBody(controller: h.controller));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    h.roster.latest.add([ada]);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Ada Lovelace'), findsOneWidget);
  });

  testWidgets('says so when the roster is empty, without an import button for counselors', (tester) async {
    await start(tester, role: StaffRole.counselor, campers: []);
    await show(tester, (h) => RostersBody(controller: h.controller));
    expect(find.text('There are no campers in this session yet.'), findsOneWidget);
    expect(find.text('Import From UltraCamp'), findsNothing, reason: 'counselors cannot import');
  });

  testWidgets('says so when a search matches nobody', (tester) async {
    await start(tester, campers: [ada, bo, cy]);
    await show(tester, (h) => RostersBody(controller: h.controller));
    h.controller.setSearchQuery('zzz');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('No campers match "zzz".'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsNothing);

    h.controller.setSearchQuery('ada');
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Ada Lovelace'), findsOneWidget);
    expect(find.text('Bo Brown'), findsNothing);
  });

  testWidgets('grouped by cabin it shows a collapsible table per cabin', (tester) async {
    await start(tester, campers: [ada, bo, cy]);
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
    await start(tester, campers: [ada]);
    await show(tester, (h) => ColumnConfig(controller: h.controller));

    expect(find.text('Visible Columns'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Hidden Camper Data'), findsOneWidget);
    expect(find.text('Nickname'), findsOneWidget);
    expect(find.text('Monday - AM1'), findsOneWidget, reason: 'blocks can be added as columns');
  });

  testWidgets('the activity switcher lists the blocks and the activities with their seats', (tester) async {
    await start(
      tester,
      campers: [
        makeCamper(first: 'Ada', last: 'Lovelace', assignments: {'s1-b1': 's1-b1-a1'}),
      ],
    );
    h.controller.toggleSelection(h.controller.campers.single);
    h.controller.selectBlock(h.controller.schedule.blocks.single);
    await show(tester, (h) => ActivitySwitcher(controller: h.controller));

    expect(find.text('Monday - AM1'), findsOneWidget);
    expect(find.text('Archery'), findsWidgets);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('Ada L'), findsOneWidget);
  });

  testWidgets('every panel lays out in the smallest window the app allows', (tester) async {
    await start(tester, campers: [ada, bo, cy]);
    h.controller.selectBlock(h.controller.schedule.blocks.single);
    h.controller.toggleSelection(ada);
    const small = Size(770, 500);

    await show(tester, (h) => RostersBody(controller: h.controller), size: small);
    expect(find.text('Ada Lovelace'), findsOneWidget);

    h.controller.setGroupBy(const FieldColumn(RosterField.cabin));
    h.controller.toggleExpandedByDefault();
    await tester.pump();
    expect(find.text('Cabin - Eagles'), findsOneWidget);
    expect(find.text('Ada Lovelace'), findsOneWidget);

    await show(tester, (h) => ColumnConfig(controller: h.controller), size: small);
    expect(find.text('Visible Columns'), findsOneWidget);

    await show(tester, (h) => ActivitySwitcher(controller: h.controller), size: small);
    expect(find.text('Select Activity'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
