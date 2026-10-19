import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/errors.dart';
import '../../models/activity.dart';
import '../../models/cabin.dart';
import '../../models/enums.dart';

/// Pure logic behind the branch catalog screens (grouping, badges, form
/// validation). Kept free of widgets and GetX so it can be tested directly;
/// the session setup screen reuses the grouping and text helpers.

/// "1 camper", "3 campers".
String pluralize(int count, String singular, [String? plural]) => '$count ${count == 1 ? singular : plural ?? '${singular}s'}';

// Cabins ----------------------------------------------------------------------

const String noVillageLabel = 'No village';

String villageLabel(String village) => village.trim().isEmpty ? noVillageLabel : village.trim();

/// The cabins of one village, in display order.
class VillageGroup {
  const VillageGroup(this.village, this.cabins);

  /// Trimmed village name; empty for cabins that belong to no village.
  final String village;
  final List<Cabin> cabins;

  String get label => villageLabel(village);
  int get capacity => cabins.fold(0, (sum, cabin) => sum + cabin.capacity);
}

/// Groups cabins by village. Villages are ordered by the position of their
/// first cabin, with cabins that belong to no village last; cabins within a
/// village are ordered by position, then name.
List<VillageGroup> groupCabinsByVillage(Iterable<Cabin> cabins) {
  final byVillage = <String, List<Cabin>>{};
  for (final cabin in cabins) {
    byVillage.putIfAbsent(cabin.village.trim(), () => []).add(cabin);
  }
  int compareCabins(Cabin a, Cabin b) {
    final byPosition = a.position.compareTo(b.position);
    return byPosition != 0 ? byPosition : compareAsciiLowerCaseNatural(a.title, b.title);
  }

  final groups = [for (final entry in byVillage.entries) VillageGroup(entry.key, entry.value.sorted(compareCabins))];
  groups.sort((a, b) {
    if (a.village.isEmpty != b.village.isEmpty) return a.village.isEmpty ? 1 : -1;
    final byFirstPosition = a.cabins.first.position.compareTo(b.cabins.first.position);
    return byFirstPosition != 0 ? byFirstPosition : compareAsciiLowerCaseNatural(a.village, b.village);
  });
  return groups;
}

/// The position a new cabin should get so that it is listed after the others.
int nextCabinPosition(Iterable<Cabin> cabins) =>
    cabins.fold(0, (highest, cabin) => cabin.position > highest ? cabin.position : highest) + 1;

class CabinFormInput {
  const CabinFormInput({this.name = '', this.displayName = '', this.village = '', this.capacity = ''});

  final String name;

  /// Blank means "show the name".
  final String displayName;

  /// Blank means no village.
  final String village;
  final String capacity;
}

class CabinFormErrors {
  const CabinFormErrors({this.name, this.displayName, this.capacity});

  final String? name;
  final String? displayName;
  final String? capacity;

  bool get hasErrors => name != null || displayName != null || capacity != null;
}

const int maxCabinNameLength = 40;
const int maxCabinCapacity = 100;

/// Names and display names are what rosters and CSV imports refer to a cabin
/// by, so none may repeat (ignoring case) among a branch's cabins.
CabinFormErrors validateCabinForm(CabinFormInput input, {Iterable<Cabin> existing = const []}) {
  final taken = {
    for (final cabin in existing) ...[
      cabin.name.trim().toLowerCase(),
      if (cabin.displayName != null) cabin.displayName!.trim().toLowerCase(),
    ],
  };

  final name = input.name.trim();
  String? nameError;
  if (name.isEmpty) {
    nameError = 'Enter a name for the cabin.';
  } else if (name.length > maxCabinNameLength) {
    nameError = 'Keep the name under $maxCabinNameLength characters.';
  } else if (taken.contains(name.toLowerCase())) {
    nameError = 'There is already a cabin called "$name".';
  }

  final displayName = input.displayName.trim();
  String? displayNameError;
  if (displayName.length > maxCabinNameLength) {
    displayNameError = 'Keep the display name under $maxCabinNameLength characters.';
  } else if (displayName.isNotEmpty && taken.contains(displayName.toLowerCase())) {
    displayNameError = 'There is already a cabin called "$displayName".';
  }

  return CabinFormErrors(
    name: nameError,
    displayName: displayNameError,
    capacity: _validateWholeNumber(input.capacity, label: 'Capacity', max: maxCabinCapacity, blankMessage: 'Enter how many campers fit.'),
  );
}

// Activities ------------------------------------------------------------------

/// The activities of one category, by name.
class ActivityGroup {
  const ActivityGroup(this.category, this.activities);

  final ActivityCategory category;
  final List<Activity> activities;
}

/// Groups activities by category, in the order the categories are declared,
/// leaving out empty ones. Activities are ordered by name.
List<ActivityGroup> groupActivitiesByCategory(Iterable<Activity> activities) {
  return [
    for (final category in ActivityCategory.values)
      if (activities.any((a) => a.category == category))
        ActivityGroup(
          category,
          activities.where((a) => a.category == category).sorted((a, b) => compareAsciiLowerCaseNatural(a.name, b.name)),
        ),
  ];
}

