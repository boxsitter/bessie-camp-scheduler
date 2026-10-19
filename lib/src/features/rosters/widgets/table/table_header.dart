import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../shared/constants/colors.dart';
import '../../../../shared/styles/text_styles.dart';
import '../../../../shared/utils/helpers/helper_functions.dart';
import '../../../../shared/widgets/buttons/checkbox.dart';
import '../../../../shared/widgets/buttons/icon_button.dart';

/// The title bar of a roster table or of one group of campers.
class BessTableHeader extends StatelessWidget {
  const BessTableHeader({
    super.key,
    required this.heading,
    required this.count,
    required this.onToggle,
    required this.onToggleExpanded,
    required this.isExpanded,
    this.isSelected,
    this.isSingle = true,
  });

  final String heading;
  final int count;
  final VoidCallback onToggle;
  final VoidCallback onToggleExpanded;
  final bool isExpanded;

  /// True when every camper is selected, null when some are.
  final bool? isSelected;

  /// Whether this is the only table (nothing to collapse).
  final bool isSingle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected == true && !isExpanded ? BessHelperFunctions.blendColors(BessColors.core, BessColors.primary, 30) : BessColors.core,
      ),
      child: Row(
        children: [
          BessCheckbox(value: isSelected, tristate: true, onPressed: onToggle),
          const SizedBox(width: 32),
          Flexible(
            child: Text(
              heading,
              style: BessTextStyles.tableHeader.copyWith(leadingDistribution: TextLeadingDistribution.even),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          if (count > 0) ...[
            const Icon(LucideIcons.usersRound),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: BessTextStyles.tableHeaderSecondary.copyWith(leadingDistribution: TextLeadingDistribution.even),
              maxLines: 1,
            ),
          ],
          const SizedBox(width: 16),
          if (!isSingle)
            BessIconButton(
              iconData: isExpanded ? LucideIcons.chevronsDownUp : LucideIcons.chevronsUpDown,
              onPressed: onToggleExpanded,
              size: 47,
            ),
        ],
      ),
    );
  }
}
