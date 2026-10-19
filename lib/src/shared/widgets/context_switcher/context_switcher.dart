import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../services/popup_service.dart';
import 'controller/session_selector_controller.dart';

/// Opens the dialog for choosing which session to work in.
Future<void> showContextSwitcher() async {
  final controller = Get.find<SessionSelectorController>()..beginSelection();
  await Get.find<PopupService>().showFullScreenDialog(
    title: 'Change session',
    description: controller.seasonName,
    actions: [
      Obx(
        () => ShadButton(
          onPressed:
              controller.canSwitch
                  ? () async {
                    if (await controller.switchToSelected()) Get.back();
                  }
                  : null,
          child: const Text('Switch'),
        ),
      ),
    ],
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SessionPicker(controller: controller, initialSessionId: controller.selectedSessionId.value),
    ),
  );
}

/// A dropdown of the season's sessions that records the choice in [controller].
class SessionPicker extends StatelessWidget {
  const SessionPicker({super.key, required this.controller, this.initialSessionId});

  final SessionSelectorController controller;
  final String? initialSessionId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sessions = controller.sessions.toList();
      if (sessions.isEmpty) return const Text('This season has no sessions yet.');
      return ShadSelect<String>(
        minWidth: 260,
        initialValue: initialSessionId,
        placeholder: const Text('Choose a session'),
        onChanged: controller.select,
        options: [for (final session in sessions) ShadOption(value: session.id, child: Text(session.name))],
        selectedOptionBuilder: (context, id) => Text(sessions.where((s) => s.id == id).firstOrNull?.name ?? ''),
      );
    });
  }
}
