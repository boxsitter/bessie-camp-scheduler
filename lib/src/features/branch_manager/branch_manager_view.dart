import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../shared/constants/sizes.dart';
import 'branch_manager_controller.dart';
import 'widgets/activities_section.dart';
import 'widgets/cabins_section.dart';
import 'widgets/setup_page.dart';

/// The content of the branch catalog page.
class BranchManagerView extends StatelessWidget {
  const BranchManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BranchManagerController>();
    return Obx(() {
      if (!controller.hasLoaded.value) {
        final error = controller.loadError.value;
        if (controller.isLoading.value || error == null) return const PageMessage.loading();
        return PageMessage(message: error, actionLabel: 'Try again', onAction: controller.load);
      }

      final canEdit = controller.canEdit;
      final tab = controller.tab.value;
      return SetupPage(
        title: 'Branch catalog',
        subtitle: canEdit
            ? 'The activities and cabins of ${controller.branchName}.'
            : 'The activities and cabins of ${controller.branchName}. You can look but not change them.',
        children: [
          _TabBar(selected: tab, onSelected: (value) => controller.tab.value = value),
          if (tab == CatalogTab.activities)
            ActivitiesSection(
              activities: controller.activities.toList(),
              canEdit: canEdit,
              onCreate: controller.openActivityForm,
              onEdit: (activity) => controller.openActivityForm(editing: activity),
              onDelete: controller.deleteActivity,
            )
          else
            CabinsCatalogSection(cabins: controller.cabins.toList(), canEdit: canEdit, onCreate: controller.openCabinForm, onDelete: controller.deleteCabin),
        ],
      );
    });
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.selected, required this.onSelected});

  final CatalogTab selected;
  final ValueChanged<CatalogTab> onSelected;

  @override
  Widget build(BuildContext context) {
    Widget tab(CatalogTab value, String label, IconData icon) {
      final leading = Icon(icon, size: 16);
      return value == selected
          ? ShadButton(size: ShadButtonSize.sm, leading: leading, child: Text(label))
          : ShadButton.ghost(size: ShadButtonSize.sm, leading: leading, onPressed: () => onSelected(value), child: Text(label));
    }

    return Row(
      children: [
        tab(CatalogTab.activities, 'Activities', LucideIcons.layoutGrid),
        const SizedBox(width: BessSizes.sm),
        tab(CatalogTab.cabins, 'Cabins', LucideIcons.house),
      ],
    );
  }
}
