import 'package:bessie/src/features/activity_preferences/widgets/draggable_activity.dart';
import 'package:bessie/src/features/activity_preferences/widgets/preference_drop_zone.dart';
import 'package:bessie/src/models/activity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

void main() {
  final archery = activity('archery', name: 'Archery');
  final swimSkills = activity('swimskills', name: 'Swim Skills', skills: true);

  Future<void> pump(
    WidgetTester tester, {
    List<Activity> library = const [],
    List<Activity> zone = const [],
    int remaining = 2,
    List<Activity>? dropped,
    List<Activity>? dragged,
    List<Activity>? tapped,
  }) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    for (final a in library)
                      DraggableActivity(activity: a, onDragStarted: () => dragged?.add(a), onTap: () => tapped?.add(a)),
                  ],
                ),
              ),
              SizedBox(
                width: 300,
                child: PreferenceDropZone(
                  title: 'Yes Please',
                  color: Colors.green,
                  activities: zone,
                  remaining: remaining,
                  onDrop: (a) => dropped?.add(a),
                  onDragStarted: (a) => dragged?.add(a),
                  onActivityTap: (a) => tapped?.add(a),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('an empty zone invites a drop and says how many are left', (tester) async {
    await pump(tester, remaining: 3);

    expect(find.text('Yes Please'), findsOneWidget);
    expect(find.text('3 remaining'), findsOneWidget);
    expect(find.text('Drag And Drop Here'), findsOneWidget);
  });

  testWidgets('dragging an activity into the zone hands it over', (tester) async {
    final dropped = <Activity>[];
    final dragged = <Activity>[];
    await pump(tester, library: [archery, swimSkills], dropped: dropped, dragged: dragged);

    await tester.drag(find.text('Archery'), const Offset(500, 0));
    await tester.pumpAndSettle();

    expect(dragged, [archery]);
    expect(dropped, [archery]);
  });

  testWidgets('dropping outside the zone does nothing', (tester) async {
    final dropped = <Activity>[];
    await pump(tester, library: [archery], dropped: dropped);

    await tester.drag(find.text('Archery'), const Offset(0, 200));
    await tester.pumpAndSettle();

    expect(dropped, isEmpty);
  });

  testWidgets('skills recs are labelled', (tester) async {
    await pump(tester, library: [archery, swimSkills]);

    expect(find.text('Skills Rec'), findsOneWidget);
    expect(find.text('Swim Skills'), findsOneWidget);
  });

  testWidgets('lists what is in the zone, draggable back out and tappable for details', (tester) async {
    final tapped = <Activity>[];
    final dragged = <Activity>[];
    await pump(tester, zone: [archery], remaining: 1, tapped: tapped, dragged: dragged);

    expect(find.text('Drag And Drop Here'), findsNothing);
    expect(find.text('Archery'), findsOneWidget);

    await tester.tap(find.text('Archery'));
    await tester.pump();
    expect(tapped, [archery]);

    await tester.drag(find.text('Archery'), const Offset(-200, 0));
    await tester.pumpAndSettle();
    expect(dragged, [archery]);
  });
}
