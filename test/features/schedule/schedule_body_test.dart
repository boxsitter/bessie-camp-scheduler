import 'package:bessie/src/data/roster_repository.dart';
import 'package:bessie/src/data/session_repository.dart';
import 'package:bessie/src/data/auth_repository.dart';
import 'package:bessie/src/data/catalog_repository.dart';
import 'package:bessie/src/data/profile_repository.dart';
import 'package:bessie/src/features/schedule/schedule_page_controller.dart';
import 'package:bessie/src/features/schedule/widgets/schedule_body.dart';
import 'package:bessie/src/features/schedule/widgets/schedule_viewer.dart';
import 'package:bessie/src/services/auth_service.dart';
import 'package:bessie/src/services/context_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'fakes.dart';
import 'fixtures.dart';

void main() {
  final monday = day(0);
  final archery = activity('archery', name: 'Archery', capacity: 1);
  final morning = block('morning', monday, title: 'Choice 1');
  final schedule = scheduleOf(
    days: [monday],
    blocks: [morning],
    scheduled: [scheduled('s-archery', morning, archery)],
    activities: [archery],
  );

  late FakeSessionRepository sessions;
  late ContextService context;
  setUp(() {
    Get.reset();
    final client = newClient();
    final roster = FakeRosterRepository(client)..campers = [camper('a', assignments: {'morning': 's-archery'})];
    sessions = FakeSessionRepository(client, schedule);
    context = ContextService(
      CatalogRepository(client),
      ProfileRepository(client),
      AuthService(AuthRepository(client), ProfileRepository(client)),
    )..session.value = campSession('s1');
    Get.put<RosterRepository>(roster);
    Get.put<SessionRepository>(sessions);
    Get.put<ContextService>(context);
    Get.put(SchedulePageController());
  });

  tearDown(Get.reset);

  Future<void> pumpBody(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GetBuilder<SchedulePageController>(
            // `state.controller` is not set yet while initState runs.
      initState: (_) => Get.find<SchedulePageController>().ensureLoaded(),
            builder: (controller) => ScheduleBody(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the weekly sheet once loaded', (tester) async {
    await pumpBody(tester);
    expect(find.byType(ScheduleViewer), findsOneWidget);
    expect(find.text('Archery'), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
    expect(find.text('Session s1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('says when no session is selected', (tester) async {
    context.session.value = null;
    await pumpBody(tester);

    expect(find.text('No session selected'), findsOneWidget);
    expect(find.byType(ScheduleViewer), findsNothing);
  });

  testWidgets('says when nothing is scheduled', (tester) async {
    sessions.schedule = scheduleOf(days: [monday], blocks: const [], scheduled: const [], activities: const []);
    await pumpBody(tester);

    expect(find.text('Nothing scheduled yet'), findsOneWidget);
  });

  testWidgets('shows a failure with a way to try again', (tester) async {
    sessions.failWith = PostgrestException(message: 'boom', code: 'XX000');
    await pumpBody(tester);

    expect(find.text('Couldn\'t load the schedule'), findsOneWidget);
    expect(find.text('The server rejected that request.'), findsOneWidget);

    sessions.failWith = null;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn\'t load the schedule'), findsNothing);
    expect(find.byType(ScheduleViewer), findsOneWidget);
  });
}
