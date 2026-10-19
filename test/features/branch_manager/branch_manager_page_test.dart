@Tags(['integration'])
library;

import 'package:bessie/src/features/branch_manager/branch_manager_view.dart';
import 'package:bessie/src/features/branch_manager/branch_manager_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../support/local_supabase.dart';
import 'support/controller_env.dart';
import 'support/harness.dart';

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
    Get.delete<BranchManagerController>(force: true);
    await open.dispose();
  });

  Future<BranchManagerController> showPage(WidgetTester tester, String email) async {
    final controller = await tester.runAsync(() async {
      env = await ControllerEnv.open(email);
      final controller = Get.put(BranchManagerController());
      await controller.load();
      return controller;
    });
    await pumpApp(tester, const BranchManagerView(), size: const Size(1100, 2800));
    return controller!;
  }

  testWidgets('lists activities, then cabins, with editing for people who may', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    final controller = await showPage(tester, admin);

    expect(find.text('Branch catalog'), findsOneWidget);
    expect(find.text('Activities'), findsWidgets);
    expect(find.text('CREATIVE'), findsOneWidget);
    expect(find.text('Soccer'), findsOneWidget);
    expect(find.text('New activity'), findsOneWidget);
    expect(find.byTooltip('Edit Soccer'), findsOneWidget);
    expect(find.text('Double block'), findsOneWidget, reason: 'the ropes course');
    expect(find.text('Hidden'), findsOneWidget, reason: 'the swim test');
    expect(find.text('Oak'), findsNothing, reason: 'cabins are on the other tab');

    await tester.tap(find.text('Cabins').first);
    await tester.pump();

    expect(controller.tab.value, CatalogTab.cabins);
    expect(find.text('PINES'), findsOneWidget);
    expect(find.text('Oak'), findsOneWidget);
    expect(find.text('New cabin'), findsOneWidget);
    expect(find.byTooltip('Delete Oak'), findsOneWidget);
  });

  testWidgets('is read only for a counselor', (tester) async {
    if (!available) return markTestSkipped('local Supabase is not running');
    await showPage(tester, counselor);

    expect(find.text('Soccer'), findsOneWidget);
    expect(find.text('New activity'), findsNothing);
    expect(find.byTooltip('Edit Soccer'), findsNothing);
    expect(find.byTooltip('Delete Soccer'), findsNothing);
    expect(find.textContaining('You can look but not change them.'), findsOneWidget);

    await tester.tap(find.text('Cabins').first);
    await tester.pump();

    expect(find.text('Oak'), findsOneWidget);
    expect(find.text('New cabin'), findsNothing);
    expect(find.byTooltip('Delete Oak'), findsNothing);
  });
}
