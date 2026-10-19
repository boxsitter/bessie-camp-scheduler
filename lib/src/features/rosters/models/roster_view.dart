import '../../../models/camper.dart';
import '../../../models/enums.dart';
import 'natural_compare.dart';
import 'roster_column.dart';
import 'roster_context.dart';

enum CellTone { normal, alert }

/// What one roster cell shows. [CellTone.alert] marks values staff should
/// notice (unassigned blocks, campers who haven't arrived, ...).
class RosterCell {
  const RosterCell(this.text, {this.tone = CellTone.normal});

  final String text;
  final CellTone tone;

  @override
  bool operator ==(Object other) => other is RosterCell && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);

  @override
  String toString() => text;
}

/// A run of campers that share a value in the grouping column.
class RosterGroup {
  const RosterGroup({required this.key, required this.title, required this.heading, required this.campers});

  static const allKey = 'all';

  /// Identifies the group across rebuilds (e.g. to remember it is collapsed).
  final String key;

  /// The shared value ("Cabin 3", "Archery", "Yes").
  final String title;

  /// What the group's header shows ("Cabin - Cabin 3").
  final String heading;
  final List<Camper> campers;

  Iterable<String> get camperIds => campers.map((c) => c.id);
}

/// Cell text, sort keys, grouping and searching for the roster table. Pure:
/// everything it needs is in the [RosterContext].
class RosterView {
  const RosterView(this.context);

  final RosterContext context;

  static const unassigned = 'Unassigned';
  static const noCabin = 'No cabin';
  static const unspecified = 'Unspecified';

  // Cells ---------------------------------------------------------------------

  RosterCell cell(Camper camper, RosterColumn column) => switch (column) {
    FieldColumn(:final field) => _fieldCell(camper, field),
    BlockColumn(:final block) => _blockCell(camper, block.id),
  };

  String text(Camper camper, RosterColumn column) => cell(camper, column).text;

  RosterCell _fieldCell(Camper camper, RosterField field) => switch (field) {
    RosterField.fullName => RosterCell(camper.fullNamePreferred),
    RosterField.firstName => RosterCell(camper.firstName),
    RosterField.preferredName => RosterCell(camper.preferredName ?? ''),
    RosterField.lastName => RosterCell(camper.lastName),
    RosterField.gender => RosterCell(camper.gender?.code ?? ''),
    RosterField.birthdate => RosterCell(formatBirthdate(camper.birthdate)),
    RosterField.age => RosterCell(camper.ageOn(context.now).toString()),
    RosterField.note => RosterCell(camper.note),
    RosterField.cabin => RosterCell(_cabinText(camper)),
    RosterField.ultracampId => RosterCell(camper.ultracampId ?? ''),
    RosterField.arrived => _yesNo(camper.arrived),
    RosterField.canSwim => _yesNo(camper.canSwim),
    RosterField.preferencesSubmitted => _yesNo(camper.preferencesSubmitted),
    RosterField.satisfactionIndex => RosterCell(camper.satisfactionIndex?.toStringAsFixed(2) ?? 'N/A'),
  };

  RosterCell _yesNo(bool value) => value ? const RosterCell('Yes') : const RosterCell('No', tone: CellTone.alert);

  String _cabinText(Camper camper) {
    final id = camper.cabinId;
    if (id == null) return noCabin;
    return context.cabinsById[id]?.title ?? 'Unknown cabin';
  }

  RosterCell _blockCell(Camper camper, String blockId) {
    final scheduledId = camper.assignments[blockId];
    if (scheduledId == null) return const RosterCell(unassigned, tone: CellTone.alert);
    final activity = context.activityIn(camper, blockId);
    if (activity == null) return const RosterCell('Unknown activity', tone: CellTone.alert);
    return RosterCell(activity.name);
  }

  /// `MM/DD/YYYY`, the format rosters are imported in.
  static String formatBirthdate(DateTime date) =>
      '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year.toString().padLeft(4, '0')}';

  // Sorting -------------------------------------------------------------------

  /// What [camper] is ordered by in [column]: a number, a lower-case string,
  /// or null when the value is blank. Blank values always sort last.
  Object? sortKey(Camper camper, RosterColumn column) {
    switch (column) {
      case FieldColumn(:final field):
        switch (field) {
          case RosterField.age:
            return camper.ageOn(context.now);
          case RosterField.birthdate:
            return camper.birthdate.millisecondsSinceEpoch;
          case RosterField.arrived:
            return camper.arrived ? 1 : 0;
          case RosterField.canSwim:
            return camper.canSwim ? 1 : 0;
          case RosterField.preferencesSubmitted:
            return camper.preferencesSubmitted ? 1 : 0;
          case RosterField.satisfactionIndex:
            return camper.satisfactionIndex;
          case RosterField.cabin:
            return camper.cabinId == null ? null : _textKey(_cabinText(camper));
          case RosterField.fullName ||
              RosterField.firstName ||
              RosterField.preferredName ||
              RosterField.lastName ||
              RosterField.gender ||
              RosterField.note ||
              RosterField.ultracampId:
            return _textKey(text(camper, column));
        }
      case BlockColumn(:final block):
        return camper.assignments[block.id] == null ? null : _textKey(text(camper, column));
    }
  }

