// import 'package:bessie/src/shared/widgets/buttons/action_initiator.dart';
// import 'package:bessie/src/shared/widgets/buttons/card_button.dart';
// import 'package:bessie/src/shared/widgets/misc/card_selector.dart';
// import 'package:bessie/src/shared/widgets/switches/icon_switch.dart';
// import 'package:bessie/src/features/activity_preferences/controllers/activity_preferences_controller_absolute.dart';
// import 'package:bessie/src/features/activity_preferences/widgets/activity_reorderable_grid.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
//
// import '../../../common/constants/colors.dart';
// import '../../../common/constants/sizes.dart';
// import '../../../common/styles/text_styles.dart';
// import '../../../common/widgets/header/menu_bar.dart';
// import '../../../common/widgets/layouts/templates/site_layout.dart';
// import '../../../common/widgets/wrappers/tint.dart';
// import '../widgets/activity_reorderable_list.dart';
//
// class ActivityPreferencesSelectorRanking extends StatelessWidget {
//   const ActivityPreferencesSelectorRanking({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return BessSiteTemplate(
//       desktop: ActivityPreferencesSelectorDesktop(),
//       menuBar: BessMenuBar(),
//     );
//   }
// }
//
// class ActivityPreferencesSelectorDesktop extends StatelessWidget {
//   const ActivityPreferencesSelectorDesktop({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<ActivityPreferencesController>(builder: (controller) {
//       if (!controller.isCamperDataLoaded) {
//         return const Center(child: CircularProgressIndicator());
//       }
//
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.max,
//         children: [
//           Text(
//             'Ranking activities for ${controller.selectedCamper?.name}',
//             style: BessTextStyles.lightTitle,
//             overflow: TextOverflow.clip,
//             maxLines: 1,
//           ),
//           const SizedBox(height: BessSizes.spaceBtwItems),
//           CardSelector(
//             cardHeight: 60,
//             cardWidth: 140,
//             maxLines: 2,
//             items: controller.campers,
//             completedItems: controller.camperIsCompleted,
//             selectedItem: controller.selectedCamper,
//             onSelectItem: controller.selectCamper,
//             isHorizontal: true,
//           ),
//           const SizedBox(height: BessSizes.spaceBtwItems),
//           Expanded(
//             child: controller.showingSkillsRecs
//                 ? ActivityReorderableList(
//                     title: 'Skills Recs',
//                     orderedItemIds: controller.orderedSkillsActivityIds,
//                     displayInfo: controller.showActivityInfo,
//                     itemIdsToNames: controller.skillsActivityNames,
//                     onReorder: controller.onReorderSkillsActivities,
//                   )
//                 : ActivityReorderableList(
//                     title: 'Choice Activities',
//                     orderedItemIds: controller.orderedStandardActivityIds,
//                     displayInfo: controller.showActivityInfo,
//                     itemIdsToNames: controller.standardActivityNames,
//                     onReorder: controller.onReorderStandardActivities,
//                   ),
//           ),
//           const SizedBox(height: BessSizes.spaceBtwItems),
//           Row(
//             children: [
//               Flexible(
//                 flex: 3,
//                 child: ActionInitiator(
//                   awaiting: controller.saveInProgress,
//                   onPressed: controller.saveActivityRanking,
//                   enabledText: 'Save Ranking',
//                   awaitingText: 'Saving...',
//                   height: 50,
//                 ),
//               ),
//               const SizedBox(width: 64),
//               Flexible(
//                 flex: 4,
//                 child: CardButton(
//                   backgroundColor: BessColors.core,
//                   onPressed: () => controller.setShowingSkillsRecs(false),
//                   tintStates: [(controller.showingSkillsRecs == false, BessColors.peach)],
//                   child: Center(
//                     child: Builder(
//                       builder: (BuildContext context) {
//                         return Text(
//                           'Choice Activities',
//                           style: BessTextStyles.standard.copyWith(
//                             color: Tint.of(context)?.foregroundColor,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.clip,
//                         );
//                       },
//                     ),
//                   ),
//                   height: 50,
//                 ),
//               ),
//               const SizedBox(width: BessSizes.spaceBtwItems),
//               Flexible(
//                 flex: 4,
//                 child: CardButton(
//                   backgroundColor: BessColors.core,
//                   onPressed: () => controller.setShowingSkillsRecs(true),
//                   tintStates: [(controller.showingSkillsRecs == true, BessColors.peach)],
//                   child: Center(
//                     child: Builder(
//                       builder: (BuildContext context) {
//                         return Text(
//                           'Skills Recs',
//                           style: BessTextStyles.standard.copyWith(
//                             color: Tint.of(context)?.foregroundColor,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.clip,
//                         );
//                       },
//                     ),
//                   ),
//                   height: 50,
//                 ),
//               ),
//               // BessIconSwitch(iconOne: LucideIcons.volleyball100, iconTwo: LucideIcons.graduationCap, value: controller.showingSkillsRecs, onToggle: controller.toggleShowingSkillsRecs),
//             ],
//           ),
//         ],
//       );
//     });
//   }
// }
