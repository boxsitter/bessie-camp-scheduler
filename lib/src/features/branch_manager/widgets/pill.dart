import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/styles/text_styles.dart';

enum PillTone { neutral, info, success, warning, danger }

/// A small rounded label such as "Skills rec" or "12 campers".
class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.tone = PillTone.neutral, this.tooltip});

  final String label;
  final PillTone tone;
  final String? tooltip;

  Color get _color => switch (tone) {
    PillTone.neutral => BessColors.middle,
    PillTone.info => BessColors.primary,
    PillTone.success => BessColors.success,
    PillTone.warning => BessColors.warning,
    PillTone.danger => BessColors.error,
  };

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color.withValues(alpha: 0.6)),
      ),
      child: Text(label, style: BessTextStyles.label.copyWith(color: BessColors.textPrimary, fontWeight: FontWeight.w500), maxLines: 1),
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}
