import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/loaders/circular_loader.dart';
import '../schedule_page_controller.dart';
import 'schedule_viewer.dart';

/// What the schedule page shows below the header: the sheet, or why there is none.
class ScheduleBody extends StatelessWidget {
  const ScheduleBody({super.key, required this.controller});

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
