import 'package:bessie/src/shared/widgets/buttons/action_initiator.dart';
import 'package:bessie/src/features/authentication/authentication_controller.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../../shared/constants//sizes.dart';
import '../../../../../shared/constants//text_strings.dart';

class BessLoginForm extends StatelessWidget {
  const BessLoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final AuthenticationController controller = Get.find<AuthenticationController>();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    final FocusNode emailFocusNode = FocusNode();
    final FocusNode passwordFocusNode = FocusNode();

    void submitForm() {
      // Unfocus fields to trigger any onUnfocus validation and hide keyboard
      emailFocusNode.unfocus();
      passwordFocusNode.unfocus();

      if (_formKey.currentState?.validate() ?? false) {
        controller.loginUser();
      } else {
        Debug.logWarning('Form validation failed');
      }
    }

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUnfocus,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: BessSizes.spaceBtwSections),
          child: Column(
            children: [
              /// Email
              TextFormField(
                focusNode: emailFocusNode,
                textInputAction: TextInputAction.next,
                autofillHints: [AutofillHints.email, AutofillHints.username],
                spellCheckConfiguration: SpellCheckConfiguration.disabled(),
                validator: (value) => InputValidation.validateEmail(value),
                controller: controller.emailController,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(passwordFocusNode);
                },
                decoration: const InputDecoration(
                  prefixIcon: Icon(LucideIcons.messageCircleMore),
                  labelText: BessTexts.email,
                ),
              ),

              const SizedBox(height: BessSizes.spaceBtwInputFields),

              /// Password
              Obx(() => TextFormField(
                    focusNode: passwordFocusNode, // Assign FocusNode
                    controller: controller.passwordController,
                    obscureText: controller.hidePassword.value,
                    validator: (value) => InputValidation.validatePassword(value),
                    textInputAction: TextInputAction.done, // Trigger submission
                    onFieldSubmitted: (_) {
                      submitForm();
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(LucideIcons.lock),
                      labelText: BessTexts.password,
                      suffixIcon: IconButton(
                        icon: Icon(controller.hidePassword.value ? LucideIcons.eyeOff : LucideIcons.eye),
                        onPressed: () => controller.hidePassword.value = !controller.hidePassword.value,
                      ),
                    ),
                  )),

              const SizedBox(height: BessSizes.spaceBtwInputFields / 2),

              /// Remember me & forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// Remember Me
                  Obx(() => Row(
                        children: [
                          Checkbox(
                              value: controller.rememberMe.value,
                              onChanged: (value) => controller.rememberMe.value = value ?? false),
                          const Text(BessTexts.rememberMe),
                        ],
                      )),

                  // /// Forget Password
                  // TextButton(
                  //     onPressed: () {
                  //       // TODO: Implement forgot password navigation
                  //       // Get.to(() => const ForgotPasswordScreen());
                  //       Debug.logInfo("Forgot Password button pressed");
                  //     },
                  //     child: const Text(BessTexts.forgotPassword)),
                ],
              ),

              const SizedBox(height: BessSizes.spaceBtwSections),

              /// Sign in button
               Obx(() => ActionInitiator(
                onPressed: () => submitForm(),
                awaiting: controller.isLoading.value,
                enabledText: 'Sign In',
               ))

              // const SizedBox(height: BessSizes.spaceBtwInputFields / 2),
              //
              // Text(BessTexts.or, style: Theme.of(context).textTheme.bodyMedium),
              //
              // const SizedBox(height: BessSizes.spaceBtwInputFields / 2),

              // /// Join button
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //       onPressed: () {}, child: const Text(BessTexts.joinCamp)),
              // )
            ],
          )),
    );
  }
}
