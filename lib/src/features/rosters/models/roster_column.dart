import '../../../models/schedule.dart';
import '../../../models/titled.dart';

/// Default column widths, in logical pixels.
abstract final class ColumnWidths {
  static const double sm = 65;
  static const double md = 100;
  static const double lg = 160;
  static const double xl = 260;
}

/// The camper fields a roster can show.
///
/// Besides titles and widths this is also what the importer instructions are
/// generated from: [csvHeader] (and [csvHeaderAlt]) are the column names an
/// UltraCamp export uses for the field.
enum RosterField implements Titled {
  fullName('Full Name', ColumnWidths.xl),
  firstName('First Name', ColumnWidths.lg, csvHeader: 'nameFirst', isRequired: true),
  preferredName('Nickname', ColumnWidths.lg, csvHeader: 'nickname'),
  lastName('Last Name', ColumnWidths.lg, csvHeader: 'nameLast', isRequired: true),
  gender('Gender', ColumnWidths.md, csvHeader: 'expressionName', csvHeaderAlt: 'Gender'),
  birthdate('Birthdate', ColumnWidths.lg, csvHeader: 'Birthdate', isRequired: true),
  age('Age', ColumnWidths.sm),
  note('Note', ColumnWidths.xl),
  cabin('Cabin', ColumnWidths.lg, csvHeader: 'Cabin', allowGrouping: true),
  ultracampId('UltraCamp id', ColumnWidths.lg, csvHeader: 'idPerson'),
  arrived('Arrived', ColumnWidths.md, allowGrouping: true),
  canSwim('Can Swim', ColumnWidths.md, allowGrouping: true),
  preferencesSubmitted('Prefs Complete', ColumnWidths.lg, allowGrouping: true),
  satisfactionIndex('ASI', ColumnWidths.md);

  const RosterField(
    this.title,
    this.defaultWidth, {
    this.csvHeader,
    this.csvHeaderAlt,
    this.isRequired = false,
    this.allowGrouping = false,
  });

  @override
  final String title;
  final double defaultWidth;

  /// The header of the matching column in an UltraCamp roster export.
  final String? csvHeader;
  final String? csvHeaderAlt;

  /// Whether an imported roster must contain this field.
  final bool isRequired;
  final bool allowGrouping;

  @override
  String get displayTitle => title;

  /// Every header an import accepts for this field.
  List<String> get csvHeaders => [
    if (csvHeader != null) csvHeader!,
    if (csvHeaderAlt != null) csvHeaderAlt!,
  ];
}

/// One column of the roster table: either a camper field or a schedule block
/// (which shows the activity each camper has in that block).
sealed class RosterColumn implements Titled {
  const RosterColumn();

  /// Stable across reloads of the schedule; two columns are equal when their
  /// ids are.
  String get id;
  double get defaultWidth;
  bool get allowGrouping;

  @override
  String get displayTitle => title;

  @override
  bool operator ==(Object other) => other is RosterColumn && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class FieldColumn extends RosterColumn {
  const FieldColumn(this.field);

  final RosterField field;

  @override
  String get id => 'field:${field.name}';
  @override
  String get title => field.title;
  @override
  double get defaultWidth => field.defaultWidth;
  @override
  bool get allowGrouping => field.allowGrouping;
}

final class BlockColumn extends RosterColumn {
  const BlockColumn(this.block);

  final Block block;

  @override
  String get id => 'block:${block.id}';
  @override
  String get title => block.displayTitle;
  @override
  double get defaultWidth => ColumnWidths.xl;
  @override
  bool get allowGrouping => true;
}

/// Catalogue and bookkeeping for [RosterColumn]s.
abstract final class RosterColumns {
  static final List<FieldColumn> allFields = [for (final field in RosterField.values) FieldColumn(field)];

  static const FieldColumn fullName = FieldColumn(RosterField.fullName);
  static const FieldColumn lastName = FieldColumn(RosterField.lastName);

  static final List<RosterColumn> defaults = [
    fullName,
    const FieldColumn(RosterField.gender),
    const FieldColumn(RosterField.age),
    const FieldColumn(RosterField.cabin),
  ];

  /// Re-points a block column at [schedule]'s blocks after the schedule was
  /// loaded again (or a different session was chosen): the block with the same
  /// id, else the equivalent block (same day, time and title). Null when there
  /// is none. Field columns are returned as they are.
  static RosterColumn? remap(RosterColumn column, Schedule schedule) {
    switch (column) {
      case FieldColumn():
        return column;
      case BlockColumn(:final block):
        final match = schedule.blockById(block.id) ?? _equivalentBlock(block, schedule);
        return match == null ? null : BlockColumn(match);
    }
  }

  /// [remap] for a list of columns; columns whose block is gone are dropped.
  static List<RosterColumn> remapToSchedule(List<RosterColumn> columns, Schedule schedule) {
    final result = <RosterColumn>[];
    for (final column in columns) {
      final remapped = remap(column, schedule);
      if (remapped != null && !result.contains(remapped)) result.add(remapped);
    }
    return result;
  }

  static Block? _equivalentBlock(Block block, Schedule schedule) {
    for (final candidate in schedule.blocks) {
      if (candidate.dayIndex == block.dayIndex && candidate.startTime == block.startTime && candidate.title == block.title) {
        return candidate;
      }
    }
    return null;
  }
}
