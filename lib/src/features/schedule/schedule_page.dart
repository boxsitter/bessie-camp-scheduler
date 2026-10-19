import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/constants/colors.dart';
import '../../shared/styles/text_styles.dart';
import '../../shared/widgets/buttons/card_button.dart';
import '../../shared/widgets/buttons/icon_button.dart';
import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';
import '../../shared/widgets/loaders/circular_loader.dart';
import 'schedule_page_controller.dart';
import 'widgets/schedule_viewer.dart';

/// The current session's weekly schedule, read-only and laid out to be
/// printed (landscape letter): one column per day, each block listing its
/// activities and how full they are.
class SchedulePage extends StatelessWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SchedulePageController>(
      initState: (state) => state.controller?.ensureLoaded(),
      builder: (controller) => BessSiteTemplate(
        desktop: SchedulePageDesktop(controller: controller),
        desktopPadding: false,
        menuBar: BessMenuBar<SchedulePageController>(externalPageController: controller),
        centerActions: [
          BessIconButton(
            iconData: LucideIcons.rotateCw500,
            onPressed: controller.reload,
            enabled: !controller.isLoading,
            isLoading: controller.isLoading,
            radius: 8,
          ),
        ],
      ),
    );
  }
}

class SchedulePageDesktop extends StatelessWidget {
  const SchedulePageDesktop({super.key, required this.controller});

  final SchedulePageController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) return const BessCircularLoader();

    final error = controller.loadError;
    if (error != null) {
      return _StatusMessage(
        icon: LucideIcons.triangleAlert,
        title: 'Couldn\'t load the schedule',
        message: error,
        actionLabel: 'Try again',
        onAction: controller.reload,
      );
    }
    if (!controller.hasSession) {
      return const _StatusMessage(
        icon: LucideIcons.calendarX,
        title: 'No session selected',
        message: 'Create or select a session to see its schedule.',
      );
    }
    final grid = controller.grid;
    if (grid == null) return const BessCircularLoader();
    if (grid.isEmpty) {
      return const _StatusMessage(
        icon: LucideIcons.calendarDays,
        title: 'Nothing scheduled yet',
        message: 'This session has no blocks. Add blocks and activities in the session manager.',
      );
    }
    return ScheduleViewer(grid: grid, title: controller.sessionName);
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.icon, required this.title, required this.message, this.actionLabel, this.onAction});

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: BessColors.textSubtle),
            const SizedBox(height: 16),
            Text(title, style: BessTextStyles.boldCardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(message, style: BessTextStyles.largerLabel, textAlign: TextAlign.center),
            if (onAction != null) ...[
              const SizedBox(height: 24),
              CardButton(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                onPressed: onAction,
                child: Center(child: Text(actionLabel ?? 'Try again', style: BessTextStyles.standard)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
