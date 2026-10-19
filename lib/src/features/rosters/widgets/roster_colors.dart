import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../models/activity_hints.dart';

/// Cell background of the repetition view: green for an activity the camper
/// has once, yellow for twice, red for three times or more.
Color? repetitionColor(RepetitionLevel? level) => switch (level) {
  RepetitionLevel.once => BessColors.green.withValues(alpha: 0.5),
  RepetitionLevel.twice => BessColors.yellow.withValues(alpha: 0.5),
  RepetitionLevel.many => BessColors.red.withValues(alpha: 0.5),
  null => null,
};

/// Tint of an activity in the switcher when preference colors are on.
Color preferenceColor(PreferenceHint hint) => switch (hint) {
  PreferenceHint.requested => BessColors.green,
  PreferenceHint.vetoed => BessColors.red,
  PreferenceHint.neutral => BessColors.yellow,
  PreferenceHint.repeated => BessColors.red,
};
