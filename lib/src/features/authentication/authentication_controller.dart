import 'package:bessie/src/ember_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../shared/routes/routes.dart';

class AuthenticationController extends GetxController {
  UserService userService = Get.find<UserService>();

  // TextEditingControllers for the form fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Observable for loading state
  final RxBool isLoading = false.obs;

  // Observable for password visibility
  final RxBool hidePassword = true.obs;

  // Observable for "Remember Me" checkbox
  final RxBool rememberMe = false.obs;

  /// Toggles the visibility of the password input field.
  void togglePasswordVisibility() {
    hidePassword.value = !hidePassword.value;
  }

  /// Attempts to log in the user with the email and password from the controllers.
  Future<void> loginUser() async {
    if (isLoading.value) return; // Prevent multiple submissions if already loading

    try {
      isLoading.value = true;

      final String email = emailController.text.trim();
      final String password = passwordController.text;

      // Perform login using your Ember Core UserService
      await userService.login(email, password, rememberMe.value, kIsWeb);

      if (userService.isAuthenticated) {
        await Get.offAllNamed(BessRoutes.rosters);
      }
    } catch (e, st) {
      Error.throwWithStackTrace(Debug.parseException(e), st);
    } finally {
      isLoading.value = false;
      passwordController.clear();
      Debug.logInfo('Password controller cleared after login attempt.');
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
    Debug.logInfo('Disposed AuthenticationController');
  }
}