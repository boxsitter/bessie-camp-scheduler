import 'dart:io';

import 'package:bessie/src/features/branch_manager/widgets/form_widgets.dart';
import 'package:bessie/src/shared/theme/shad_theme.dart';
import 'package:bessie/src/shared/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Loads the app's font so text is measured as it is on screen; the test
/// default (Ahem) is much wider and would report overflows that never happen.
Future<void> loadAppFonts() async {
  final loader = FontLoader('Inter');
  for (final file in ['Inter_18pt-Light', 'Inter_18pt-Regular', 'Inter_28pt-Medium', 'Inter_24pt-SemiBold']) {
    final bytes = File('assets/fonts/inter/$file.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Pumps [child] inside the same app shell the real app uses (Shad theme over
/// a GetMaterialApp), on a desktop sized window.
Future<void> pumpApp(WidgetTester tester, Widget child, {Size size = const Size(1280, 1000)}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ShadApp.custom(
      themeMode: ThemeMode.light,
      theme: BessShadTheme.shadThemeData,
      appBuilder: (context) => GetMaterialApp(
        theme: BessieAppTheme.theme,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ShadSonner(child: child!),
        home: Scaffold(body: Padding(padding: const EdgeInsets.all(24), child: child)),
      ),
    ),
  );
  await tester.pump();
}

/// A dialog that is open on screen; [result] completes when it closes.
class OpenDialog<T> {
  const OpenDialog(this.result);

  final Future<T?> result;
}

/// Opens [dialog] the way the app does, and waits for it to appear.
Future<OpenDialog<T>> openDialog<T>(WidgetTester tester, Widget dialog) async {
  final result = showFormDialog<T>(dialog);
  await tester.pumpAndSettle();
  return OpenDialog(result);
}
