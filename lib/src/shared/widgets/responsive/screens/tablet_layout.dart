import 'package:bessie/src/shared/widgets/header/header.dart';
import 'package:flutter/material.dart';

import '../../../constants/sizes.dart';
import '../../header/menu_bar.dart';
import '../../layouts/sidebars/sidebar.dart';

class TabletLayout extends StatelessWidget {
  TabletLayout({super.key, this.body, required this.menuBar, this.usePadding = true});

  final Widget? body;
  final bool usePadding;
  final BessMenuBar menuBar;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: scaffoldKey,
        drawer: const BessSidebar(),
        appBar: BessHeader(menuBar: menuBar, scaffoldKey: scaffoldKey),
        body: Padding(
          padding: usePadding ? const EdgeInsets.all(BessSizes.lg) : EdgeInsetsGeometry.zero,
          child: body ?? const SizedBox(),
        ));
  }
}
