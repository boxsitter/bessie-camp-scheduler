import 'package:get/get.dart';

import '../../../../models/camp_session.dart';
import '../../../../services/context_service.dart';
import '../../../services/toast.dart';

/// Which session of the season the user is working in, and changing it.
///
/// Switching only tells [ContextService]; page controllers reload on their
/// own when the session changes, and the user stays on the page they are on.
class SessionSelectorController extends GetxController {
  SessionSelectorController({ContextService? context}) : _context = context ?? Get.find<ContextService>();

  final ContextService _context;

  /// The sessions of the current season, oldest first.
  RxList<CampSession> get sessions => _context.sessions;

  /// The names below read observables, so use them inside an `Obx`.
  String get seasonName => _context.season.value?.name ?? '';
  String get sessionName => _context.session.value?.name ?? 'No session';

  /// The choice being made in the switcher dialog.
  final RxnString selectedSessionId = RxnString();
  final RxBool isSwitching = false.obs;

  /// Whether the dialog's "Switch" button should do something.
  bool get canSwitch => !isSwitching.value && selectedSessionId.value != null && selectedSessionId.value != _context.session.value?.id;

  /// Starts a new choice with the current session selected.
  void beginSelection() => selectedSessionId.value = _context.session.value?.id;

  void select(String? sessionId) => selectedSessionId.value = sessionId;

  /// Switches to the selected session. Returns whether it worked.
  Future<bool> switchToSelected() async {
    final sessionId = selectedSessionId.value;
    if (sessionId == null || isSwitching.value) return false;
    isSwitching.value = true;
    try {
      return await attempt(() async {
            await _context.switchSession(sessionId);
            return true;
          }) ??
          false;
    } finally {
      isSwitching.value = false;
    }
  }
}
