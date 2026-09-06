import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/containers/rounded_container.dart';

class BessDraggableContainer<T extends Object> extends StatelessWidget {
  const BessDraggableContainer({
    super.key,
    required this.item,
    this.onDragStarted,
    this.onDragEnd,
    this.padding = const EdgeInsets.all(8),
  });

  final dynamic item;
  final void Function()? onDragStarted;
  final void Function(DraggableDetails)? onDragEnd;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const EdgeInsets internalPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    const EdgeInsets ghostPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    final TextStyle textStyle = BessTextStyles.standardBold.copyWith(fontSize: 16);

    Widget getChild(bool isTransparent) {
      if (item is PrincipalActivity && (item as PrincipalActivity).isSkillsRec == true) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skills Rec', style: isTransparent ? textStyle.copyWith(color: Colors.transparent) : textStyle.copyWith(color: BessColors.yellow, fontSize: 12)),
            Text(item.displayTitle, style: isTransparent ? textStyle.copyWith(color: Colors.transparent) : textStyle),
          ],
        );
      } else {
        return Text(item.displayTitle, style: isTransparent ? textStyle.copyWith(color: Colors.transparent) : textStyle);
      }
    }


    // The widget as it appears normally in the list.
    final Widget originalWidget = BessRoundedContainer(
      backgroundColor: BessColors.background,
      showBorder: true,
      borderColor: BessColors.borderSecondary,
      showShadow: false,
      clipContent: false,
      padding: internalPadding,
      child: getChild(false),
    );

    // The widget that is being dragged by the user.
    // It's wrapped in a Material widget to ensure text styles and themes are applied correctly.
    final Widget feedbackWidget = Material(
      color: Colors.transparent,
      child: BessRoundedContainer(
        backgroundColor: BessColors.background,
        showBorder: true,
        borderColor: BessColors.borderSecondary,
        showShadow: true, // The dragged widget has a shadow.
        clipContent: false,
        padding: internalPadding,
        child: getChild(false),
      ),
    );

    // The "ghost" widget that is left behind in the list.
    final Widget ghostWidget = Container(
      color: Colors.transparent,
      padding: ghostPadding,
      child: getChild(true),
    );

    return Padding(
      padding: padding, // This outer padding is for spacing within the grid/list.
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Draggable<T>(
          data: item,
          feedback: feedbackWidget,
          childWhenDragging: ghostWidget,
          onDragStarted: onDragStarted,
          onDragEnd: onDragEnd,
          maxSimultaneousDrags: 1,
          child: originalWidget,
        ),
      ),
    );
  }
}
