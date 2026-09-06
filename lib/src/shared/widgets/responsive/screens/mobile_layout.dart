import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:flutter/material.dart';

import '../../../constants/sizes.dart';

class MobileLayout extends StatelessWidget {
  MobileLayout({super.key, this.body});

  final Widget? body;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    //   return Scaffold(
    //       key: scaffoldKey,
    //       drawer: const BessSidebar(),
    //       appBar: BessHeader(scaffoldKey: scaffoldKey),
    //       body: Padding(
    //         padding: const EdgeInsets.all(BessSizes.lg),
    //         child: body ?? const SizedBox(),
    //       ));
    // }

    return Scaffold(
      key: scaffoldKey,
      body: Padding(
        padding: const EdgeInsets.all(BessSizes.lg),
        child: Center(
            child: Text(
          'Bessie is not currently functional with a mobile or compact layout. Sorry :/',
          style: BessTextStyles.lightTitle,
        )),
      ),
    );
  }
}
