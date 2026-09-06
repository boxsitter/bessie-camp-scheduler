// import 'package:bessie/src/shared/styles/text_styles.dart';
// import 'package:bessie/src/shared/utils/helpers/helper_functions.dart';
// import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
// import 'package:bessie/src/shared/widgets/containers/rounded_container.dart';
// import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
// import 'package:bessie/src/shared/widgets/misc/cardousel.dart';
// import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_absolute.dart';
// import 'package:flutter/material.dart';
//
// import '../../../common/constants/colors.dart';
// import '../../../common/constants/sizes.dart';
//
// class ActivityPreferencesSelectorAbsolute extends StatelessWidget {
//   const ActivityPreferencesSelectorAbsolute({super.key, required this.controller});
//
//   final ActivityPreferencesControllerAbsolute controller;
//
//   @override
//   Widget build(BuildContext context) {
//     if (controller.isActivityDataLoaded == false) return BessCircularLoader();
//
//     return Cardousel(
//       controller: controller,
//       itemCount: controller.principalActivities.length,
//       expandedCardBuilder: (index) {
//         final int? currentPref = controller.principalActivities[index].$2;
//         return BessRoundedContainer(
//           padding: EdgeInsets.all(8.0),
//           strokeAlign: 1.0,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Expanded(child: Text(controller.principalActivities[index].$1.displayTitle, style: BessTextStyles.largeCardHeader, maxLines: 2)),
//                     Spacer(),
//                     if (controller.preferenceSelectionLoading)
//                       BessCircularLoader(),
//                     if (!controller.preferenceSelectionLoading)
//                       Expanded(child: Text(controller.principalActivities[index].$1.description, style: BessTextStyles.standardSecondary.copyWith(fontSize: 18), maxLines: 4, overflow: TextOverflow.ellipsis,)),
//                   ],
//                 ),
//               ),
//
//               Spacer(),
//
//               Row(
//                 children: List.generate(11, (number) {
//                   bool isSelected = controller.principalActivities[index].$2 == number;
//                   return Expanded(
//                     child: Padding(
//                       padding: const EdgeInsets.all(4.0),
//                       child: CardButton(
//                         height: 70,
//                         radius: 24,
//                         tintConditions: [(isSelected, BessColors.primary), (true, BessHelperFunctions.lerpColorList([BessColors.red, BessColors.yellow, BessColors.green], number / 10))],
//                         onPressed: () => controller.preferenceSelectionLoading ? {} : controller.setActivityPreference(index, isSelected == true ? null : number / 10),
//                         child: Center(
//                           child: Text(
//                             '${number}',
//                             style: BessTextStyles.standardBold.copyWith(fontSize: isSelected ? 24 : 18),
//                             maxLines: 1,
//                             overflow: TextOverflow.clip,
//                           ),
//                         ),
//                         showBorder: true,
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//             ],
//           ),
//           showBorder: true,
//           borderColor: BessColors.borderSecondary,
//           tintConditions: [(currentPref != null, BessColors.green)],
//         );
//       },
//       collapsedCardBuilder: (index) {
//         final int? currentPref = controller.principalActivities[index].$2;
//         return CardButton(
//           child: Column(
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(controller.principalActivities[index].$1.displayTitle, style: BessTextStyles.largeCardHeader),
//                   Text(currentPref != null ? currentPref.toString() : '', style: BessTextStyles.largeCardHeader.copyWith(leadingDistribution: TextLeadingDistribution.even)),
//                 ],
//               ),
//               Spacer(),
//             ],
//           ),
//           showBorder: true,
//           borderColor: BessColors.borderSecondary,
//           tintConditions: [(currentPref != null, BessColors.green)],
//           showShadow: true,
//           onPressed: () => controller.setFocusedActivityIndex(index),
//         );
//       }
//     );
//   }
// }
