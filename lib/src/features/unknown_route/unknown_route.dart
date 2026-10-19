import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/constants/colors.dart';
import '../../shared/routes/routes.dart';
import '../../shared/styles/text_styles.dart';
import '../../shared/widgets/buttons/card_button.dart';

/// Shown for any address the app has no page for.
class UnknownRoute extends StatelessWidget {
  const UnknownRoute({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.compass, size: 48, color: BessColors.textSubtle),
                const SizedBox(height: 16),
                Text('Page not found', style: BessTextStyles.boldCardTitle, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'The page you tried to open doesn\'t exist or has moved.',
                  style: BessTextStyles.largerLabel,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CardButton(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  baseTint: BessColors.primary,
                  onPressed: () => Get.offAllNamed(BessRoutes.rosters),
                  child: Center(child: Text('Go back home', style: BessTextStyles.standard)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
