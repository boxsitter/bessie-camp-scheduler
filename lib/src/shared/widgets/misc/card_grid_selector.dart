import 'package:flutter/material.dart';


class CardGridSelector<T> extends StatelessWidget {
  const CardGridSelector({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.columns = 2,
    this.childAspectRatio = 1.0,
    this.scrollDirection = Axis.vertical,
  });

  /// The list of items to display in the selector.
  final List<T> items;

  /// A builder function to create the widget for each item.
  /// It provides the build context and the item itself.
  /// This builder is responsible for returning a CardButton widget.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// The number of columns in the grid.
  final int columns;

  /// The ratio of the cross-axis to the main-axis extent of each child.
  final double childAspectRatio;

  /// The direction of scrolling for the grid.
  final Axis scrollDirection;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      scrollDirection: scrollDirection,
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return itemBuilder(context, item);
      },
    );
  }
}