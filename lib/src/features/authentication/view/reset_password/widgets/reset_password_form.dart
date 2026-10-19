import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../shared/constants/sizes.dart';
import '../../../../../shared/constants/text_strings.dart';
import '../../../../../shared/widgets/buttons/action_initiator.dart';
import '../../../auth_validators.dart';
import '../../../authentication_controller.dart';

/// Choose a new password (twice) and continue into the app.
class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({super.key});

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final AuthenticationController _controller = Get.find<AuthenticationController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _confirmFocus = FocusNode();

  @override
  void dispose() {
    _confirmFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) _controller.resetPassword();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a new password', style: theme.headlineMedium),
            const SizedBox(height: BessSizes.spaceBtwItems),
            Text('At least ${AuthValidators.minPasswordLength} characters.', style: theme.labelMedium),
            const SizedBox(height: BessSizes.spaceBtwItems * 2),
            Obx(
              () => TextFormField(
                controller: _controller.newPasswordController,
                obscureText: _controller.hidePassword.value,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.newPassword,
                onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
                decoration: InputDecoration(
                  prefixIcon: const Icon(LucideIcons.lock),
                  labelText: BessTexts.newPassword,
                  suffixIcon: IconButton(
                    icon: Icon(_controller.hidePassword.value ? LucideIcons.eyeOff : LucideIcons.eye),
                    onPressed: _controller.togglePasswordVisibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: BessSizes.spaceBtwInputFields),
            Obx(
              () => TextFormField(
                controller: _controller.confirmPasswordController,
                focusNode: _confirmFocus,
                obscureText: _controller.hidePassword.value,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) => AuthValidators.confirmPassword(value, _controller.newPasswordController.text),
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.lock), labelText: 'Confirm new password'),
              ),
            ),
            const SizedBox(height: BessSizes.spaceBtwItems * 2),
            Obx(() => ActionInitiator(onPressed: _submit, awaiting: _controller.isLoading.value, enabledText: 'Change password')),
            const SizedBox(height: BessSizes.spaceBtwItems),
            Center(child: TextButton(onPressed: _controller.cancelPasswordReset, child: const Text('Cancel'))),
          ],
        ),
      ),
    );
  }
}
