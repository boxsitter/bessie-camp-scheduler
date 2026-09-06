import 'package:flutter/material.dart';

import '../../constants/colors.dart';
import '../../constants/sizes.dart';
import '../buttons/card_button.dart';

class CardSelector<T> extends StatelessWidget {
  const CardSelector({
    super.key,
    required this.items,
    required this.onSelectItem,
    this.cardHeight,
    this.cardWidth,
    this.maxLines,
    this.isHorizontal = false,
    this.selectedItem,
    this.itemCompleted,
    required this.childBuilder,
    this.itemInProgress,
  });

  /// The list of items to display in the selector.
  /// Each item must implement the 'Titled' mixin.
  final List<T> items;
  final T? selectedItem;
  final bool Function(T item)? itemCompleted;
  final bool Function(T item)? itemInProgress;
  final Widget Function(BuildContext context, T item)? childBuilder;

  /// A callback function that is invoked with the selected item when a card is tapped.
  final void Function(T) onSelectItem;

  final double? cardHeight;
  final double? cardWidth;
  final int? maxLines;
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cardItems = items.map((item) {
      final bool isSelected = selectedItem == item;
      final bool isCompleted = itemCompleted != null ? itemCompleted!(item) : false;
      final bool isInProgress = itemInProgress != null ? itemInProgress!(item) : false;

      return Padding(
        padding: isHorizontal
            ? const EdgeInsets.symmetric(horizontal: BessSizes.spaceBtwItems / 2)
            : const EdgeInsets.symmetric(vertical: 6, horizontal: BessSizes.spaceBtwItems),
        child: CardButton(
          height: cardHeight,
          width: cardWidth,
          tintConditions: [
            (isSelected, BessColors.primary),
            (isCompleted, BessColors.green),
            (isInProgress, BessColors.yellow)
          ],
          onPressed: () => onSelectItem(item),
          padding: EdgeInsets.all(8),
          child: SizedBox(width: double.infinity, child: childBuilder!(context, item)),
        ),
      );
    }).toList();

    return SingleChildScrollView(
      scrollDirection: isHorizontal ? Axis.horizontal : Axis.vertical,
      child: isHorizontal ? Row(children: cardItems) : Column(children: cardItems),
    );
  }
}
