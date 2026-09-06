import 'package:bessie/src/repositories/authentication_repository.dart';
import 'package:get/get.dart';

import '../ember_core.dart';

class UserService extends GetxService {
  AuthenticationRepository authRepo = Get.find<AuthenticationRepository>();
  bool get isAuthenticated => authRepo.isUserLoggedIn;

  Future<void> registerCoreUser({
    required Commit commit,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? preferredName = '',
    String note = '',
    required Role role,
  }) async {
    String firebaseUid = await authRepo.registerWithEmailAndPassword(email: email, password: password);

    CoreUser userToRegister = CoreUser(
      firebaseUid: firebaseUid,
      firstName: firstName,
      lastName: lastName,
      preferredName: preferredName,
      note: note,
      role: role,
    );
    commit.addObjectToPush(userToRegister);
  }

  Future<bool> login(String email, String password, bool rememberMe, bool isWeb) async {
    await authRepo.loginWithEmailAndPassword(email, password, rememberMe,  isWeb);
    if (isAuthenticated) {
      await EmberCore.onLogin();
      FrontendManager.instance.onLogin();
    }
    return isAuthenticated;
  }

  Future<void> logout() async {
    await authRepo.logout();
  }

  Future<CoreUser> getCurrentUser() async {
    PullRepository pullRepo = Get.find<PullRepository>();
    String? firebaseUid = authRepo.firebaseUid;
    if (firebaseUid == null) {
      throw Exception('User not logged in');
    }
    String? userId = await pullRepo.queryField('core_user', 'rot', 'firebaseUid', firebaseUid);
    print(userId);
    if (userId == null) {
      throw Exception('User does not have a CoreUser object associated with their firebase credentials');
    }
    CoreUser user = await pullRepo.getObject(userId);
    return user;
  }
}