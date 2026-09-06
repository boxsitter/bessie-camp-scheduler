import '../ember_core.dart';

class ModelHelperFunctions {
  // CamperPreference
  static int preferencesCompletedCount(Camper camper) {
    // Access the values of the map, filter out the nulls, and return the count.
    return camper.preferenceRefs.values.where((value) => value != null).length;
  }

  static bool preferenceCompleted(Camper camper, Schedule schedule) {
    // Use the 'every' method to iterate through each id in the set.
    // 'every' returns true only if the provided condition is true for ALL elements.
    return schedule.principalActivityRefs.every((id) {
      final isTeenSkills = id == 'teen_skills_rec-principal_activity-brn-zDbCdF6'; // TODO: EW EW EW FIX THIS SHIT
      // Check 1: Key exists in preferenceRefs AND its value is not null.
      final hasNonNullPreference = camper.preferenceRefs.containsKey(
          id) && camper.preferenceRefs[id] != null || isTeenSkills;

      // Check 2: Key exists in preferenceWeightRefs.
      // (No need to check for null value here as the map type is <PrincipalActivityId, double>)
      final hasWeight = camper.preferenceWeightRefs.containsKey(id) || isTeenSkills;

      // The condition for 'every' returns true only if both checks pass for the current id.
      return hasNonNullPreference && hasWeight;
    });
  }

  static bool? simplePreferencesCompleted(Camper camper) {
    if (camper.preferenceRefs.isEmpty) return null;
    for (double? preference in camper.preferenceRefs.values) {
      if (preference==null) return false;
    }
    return true;
  }
}