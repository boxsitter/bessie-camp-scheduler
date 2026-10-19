import 'dart:async';

import 'package:get/get.dart';

import '../../core/errors.dart';
import '../../data/catalog_repository.dart';
import '../../data/roster_repository.dart';
import '../../models/activity.dart';
import '../../models/cabin.dart';
import '../../services/auth_service.dart';
import '../../services/context_service.dart';
import '../../shared/mixins/route_aware_controller_mixin.dart';
import '../../shared/services/popup_service.dart';
import '../../shared/services/toast.dart';
import 'catalog_logic.dart';
import 'widgets/activity_form_dialog.dart';
import 'widgets/cabin_form_dialog.dart';
import 'widgets/form_widgets.dart';

enum CatalogTab { activities, cabins }

/// Manages the current branch's catalog of activities and cabins.
class BranchManagerController extends GetxController with RouteAwareControllerMixin {
  final ContextService _context = Get.find<ContextService>();
  final AuthService _auth = Get.find<AuthService>();
  final CatalogRepository _catalog = Get.find<CatalogRepository>();
  final RosterRepository _roster = Get.find<RosterRepository>();
  final PopupService _popups = Get.find<PopupService>();

  final RxBool isLoading = false.obs;

  /// True once the catalog has been read at least once.
  final RxBool hasLoaded = false.obs;
  final RxnString loadError = RxnString();
  final RxList<Activity> activities = <Activity>[].obs;
  final RxList<Cabin> cabins = <Cabin>[].obs;
  final Rx<CatalogTab> tab = CatalogTab.activities.obs;

  Worker? _branchWorker;
  int _generation = 0;

  /// Only root, directors and admins change the catalog; the database
  /// enforces it too.
  bool get canEdit => _auth.profile.value?.role.canEditSessionData ?? false;

  String get branchName => _context.branch.value?.name ?? '';

  @override
  void onInit() {
    super.onInit();
    _branchWorker = ever(_context.branch, (_) {
      hasLoaded.value = false;
      unawaited(load());
    });
    unawaited(load());
  }

  @override
  void onClose() {
    _branchWorker?.dispose();
    super.onClose();
  }

  @override
  void onNavigateTo(String to, String? from) {
    unawaited(load());
  }

  Future<void> load() async {
    final branchId = _context.branch.value?.id;
    if (branchId == null) {
      activities.clear();
      cabins.clear();
      hasLoaded.value = false;
      return;
    }

    final generation = ++_generation;
    isLoading.value = true;
    try {
      final loaded = await Future.wait<Object>([_catalog.listActivities(branchId), _catalog.listCabins(branchId)]);
      if (generation != _generation) return;
      activities.assignAll(loaded[0] as List<Activity>);
      cabins.assignAll(loaded[1] as List<Cabin>);
      loadError.value = null;
      hasLoaded.value = true;
    } catch (e, st) {
      if (generation != _generation) return;
      Toast.failure(e, st);
      loadError.value = AppException.from(e, st).message;
    } finally {
      if (generation == _generation) isLoading.value = false;
    }
  }

  // Activities ------------------------------------------------------------------

  /// Opens the activity form: a new activity, or [editing] one.
  Future<void> openActivityForm({Activity? editing}) {
    if (!_ensureCanEdit()) return Future.value();
    return showFormDialog<bool>(
      ActivityFormDialog(
        activity: editing,
        otherActivityNames: [
          for (final activity in activities)
            if (activity.id != editing?.id) activity.name,
        ],
        onSubmit: (input) => saveActivity(input, editing: editing),
      ),
    );
  }

  /// Creates the activity [input] describes, or updates [editing]. Throws an
  /// [AppException] when the database refuses.
  Future<void> saveActivity(ActivityFormInput input, {Activity? editing}) async {
    final activity = buildActivity(input, branchId: _context.branchId, id: editing?.id ?? '');
    if (editing == null) {
      final created = await _catalog.createActivity(activity);
      activities.add(created);
      Toast.success('Created "${created.name}".');
    } else {
      final updated = await _catalog.updateActivity(activity);
      final index = activities.indexWhere((a) => a.id == updated.id);
      if (index >= 0) {
        activities[index] = updated;
      } else {
        activities.add(updated);
      }
      Toast.success('Saved "${updated.name}".');
    }
  }

  Future<void> deleteActivity(Activity activity) async {
    if (!_ensureCanEdit()) return;
    final confirmed = await _popups.showConfirmationDialog(
      title: 'Delete ${activity.name}?',
      message: 'This removes the activity from the catalog and cannot be undone. An activity that is still scheduled in a session cannot be deleted.',
    );
    if (!confirmed) return;

    try {
      await _catalog.deleteActivity(activity.id);
      activities.removeWhere((a) => a.id == activity.id);
      Toast.success('Deleted "${activity.name}".');
    } catch (e, st) {
      final stillScheduled = activityStillScheduledMessage(e, activity);
      if (stillScheduled != null) {
        Toast.error(stillScheduled, title: 'Not deleted');
      } else {
        Toast.failure(e, st);
      }
    }
  }

  // Cabins ----------------------------------------------------------------------

  Future<void> openCabinForm() {
    if (!_ensureCanEdit()) return Future.value();
    return showFormDialog<bool>(CabinFormDialog(existingCabins: cabins.toList(), onSubmit: createCabin));
  }

  /// Creates the cabin [input] describes, listed after the existing ones.
  /// Throws an [AppException] when the database refuses.
  Future<void> createCabin(CabinFormInput input) async {
    final displayName = input.displayName.trim();
    final created = await _catalog.createCabin(
      branchId: _context.branchId,
      name: input.name.trim(),
      displayName: displayName.isEmpty ? null : displayName,
      village: input.village.trim(),
      capacity: int.parse(input.capacity.trim()),
      position: nextCabinPosition(cabins),
    );
    cabins.add(created);
    Toast.success('Created cabin "${created.title}".');
  }

  Future<void> deleteCabin(Cabin cabin) async {
    if (!_ensureCanEdit()) return;

    var camperNote = '';
    final session = _context.session.value;
    if (session != null) {
      final campers = await attempt(() => _roster.fetchCampers(session.id));
      if (campers == null) return;
      final staying = campers.where((camper) => camper.cabinId == cabin.id).length;
      if (staying > 0) camperNote = ' (${pluralize(staying, 'camper')} in ${session.name})';
    }

    final confirmed = await _popups.showConfirmationDialog(
      title: 'Delete ${cabin.title}?',
      message:
          'The cabin is removed from every session it is registered for, and campers staying in it are left without a cabin$camperNote. This cannot be undone.',
    );
    if (!confirmed) return;

    try {
      await _catalog.deleteCabin(cabin.id);
      cabins.removeWhere((c) => c.id == cabin.id);
      Toast.success('Deleted cabin "${cabin.title}".');
    } catch (e, st) {
      Toast.failure(e, st);
    }
  }

  bool _ensureCanEdit() {
    if (canEdit) return true;
    Toast.warning('Only directors and admins can change the catalog.');
    return false;
  }
}