enum ActivityBadge {
  skillsRec('Skills rec', 'Offered during skills rec blocks.'),
  doubleBlock('Double block', 'Takes up two consecutive blocks on the same day.'),
  hidden('Hidden', 'Keeps campers busy but is never offered to them or assigned automatically.'),
  noRanking('No ranking', 'Campers are not asked to rank it.');

  const ActivityBadge(this.label, this.hint);

  final String label;
  final String hint;
}

List<ActivityBadge> activityBadges(Activity activity) => [
  if (activity.isSkillsRec) ActivityBadge.skillsRec,
  if (activity.doubleSchedule) ActivityBadge.doubleBlock,
  if (activity.isHidden) ActivityBadge.hidden,
  if (!activity.preferenceRequired) ActivityBadge.noRanking,
];

/// What the user typed into the activity form.
class ActivityFormInput {
  const ActivityFormInput({
    this.name = '',
    this.description = '',
    this.capacity = '',
    this.category = ActivityCategory.other,
    this.isSkillsRec = false,
    this.doubleSchedule = false,
    this.maxAssignments = '',
    this.isHidden = false,
    this.preferenceRequired = true,
  });

  factory ActivityFormInput.fromActivity(Activity activity) => ActivityFormInput(
    name: activity.name,
    description: activity.description,
    capacity: '${activity.capacity}',
    category: activity.category,
    isSkillsRec: activity.isSkillsRec,
    doubleSchedule: activity.doubleSchedule,
    maxAssignments: activity.maxAssignments == null ? '' : '${activity.maxAssignments}',
    isHidden: activity.isHidden,
    preferenceRequired: activity.preferenceRequired,
  );

  final String name;
  final String description;
  final String capacity;
  final ActivityCategory category;
  final bool isSkillsRec;
  final bool doubleSchedule;

  /// Blank means no limit.
  final String maxAssignments;
  final bool isHidden;
  final bool preferenceRequired;
}

class ActivityFormErrors {
  const ActivityFormErrors({this.name, this.capacity, this.maxAssignments});

  final String? name;
  final String? capacity;
  final String? maxAssignments;

  bool get hasErrors => name != null || capacity != null || maxAssignments != null;
}

const int maxActivityNameLength = 80;
const int maxActivityCapacity = 500;
const int maxActivityAssignments = 50;

/// [otherActivityNames] are the names of the branch's other activities (not
/// the one being edited); names are unique within a branch, ignoring case.
ActivityFormErrors validateActivityForm(ActivityFormInput input, {Iterable<String> otherActivityNames = const []}) {
  final name = input.name.trim();
  String? nameError;
  if (name.isEmpty) {
    nameError = 'Enter a name for the activity.';
  } else if (name.length > maxActivityNameLength) {
    nameError = 'Keep the name under $maxActivityNameLength characters.';
  } else if (otherActivityNames.any((other) => other.trim().toLowerCase() == name.toLowerCase())) {
    nameError = 'There is already an activity called "$name".';
  }

  return ActivityFormErrors(
    name: nameError,
    capacity: _validateWholeNumber(
      input.capacity,
      label: 'Capacity',
      max: maxActivityCapacity,
      blankMessage: 'Enter how many campers fit.',
    ),
    // Optional: blank means no limit.
    maxAssignments: _validateWholeNumber(input.maxAssignments, label: 'The limit', max: maxActivityAssignments),
  );
}

/// Builds the activity a valid [input] describes. [id] stays empty for an
/// activity that has not been created yet.
Activity buildActivity(ActivityFormInput input, {required String branchId, String id = ''}) {
  final maxAssignments = input.maxAssignments.trim();
  return Activity(
    id: id,
    branchId: branchId,
    name: input.name.trim(),
    description: input.description.trim(),
    capacity: int.parse(input.capacity.trim()),
    category: input.category,
    isSkillsRec: input.isSkillsRec,
    doubleSchedule: input.doubleSchedule,
    maxAssignments: maxAssignments.isEmpty ? null : int.parse(maxAssignments),
    isHidden: input.isHidden,
    preferenceRequired: input.preferenceRequired,
  );
}

/// Choosing the skills category marks the activity as a skills rec (and
/// moving it out of that category clears the mark); the box can still be
/// changed afterwards.
bool skillsRecAfterCategoryChange({required ActivityCategory from, required ActivityCategory to, required bool isSkillsRec}) {
  if (to == ActivityCategory.skills) return true;
  if (from == ActivityCategory.skills) return false;
  return isSkillsRec;
}

/// The database refuses to delete an activity that is still scheduled but
/// words it generically. Returns what to tell the user in that case, null for
/// any other failure.
String? activityStillScheduledMessage(Object error, Activity activity) {
  final cause = error is AppException ? error.cause : error;
  if (cause is PostgrestException && cause.code == '23503') {
    return '"${activity.name}" is still scheduled in a session. Remove it from every block it is scheduled in, then delete it.';
  }
  return null;
}

/// Null when [raw] is a whole number from 1 to [max]. A blank value is an
/// error only when [blankMessage] says what to tell the user.
String? _validateWholeNumber(String raw, {required String label, required int max, String? blankMessage}) {
  final text = raw.trim();
  if (text.isEmpty) return blankMessage;
  final value = int.tryParse(text);
  if (value == null) return '$label must be a whole number.';
  if (value < 1) return '$label must be at least 1.';
  if (value > max) return '$label can be at most $max.';
  return null;
}
