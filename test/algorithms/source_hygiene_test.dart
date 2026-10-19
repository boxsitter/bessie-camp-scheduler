// Guards the structural promises of lib/src/algorithms: it is pure Dart, it
// compiles on case-sensitive file systems, and the abandoned code is gone.
//
// `flutter test` runs with the package root as working directory.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final Directory root = Directory('lib/src/algorithms');

List<File> sourceFiles() => [
  for (final entity in root.listSync(recursive: true))
    if (entity is File && entity.path.endsWith('.dart')) entity,
];

/// Every `import` / `export` directive of [file]: (directive, uri).
List<(String, String)> directivesOf(File file) {
  final pattern = RegExp(
    r'''^\s*(import|export)\s+['"]([^'"]+)['"]''',
    multiLine: true,
  );
  return [
    for (final match in pattern.allMatches(file.readAsStringSync()))
      (match.group(1)!, match.group(2)!),
  ];
}

/// Whether [path] exists *with exactly this spelling*, even on a
/// case-insensitive file system (which would happily open `Constraint.dart`
/// for `constraint.dart`): every segment must appear verbatim in the listing of
/// its parent directory.
bool existsWithExactCase(String path) {
  final segments =
      File(path).absolute.uri.pathSegments.where((s) => s.isNotEmpty).toList();
  var current = Directory(Platform.pathSeparator);
  for (final segment in segments) {
    final names = {
      for (final entity in current.listSync())
        entity.uri.pathSegments.where((s) => s.isNotEmpty).last,
    };
    if (!names.contains(segment)) return false;
    current = Directory(current.uri.resolve(segment).toFilePath());
  }
  return true;
}

void main() {
  test('the algorithms directory is where the tests expect it', () {
    expect(
      root.existsSync(),
      isTrue,
      reason: 'run `flutter test` from the repository root',
    );
    expect(sourceFiles(), isNotEmpty);
  });

  test('every Dart file and every directory name is lowercase snake_case', () {
    final fileName = RegExp(r'^[a-z][a-z0-9_]*\.dart$');
    final dirName = RegExp(r'^[a-z][a-z0-9_]*$');
    for (final entity in root.listSync(recursive: true)) {
      final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
      if (entity is File && entity.path.endsWith('.dart')) {
        expect(
          fileName.hasMatch(name),
          isTrue,
          reason: '${entity.path} is not snake_case',
        );
      } else if (entity is Directory) {
        expect(
          dirName.hasMatch(name),
          isTrue,
          reason: '${entity.path} is not snake_case',
        );
      } else if (entity is File) {
        // The only non-Dart file is the conventional README.
        expect(name, 'README.md', reason: 'unexpected file ${entity.path}');
      }
    }
  });

  test(
    'every import and export resolves to a file with exactly that spelling',
    () {
      for (final file in sourceFiles()) {
        for (final (_, uri) in directivesOf(file)) {
          if (uri.startsWith('dart:') || uri.startsWith('package:')) continue;
          final target = file.parent.uri.resolve(uri).toFilePath();
          expect(
            File(target).existsSync(),
            isTrue,
            reason: '${file.path} imports missing $uri',
          );
          expect(
            existsWithExactCase(target),
            isTrue,
            reason: '${file.path} imports $uri with the wrong letter case',
          );
        }
      }
    },
  );

  test(
    'the engine is pure Dart: only dart:*, package:collection and itself',
    () {
      final rootPath = root.absolute.path;
      for (final file in sourceFiles()) {
        for (final (_, uri) in directivesOf(file)) {
          final reason = '${file.path} imports $uri';
          if (uri.startsWith('dart:')) continue;
          if (uri.startsWith('package:collection/')) continue;
          if (uri.startsWith('package:bessie/')) {
            expect(
              uri.startsWith('package:bessie/src/algorithms/'),
              isTrue,
              reason: reason,
            );
            continue;
          }
          expect(uri.startsWith('package:'), isFalse, reason: reason);
          final resolved =
              File(file.parent.uri.resolve(uri).toFilePath()).absolute.path;
          expect(
            resolved.startsWith(rootPath),
            isTrue,
            reason: '$reason, which escapes lib/src/algorithms',
          );
        }
      }
    },
  );

  test('no forbidden dependency or construct appears in the source', () {
    final forbidden = {
      'package:flutter': 'the engine must not depend on Flutter',
      'package:intl': 'dates are compared by dayId, not formatted',
      'package:get': 'no GetX in the engine',
      'DateFormat': 'dates are compared by dayId, not formatted',
      'DateTime.now': 'the clock comes from AssignmentContext.now',
      'Duration.zero':
          'steps return a StepOutcome; the pipeline measures durations',
      'print(': 'the engine does not print',
    };
    for (final file in sourceFiles()) {
      final text = file.readAsStringSync();
      forbidden.forEach((token, why) {
        expect(
          text.contains(token),
          isFalse,
          reason: '${file.path} contains "$token": $why',
        );
      });
    }
  });

  test(
    'the abandoned three-pass design and the unused constraints are gone',
    () {
      const deletedFiles = [
        'fill_schedule.dart',
        'overfill_requests.dart',
        'request_fulfillment.dart',
        'same_day_repetition_constraint.dart',
        'weekly_repetition_constraint.dart',
      ];
      final names = sourceFiles().map((f) => f.uri.pathSegments.last).toSet();
      for (final name in deletedFiles) {
        expect(
          names.contains(name),
          isFalse,
          reason: '$name should be deleted',
        );
      }

      const deletedSymbols = [
        'FillSchedule',
        'OverfillRequests',
        'RequestFulfillment',
        'SameDayRepetitionConstraint',
        'WeeklyRepetitionConstraint',
        'allScheduledActivityToPeriodMap',
        'PreferenceType.flexible',
      ];
      for (final file in sourceFiles()) {
        final text = file.readAsStringSync();
        for (final symbol in deletedSymbols) {
          expect(
            text.contains(symbol),
            isFalse,
            reason: '${file.path} still mentions $symbol',
          );
        }
      }
    },
  );

  test('ProcessAssignmentsStep no longer takes an unused Random', () {
    final process = File(
      'lib/src/algorithms/common/steps/process_assignments_step.dart',
    );
    expect(process.readAsStringSync().contains('Random'), isFalse);
  });

  test('both strategies and the public entry point exist', () {
    for (final path in [
      'assignment_engine.dart',
      'algorithm_pipeline.dart',
      'diplomatic_algorithm/diplomatic_algorithm.dart',
      'diplomatic_algorithm/diplomatic_scorer.dart',
      'greedy_scoring_algorithm/greedy_scoring_algorithm.dart',
      'greedy_scoring_algorithm/greedy_scorer.dart',
    ]) {
      expect(
        File('lib/src/algorithms/$path').existsSync(),
        isTrue,
        reason: path,
      );
    }
  });
}
