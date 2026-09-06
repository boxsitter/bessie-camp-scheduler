// import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
// import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_absolute.dart';
// import 'package:bessie/src/ember_core.dart';
// import 'package:flutter/material.dart';
//
// import '../../../common/constants/colors.dart';
// import '../../../common/constants/sizes.dart';
// import '../../../common/styles/text_styles.dart';
// import '../../../common/widgets/buttons/card_button.dart';
//
// class ActivityPreferencesCabinsAbsolute extends StatelessWidget {
//   const ActivityPreferencesCabinsAbsolute({
//     super.key,
//     required this.controller,
//   });
//
//   final ActivityPreferencesControllerAbsolute controller;
//
//   @override
//   Widget build(BuildContext context) {
//     if (controller.isCabinCamperDataLoaded == false) {
//       return BessCircularLoader();
//     }
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
//         Text(
//           'Cabins',
//           style: BessTextStyles.lightTitle,
//           overflow: TextOverflow.clip,
//           maxLines: 1,
//         ),
//         const SizedBox(height: BessSizes.spaceBtwSections),
//         Expanded(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.only(right: 24),
//             child: Wrap(
//               spacing: 24,
//               runSpacing: 24,
//               children: controller.cabinCamperData.map((cabinRecord) {
//                 final name = cabinRecord.$1.$2.displayTitle;
//                 final count = cabinRecord.$1.$1.camperRefs.length;
//                 final preferencesCount = cabinRecord.$2.$2;
//                 final bool isCompleted = preferencesCount >= count;
//                 final bool isInProgress = preferencesCount > 0 && preferencesCount < count;
//
//                 return CardButton(
//                   // tintConditions: [(isInProgress, BessColors.yellow), (isCompleted, BessColors.green)],
//                   height: 90,
//                   width: 250,
//                   onPressed: () => controller.setSelectedCabinData(cabinRecord),
//                   padding: const EdgeInsets.all(16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text(
//                         name,
//                         style: BessTextStyles.boldCardTitle,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         //'$preferencesCount/$count campers completed',
//                         '',
//                         style: BessTextStyles.largerLabel,
//                       ),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         )
//       ]),
//     );
//   }
// }
