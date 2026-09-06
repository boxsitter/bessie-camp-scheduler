//
//
// import 'package:flutter/material.dart';
//
// import '../../controller/console_controller.dart';
//
// class BessConsoleInput extends StatelessWidget {
//   const BessConsoleInput({
//     super.key,
//     required this.textFieldFocusNode,
//     required this.textEditingController,
//     required this.consoleController,
//   });
//
//   final FocusNode textFieldFocusNode;
//   final TextEditingController textEditingController;
//   final ConsoleController consoleController;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Expanded(
//           child: TextField(
//             focusNode: textFieldFocusNode,
//             controller: textEditingController,
//             style: const TextStyle(
//               fontFamily: 'Courier',
//               fontSize: 14.0,
//               color: Colors.black,
//             ),
//             cursorColor: Colors.black,
//             decoration: const InputDecoration(
//               hintText: 'Enter command',
//               hintStyle: TextStyle(color: Colors.black),
//             ),
//             onSubmitted: (value) {
//               if (value.isNotEmpty) {
//                 consoleController.executeCommand(value);
//                 textEditingController.clear();
//                 textFieldFocusNode.requestFocus();
//               }
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }