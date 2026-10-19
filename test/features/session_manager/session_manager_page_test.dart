@Tags(['integration'])
library;

import 'package:bessie/src/features/branch_manager/widgets/setup_page.dart';
import 'package:bessie/src/features/session_manager/session_manager_view.dart';
import 'package:bessie/src/features/session_manager/session_manager_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../support/local_supabase.dart';
import '../branch_manager/support/controller_env.dart';
import '../branch_manager/support/harness.dart';

void main() {
  late bool available;
  ControllerEnv? env;

  setUpAll(() async {
    available = await localSupabaseAvailable();
    await loadAppFonts();
    allowRealHttp();
  });

  tearDownAll(ControllerEnv.closeClients);

  tearDown(() async {
    final open = env;
    env = null;
    if (open == null) return;
    Get.delete<SessionManagerController>(force: true);
    await open.dispose();
  });

  /// Shows the page for [email] on a throwaway session (or the seeded one when [throwaway] is false).
  Future<SessionManagerController> showPage(WidgetTester tester, String email, {bool throwaway = true}) async {
    final controller = await tester.runAsync(() async {
      env = await ControllerEnv.open(email);
      if (throwaway) await env!.createTestSession();
      final controller = Get.put(SessionManagerController());
      await controller.reload();
      return controller;
    });
    await pumpApp(tester, const SessionManagerView(), size: const Size(1100, 2800));
    return controller!;
  }

  testWidgets('shows the session to someone who can edit it', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final controller = await showPage(tester, admin);

    expect(find.text('Session setup'), findsOneWidget);
    expect(find.text(controller.setup.value!.session.name), findsWidgets);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Cabins'), findsOneWidget);
    expect(find.text('Preference limits'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('New session'), findsOneWidget);
    expect(find.text('Save cabins'), findsOneWidget);
    expect(find.text('Save limits'), findsOneWidget);
    expect(find.text('Add activities'), findsWidgets);
    expect(find.text('PINES'), findsOneWidget);
    expect(find.text('Ernie'), findsOneWidget, reason: 'cabins show their display name');
    expect(find.text('Skills rec'), findsOneWidget);
  });

  testWidgets('ticking a cabin shows the pending change', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await showPage(tester, admin);
    expect(find.text('No changes.'), findsOneWidget);

    await tester.tap(find.text('Oak'));
    await tester.pump();

    expect(find.text('1 cabin removed.'), findsOneWidget);
    expect(tester.widget<ShadButton>(find.widgetWithText(ShadButton, 'Save cabins')).onPressed, isNotNull);
  });

  testWidgets('shows a read only view to a counselor', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await showPage(tester, counselor, throwaway: false);

    expect(find.text('Session setup'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('New session'), findsNothing);
    expect(find.text('Save cabins'), findsNothing);
    expect(find.text('Save limits'), findsNothing);
    expect(find.text('Add activities'), findsNothing);
    expect(find.textContaining('You can look but not change it.'), findsOneWidget);
  });

  testWidgets('says so when the season has no sessions', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final controller = await showPage(tester, admin);

    env!.context.session.value = null;
    await tester.runAsync(controller.reload);
    await tester.pump();

    expect(find.byType(SetupPage), findsNothing);
    expect(find.text('This season has no sessions yet.'), findsOneWidget);
    expect(find.text('Create the first session'), findsOneWidget);
  });
}
