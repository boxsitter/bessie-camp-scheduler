import 'package:get/get.dart';

import '../../../features/authentication/authentication_controller.dart';
import '../../../models/staff_profile.dart';
import '../../../services/auth_service.dart';

/// What the header shows about the signed-in user.
///
/// The getters read [AuthService.profile], so call them inside an `Obx`.
class HeaderController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  StaffProfile? get user => _auth.profile.value;

  String get displayName => user?.fullName ?? '';
  String get roleTitle => user?.role.title ?? '';

  String get initials {
    final text = user?.initials ?? '';
    return text.isEmpty ? '?' : text;
  }

  Future<void> signOut() => Get.find<AuthenticationController>().signOut();
}
