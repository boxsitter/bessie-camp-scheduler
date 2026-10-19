import 'roster_column.dart';

/// Column and table widths for a roster table.
class TableLayout {
  const TableLayout({required this.columnWidths, required this.tableWidth});

  /// Width of the checkbox column that starts every row.
  static const double checkboxWidth = 50;

  /// Each column's width, in the order of the columns.
  final List<double> columnWidths;
  final double tableWidth;

  /// Gives every column its default width and, when [maxWidth] leaves room,
  /// hands the extra space to the last column.
  factory TableLayout.fit(List<RosterColumn> columns, double maxWidth) {
    if (columns.isEmpty) return const TableLayout(columnWidths: [], tableWidth: checkboxWidth);

    final widths = [for (final column in columns) column.defaultWidth];
    final minimum = widths.fold<double>(checkboxWidth, (sum, width) => sum + width);
    if (maxWidth > minimum) {
      widths[widths.length - 1] += maxWidth - minimum;
      return TableLayout(columnWidths: widths, tableWidth: maxWidth);
    }
    return TableLayout(columnWidths: widths, tableWidth: minimum);
  }
}
