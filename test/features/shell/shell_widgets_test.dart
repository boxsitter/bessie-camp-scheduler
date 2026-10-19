import 'package:bessie/src/features/authentication/authentication_controller.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:bessie/src/shared/theme/shad_theme.dart';
import 'package:bessie/src/shared/widgets/context_switcher/controller/session_selector_controller.dart';
import 'package:bessie/src/shared/widgets/header/controllers/menu_bar_controller.dart';
import 'package:bessie/src/shared/widgets/header/header.dart';
import 'package:bessie/src/shared/widgets/header/header_controller.dart';
import 'package:bessie/src/shared/widgets/header/menu_bar.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar.dart';
import 'package:bessie/src/shared/widgets/layouts/sidebars/sidebar_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../cli/support/fake_services.dart';

void main() {
  late TestWorld world;

  Future<void> show(WidgetTester tester, Widget body, {StaffRole role = StaffRole.admin, double width = 1400}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    world = TestWorld(
      sessions: [campSession('s1', 'Session 1', DateTime(2026, 6, 15)), campSession('s2', 'Session 2', DateTime(2026, 7, 6))],
      profile: staffProfile(role: role, first: 'Ada', last: 'Lovelace'),
    )..loadSeason();
    Get.put(world.auth);
    Get.put(world.context);
    Get.put(SidebarController());
    Get.put(MenuBarController());
    Get.put(SessionSelectorController());
    Get.put(HeaderController());
    Get.put(AuthenticationController());
    await tester.pumpWidget(ShadApp(theme: BessShadTheme.shadThemeData, home: Scaffold(body: body)));
    // Lets the animation package's zero-delay timers fire.
    await tester.pumpAndSettle();
  }

  // Navigation (after signing out) is a no-op without an app to navigate in.
  setUp(() => Get.testMode = true);
  tearDown(() {
    Get.reset();
    Get.testMode = false;
  });

  group('sidebar', () {
    testWidgets('shows every page to an admin, and the current session', (tester) async {
      await show(tester, const Row(children: [BessSidebar()]));

      for (final title in ['Rosters', 'Preferences', 'Schedule', 'Session setup', 'Branch manager', 'Console']) {
        expect(find.text(title), findsOneWidget, reason: title);
      }
      expect(find.text('Summer 2026'), findsOneWidget);
      expect(find.text('Session 1'), findsOneWidget);
    });

    testWidgets('shows a counselor only the pages that do not change data', (tester) async {
      await show(tester, const Row(children: [BessSidebar()]), role: StaffRole.counselor);

      expect(find.text('Rosters'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      for (final title in ['Session setup', 'Branch manager', 'Console']) {
        expect(find.text(title), findsNothing, reason: title);
      }
    });

    testWidgets('the session name follows a switch made anywhere', (tester) async {
      await show(tester, const Row(children: [BessSidebar()]));

      await world.context.switchSession('s2');
      await tester.pump();

      expect(find.text('Session 2'), findsOneWidget);
      expect(find.text('Session 1'), findsNothing);
    });
  });

  group('header', () {
    Widget header() => const BessHeader(menuBar: BessMenuBar());

    testWidgets('shows who is signed in', (tester) async {
      await show(tester, header());

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('AL'), findsOneWidget);
    });

    testWidgets('keeps just the initials on a narrower window', (tester) async {
      await show(tester, header(), width: 1000);

      expect(find.text('AL'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsNothing);
    });

    testWidgets('the user menu has the role and Sign out, which signs the user out', (tester) async {
      await show(tester, header());

      await tester.tap(find.text('Ada Lovelace'));
      await tester.pumpAndSettle();
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(world.auth.profile.value, isNull);
      expect(world.context.session.value, isNull);
    });

    testWidgets('shows a placeholder while nobody is signed in', (tester) async {
      await show(tester, header());

      world.auth.profile.value = null;
      await tester.pump();

      expect(find.text('?'), findsOneWidget);
    });
  });
}
