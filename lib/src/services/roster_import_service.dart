import 'dart:convert';

import 'package:csv/csv.dart';

import '../core/errors.dart';
import '../models/camper.dart';
import '../models/enums.dart';

/// A problem in an uploaded roster file, worded for the person who uploaded it.
class RosterImportException extends AppException {
  RosterImportException(super.message);
}

class ParsedRoster {
  const ParsedRoster({required this.rows, required this.skippedBlankRows, required this.duplicatesInFile});

  final List<CamperImportRow> rows;
  final int skippedBlankRows;
  final int duplicatesInFile;
}

/// Reads UltraCamp-style roster exports.
///
/// Columns are matched by header name, case-insensitively:
/// `nameFirst`, `nickname`, `nameLast`, `expressionName` (or `Gender`),
/// `Birthdate`, `Cabin` and `idPerson`. Only the first, last and birthdate
/// columns are required.
class RosterCsvParser {
  const RosterCsvParser();

  static const _columns = <String, List<String>>{
    'firstName': ['namefirst', 'first name', 'firstname'],
    'preferredName': ['nickname', 'preferred name'],
    'lastName': ['namelast', 'last name', 'lastname'],
    'gender': ['expressionname', 'gender'],
    'birthdate': ['birthdate', 'birth date', 'dob'],
    'cabin': ['cabin'],
    'ultracampId': ['idperson', 'ultracamp id', 'ultracampid'],
  };

  static const _headerNames = {'firstName': 'nameFirst', 'lastName': 'nameLast', 'birthdate': 'Birthdate'};

  String decode(List<int> bytes) {
    var text = utf8.decode(bytes, allowMalformed: true);
    if (text.startsWith('﻿')) text = text.substring(1);
    return text;
  }

  ParsedRoster parse(String csv) {
    final normalized = csv.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = const CsvToListConverter(eol: '\n', shouldParseNumbers: false).convert(normalized);
    if (rows.length < 2) {
      throw RosterImportException('The file needs a header row and at least one camper.');
    }

    final headers = rows.first.map((h) => h.toString().trim().toLowerCase()).toList();
    int indexOf(String column) {
      for (final name in _columns[column]!) {
        final i = headers.indexOf(name);
        if (i != -1) return i;
      }
      return -1;
    }

    final index = {for (final column in _columns.keys) column: indexOf(column)};
    for (final required in const ['firstName', 'lastName', 'birthdate']) {
      if (index[required] == -1) {
        throw RosterImportException('The file is missing the "${_headerNames[required]}" column.');
      }
    }

    String? cell(List<dynamic> row, String column) {
      final i = index[column]!;
      if (i == -1 || i >= row.length) return null;
      final text = row[i].toString().trim();
      return text.isEmpty ? null : text;
    }

    final parsed = <CamperImportRow>[];
    final seen = <String>{};
    var blank = 0;
    var duplicates = 0;

    for (var r = 1; r < rows.length; r++) {
      final row = rows[r];
      final lineNumber = r + 1;
      if (row.every((c) => c.toString().trim().isEmpty)) {
        blank++;
        continue;
      }

      final firstName = cell(row, 'firstName');
      final lastName = cell(row, 'lastName');
      final birthdateText = cell(row, 'birthdate');
      if (firstName == null || lastName == null || birthdateText == null) {
        throw RosterImportException('Row $lineNumber is missing a first name, last name or birthdate.');
      }
      final birthdate = parseBirthdate(birthdateText);
      if (birthdate == null) {
        throw RosterImportException('The birthdate "$birthdateText" in row $lineNumber isn\'t a valid date. Use MM/DD/YYYY.');
      }

      final key = '${firstName.toLowerCase()}|${lastName.toLowerCase()}|${birthdate.toIso8601String()}';
      if (!seen.add(key)) {
        duplicates++;
        continue;
      }

      parsed.add(
        CamperImportRow(
          firstName: firstName,
          lastName: lastName,
          birthdate: birthdate,
          preferredName: cell(row, 'preferredName'),
          gender: parseGender(cell(row, 'gender')),
          cabinName: cell(row, 'cabin'),
          ultracampId: cell(row, 'ultracampId'),
        ),
      );
    }

    return ParsedRoster(rows: parsed, skippedBlankRows: blank, duplicatesInFile: duplicates);
  }

  /// Accepts `M/D/YYYY` (optionally followed by a time) and `YYYY-MM-DD`.
  /// Returns a local calendar date, or null when [text] isn't a real date.
  static DateTime? parseBirthdate(String text) {
    final us = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s.*)?$').firstMatch(text.trim());
    final iso = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})(?:[T\s].*)?$').firstMatch(text.trim());
    int year, month, day;
    if (us != null) {
      month = int.parse(us.group(1)!);
      day = int.parse(us.group(2)!);
      year = int.parse(us.group(3)!);
    } else if (iso != null) {
      year = int.parse(iso.group(1)!);
      month = int.parse(iso.group(2)!);
      day = int.parse(iso.group(3)!);
    } else {
      return null;
    }
    final date = DateTime(year, month, day);
    // DateTime rolls 2/30 over to 3/2; reject those.
    if (date.year != year || date.month != month || date.day != day) return null;
    return date;
  }

  static Gender? parseGender(String? value) {
    if (value == null) return null;
    final v = value.toLowerCase();
    if (v == 'male' || v == 'm') return Gender.male;
    if (v == 'female' || v == 'f') return Gender.female;
    if (v.startsWith('non-binary') || v.startsWith('nonbinary') || v == 'nb') return Gender.nonBinary;
    return null;
  }
}
