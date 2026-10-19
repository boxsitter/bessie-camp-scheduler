import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/features/rosters/models/table_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const columns = <RosterColumn>[FieldColumn(RosterField.fullName), FieldColumn(RosterField.age)];
  const minimum = TableLayout.checkboxWidth + ColumnWidths.xl + ColumnWidths.sm;

  test('uses the default widths when the space is tight', () {
    final layout = TableLayout.fit(columns, 100);
    expect(layout.columnWidths, [ColumnWidths.xl, ColumnWidths.sm]);
    expect(layout.tableWidth, minimum);
  });

  test('gives the spare room to the last column', () {
    final layout = TableLayout.fit(columns, minimum + 200);
    expect(layout.columnWidths, [ColumnWidths.xl, ColumnWidths.sm + 200]);
    expect(layout.tableWidth, minimum + 200);
  });

  test('is just the checkbox column with no columns', () {
    final layout = TableLayout.fit(const [], 800);
    expect(layout.columnWidths, isEmpty);
    expect(layout.tableWidth, TableLayout.checkboxWidth);
  });
}
