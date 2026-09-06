import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../shared/routes/routes.dart';
import '../../../../../shared/constants//image_strings.dart';
import '../../../../../shared/constants//sizes.dart';
import '../../../../../shared/constants//text_strings.dart';

class ResetPasswordWidget extends StatelessWidget {
  const ResetPasswordWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final email = Get.arguments ?? '';
    return Column(
      children: [
        /// Header
        Row(
          children: [
            IconButton(
                onPressed: () => Get.offAllNamed(BessRoutes.login),
                icon: Icon(LucideIcons.x)),
          ],
        ),
        const SizedBox(height: BessSizes.spaceBtwItems),

        /// Image
        const Image(
            image: AssetImage(BessImages.deliveredEmailIllustration),
            width: 300,
            height: 300),
        const SizedBox(height: BessSizes.spaceBtwItems),

        // Title & Subtitle
        Text('${BessTexts.changeYourPasswordTitle} $email',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: BessSizes.spaceBtwItems),
        Text(BessTexts.changeYourPasswordSubTitle,
            style: Theme.of(context).textTheme.labelMedium,
            textAlign: TextAlign.center),
        const SizedBox(height: BessSizes.spaceBtwSections),

        /// Buttons
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () => Get.offAllNamed(BessRoutes.login),
              child: const Text(BessTexts.done)),
        ),
        const SizedBox(height: BessSizes.spaceBtwItems),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
              onPressed: () {}, child: const Text(BessTexts.resendEmail)),
        ),
      ],
    );
  }
}
