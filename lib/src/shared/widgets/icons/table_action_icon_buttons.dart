import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/colors.dart';

/// Widget for displaying action buttons for table rows
class TTableActionButtons extends StatelessWidget {
  const TTableActionButtons({
    super.key,
    this.view = false,
    this.edit = true,
    this.delete = true,
    this.onViewPressed,
    this.onEditPressed,
    this.onDeletePressed,
  });

  /// Flag to determine whether the view button is enabled
  final bool view;

  /// Flag to determine whether the edit button is enabled
  final bool edit;

  /// Flag to determine whether the delete button is enabled
  final bool delete;

  /// Callback function for when the view button is pressed
  final VoidCallback? onViewPressed;

  /// Callback function for when the edit button is pressed
  final VoidCallback? onEditPressed;

  /// Callback function for when the delete button is pressed
  final VoidCallback? onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (view)
          IconButton(
            onPressed: onViewPressed,
            icon: Icon(LucideIcons.eye, color: BessColors.semiHigh),
          ),
        if (edit)
          IconButton(
            onPressed: onEditPressed,
            icon: Icon(LucideIcons.pencil, color: BessColors.primary),
          ),
        if (delete)
          IconButton(
            onPressed: onDeletePressed,
            icon: Icon(LucideIcons.trash2, color: BessColors.error),
          ),
      ],
    );
  }
}
