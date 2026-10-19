import 'package:flutter/material.dart';

import '../../../../shared/widgets/layouts/templates/center_box.dart';

/// The page behind the sign-in, forgot-password and reset-password screens: a
/// centered card that scrolls on small screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: BessCenterBox(child: child));
  }
}
