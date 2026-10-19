import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../shared/styles/text_styles.dart';

/// A whole number adjusted with minus and plus buttons.
class NumberStepper extends StatelessWidget {
  const NumberStepper({super.key, required this.value, required this.onChanged, this.min = 0, this.max = 99});

  final int value;
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShadIconButton.secondary(
          width: 32,
          height: 32,
          icon: const Icon(LucideIcons.minus, size: 14),
          onPressed: onChanged == null || value <= min ? null : () => onChanged(value - 1),
        ),
        SizedBox(width: 40, child: Text('$value', textAlign: TextAlign.center, style: BessTextStyles.standardBold)),
        ShadIconButton.secondary(
          width: 32,
          height: 32,
          icon: const Icon(LucideIcons.plus, size: 14),
          onPressed: onChanged == null || value >= max ? null : () => onChanged(value + 1),
        ),
      ],
    );
  }
}
