import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'shared/constants/text_strings.dart';
import 'shared/routes/navigation_observer.dart';
import 'shared/routes/routes.dart';
import 'shared/theme/shad_theme.dart';
import 'shared/theme/theme.dart';
import 'shared/utils/device/web_material_scroll.dart';

class BessieFlutterApp extends StatelessWidget {
  const BessieFlutterApp({super.key});

  static final BessNavigationObserver _navObserver = Get.find<BessNavigationObserver>();

  @override
  Widget build(BuildContext context) {
    return ShadApp.custom(
      themeMode: ThemeMode.light,
      theme: BessShadTheme.shadThemeData,
      appBuilder: (context) {
        return GetMaterialApp(
          title: BessTexts.appName,
          themeMode: ThemeMode.light,
          theme: BessieAppTheme.theme,
          debugShowCheckedModeBanner: false,
          scrollBehavior: MyCustomScrollBehavior(),
          initialRoute: BessRoutes.rosters,
          unknownRoute: BessRoutes.pages.last,
          navigatorObservers: [_navObserver],
          defaultTransition: Transition.noTransition,
          getPages: BessRoutes.pages,
          builder: (context, child) {
            return ShadSonner(visibleToastsAmount: 3, padding: EdgeInsets.all(42), child: child!);
          },
        );
      },
    );
  }
}
