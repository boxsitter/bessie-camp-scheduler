import 'package:bessie/src/cli/cli.dart';
import 'package:get/get.dart';

import '../ember_core.dart';

class UserCommands {
  static Map<String, EmberCommand> list = {
    'mkuser': CreateUser(
      userInput: FrontendManager.instance.getUserInputImplementation(),
      userOutput: FrontendManager.instance.getUserOutputImplementation(),
    ),
  };
}

class CreateUser extends EmberCommand {
  final UserService userService = Get.find<UserService>();
  final ClientContext clientContext = Get.find<ClientContext>();
  final CommitRepository commitRepo = Get.find<CommitRepository>();
  
  @override
  final String name = 'mkuser';
  @override
  final String description = 'Creates and registers a new user';
  @override
  String get invocationDetails => 'mkuser';
  @override
  List<String> get examples => ['mkuser'];

  CreateUser({
    required super.userInput,
    required super.userOutput,
  });

  @override
  Future<dynamic> run() async {
    String email = await userInput.prompt('Email: ', allowEmpty: false);
    String password = await userInput.promptPassword('Password: ');
    String confirmPassword = await userInput.promptPassword('Confirm Password: ');

    if (password != confirmPassword) {
      userOutput.error('Passwords must match, try again');
      return;
    }

    final List<FormFieldDescriptor> formFieldDescriptors = [
      TextFormFieldDescriptor(label: 'First Name', hintText: 'Enter name...', isRequired: true),
      TextFormFieldDescriptor(label: 'Last Name', hintText: 'Enter last name...', isRequired: true),
      TextFormFieldDescriptor(label: 'Preferred name/camp name (optional)', hintText: 'Enter name...', isRequired: false),
    ];
    final promptOutput = await userInput.promptForm('Registration', formFieldDescriptors);
    if (promptOutput == null) {
      return;
    }

    Commit commit = Commit(disarmRequirementsLevel: 0);
    await userService.registerCoreUser(
        commit: commit,
        email: email,
        password: password,
        firstName: promptOutput[0] as String,
        lastName: promptOutput[1] as String,
        preferredName: (promptOutput[2] as String).isEmpty ? null : promptOutput[2] as String,
        // branchRef: await clientContext.getBranchId(), // TODO: Fix this
        // organizationRef: await clientContext.getOrganizationId(),
        role: Role.admin
    );
    commitRepo.commit(commit);
  }
}