import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/widgets/loaders/circular_loader.dart';

/// The body of a setup page: a heading and then [children], scrolling, with a
/// comfortable maximum width.
class SetupPage extends StatelessWidget {
  const SetupPage({super.key, required this.title, this.subtitle, this.trailing, required this.children});

  final String title;
  final String? subtitle;

  /// Shown at the end of the heading, e.g. a button.
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.only(bottom: BessSizes.spaceBtwSections),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: BessTextStyles.tableHeader),
                      if (subtitle != null) ...[const SizedBox(height: BessSizes.xs), Text(subtitle!, style: BessTextStyles.standardSecondary)],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: BessSizes.md), trailing!],
              ],
            ),
            const SizedBox(height: BessSizes.lg),
            for (final child in children) ...[child, const SizedBox(height: BessSizes.md)],
          ],
        ),
      ),
    );
  }
}

/// A centered note replacing a page's content: loading, a failure to load, or
/// nothing to show yet.
class PageMessage extends StatelessWidget {
  const PageMessage.loading({super.key}) : message = null, actionLabel = null, onAction = null;
  const PageMessage({super.key, required String this.message, this.actionLabel, this.onAction});

  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final message = this.message;
    if (message == null) return const BessCircularLoader();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: BessTextStyles.standardSecondary, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: BessSizes.md),
            ShadButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
