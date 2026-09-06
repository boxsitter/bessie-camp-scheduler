import 'package:get/get_state_manager/src/rx_flutter/rx_disposable.dart';

import '../ember_core.dart';


class CommitService extends GetxService{
  static CoreFrontend frontend = FrontendManager.instance;

  Future<bool> disarmCommit(Commit commit) async {
    if (!commit.armed) {
      return true;
    }
    if (commit.disarmRequirementsLevel == 0) {
      commit.disarm();
      return true;
    }
    if (commit.disarmRequirementsLevel == 1) {
      // TODO: Give the user details about operation
      bool confirmed = await frontend.getConfirmation(title: 'Confirm Action', message: commit.confirmationMessage);
      if (confirmed) {
        commit.disarm();
        return true;
      } else {
        return false;
      }
    }
    return false;
  }


}