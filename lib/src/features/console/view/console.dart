import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xterm/ui.dart';

import '../../../shared/widgets/header/menu_bar.dart';
import '../../../shared/widgets/layouts/templates/site_layout.dart';
import '../controller/console_controller.dart';
import 'themes/console_theme.dart';

class ConsoleScreen extends StatelessWidget {
  const ConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BessSiteTemplate(desktop: _ConsoleTerminal(), menuBar: BessMenuBar());
  }
}

class _ConsoleTerminal extends StatelessWidget {
  const _ConsoleTerminal();

  @override
  Widget build(BuildContext context) {
    final console = Get.find<ConsoleController>();
    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        child: TerminalView(
          console.terminal,
          autofocus: true,
          textStyle: const TerminalStyle(fontFamily: 'FiraCodeMono', fontSize: 15, height: 1.5),
          theme: BessConsoleThemes.defaultBessTheme,
        ),
      ),
    );
  }
}
