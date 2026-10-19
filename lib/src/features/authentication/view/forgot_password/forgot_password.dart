import 'package:flutter/material.dart';

import '../widgets/auth_scaffold.dart';
import 'widgets/forgot_password_form.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScaffold(child: ForgotPasswordForm());
  }
}
