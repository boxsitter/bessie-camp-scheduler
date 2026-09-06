import 'package:flutter/material.dart';

/// A generic widget that displays a list of items in a wrap-around grid layout.
///
/// It takes a list of items of any type `T` and an `itemBuilder` function
/// to build a widget for each item. The grid is scrollable.
class WidgetGrid<T> extends StatelessWidget {
  const WidgetGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
  });

  /// The list of data items to display in the grid.
  final List<T> items;

  /// A function that takes the `BuildContext` and an `item` and returns
  /// the widget to be displayed in the grid.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// The spacing between items on the main axis (horizontally).
  final double spacing;

  /// The spacing between items on the cross axis (vertically).
  final double runSpacing;


  @override
  Widget build(BuildContext context) {
    // A SingleChildScrollView makes the Wrap grid scrollable if the content overflows.
    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        // We map the list of data items to a list of widgets.
        children: items.map((item) {
          // For each item, we call your itemBuilder to create the widget.
          return itemBuilder(context, item);
        }).toList(), // .toList() converts the resulting Iterable into a List.
      ),
    );
  }
}