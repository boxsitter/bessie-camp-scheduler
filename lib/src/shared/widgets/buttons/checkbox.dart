import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';

class BessCheckbox extends StatelessWidget {
  final bool? value;
  final bool? tristate;
  final VoidCallback? onPressed;
  final bool enabled;

  const BessCheckbox({
    super.key,
    this.value,
    this.tristate = false,
    this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    bool tinted = value == true || tristate == true && value == null;
    IconData? icon;
    if (value == null && tristate == true) {
      icon = LucideIcons.minus600;
    } else if (value == true) {
      icon = LucideIcons.check500;
    } else {
      icon = null;
    }
    return CardButton(
      width: 19.0,
      height: 19.0,
      onPressed: onPressed,
      tintConditions: [(tinted, BessColors.primary)],
      showBorder: true,
      borderThickness: 2.0,
      radius: 5.0,
      padding: EdgeInsets.zero,
      backgroundColor: tinted ? Colors.white : Colors.transparent,
      borderColor: BessColors.textPrimary,
      enabled: enabled,
      child: Center(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(value),
          tween: Tween<double>(
            begin: 0.0,
            end: value == true || value == null && tristate == true ? 1.0 : 0.0,
          ),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOutQuart,
          builder: (context, progress, child) {
            // Define the icon widget, ensuring it's always rendered if needed
            final iconWidget = icon != null
                ? Icon(
                    icon,
                    color: tinted ? BessColors.primary : BessColors.textPrimary,
                    size: 16, // Use the actual icon size
                  )
                : const SizedBox.shrink();

            // Create a fixed-size container for the icon to ensure it stays centered
            // and the clip operates consistently over its area.
            return SizedBox(
              width: 16, // Match the icon's size or the desired clip width
              height: 16, // Match the icon's size or the desired clip height
              child: ClipRect(
                // Use a RectTween to animate the clip directly, which might be more explicit
                // and avoid perceived movement from Align.widthFactor.
                child: Align(
                  // Use Align to position the child within the clipped space
                  alignment: Alignment.center, // Center the icon within its full space
                  widthFactor: 1.0, // Don't use widthFactor for clipping, use ClipRect directly
                  heightFactor: 1.0,
                  child: Opacity(
                    opacity: progress > 0.0 ? 1.0 : 0.0,
                    child: OverflowBox(
                      // Allows child to be larger than parent without breaking layout
                      alignment: Alignment.centerLeft, // This ensures the content is aligned to the left before clipping
                      maxWidth: 16, // Max width of the icon
                      maxHeight: 16, // Max height of the icon
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.centerLeft, // Start revealing from the left
                          widthFactor: progress, // Control the visible width with animation
                          child: iconWidget,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
