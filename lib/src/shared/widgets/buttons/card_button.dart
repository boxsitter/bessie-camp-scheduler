import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../containers/rounded_container.dart';
import '../wrappers/tint.dart';

/// A flexible, interactive card component that darkens on hover and provides
/// visual feedback on press.
class CardButton extends StatefulWidget {
  const CardButton({
    super.key,
    required this.child,
    this.onPressed,
    this.enabled = true,
    this.height,
    this.width,
    this.backgroundColor,
    this.borderColor,
    this.borderThickness = 2,
    this.radius,
    this.padding,
    this.showBorder = true,
    this.baseTint,
    this.tintConditions,
    this.clipContent = false,
    this.showShadow = false,
    this.disabledBackgroundColor,
  });

  /// The content displayed inside the card.
  final Widget child;

  /// The callback that is executed when the card is tapped.
  final VoidCallback? onPressed;

  /// Whether the card is interactive. If false, a disabled overlay is shown.
  final bool enabled;

  /// The height of the card.
  final double? height;

  /// The width of the card.
  final double? width;

  /// The background color of the card.
  final Color? backgroundColor;

  /// The border color of the card.
  final Color? borderColor;

  /// The thickness of the border.
  final double borderThickness;

  /// The corner radius of the card.
  final double? radius;

  /// The padding inside the card.
  final EdgeInsets? padding;

  /// Whether to display the border.
  final bool showBorder;

  /// The default tint to apply when no other state is active.
  final Color? baseTint;

  /// An ordered list of custom states and their corresponding tints.
  /// The first state in the list where `isActive` is true will be used.
  final List<TintCondition>? tintConditions;

  /// Whether to clip the content to the card's rounded corners.
  final bool clipContent;

  final bool showShadow;

  final Color? disabledBackgroundColor;

  @override
  State<CardButton> createState() => _CardButtonState();
}

class _CardButtonState extends State<CardButton> {
  bool _isHovering = false;
  bool _isPressed = false;
  Timer? _pressReleaseTimer;

  @override
  void dispose() {
    _pressReleaseTimer?.cancel();
    super.dispose();
  }

  void _onPressDown(_) {
    _pressReleaseTimer?.cancel();
    setState(() => _isPressed = true);
  }

  void _onPressUp(_) {
    _pressReleaseTimer = Timer(const Duration(milliseconds: 30), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  void _onPressCancel() {
    _pressReleaseTimer = Timer(const Duration(milliseconds: 30), () {
      if (mounted) setState(() => _isPressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.enabled == false) {
      // Render the disabled state
      return BessRoundedContainer(
        height: widget.height,
        width: widget.width,
        borderThickness: widget.borderThickness,
        padding: widget.padding,
        radius: widget.radius,
        showBorder: widget.showBorder,
        borderColor: widget.disabledBackgroundColor ?? BessColors.overlay1,
        clipContent: false,
        child: widget.child,
        backgroundColor: widget.disabledBackgroundColor ?? BessColors.overlay1,
      );
    }

    // The card darkens only on hover, and not when being actively pressed.
    final bool finalDarken = _isHovering && !_isPressed;

    // Render the enabled, interactive state
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _onPressDown,
      onTapUp: _onPressUp,
      onTapCancel: _onPressCancel,
      behavior: HitTestBehavior.translucent,
      dragStartBehavior: DragStartBehavior.down,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: BessRoundedContainer(
          height: widget.height,
          width: widget.width,
          borderThickness: widget.borderThickness,
          padding: widget.padding,
          radius: widget.radius,
          showBorder: widget.showBorder,
          clipContent: widget.clipContent,
          backgroundColor: widget.backgroundColor,
          borderColor: widget.borderColor,
          // Pass the final, resolved values to the container.
          tintConditions: [
            // 1. Spread all the existing conditions into the new list
            ...?widget.tintConditions,

            // 2. Conditionally add the new item if baseTint is not null
            if (widget.baseTint != null) (true, widget.baseTint),
          ],
          darken: finalDarken,
          child: widget.child,
          showShadow: widget.showShadow,
          margin: EdgeInsets.zero,
        ),
      ),
    );
  }
}