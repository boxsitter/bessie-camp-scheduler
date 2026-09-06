
import 'package:bessie/src/shared/widgets/containers/titled_container.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../shared/styles/text_styles.dart';
import '../../../../shared/widgets/containers/rounded_container.dart';

class ActivityReorderableList extends StatelessWidget {
  const ActivityReorderableList({
    super.key,
    required this.orderedItemIds,
    required this.displayInfo,
    required this.itemIdsToNames,
    required this.onReorder,
    required this.title,
  });

  final List<String> orderedItemIds;
  final Map<String, String> itemIdsToNames;
  final void Function(String) displayInfo;
  final void Function(int, int) onReorder;

  final String title;

  @override
  Widget build(BuildContext context) {
    return TitledContainer(
      title: title,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: orderedItemIds.length,
        itemBuilder: (context, index) {
          final activityId = orderedItemIds[index];
          final activityName = itemIdsToNames[activityId] ?? 'Unknown Activity';

          return BessRoundedContainer(
              key: ValueKey(activityId),
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              height: 50,
              borderThickness: 2,
              showBorder: true,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '#${index + 1}    $activityName',
                    style: BessTextStyles.standard,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.info),
                    // Remove padding
                    padding: EdgeInsets.zero,
                    // Remove minimum size constraints
                    constraints: const BoxConstraints(),
                    onPressed: () => displayInfo(activityId),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.grab,

                    child: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(LucideIcons.gripVertical),
                    ),
                  ),
                ],
              ));
        },
        onReorder: onReorder,
        proxyDecorator: (Widget child, int index, Animation<double> animation) {
          return Material(
            color: Colors.transparent,
            child: child,
          );
        },
      ),
    );
  }
}
