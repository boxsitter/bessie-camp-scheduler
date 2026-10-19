import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../shared/constants/sizes.dart';
import '../../../../../shared/constants/text_strings.dart';
import '../../../../../shared/routes/routes.dart';
import '../../../../../shared/styles/text_styles.dart';
import '../../../../../shared/widgets/buttons/action_initiator.dart';
import '../../../auth_validators.dart';
import '../../../authentication_controller.dart';

class BessLoginForm extends StatefulWidget {
  const BessLoginForm({super.key});

  @override
  State<BessLoginForm> createState() => _BessLoginFormState();
}

class _BessLoginFormState extends State<BessLoginForm> {
  final AuthenticationController _controller = Get.find<AuthenticationController>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void dispose() {
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) _controller.signIn();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: BessSizes.spaceBtwSections),
        child: AutofillGroup(
          child: Column(
            children: [
              TextFormField(
                controller: _controller.emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                validator: AuthValidators.email,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.mail), labelText: BessTexts.email),
              ),
              const SizedBox(height: BessSizes.spaceBtwInputFields),
              Obx(
                () => TextFormField(
                  controller: _controller.passwordController,
                  focusNode: _passwordFocus,
                  obscureText: _controller.hidePassword.value,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  validator: AuthValidators.password,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.lock),
                    labelText: BessTexts.password,
                    suffixIcon: IconButton(
                      icon: Icon(_controller.hidePassword.value ? LucideIcons.eyeOff : LucideIcons.eye),
                      onPressed: _controller.togglePasswordVisibility,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: () => Get.toNamed(BessRoutes.forgotPassword), child: const Text(BessTexts.forgotPassword)),
              ),
              const SizedBox(height: BessSizes.spaceBtwItems),
              Obx(() => ActionInitiator(onPressed: _submit, awaiting: _controller.isLoading.value, enabledText: BessTexts.signIn)),
              const SizedBox(height: BessSizes.spaceBtwSections),
              Text(
                'Accounts are created by your camp director, so there is no sign-up. '
                'If you can\'t get in, ask them to set you up.',
                textAlign: TextAlign.center,
                style: BessTextStyles.subtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
