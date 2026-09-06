import 'dart:ui';

import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_absolute.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.controller,
    required this.index,
    required this.collapsedCard,
    required this.expandedCard,
    required this.collapsedHeight,
    required this.expandedHeight,
    required this.minVerticalMargin,
    required this.maxVerticalMargin,
    required this.horizontalMargin,
  });

  final ActivityPreferencesControllerAbsolute controller;
  final int index;
  final Widget collapsedCard;
  final Widget expandedCard;
  final double collapsedHeight;
  final double expandedHeight;
  final double minVerticalMargin;
  final double maxVerticalMargin;
  final double horizontalMargin;

  double get _slotHeight => collapsedHeight + (minVerticalMargin * 2);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller.scrollController,
      builder: (context, child) {
        double page = 0;
        if (controller.scrollController.hasClients && controller.scrollController.position.haveDimensions) {
          page = controller.scrollController.offset / _slotHeight;
        }

        final double focusValue = (1 - (page - index).abs()).clamp(0.0, 1.0);
        final double curvedFocusValue = Curves.easeInOut.transform(focusValue);
        final verticalMargin =
            lerpDouble(minVerticalMargin, maxVerticalMargin, curvedFocusValue)!;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: verticalMargin,
          ),
          child: LayoutBuilder(
          builder: (context, constraints) {
        final height = lerpDouble(collapsedHeight, expandedHeight, curvedFocusValue)!;

              return SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 1.0 - curvedFocusValue,
                child: IgnorePointer(
                  ignoring: curvedFocusValue > 0.5,
                  child: collapsedCard,
                ),
              ),
              Opacity(
                opacity: curvedFocusValue,
                child: IgnorePointer(
                  ignoring: curvedFocusValue < 0.5,
                  child: expandedCard,
                ),
              ),
            ],
          ),
        );
      },
          ),
    );
      },
    );
  }
}