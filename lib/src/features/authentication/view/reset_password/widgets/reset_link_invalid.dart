import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../shared/constants/sizes.dart';
import '../../../../../shared/routes/routes.dart';

/// Shown when the reset page is opened without a valid reset link.
class ResetLinkInvalid extends StatelessWidget {
  const ResetLinkInvalid({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This link doesn\'t work', style: theme.headlineMedium),
        const SizedBox(height: BessSizes.spaceBtwItems),
        Text(
          'Reset links expire after a while and can only be used once, in the browser that asked for them. '
          'Request a new one and try again.',
          style: theme.bodyMedium,
        ),
        const SizedBox(height: BessSizes.spaceBtwSections),
        Row(
          children: [
            TextButton(onPressed: () => Get.offAllNamed(BessRoutes.login), child: const Text('Back to sign in')),
            const Spacer(),
            ElevatedButton(onPressed: () => Get.offAllNamed(BessRoutes.forgotPassword), child: const Text('Send a new link')),
          ],
        ),
      ],
    );
  }
}
