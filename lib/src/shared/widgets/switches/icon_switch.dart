import 'package:bessie/src/shared/constants/animation_curves.dart';
import 'package:bessie/src/shared/constants/durations.dart';
import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// A custom icon switch widget with a sliding circle animation.
///
/// This widget is stateless and its state is managed by the parent widget.
class BessIconSwitch extends StatelessWidget {
  const BessIconSwitch({
    super.key,
    required this.iconOne,
    required this.iconTwo,
    this.colorOne,
    this.colorTwo,
    required this.value,
    required this.onToggle,
  });

  /// The icon to display on the "un-toggled" (left) side.
  final IconData iconOne;

  /// The icon to display on the "toggled" (right) side.
  final IconData iconTwo;

  final Color? colorOne;
  final Color? colorTwo;

  /// The current state of the switch. `false` for left, `true` for right.
  final bool value;

  /// A callback function that is invoked when the switch is tapped.
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final double width = 50;
    final double height = 27;
    final double iconSize = height - 9;
    final double padding = (height - iconSize) / 2;

    return CardButton(
      onPressed: onToggle,
      width: width,
      height: height,
      radius: 90,
      backgroundColor: BessColors.core,
      tintConditions: [(value, colorTwo), (!value, colorOne)],
      borderThickness: 1,
      padding: EdgeInsets.zero,
      child: AnimatedAlign(
        duration: BessDurations.animShort,
        curve: BessAnimationCurves.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: BessDurations.animShort,
                curve: BessAnimationCurves.easeOut,
                opacity: value ? 0.0 : 1.0,
                child: Icon(
                  iconOne,
                  color: value ? colorTwo : colorOne,
                  size: iconSize,
                ),
              ),
              AnimatedOpacity(
                duration: BessDurations.animShort,
                curve: BessAnimationCurves.easeOut,
                opacity: value ? 1.0 : 0.0,
                child: Icon(
                  iconTwo,
                  color: value ? colorTwo : colorOne,
                  size: iconSize,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
