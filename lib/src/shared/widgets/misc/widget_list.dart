import 'package:flutter/material.dart';


class WidgetList<T> extends StatelessWidget {
  const WidgetList({
    super.key,
    required this.items,
    required this.itemBuilder,
  });

  /// The list of data items to display.
  final List<T> items;

  /// A function that takes the `BuildContext` and an `item` and returns
  /// the widget to be displayed in the list.
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    // A ScrollController is used to control a scrollable widget.
    final ScrollController scrollController = ScrollController();

    return Scrollbar(
      thumbVisibility: true, // Make the scrollbar thumb always visible
      controller: scrollController, // Connect the controller to the Scrollbar
      thickness: 14.0, // Make the scrollbar thicker
      radius: const Radius.circular(4.0), // Round the corners of the scrollbar
      interactive: true,
      child: ListView.builder(
        controller: scrollController, // Connect the controller to the ListView
        clipBehavior: Clip.hardEdge,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return itemBuilder(context, item);
        },
      ),
    );
  }
}
