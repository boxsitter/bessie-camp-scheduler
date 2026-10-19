import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../services/auth_service.dart';
import '../widgets/auth_scaffold.dart';
import 'widgets/reset_link_invalid.dart';
import 'widgets/reset_password_form.dart';

/// Where the emailed link brings the user to choose a new password.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    return AuthScaffold(
      // Following the emailed link signs the user in to a recovery session.
      child: Obx(() => auth.recoveringPassword.value || auth.profile.value != null ? const ResetPasswordForm() : const ResetLinkInvalid()),
    );
  }
}
