import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';

class HeaderController extends GetxController {


  // Reactive variables to hold the user data and loading/error states
  final Rx<CoreUser?> currentUser = Rx<CoreUser?>(null);
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  // --- Safely computed properties ---
  String get userFullName {
    if (currentUser.value?.preferredName != null) {
      return currentUser.value?.preferredName ?? 'User';
    }
    return currentUser.value?.fullName ?? 'User';
  }

  String get userRoleName {
    // Assuming Role is an enum and role.name is always a valid string.
    // If CoreUser.role can be null, this needs a null check too.
    // For example: currentUser.value?.role?.name ?? 'Role';
    // Based on CoreUser, 'role' is not nullable, but role.name gives the string.
    if (currentUser.value?.role.name == 'root') {
      return '';
    }
    return currentUser.value?.role.name ?? 'Role';
  }

  String get userInitial {
    final name = currentUser.value?.fullName;
    if (name != null && name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return '?';
  }
  // --- End safely computed properties ---

  @override
  void onInit() {
    super.onInit();
  }
}