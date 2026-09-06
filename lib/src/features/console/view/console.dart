import 'package:bessie/src/features/console/view/themes/console_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xterm/ui.dart';

import '../../../shared/widgets/header/menu_bar.dart';
import '../../../shared/widgets/layouts/templates/site_layout.dart';
import '../controller/console_controller.dart';

class ConsoleScreen extends StatelessWidget {
  const ConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BessSiteTemplate(desktop: ConsoleScreenDesktop(), menuBar: BessMenuBar(),);
  }
}

class ConsoleScreenDesktop extends StatelessWidget {
  ConsoleScreenDesktop({super.key});

  final ConsoleController consoleController = Get.find<ConsoleController>();
  // final TextEditingController textEditingController = TextEditingController();
  // final FocusNode textFieldFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black, // Terminal background color
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
            padding: const EdgeInsets.all(16), // Padding inside the terminal
            child: TerminalView(
              consoleController.terminal,
              autofocus: true,
              textStyle: const TerminalStyle(
                fontFamily: 'FiraCodeMono',
                fontSize: 15, // Customize font size
                height: 1.5,
              ),
              theme: BessConsoleThemes.defaultBessTheme,
            ),
          ),
        ),
      ],
    );
  }
}




