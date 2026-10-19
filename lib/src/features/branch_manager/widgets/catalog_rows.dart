import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';

/// The heading of a group of rows ("Creative", "Pines") with a muted detail.
class GroupHeading extends StatelessWidget {
  const GroupHeading({super.key, required this.label, this.detail});

  final String label;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: BessSizes.md, bottom: BessSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(child: Text(label.toUpperCase(), style: BessTextStyles.columnHeader, overflow: TextOverflow.ellipsis)),
          if (detail != null) ...[const SizedBox(width: BessSizes.sm), Text(detail!, style: BessTextStyles.subtle)],
        ],
      ),
    );
  }
}

/// One row of a catalog list: [content] and, at the end, [actions].
class CatalogRow extends StatelessWidget {
  const CatalogRow({super.key, required this.content, this.actions = const []});

  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: BessSizes.sm),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: BessColors.borderPrimary))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: content),
          for (final action in actions) ...[const SizedBox(width: BessSizes.xs), action],
        ],
      ),
    );
  }
}

/// A small icon button with a tooltip, for the end of a [CatalogRow].
class RowIconButton extends StatelessWidget {
  const RowIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.color});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: ShadIconButton.ghost(
        width: 32,
        height: 32,
        foregroundColor: color,
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
      ),
    );
  }
}
