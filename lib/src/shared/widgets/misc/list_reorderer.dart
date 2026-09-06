import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';

class VerticalListReorderer<T> extends StatelessWidget {
  const VerticalListReorderer({
    super.key,
    this.trailingBuilder,
    required this.items,
    required this.onReorder,
    required this.titleBuilder,
  });

  final Widget? Function(T item)? trailingBuilder;
  final Widget? Function(T item) titleBuilder;
  final List<T> items;
  final Function(int, int) onReorder;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        // The 'child' is the ListTile being dragged.
        return Material(
          // The elevation creates the shadow effect you want to keep.
          elevation: 6.0,
          // CRITICAL: Match the shape and color to your ListTile's properties.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BessSizes.cardRadiusLg),
          ),
          color: BessColors.core,
          // This ensures the shadow is cast from the rounded shape,
          // and the background is seamless.
          child: child,
        );
      },
      children: items.map((T item) {
        return ListTile(
          tileColor: BessColors.core,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BessSizes.cardRadiusLg),
            side: BorderSide.none,
          ),
          key: ValueKey(item),
          title: titleBuilder(item),
          leading: ReorderableDragStartListener(
            index: items.indexOf(item),
            child: MouseRegion(cursor: SystemMouseCursors.grab, child: const Icon(LucideIcons.gripVertical)),
          ),
          trailing: trailingBuilder?.call(item),
        );
      }).toList(),
    );
  }
}
