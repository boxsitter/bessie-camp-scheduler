import 'package:bessie/src/features/schedule/schedule_grid.dart';
import 'package:bessie/src/features/schedule/widgets/schedule_paper.dart';
import 'package:bessie/src/features/schedule/widgets/schedule_viewer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final monday = day(0);
  final tuesday = day(1);
  final archery = activity('archery', name: 'Archery', capacity: 1);
  final pottery = activity('pottery', name: 'Pottery', capacity: 10);
  final swimTest = activity('swimtest', name: 'Swim Test', hidden: true);
  final choice1 = block('c1', monday, title: 'Choice Activity 1');
  final skills = block(
    'sk',
    tuesday,
    title: 'Skills Rec',
    start: const Duration(hours: 9, minutes: 15),
    end: const Duration(hours: 10, minutes: 10),
  );

  final grid = ScheduleGrid.build(
    scheduleOf(
      days: [monday, tuesday],
      blocks: [choice1, skills],
      scheduled: [
        scheduled('s1', choice1, archery),
        scheduled('s2', choice1, pottery),
        scheduled('s3', choice1, swimTest),
        scheduled('s4', skills, pottery),
      ],
      activities: [archery, pottery, swimTest],
    ),
    [
      camper('a', assignments: {'c1': 's1'}),
      camper('b', assignments: {'c1': 's1'}),
      camper('c', assignments: {'c1': 's2', 'sk': 's4'}),
    ],
  );

  Future<void> pumpPaper(WidgetTester tester, Widget child, {Size size = const Size(1400, 900)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
  }

  testWidgets('the sheet lists each day, block, activity and its enrollment', (tester) async {
    await pumpPaper(tester, SingleChildScrollView(scrollDirection: Axis.horizontal, child: SchedulePaper(grid: grid, title: 'Session 1')));

    expect(find.text('Session 1'), findsOneWidget);
    expect(find.text('Jul 6-7, 2026'), findsOneWidget);
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('Choice Activity 1'), findsOneWidget);
    expect(find.text('10:15-11:15 AM  -  3/3 placed'), findsOneWidget);
    expect(find.text('9:15-10:10 AM  -  1/3 placed'), findsOneWidget);
    expect(find.text('Archery'), findsOneWidget);
    expect(find.text('Pottery'), findsNWidgets(2));
    expect(find.text('Swim Test'), findsOneWidget);
    expect(find.text('2/1'), findsOneWidget, reason: 'archery has more campers than room');
    expect(find.text('1/10'), findsNWidgets(2));
    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('1 activity over capacity'), findsOneWidget);
  });

  testWidgets('over-capacity activities are red', (tester) async {
    await pumpPaper(tester, SingleChildScrollView(scrollDirection: Axis.horizontal, child: SchedulePaper(grid: grid)));

    final over = tester.widget<Text>(find.text('2/1'));
    final fine = tester.widget<Text>(find.text('0/10'));
    expect(over.style?.color, isNot(fine.style?.color));
    expect(over.style?.fontWeight, FontWeight.w600);
    expect(tester.widget<Text>(find.text('Archery')).style?.color, over.style?.color);
  });

  testWidgets('the sheet has the proportions of a landscape letter page', (tester) async {
    await pumpPaper(
      tester,
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: SchedulePaper(grid: grid)),
      size: const Size(2600, 2200),
    );

    final size = tester.getSize(find.byType(SchedulePaper));
    expect(size.width, SchedulePaperLayout.width);
    expect(size.height, greaterThanOrEqualTo(SchedulePaperLayout.minHeight));
  });

  testWidgets('the viewer fits the sheet to the window and can zoom', (tester) async {
    await pumpPaper(tester, ScheduleViewer(grid: grid, title: 'Session 1'));

    final interactive = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
    final scale = interactive.transformationController!.value.getMaxScaleOnAxis();
    expect(scale, closeTo(1400 / (SchedulePaperLayout.width + 48), 0.001));
    expect(find.text('Monday'), findsOneWidget);

    interactive.transformationController!.value = Matrix4.identity();
    await tester.pump();
    await tester.tap(find.byType(ScheduleViewer));
    await tester.pump(kDoubleTapMinTime + const Duration(milliseconds: 10));
    await tester.tap(find.byType(ScheduleViewer));
    await tester.pump(const Duration(seconds: 1));
    expect(interactive.transformationController!.value.getMaxScaleOnAxis(), closeTo(scale, 0.001));
  });
}
