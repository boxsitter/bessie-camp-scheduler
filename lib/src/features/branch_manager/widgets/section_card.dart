import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';

/// A titled, bordered block of a setup page.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, this.subtitle, this.trailing, required this.child});

  final String title;
  final String? subtitle;

  /// Shown at the end of the header, e.g. a button.
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(BessSizes.bg),
      decoration: BoxDecoration(
        color: BessColors.core,
        borderRadius: BorderRadius.circular(BessSizes.cardRadiusLg),
        border: Border.all(color: BessColors.borderPrimary, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: BessTextStyles.tableHeaderSecondary),
                    if (subtitle != null) ...[
                      const SizedBox(height: BessSizes.xs),
                      Text(subtitle!, style: BessTextStyles.standardSecondary),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: BessSizes.md), trailing!],
            ],
          ),
          const SizedBox(height: BessSizes.md),
          child,
        ],
      ),
    );
  }
}