  static String? _textKey(String text) {
    final trimmed = text.trim();
    return trimmed.isEmpty ? null : trimmed.toLowerCase();
  }

  /// Orders campers by [column]; blanks last in either direction. Ties are
  /// broken by name so the order never jumps around.
  int compare(Camper a, Camper b, RosterColumn column, SortDirection direction) =>
      _compareKeys(sortKey(a, column), sortKey(b, column), a, b, direction);

  static int _compareKeys(Object? ka, Object? kb, Camper a, Camper b, SortDirection direction) {
    if (ka != null && kb != null) {
      final byKey = switch ((ka, kb)) {
        (final num x, final num y) => x.compareTo(y),
        (final String x, final String y) => naturalCompare(x, y),
        _ => ka.toString().compareTo(kb.toString()),
      };
      if (byKey != 0) return direction == SortDirection.asc ? byKey : -byKey;
    } else if (ka != null) {
      return -1;
    } else if (kb != null) {
      return 1;
    }
    return _byName(a, b);
  }

  static int _byName(Camper a, Camper b) {
    final byLast = naturalCompare(a.lastName.toLowerCase(), b.lastName.toLowerCase());
    if (byLast != 0) return byLast;
    final byFirst = naturalCompare(a.firstName.toLowerCase(), b.firstName.toLowerCase());
    if (byFirst != 0) return byFirst;
    return a.id.compareTo(b.id);
  }

  List<Camper> sorted(Iterable<Camper> campers, RosterColumn column, SortDirection direction) {
    final keyed = [for (final camper in campers) (camper, sortKey(camper, column))];
    keyed.sort((a, b) => _compareKeys(a.$2, b.$2, a.$1, b.$1, direction));
    return [for (final entry in keyed) entry.$1];
  }

  // Searching -----------------------------------------------------------------

  bool matches(Camper camper, String query) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return true;
    return camper.fullName.toLowerCase().contains(needle) ||
        camper.fullNamePreferred.toLowerCase().contains(needle) ||
        (camper.preferredName ?? '').toLowerCase().contains(needle) ||
        camper.firstName.toLowerCase().contains(needle) ||
        camper.lastName.toLowerCase().contains(needle);
  }

  List<Camper> filter(Iterable<Camper> campers, String query) => [
    for (final c in campers)
      if (matches(c, query)) c,
  ];

  // Grouping ------------------------------------------------------------------

  /// The title of the group [camper] belongs to when grouping by [column].
  String groupTitle(Camper camper, RosterColumn column) {
    final value = text(camper, column).trim();
    return value.isEmpty ? unspecified : value;
  }

  static bool _isPlaceholder(String title) => title == unassigned || title == noCabin || title == unspecified;

  /// The roster as shown: searched, sorted, and (when [groupBy] is set)
  /// split into groups ordered by title with the placeholder groups
  /// ("Unassigned", "No cabin", ...) last.
  List<RosterGroup> arrange(
    Iterable<Camper> campers, {
    String query = '',
    required RosterColumn sortBy,
    SortDirection direction = SortDirection.asc,
    RosterColumn? groupBy,
  }) {
    final ordered = sorted(filter(campers, query), sortBy, direction);
    if (groupBy == null) {
      return [RosterGroup(key: RosterGroup.allKey, title: 'All Campers', heading: 'All Campers', campers: ordered)];
    }

    final byTitle = <String, List<Camper>>{};
    for (final camper in ordered) {
      byTitle.putIfAbsent(groupTitle(camper, groupBy), () => []).add(camper);
    }
    final titles =
        byTitle.keys.toList()..sort((a, b) {
          final aPlaceholder = _isPlaceholder(a);
          final bPlaceholder = _isPlaceholder(b);
          if (aPlaceholder != bPlaceholder) return aPlaceholder ? 1 : -1;
          return naturalCompare(a.toLowerCase(), b.toLowerCase());
        });

    return [
      for (final title in titles)
        RosterGroup(
          key: '${groupBy.id}|$title',
          title: title,
          heading: switch (groupBy) {
            FieldColumn(:final field) => '${field.title} - $title',
            BlockColumn() => title,
          },
          campers: byTitle[title]!,
        ),
    ];
  }
}
