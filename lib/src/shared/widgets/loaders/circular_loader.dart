import 'package:flutter/material.dart';

import '../../constants/colors.dart';

/// A circular loader widget with customizable foreground and background colors.
class BessCircularLoader extends StatelessWidget {
  /// Default constructor for the TCircularLoader.
  ///
  /// Parameters:
  ///   - foregroundColor: The color of the circular loader.
  ///   - backgroundColor: The background color of the circular loader.
  const BessCircularLoader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
          color: BessColors.primary,
          backgroundColor: Colors.transparent,

      ),
    );
  }
}
