/// How the roster table is drawn.
class RosterTableStyle {
  const RosterTableStyle({
    this.alternateRowColors = true,
    this.highContrast = false,
    this.rowSeparators = false,
    this.columnSeparators = false,
    this.compact = true,
  });

  final bool alternateRowColors;
  final bool highContrast;
  final bool rowSeparators;
  final bool columnSeparators;
  final bool compact;

  RosterTableStyle copyWith({bool? alternateRowColors, bool? highContrast, bool? rowSeparators, bool? columnSeparators, bool? compact}) =>
      RosterTableStyle(
        alternateRowColors: alternateRowColors ?? this.alternateRowColors,
        highContrast: highContrast ?? this.highContrast,
        rowSeparators: rowSeparators ?? this.rowSeparators,
        columnSeparators: columnSeparators ?? this.columnSeparators,
        compact: compact ?? this.compact,
      );
}
