import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/sizes.dart';
import '../../../shared/styles/text_styles.dart';
import '../../../shared/utils/helpers/helper_functions.dart';

class BessSearchbar extends StatelessWidget {
  const BessSearchbar({super.key, required this.onSearchChange, required this.noMatches, this.controller});

  final void Function(String query) onSearchChange;

  /// Tints the bar red to say that the search found nobody.
  final bool noMatches;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final accent = noMatches ? BessColors.red : BessColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        width: 230,
        child: TextField(
          controller: controller,
          onChanged: onSearchChange,
          style: BessTextStyles.label.copyWith(color: BessColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search name...',
            hintStyle: BessTextStyles.label,
            prefixIcon: Icon(Icons.search, size: 18, color: accent),
            contentPadding: const EdgeInsets.symmetric(horizontal: BessSizes.sm),
            filled: true,
            fillColor: noMatches ? BessHelperFunctions.blendColors(BessColors.core, BessColors.red, 30) : BessColors.crust,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(90), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(90), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(90),
              borderSide: BorderSide(color: noMatches ? BessColors.red : BessColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}
