import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../models/activity.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/containers/titled_container.dart';
import '../../../shared/widgets/misc/widget_list.dart';
import 'draggable_activity.dart';

/// A list that activities are dropped into to be requested or vetoed.
class PreferenceDropZone extends StatelessWidget {
  const PreferenceDropZone({
    super.key,
    required this.title,
    required this.color,
    required this.activities,
    required this.remaining,
    required this.onDrop,
    required this.onDragStarted,
    required this.onActivityTap,
    this.highlightRemaining = false,
  });

  final String title;

  /// The tint of the zone.
  final Color color;
  final List<Activity> activities;
  final int remaining;

  /// Colors the "remaining" label like a skills rec instead of like the zone.
  final bool highlightRemaining;

  final void Function(Activity activity) onDrop;
  final void Function(Activity activity) onDragStarted;
  final void Function(Activity activity) onActivityTap;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Activity>(
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidates, rejected) => TitledContainer(
        title: title,
        baseTint: color,
        padding: EdgeInsets.zero,
        trailing: Text(
          '$remaining remaining',
          style: BessTextStyles.standard.copyWith(color: highlightRemaining ? BessColors.yellow : color),
        ),
        child: activities.isEmpty
            ? _EmptyHint(color: color)
            : WidgetList<Activity>(
                items: activities,
                itemBuilder: (context, activity) => DraggableActivity(
                  activity: activity,
                  padding: const EdgeInsets.only(left: 32, right: 32, top: 16),
                  onDragStarted: () => onDragStarted(activity),
                  onTap: () => onActivityTap(activity),
                ),
              ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.replace, color: color),
          const SizedBox(height: 16),
          Text('Drag And Drop Here', style: BessTextStyles.standard.copyWith(color: color)),
        ],
      ),
    );
  }
}
