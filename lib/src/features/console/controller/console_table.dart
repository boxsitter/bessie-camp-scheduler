import 'console_style.dart';

/// Lays out [rows] as aligned columns, one string per line. [headers], when
/// given, are emphasized and underlined.
List<String> formatTable(List<List<String>> rows, {List<String>? headers}) {
  final allRows = [if (headers != null) headers, ...rows];
  final columnCount = allRows.fold(0, (count, row) => row.length > count ? row.length : count);
  final widths = List<int>.filled(columnCount, 0);
  for (final row in allRows) {
    for (var i = 0; i < row.length; i++) {
      if (row[i].length > widths[i]) widths[i] = row[i].length;
    }
  }

  String line(List<String> cells, {String Function(String)? style}) {
    final formatted = <String>[];
    for (var i = 0; i < columnCount; i++) {
      final cell = i < cells.length ? cells[i] : '';
      // The last column is not padded, so lines carry no trailing spaces.
      final text = i == columnCount - 1 ? cell : cell.padRight(widths[i]);
      formatted.add(style == null ? text : style(text));
    }
    final joined = formatted.join('  ');
    // Short rows leave empty columns behind; headers are styled, so left alone.
    return style == null ? joined.trimRight() : joined;
  }

  return [
    if (headers != null && headers.isNotEmpty) ...[
      line(headers, style: ConsoleStyle.emphasis),
      widths.map((width) => '-' * width).join('  '),
    ],
    for (final row in rows) line(row),
  ];
}
