import 'package:bessie/src/features/console/controller/console_table.dart';
import 'package:flutter_test/flutter_test.dart';

String plain(String text) => text.replaceAll(RegExp(r'\x1B\[[0-9;]*m'), '');

void main() {
  test('aligns columns to the widest cell and leaves no trailing space', () {
    final lines = formatTable([
      ['Session 1', '2026-06-15'],
      ['S2', ''],
    ]);

    expect(lines, ['Session 1  2026-06-15', 'S2']);
  });

  test('headers are underlined and counted when sizing columns', () {
    final lines = formatTable(
      [
        ['a', 'b'],
      ],
      headers: ['Name', 'Starts'],
    );

    expect(lines.map(plain), ['Name  Starts', '----  ------', 'a     b']);
  });

  test('copes with rows of different lengths', () {
    final lines = formatTable([
      ['one'],
      ['two', 'extra', 'more'],
    ]);

    expect(lines, ['one', 'two  extra  more']);
  });

  test('an empty table has no lines', () {
    expect(formatTable([]), isEmpty);
  });
}
