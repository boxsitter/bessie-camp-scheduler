// packages/ember_cli_utils/lib/src/io/output_utils.dart
import 'dart:io';
import 'package:ansicolor/ansicolor.dart';
import 'package:bessie/src/cli/io/io_interfaces.dart';
import 'package:tabular/tabular.dart';

/// A utility class for stylized CLI output.
class CliOutput implements UserOutput {
  final AnsiPen _penError = AnsiPen()..red(bold: true);
  final AnsiPen _penWarning = AnsiPen()..yellow();
  final AnsiPen _penSuccess = AnsiPen()..green();
  final AnsiPen _penInfo = AnsiPen()..blue();
  final AnsiPen _penEmph = AnsiPen()..cyan(bold: true);
  final AnsiPen _penDim = AnsiPen()..gray(level: 0.5);

  @override
  void log(String message) {
    stdout.writeln(message);
  }

  @override
  void error(String message, {String? details}) {
    stderr.writeln(_penError('Error: $message'));
    if (details != null && details.isNotEmpty) {
      stderr.writeln(_penDim(details));
    }
  }

  @override
  void warning(String message) {
    stdout.writeln(_penWarning('Warning: $message'));
  }

  @override
  void success(String message) {
    stdout.writeln(_penSuccess(message));
  }

  @override
  void info(String message) {
    stdout.writeln(_penInfo(message));
  }

  @override
  void printEmph(String message) {
    stdout.writeln(_penEmph(message));
  }

  @override
  void printDim(String message) {
    stdout.writeln(_penDim(message));
  }

  @override
  void printHeading(String message) {
    stdout.writeln(''); // Add some space before a heading
    stdout.writeln(_penEmph(message.toUpperCase()));
    stdout.writeln('-' * message.length);
  }

  /// Prints a simple key-value pair.
  @override
  void printProperty(String key, dynamic value) {
    stdout.writeln('${_penEmph(key)}: $value');
  }

  /// Prints a list of items.
  @override
  void printList(List<String> items, {String title = 'Items:'}) {
    if (items.isEmpty) {
      log('$title (No items)');
      return;
    }
    log(title);
    for (final item in items) {
      log('  - $item');
    }
  }

  /// Prints a table to the console using the tabular package.
  ///
  /// [dataRows] is a list of rows, where each row is a list of cell strings.
  /// [headers] is an optional list of header strings for the table.
  /// All rows, including the header row if provided, should ideally have the same number of columns.
  @override
  void printTable(List<List<String>> dataRows, {List<String>? headers}) {
    if (dataRows.isEmpty && (headers == null || headers.isEmpty)) {
      log('(Empty table)');
      return;
    }

    List<List<dynamic>> tableData = []; // tabular expects List<List<dynamic>>
    if (headers != null && headers.isNotEmpty) {
      // Optionally style headers using AnsiPen
      tableData.add(headers.map((h) => _penEmph(h)).toList());
    }

    // Add data rows
    tableData.addAll(dataRows);

    if (tableData.isEmpty) {
      log('(Table data is empty after processing headers)');
      return;
    }

    // Basic validation for consistent column counts before passing to Tabular
    // Tabular itself might handle inconsistencies, but it's good to be aware.
    if (tableData.isNotEmpty) {
      final numColumns = tableData.first.length;
      if (tableData.any((row) => row.length != numColumns)) {
        error(
            "Table rows have inconsistent number of columns. Table output might be misaligned.",
            details: "Ensure all data rows and the header row have the same number of elements."
        );
        // Proceeding anyway, Tabular might handle it or print oddly.
      }
    }

    var string = tabular(tableData);
    log(string);
  }
}