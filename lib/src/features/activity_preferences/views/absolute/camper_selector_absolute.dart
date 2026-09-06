// import 'package:bessie/src/shared/widgets/loaders/circular_loader.dart';
// import 'package:bessie/src/shared/widgets/misc/card_selector.dart';
// import 'package:bessie/src/ember_core.dart';
// import 'package:flutter/material.dart';
//
// import '../../../common/constants/sizes.dart';
// import '../../../common/styles/text_styles.dart';
// import '../../../common/widgets/wrappers/tint.dart';
//
// class CamperSelectorAbsolute extends StatelessWidget {
//   const CamperSelectorAbsolute({
//     super.key,
//     this.campers = const [],
//     this.selectedCamper,
//     this.onSelectCamper,
//     required this.isCampersLoaded,
//     this.cabinName,
//     this.totalActivities,
//     this.relevantActivityIds = const {},
//   });
//
//   final String? cabinName;
//   final List<Camper> campers;
//   final Camper? selectedCamper;
//   final void Function(Camper)? onSelectCamper;
//   final bool isCampersLoaded;
//   final int? totalActivities;
//   final Set<PrincipalActivityId> relevantActivityIds;
//
//   @override
//   Widget build(BuildContext context) {
//     if (isCampersLoaded == false) {
//       return BessCircularLoader();
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Text(
//           cabinName != null ? cabinName! : 'Campers',
//           style: BessTextStyles.boldCardTitle,
//         ),
//         Expanded(
//           child: CardSelector(
//             cardHeight: 60,
//             cardWidth: double.infinity,
//             maxLines: 2,
//             items: campers,
//             itemCompleted: (Camper camper) => camper.relevantPrefsCompleted(relevantActivityIds) == true,
//             itemInProgress: (Camper camper) => camper.relevantPrefsCompleted(relevantActivityIds) != 0,
//             selectedItem: selectedCamper,
//             onSelectItem: onSelectCamper ?? (Camper) => {},
//             isHorizontal: false,
//             childBuilder: (BuildContext context, Camper item) => Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(
//                   child: Text(
//                     '${item.displayTitle}',
//                     style: BessTextStyles.standard.copyWith(
//                       // This will now correctly find the foregroundColor provided by Tint.
//                       color: Tint.of(context)?.foregroundColor,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 Text(
//                   '${item.getRelevantCompletedCount(relevantActivityIds)}/${totalActivities == null ? 'loading...' : totalActivities}',
//                   style: BessTextStyles.standard.copyWith(
//                     // This will now correctly find the foregroundColor provided by Tint.
//                     color: Tint.of(context)?.foregroundColor,
//                   ),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
