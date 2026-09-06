import 'package:bessie/src/shared/constants/sizes.dart';
import 'package:flutter/material.dart';

import '../../shared/styles/text_styles.dart';
import '../../shared/widgets/header/menu_bar.dart';
import '../../shared/widgets/layouts/templates/site_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key = const ValueKey('HomeScreen')});

  @override
  Widget build(BuildContext context) {
    return const BessSiteTemplate(desktop: HomeScreenDesktop(), menuBar: BessMenuBar(),);
  }
}

class HomeScreenDesktop extends StatelessWidget {
  const HomeScreenDesktop({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
   return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome To Bessie!',
                style: BessTextStyles.lightTitle,
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),

              const SizedBox(height: BessSizes.spaceBtwItems),

              Text(
                'Nothing much to see here right now',
                style: BessTextStyles.standard,
                overflow: TextOverflow.clip,
                maxLines: 1,
              ),
            ],
          );
  }
}

// class HomeScreenMobile extends StatelessWidget {
//   const HomeScreenMobile({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return
//   }
//
// }