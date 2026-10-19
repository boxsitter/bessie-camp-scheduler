import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/containers/rounded_container.dart';
import '../../../shared/widgets/layouts/templates/site_layout.dart';
import '../../../shared/widgets/loaders/circular_loader.dart';
import '../controllers/activity_preferences_controller.dart';
import '../widgets/header_builders.dart';
import 'activity_preferences_cabins.dart';
import 'activity_preferences_selector.dart';
import 'camper_selector.dart';

/// Collects each camper's activity requests and vetoes: pick a cabin, pick a
/// camper, drag activities into place.
class ActivityPreferences extends StatelessWidget {
  const ActivityPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ActivityPreferencesController>(
      initState: (state) => state.controller?.ensureLoaded(),
      builder: (controller) => BessSiteTemplate(
        desktop: ActivityPreferencesDesktop(controller: controller),
        desktopPadding: false,
        tabletPadding: false,
        menuBar: buildActivityPreferencesMenuBar(controller: controller),
        centerActions: buildActivityPreferencesCenterActions(controller: controller),
      ),
    );
  }
}

class ActivityPreferencesDesktop extends StatelessWidget {
  const ActivityPreferencesDesktop({super.key, required this.controller});

  final ActivityPreferencesController controller;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) return const BessCircularLoader();

    final error = controller.loadError;
    if (error != null) {
      return _StatusMessage(
        icon: LucideIcons.triangleAlert,
        title: 'Couldn\'t load the campers',
        message: error,
        actionLabel: 'Try again',
        onAction: controller.reload,
      );
    }
    if (!controller.hasSession) {
      return const _StatusMessage(
        icon: LucideIcons.calendarX,
        title: 'No session selected',
        message: 'Create or select a session to collect activity preferences.',
      );
    }
    if (!controller.hasCampers) {
      return const _StatusMessage(
        icon: LucideIcons.users,
        title: 'No campers yet',
        message: 'Import this session\'s roster first, then come back to collect their preferences.',
      );
    }
    if (controller.showingCabins) return ActivityPreferencesCabins(controller: controller);

    return Row(
      children: [
        if (controller.campersPaneOpen)
          BessRoundedContainer(
            width: 200,
            height: double.infinity,
            backgroundColor: BessColors.crust,
            showBorder: true,
            borderThickness: 1,
            borderColor: BessColors.borderPrimary,
            padding: const EdgeInsets.only(right: 16, left: 16, top: 16),
            manualBorderRadius: const BorderRadius.only(bottomRight: Radius.circular(32), topRight: Radius.circular(32)),
            showShadow: true,
            child: CamperSelector(
              campers: controller.campersInSelectedCabin,
              selectedCamper: controller.selectedCamper,
              onSelectCamper: controller.selectCamper,
              isPending: controller.isPending,
              cabinName: controller.selectedCabinTitle,
            ),
          ),
        Expanded(child: ActivityPreferencesSelector(controller: controller)),
      ],
    );
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
