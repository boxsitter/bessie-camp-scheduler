import 'package:flutter/material.dart';

import '../../../models/activity.dart';
import '../../../models/enums.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/buttons/card_button.dart';
import '../../../shared/widgets/containers/titled_container.dart';
import '../../../shared/widgets/misc/tab_switcher.dart';
import '../../../shared/widgets/misc/widget_grid.dart';
import 'draggable_activity.dart';

/// The activities the camper is open to ("I'd be open to trying it"), split
/// into category tabs, plus the switch between standard activities and
/// skills recs. Dropping an activity here takes it out of requests/vetoes.
class ActivityLibrary extends StatelessWidget {
  const ActivityLibrary({
    super.key,
    required this.activities,
    required this.categories,
    required this.selectedCategory,
    required this.skillsMode,
    required this.canSwitchMode,
    required this.onCategorySelected,
    required this.onModeSelected,
    required this.onDrop,
    required this.onDragStarted,
    required this.onActivityTap,
  });

  final List<Activity> activities;
  final List<ActivityCategory> categories;
  final ActivityCategory? selectedCategory;
  final bool skillsMode;
  final bool canSwitchMode;

  final void Function(ActivityCategory category) onCategorySelected;
  final void Function(bool skillsRecs) onModeSelected;
  final void Function(Activity activity) onDrop;
  final void Function(Activity activity) onDragStarted;
  final void Function(Activity activity) onActivityTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DragTarget<Activity>(
            onAcceptWithDetails: (details) => onDrop(details.data),
            builder: (context, candidates, rejected) => TitledContainer(
              title: 'Activity Library (I\'d Be Open To Trying It)',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!skillsMode && categories.length > 1) ...[
                      SizedBox(
                        width: double.infinity,
                        child: TabSwitcher<ActivityCategory>(
                          items: categories,
                          selectedItem: selectedCategory,
                          onItemSelected: onCategorySelected,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: activities.isEmpty
                            ? Center(child: Text('Nothing left to pick here.', style: BessTextStyles.largerLabel))
                            : WidgetGrid<Activity>(
                                items: activities,
                                runSpacing: 4,
                                spacing: 2,
                                itemBuilder: (context, activity) => DraggableActivity(
                                  activity: activity,
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  onDragStarted: () => onDragStarted(activity),
                                  onTap: () => onActivityTap(activity),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (canSwitchMode) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: 'Standard Activities',
                  tint: BessColors.primary,
                  selected: !skillsMode,
                  onPressed: () => onModeSelected(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ModeButton(
                  label: 'Skills Recs',
                  tint: BessColors.yellow,
                  selected: skillsMode,
                  onPressed: () => onModeSelected(true),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.tint, required this.selected, required this.onPressed});

  final String label;
  final Color tint;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CardButton(
      tintConditions: [(selected, tint)],
      onPressed: onPressed,
      child: Center(child: Text(label, style: BessTextStyles.standard)),
    );
  }
}
