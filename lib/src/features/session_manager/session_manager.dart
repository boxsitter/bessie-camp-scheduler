import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import '../branch_manager/widgets/setup_page.dart';
import 'session_manager_controller.dart';
import 'session_setup_logic.dart';
import 'widgets/cabins_section.dart';
import 'widgets/limits_section.dart';
import 'widgets/overview_section.dart';
import 'widgets/schedule_section.dart';

/// Session setup: cabins, preference limits and schedule of the current
/// session, and creating new sessions.
class SessionManager extends StatelessWidget {
  const SessionManager({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: const SessionManagerView(), menuBar: BessMenuBar());
  }
}

class SessionManagerView extends StatelessWidget {
  const SessionManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SessionManagerController>();
    return Obx(() {
      final canEdit = controller.canEdit;
      final newSession = canEdit ? controller.openNewSession : null;

      final setup = controller.setup.value;
      if (setup == null) {
        if (!controller.hasSession) {
          return PageMessage(
            message: 'This season has no sessions yet.',
            actionLabel: canEdit ? 'Create the first session' : null,
            onAction: newSession,
          );
        }
        final error = controller.loadError.value;
        if (controller.isLoading.value || error == null) return const PageMessage.loading();
        return PageMessage(message: error, actionLabel: 'Try again', onAction: controller.reload);
      }

      final busy = controller.isSaving.value;
      return SetupPage(
        title: 'Session setup',
        subtitle: canEdit ? setup.session.name : '${setup.session.name}. You can look but not change it.',
        trailing: newSession == null
            ? null
            : ShadButton.secondary(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.plus, size: 16),
                onPressed: newSession,
                child: const Text('New session'),
              ),
        children: [
          OverviewSection(setup: setup, seasonName: controller.seasonName),
          SessionCabinsSection(
            setup: setup,
            selected: controller.selectedCabinIds.toSet(),
            canEdit: canEdit,
            busy: busy,
            onToggle: controller.toggleCabin,
            onSetMany: controller.setCabinsSelected,
            onSave: controller.saveCabins,
            onReset: controller.resetCabins,
          ),
          LimitsSection(
            draft: controller.limitsDraft.value,
            saved: LimitsDraft.fromLimits(setup.session.limits),
            canEdit: canEdit,
            busy: busy,
            onChanged: controller.setLimits,
            onSave: controller.saveLimits,
            onReset: controller.resetLimits,
          ),
          ScheduleSection(setup: setup, canEdit: canEdit, busy: busy, onAdd: controller.addActivities, onRemove: controller.removeActivity),
        ],
      );
    });
  }
}
