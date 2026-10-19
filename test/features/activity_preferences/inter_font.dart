import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the app's Inter font, so text is measured like it is on screen
/// (tests otherwise draw every glyph as a full-size square and overflow).
Future<void> loadInterFont() async {
  final loader = FontLoader('Inter');
  for (final file in ['Inter_18pt-Light.ttf', 'Inter_18pt-Regular.ttf']) {
    loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/inter/$file').readAsBytesSync())));
  }
  await loader.load();
}
