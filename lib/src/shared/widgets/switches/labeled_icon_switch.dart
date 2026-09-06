import 'package:bessie/src/shared/constants/animation_curves.dart';
import 'package:bessie/src/shared/constants/durations.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// A custom icon switch widget with a sliding circle animation.
///
/// This widget is stateless and its state is managed by the parent widget.
class BessIconSwitch extends StatelessWidget {
  const BessIconSwitch({
    super.key,
    required this.width,
    required this.iconOne,
    required this.iconTwo,
    required this.colorOne,
    required this.colorTwo,
    required this.labelOne,
    required this.labelTwo,
    required this.value,
    required this.onToggle,
  });

  final double width;

  /// The icon to display on the "un-toggled" (left) side.
  final IconData iconOne;

  /// The icon to display on the "toggled" (right) side.
  final IconData iconTwo;

  final Color colorOne;
  final Color colorTwo;

  /// The label to display on the "un-toggled" (right) side.
  final String labelOne;

  /// The label to display on the "toggled" (left) side.
  final String labelTwo;

  /// The current state of the switch. `false` for left, `true` for right.
  final bool value;

  /// A callback function that is invoked when the switch is tapped.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    // Define the dimensions of the switch and its components
    const double height = 36;
    const double iconContainerSize = height;
    const double iconSize = 22;
    // This is the width of the space dedicated to the label.
    final double labelSpaceWidth = width - iconContainerSize;

    // Define text styles for the two states for better contrast
    final offStyle = TextStyle(color: BessColors.textInverted, fontWeight: FontWeight.bold);
    final onStyle = TextStyle(color: BessColors.textInverted, fontWeight: FontWeight.bold);

    // The circular knob that contains the fading icons
    final Widget slidingIconKnob = Container(
      width: iconContainerSize,
      height: iconContainerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedOpacity(
            duration: BessDurations.animShort,
            curve: BessAnimationCurves.easeOut,
            opacity: value ? 0.0 : 1.0,
            child: Icon(iconOne, color: BessColors.textInverted, size: iconSize),
          ),
          AnimatedOpacity(
            duration: BessDurations.animShort,
            curve: BessAnimationCurves.easeOut,
            opacity: value ? 1.0 : 0.0,
            child: Icon(iconTwo, color: BessColors.textInverted, size: iconSize),
          ),
        ],
      ),
    );

    // The single Row that contains all the sliding elements, as you suggested.
    final Widget slidingRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Container for Label 2
        SizedBox(
          width: labelSpaceWidth,
          child: Center(
            child: Text(labelTwo, style: onStyle, overflow: TextOverflow.clip),
          ),
        ),

        // Icon Knob
        slidingIconKnob,

        // Container for Label 1
        SizedBox(
          width: labelSpaceWidth,
          child: Center(
            child: Text(labelOne, style: offStyle, overflow: TextOverflow.clip),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        // The main container, which animates its color
        child: AnimatedContainer(
          duration: BessDurations.animShort,
          curve: BessAnimationCurves.easeOut,
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: value ? colorTwo : colorOne,
          ),
          // ClipRRect provides the masking effect for the sliding row
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height / 2),
            child: Stack(
              children: [
                // Animate the position of the entire Row
                AnimatedPositioned(
                  duration: BessDurations.animShort,
                  curve: BessAnimationCurves.easeOut,
                  // When ON, left is 0.
                  // When OFF, the row is shifted left by the width of the label space,
                  // hiding labelTwo and bringing the icon to the start of the frame.
                  left: value ? 0 : -labelSpaceWidth,
                  top: 0,
                  bottom: 0,
                  child: slidingRow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
