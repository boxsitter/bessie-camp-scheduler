import 'package:bessie/src/shared/widgets/layouts/templates/center_box.dart';
import 'package:bessie/src/features/authentication/view/login/widgets/login_form.dart';
import 'package:bessie/src/features/authentication/view/login/widgets/login_header.dart';
import 'package:flutter/material.dart';

import '../../../../shared/constants//sizes.dart';
import '../../../../shared/widgets/header/menu_bar.dart';
import '../../../../shared/widgets/layouts/templates/site_layout.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(
        useLayout: false,
        desktop: const LoginScreenDesktopTablet(),
        mobile: const LoginScreenMobile(),
      menuBar: BessMenuBar(),
    );
  }
}

class LoginScreenDesktopTablet extends StatelessWidget {
  const LoginScreenDesktopTablet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const BessCenterBox(
      child: Column(
        children: [
          // Header
          BessLoginHeader(),
          // Form
          BessLoginForm(),
        ],
      ),
    );
  }
}

class LoginScreenMobile extends StatelessWidget {
  const LoginScreenMobile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(BessSizes.defaultSpace),
            child: Column(
              children: [
                // Header
                BessLoginHeader(),
                // Form
                BessLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
