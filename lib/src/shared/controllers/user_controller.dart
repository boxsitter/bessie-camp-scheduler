import 'package:bessie/src/ember_core.dart';
import 'package:get/get.dart';

class UserController extends GetxController {

  static CoreUser nullUser = CoreUser(firebaseUid: null, firstName: 'null', lastName: 'null', role: Role.nullRole);

  CoreUser currentUser = nullUser;
  bool fetchingUserData = false;

}

