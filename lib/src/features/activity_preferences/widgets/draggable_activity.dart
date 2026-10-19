import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/containers/rounded_container.dart';

/// An activity as a card that can be dragged between the library and the
/// "Yes please" / "No thanks" lists. Tapping it shows the activity's details.
class DraggableActivity extends StatelessWidget {
  const DraggableActivity({
    super.key,
    required this.activity,
    this.onDragStarted,
    this.onTap,
    this.padding = const EdgeInsets.all(8),
  });

  final Activity activity;
  final VoidCallback? onDragStarted;
  final VoidCallback? onTap;

  /// Space around the card, for spacing within the grid/list it is in.
  final EdgeInsets padding;

  static const _cardPadding = EdgeInsets.symmetric(horizontal: 18, vertical: 12);

  @override
  Widget build(BuildContext context) {
    final card = _ActivityCard(activity: activity);

    return Padding(
      padding: padding,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Draggable<Activity>(
          data: activity,
          feedback: Material(
            color: Colors.transparent,
            child: _ActivityCard(activity: activity, showShadow: true),
          ),
          // Keeps the space the card took up while it is being dragged.
          childWhenDragging: Opacity(opacity: 0, child: card),
          onDragStarted: onDragStarted,
          maxSimultaneousDrags: 1,
          child: GestureDetector(onTap: onTap, child: card),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, this.showShadow = false});

  final Activity activity;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final nameStyle = BessTextStyles.standardBold.copyWith(fontSize: 16);

    return BessRoundedContainer(
      backgroundColor: BessColors.background,
      showBorder: true,
      borderColor: BessColors.borderSecondary,
      showShadow: showShadow,
      clipContent: false,
      padding: DraggableActivity._cardPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.isSkillsRec) Text('Skills Rec', style: nameStyle.copyWith(color: BessColors.yellow, fontSize: 12)),
          Text(activity.name, style: nameStyle),
        ],
      ),
    );
  }
}
