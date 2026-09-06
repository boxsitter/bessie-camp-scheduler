import 'package:bessie/src/shared/styles/text_styles.dart';
import 'package:bessie/src/ember_core.dart';
import 'package:flutter/material.dart';

// Assuming card_button.dart is in a path accessible from this file.
// Based on your project structure, you might need to adjust the import path.
import '../../constants/colors.dart';
import '../buttons/card_button.dart';

/// A widget that displays a row of tabs that can wrap to a new line.
///
/// It creates a horizontal row of [CardButton] widgets to represent tabs.
/// If the available width is too small, it will wrap to a new line.
class TabSwitcher<T extends Titled> extends StatelessWidget {
  /// The list of items to display as tabs.
  final List<T> items;

  /// The currently selected item. Can be null.
  final T? selectedItem;

  /// A callback that is invoked when a tab is tapped.
  final ValueChanged<T> onItemSelected;

  /// The text style for the selected tab.
  final TextStyle? selectedTextStyle;

  /// The text style for unselected tabs.
  final TextStyle? unselectedTextStyle;

  const TabSwitcher({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onItemSelected,
    this.selectedTextStyle,
    this.unselectedTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12.0, // Horizontal space between tabs.
      runSpacing: 4.0, // Vertical space between rows of tabs.
      alignment: WrapAlignment.start,
      children: items.map((item) {
        final isSelected = selectedItem == item;

        return CardButton(
          onPressed: () => onItemSelected(item),
          tintConditions: [(isSelected, BessColors.primary)],
          backgroundColor: BessColors.background,
          showBorder: false,
          showShadow: false,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
          child: Text(
            item.title,
            textAlign: TextAlign.center,
            style: BessTextStyles.standard,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
    );
  }
}
