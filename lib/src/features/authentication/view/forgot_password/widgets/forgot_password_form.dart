import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../shared/constants/sizes.dart';
import '../../../../../shared/constants/text_strings.dart';
import '../../../../../shared/routes/routes.dart';
import '../../../../../shared/widgets/buttons/action_initiator.dart';
import '../../../auth_validators.dart';
import '../../../authentication_controller.dart';

/// Asks for the account's email address and sends a reset link to it.
class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final AuthenticationController _controller = Get.find<AuthenticationController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _sent = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final sent = await _controller.sendResetLink();
    if (mounted && sent) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(onPressed: Get.back, icon: const Icon(LucideIcons.arrowLeft), tooltip: 'Back to sign in'),
        const SizedBox(height: BessSizes.spaceBtwItems),
        Text(BessTexts.forgotPasswordTitle, style: theme.headlineMedium),
        const SizedBox(height: BessSizes.spaceBtwItems),
        if (_sent) ..._confirmation(theme) else ..._form(theme),
      ],
    );
  }

  List<Widget> _form(TextTheme theme) => [
    Text('Enter the email address of your account and we\'ll send you a link to choose a new password.', style: theme.labelMedium),
    const SizedBox(height: BessSizes.spaceBtwItems * 2),
    Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller.emailController,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.email],
        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
        validator: AuthValidators.email,
        onFieldSubmitted: (_) => _submit(),
        decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.mail), labelText: BessTexts.email),
      ),
    ),
    const SizedBox(height: BessSizes.spaceBtwItems * 2),
    Obx(() => ActionInitiator(onPressed: _submit, awaiting: _controller.isLoading.value, enabledText: 'Send reset link')),
  ];

  List<Widget> _confirmation(TextTheme theme) => [
    Text('Check your inbox', style: theme.titleMedium),
    const SizedBox(height: BessSizes.sm),
    Text(
      'If ${_controller.emailController.text.trim()} belongs to a Bessie account, a reset link is on its way. '
      'Open it in this same browser to choose your new password.',
      style: theme.bodyMedium,
    ),
    const SizedBox(height: BessSizes.spaceBtwSections),
    Row(
      children: [
        TextButton(onPressed: () => setState(() => _sent = false), child: const Text('Use a different address')),
        const Spacer(),
        TextButton(onPressed: () => Get.offAllNamed(BessRoutes.login), child: const Text('Back to sign in')),
      ],
    ),
  ];
}
