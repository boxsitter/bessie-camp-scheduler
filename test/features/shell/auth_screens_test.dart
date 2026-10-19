import 'package:bessie/src/features/authentication/authentication_controller.dart';
import 'package:bessie/src/features/authentication/view/forgot_password/forgot_password.dart';
import 'package:bessie/src/features/authentication/view/login/login.dart';
import 'package:bessie/src/features/authentication/view/reset_password/reset_password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../../cli/support/fake_services.dart';

void main() {
  late TestWorld world;

  Future<void> show(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    world = TestWorld();
    Get.put(world.auth);
    Get.put(AuthenticationController());
    await tester.pumpWidget(MaterialApp(home: screen));
  }

  tearDown(Get.reset);

  group('login', () {
    testWidgets('explains that accounts come from the director and has no remember-me or sign-up', (tester) async {
      await show(tester, const LoginScreen());

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.textContaining('no sign-up'), findsOneWidget);
      expect(find.text('Remember Me'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('does not try to sign in with an invalid email or empty password', (tester) async {
      await show(tester, const LoginScreen());

      await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(Get.find<AuthenticationController>().isLoading.value, isFalse);
    });

    testWidgets('the password can be shown and hidden', (tester) async {
      await show(tester, const LoginScreen());
      final controller = Get.find<AuthenticationController>();

      expect(controller.hidePassword.value, isTrue);
      await tester.tap(find.byType(IconButton).first);
      await tester.pump();
      expect(controller.hidePassword.value, isFalse);
    });
  });

  group('forgot password', () {
    testWidgets('asks for an email address and checks it', (tester) async {
      await show(tester, const ForgotPasswordScreen());

      expect(find.text('Send reset link'), findsOneWidget);
      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      expect(find.text('Enter your email address.'), findsOneWidget);
    });
  });

  group('reset password', () {
    testWidgets('says the link does not work when the page is opened without one', (tester) async {
      await show(tester, const ResetPasswordScreen());

      expect(find.text('This link doesn\'t work'), findsOneWidget);
      expect(find.text('Send a new link'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('shows the form once a recovery session exists', (tester) async {
      await show(tester, const ResetPasswordScreen());
      world.auth.recoveringPassword.value = true;
      await tester.pump();

      expect(find.text('Choose a new password'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('requires 8 characters and a matching confirmation', (tester) async {
      await show(tester, const ResetPasswordScreen());
      world.auth.recoveringPassword.value = true;
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).first, 'short');
      await tester.enterText(find.byType(TextFormField).last, 'different');
      await tester.tap(find.text('Change password'));
      await tester.pump();

      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(find.text('The passwords don\'t match.'), findsOneWidget);
      expect(Get.find<AuthenticationController>().isLoading.value, isFalse);
    });
  });
}
