import '../ember_core.dart';

class RosterField implements Titled {
  final String name;
  @override
  final String title;
  final bool required;
  final double defaultWidth;
  final String? dataId;
  final String? csvHeader;
  final String? csvHeaderAlt;
  final bool allowGrouping;

  /// Constructor using named parameters for improved readability.
  const RosterField({
    required this.name,
    required this.title,
    required this.required,
    required this.defaultWidth,
    this.dataId,
    this.csvHeader,
    this.csvHeaderAlt,
    this.allowGrouping = false,
  });

  static const double widthSm = 65;
  static const double widthMd = 100;
  static const double widthLg = 160;
  static const double widthXl = 260;

  /// --- Static definitions for each field ---
  static const RosterField coreId = RosterField(name: 'coreId', title: 'Bessie Id', required: false, defaultWidth: widthXl);
  static const RosterField fullName = RosterField(name: 'fullName', title: 'Full Name', required: false, defaultWidth: widthXl);
  static const RosterField firstName = RosterField(
    name: 'firstName',
    title: 'First Name',
    required: true,
    defaultWidth: widthLg,
    csvHeader: 'nameFirst',
  );
  static const RosterField preferredName = RosterField(
    name: 'preferredName',
    title: 'Nickname',
    required: false,
    defaultWidth: widthLg,
    csvHeader: 'nickname',
  );
  static const RosterField lastName = RosterField(
    name: 'lastName',
    title: 'Last Name',
    required: true,
    defaultWidth: widthLg,
    csvHeader: 'nameLast',
  );
  static const RosterField gender = RosterField(
    name: 'gender',
    title: 'Gender',
    required: false,
    defaultWidth: widthMd,
    csvHeader: 'expressionName',
    csvHeaderAlt: 'Gender',
  );
  static const RosterField birthdate = RosterField(
    name: 'birthdate',
    title: 'Birthdate',
    required: true,
    defaultWidth: widthLg,
    csvHeader: 'Birthdate',
  );
  static const RosterField age = RosterField(name: 'age', title: 'Age', required: false, defaultWidth: widthSm);
  static const RosterField note = RosterField(name: 'note', title: 'Note', required: false, defaultWidth: widthXl);
  static const RosterField cabinName = RosterField(
    name: 'cabinName',
    title: 'Cabin',
    required: false,
    defaultWidth: widthLg,
    csvHeader: 'Cabin',
    allowGrouping: true,
  );
  static const RosterField ultracampId = RosterField(
    name: 'ultracampId',
    title: 'UltraCamp id',
    required: false,
    defaultWidth: widthLg,
    csvHeader: 'idPerson',
  );
  static const RosterField arrived = RosterField(
    name: 'arrived',
    title: 'Arrived',
    required: false,
    defaultWidth: widthMd,
    allowGrouping: true,
  );
  static const RosterField canSwim = RosterField(
    name: 'canSwim',
    title: 'Can Swim',
    required: false,
    defaultWidth: widthMd,
    allowGrouping: true,
  );
  static const RosterField preferencesCompleted = RosterField(
    name: 'preferencesCompleted',
    title: 'Prefs Complete',
    required: false,
    defaultWidth: widthLg,
    allowGrouping: true,
  );
  static const RosterField activitySatisfactionIndex = RosterField(
    name: 'activitySatisfactionIndex',
    title: 'ASI',
    required: false,
    defaultWidth: widthMd,
    allowGrouping: false,
  );

  /// A list of all possible RosterField values, similar to `Enum.values`.
  static const List<RosterField> values = [
    coreId,
    fullName,
    firstName,
    preferredName,
    lastName,
    gender,
    birthdate,
    age,
    note,
    cabinName,
    ultracampId,
    arrived,
    canSwim,
    preferencesCompleted,
    activitySatisfactionIndex,
  ];

  @override
  String toString() => title;

  // Optional: Overriding equals and hashCode makes comparisons work as expected.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RosterField && runtimeType == other.runtimeType && title == other.title;

  @override
  int get hashCode => title.hashCode;

  @override
  String get displayTitle => title;
}
