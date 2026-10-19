import 'package:flutter/material.dart';

import '../../../constants/sizes.dart';
import '../../../styles/text_styles.dart';

/// Bessie's pages don't fit a phone yet; say so instead of showing a broken page.
class MobileLayout extends StatelessWidget {
  const MobileLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BessSizes.lg),
      child: Center(
        child: Text('Bessie is not currently functional with a mobile or compact layout. Sorry :/', style: BessTextStyles.lightTitle),
      ),
    );
  }
}
