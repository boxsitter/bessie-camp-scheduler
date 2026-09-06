// import 'package:flutter/material.dart';
// import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
//
// import '../../controller/console_controller.dart';
//
// class BessConsole extends StatelessWidget {
//   const BessConsole({
//     super.key,
//     required this.consoleController,
//   });
//
//   final ConsoleController consoleController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16.0),
//       decoration: BoxDecoration(
//         color: Colors.black,
//         borderRadius: BorderRadius.circular(12.0),
//       ),
//       child: Column(
//         mainAxisSize:
//         MainAxisSize.min, // Make the column take minimum height
//         children: [
//           // Display logs in a scrollable area
//           Expanded(
//             child: Obx(() => ListView.builder(
//               reverse: false, // Retain reverse to add new logs below the current ones.
//               physics: const AlwaysScrollableScrollPhysics(),
//               itemCount: consoleController.logs.length,
//               itemBuilder: (context, index) {
//                 // Show logs in normal order
//                 final log = consoleController.logs[index];
//                 final logType = log['type'];
//                 final message = log['message'];
//                 return Align(
//                   alignment: Alignment.topLeft, // Align text to the top.
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 2.0),
//                     child: Text(
//                       message!,
//                       style: TextStyle(
//                         fontFamily: 'Courier',
//                         fontSize: 14.0,
//                         color: logType == 'user'
//                             ? Colors.greenAccent
//                             : Colors.blueAccent,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }