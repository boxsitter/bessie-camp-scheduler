// import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_absolute.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../pages/activity_preferences/controllers/activity_preferences_controller_diplomatic.dart';
// import '../../../pages/activity_preferences/views/activity_preferences_selector_diplomatic.dart';
// import '../../../pages/activity_preferences/widgets/activity_card.dart';
// import '../../styles/custom_scroll_physics.dart';
//
// // --- Constants ---
// const double _kCollapsedHeight = 76.0;
// const double _kExpandedHeight = 240.0; // New height for the expanded card
// const double _kMinVerticalMargin = 4.0;
// const double _kMaxVerticalMargin = 64.0;
// const double _kAlignment = 0.1; // 0.0 for top, 0.5 for center, 1.0 for bottom
// const double _kHorizontalMargin = 32.0;
//
// double get _slotHeight => _kCollapsedHeight + (_kMinVerticalMargin * 2);
//
// class Cardousel extends StatelessWidget {
//   const Cardousel({
//     super.key,
//     required this.controller,
//     required this.collapsedCardBuilder,
//     required this.expandedCardBuilder,
//     required this.itemCount,
//   });
//
//   final ActivityPreferencesControllerDiplomatic controller;
//   final Widget Function(int index) collapsedCardBuilder;
//   final Widget Function(int index) expandedCardBuilder;
//   final int itemCount;
//
//   @override
//   Widget build(BuildContext context) {
//     final viewportSize = MediaQuery.of(context).size;
//
//     // Calculate the total height of the card when it is fully expanded and focused.
//     final focusedCardHeight = _kExpandedHeight + (_kMaxVerticalMargin * 2);
//
//     // Calculate the total vertical space available for padding.
//     final totalVerticalSpace =
//         (viewportSize.height - focusedCardHeight).clamp(0.0, double.infinity);
//
//     // Calculate top and bottom padding based on the alignment constant.
//     final topPadding = totalVerticalSpace * _kAlignment;
//     final bottomPadding = totalVerticalSpace * (1 - _kAlignment);
//
//     return NotificationListener<ScrollEndNotification>(
//       onNotification: (notification) {
//         final closestIndex = (notification.metrics.pixels / _slotHeight).round().clamp(0, itemCount - 1);
//         if (controller.focusedActivityIndex.value != closestIndex) {
//           controller.onPageChanged(closestIndex);
//         }
//         return true;
//       },
//       child: ListView.builder(
//         controller: controller.scrollController,
//         physics: CustomScrollPhysics(itemHeight: _slotHeight),
//         itemCount: itemCount,
//         padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
//         itemBuilder: (context, index) {
//           return ActivityCard(
//             controller: controller,
//             index: index,
//             collapsedCard: collapsedCardBuilder(index),
//             expandedCard: expandedCardBuilder(index),
//             collapsedHeight: _kCollapsedHeight,
//             expandedHeight: _kExpandedHeight,
//             minVerticalMargin: _kMinVerticalMargin,
//             maxVerticalMargin: _kMaxVerticalMargin,
//             horizontalMargin: _kHorizontalMargin,
//           );
//         },
//       ),
//     );
//   }
// }
