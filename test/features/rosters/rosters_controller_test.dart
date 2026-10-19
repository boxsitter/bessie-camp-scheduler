import 'package:bessie/src/features/rosters/controllers/rosters_controller.dart';
import 'package:bessie/src/features/rosters/models/roster_column.dart';
import 'package:bessie/src/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

import 'roster_fixtures.dart';
import 'roster_harness.dart';

void main() {
  late RostersHarness h;

  final ada = makeCamper(first: 'Ada', last: 'Lovelace', cabinId: 'c1');
  final bo = makeCamper(first: 'Bo', last: 'Brown', arrived: true);
  final cy = makeCamper(first: 'Cy', last: 'Green');

  RostersController controller() => h.controller;

  setUp(() => h = RostersHarness());
  tearDown(() => h.dispose());

  test('shows nothing to load until a session is selected', () async {
    controller().activate();
    await pumpEventQueue();
    expect(controller().hasSession, isFalse);
    expect(controller().loading, isFalse);
    expect(h.roster.watched, isEmpty);
  });

  test('loads the schedule and cabins and watches the live roster of the session', () async {
    h.auth.profile.value = fakeProfile(StaffRole.director);
    h.context.session.value = fakeSession('s1');
    controller().onNavigateTo('/', null);
    await pumpEventQueue();

    expect(h.roster.watched, ['s1']);
    expect(controller().loading, isTrue, reason: 'the roster has not been emitted yet');

    h.roster.latest.add([cy, ada, bo]);
    await pumpEventQueue();

    expect(controller().loading, isFalse);
    expect(controller().schedule.blocks.single.id, 's1-b1');
    expect(controller().filteredCampers.map((c) => c.firstName), ['Bo', 'Cy', 'Ada'], reason: 'sorted by last name');
    expect(controller().view.text(ada, const FieldColumn(RosterField.cabin)), 'Eagles');
  });

  test('does not start a second watch while one is running, and stops watching when leaving the page', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().onNavigateTo('/', null);
    controller().activate();
    await pumpEventQueue();
    expect(h.roster.watched, hasLength(1));

    controller().onNavigateFrom('/', '/schedule-page');
    await pumpEventQueue();
    expect(h.roster.cancelled, 1);

    controller().onNavigateTo('/', '/schedule-page');
    await pumpEventQueue();
    expect(h.roster.watched, ['s1', 's1']);
  });

  test('stops watching when the controller is closed', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().onClose();
    await pumpEventQueue();
    expect(h.roster.cancelled, 1);
  });

  test('keeps the selection when the roster is emitted again and drops campers that are gone', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().toggleSelection(ada);
    controller().toggleSelection(bo);
    expect(controller().selectedIds, {ada.id, bo.id});

    h.roster.latest.add([ada, bo, cy]);
    await pumpEventQueue();
    expect(controller().selectedIds, {ada.id, bo.id});

    h.roster.latest.add([ada, cy]);
    await pumpEventQueue();
    expect(controller().selectedIds, {ada.id});
    expect(controller().selectedCampers.single.firstName, 'Ada');
  });

  test('reloads for the new session and forgets the old selection', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().addColumn(BlockColumn(controller().schedule.blocks.single));
    controller().toggleSelection(ada);

    h.context.session.value = fakeSession('s2');
    await pumpEventQueue();

    expect(h.roster.watched, ['s1', 's2']);
    expect(h.roster.cancelled, 1);
    expect(controller().selectedIds, isEmpty);
    expect(controller().campers, isEmpty);
    expect(controller().loading, isTrue);

    h.roster.latest.add([bo]);
    await pumpEventQueue();
    expect(controller().loading, isFalse);
    expect(controller().campers.single.firstName, 'Bo');
    expect(controller().schedule.blocks.single.id, 's2-b1');
    final block = controller().columns.whereType<BlockColumn>().single;
    expect(block.block.id, 's2-b1', reason: 'the block column follows the equivalent block of the new session');
  });

  test('a session change while another page is showing is picked up when the page returns', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().onNavigateFrom('/', '/schedule-page');
    h.context.session.value = fakeSession('s2');
    await pumpEventQueue();
    expect(h.roster.watched, ['s1'], reason: 'nothing is watched while the page is hidden');

    controller().onNavigateTo('/', '/schedule-page');
    await pumpEventQueue();
    expect(h.roster.watched, ['s1', 's2']);
  });

  test('searching filters after a short delay', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().setSearchQuery('lace');
    expect(controller().filteredCampers, hasLength(3), reason: 'debounced');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(controller().filteredCampers.map((c) => c.firstName), ['Ada']);
    expect(controller().noMatches, isFalse);

    controller().setSearchQuery('nobody');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(controller().noMatches, isTrue);
  });

  test('choosing the sorted column again flips the direction and a new column starts ascending', () async {
    await h.start(campers: [cy, ada, bo]);
    expect(controller().sortBy, RosterColumns.lastName);
    controller().setSortBy(RosterColumns.lastName);
    expect(controller().sortDirection, SortDirection.desc);
    expect(controller().filteredCampers.map((c) => c.firstName), ['Ada', 'Cy', 'Bo']);
    controller().setSortBy(const FieldColumn(RosterField.age));
    expect(controller().sortDirection, SortDirection.asc);
  });

  test('select all, group selection and invert work on what is shown', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().setGroupBy(const FieldColumn(RosterField.arrived));
    expect(controller().groups.map((g) => g.title), ['No', 'Yes']);

    controller().toggleSelectGroup(controller().groups.first);
    expect(controller().selectedIds, {ada.id, cy.id});
    expect(controller().groupSelectionState(controller().groups.first), isTrue);
    expect(controller().groupSelectionState(controller().groups.last), isFalse);

    controller().invertSelection();
    expect(controller().selectedIds, {bo.id});

    controller().toggleSelectAll();
    expect(controller().selectedIds, isEmpty, reason: 'something was selected, so select-all unselects');
    controller().toggleSelectAll();
    expect(controller().allVisibleSelected, isTrue);
  });

  test('toggle arrived marks everyone arrived when anyone has not arrived', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().toggleSelection(ada);
    controller().toggleSelection(bo);
    await controller().toggleArrived();
    expect(h.roster.arrivedCalls.single.$1, unorderedEquals([ada.id, bo.id]));
    expect(h.roster.arrivedCalls.single.$2, isTrue);
  });

  test('toggle arrived marks everyone not arrived when they all have', () async {
    await h.start(campers: [cy, ada, bo]);
    controller().toggleSelection(bo);
    await controller().toggleArrived();
    expect(h.roster.arrivedCalls.single.$2, isFalse);
  });

  test('counselors cannot write: nothing reaches the repository', () async {
    await h.start(role: StaffRole.counselor, campers: [cy, ada, bo]);
    expect(controller().canEdit, isFalse);
    controller().toggleSelection(ada);
    await controller().toggleArrived();
    await controller().deleteSelected();
    await controller().unassignSelectedFromAll();
    expect(h.roster.arrivedCalls, isEmpty);
    expect(h.roster.deleteCalls, isEmpty);
  });

  test('the activity switcher plans changes for the selected campers', () async {
    final schedule = makeSchedule(
      blocks: [makeBlock('b1', 'AM1')],
      activities: [makeActivity('a1', 'Archery'), makeActivity('a2', 'Canoeing')],
      scheduled: {'s-a1': ('b1', 'a1'), 's-a2': ('b1', 'a2')},
    );
    h.sessions.schedules['s1'] = schedule;
    await h.start(
      campers: [
        makeCamper(first: 'Ada', last: 'Lovelace', assignments: {'b1': 's-a1'}),
        makeCamper(first: 'Bo', last: 'Brown'),
      ],
    );
    final c = controller();
    final ada = c.campers.firstWhere((camper) => camper.firstName == 'Ada');
    final bo = c.campers.firstWhere((camper) => camper.firstName == 'Bo');

    c.selectBlock(c.schedule.blocks.single);
    c.selectScheduled(schedule.scheduledActivityById('s-a2')!);
    expect(c.plannedChange(ada)?.from, 'Archery');
    expect(c.plannedChange(ada)?.to, 'Canoeing');
    expect(c.plannedChange(bo)?.from, isNull);
    expect(c.plannedChange(bo)?.to, 'Canoeing');
    expect(c.selectedBlockActivities.map(c.activityName), ['Archery', 'Canoeing']);

    c.selectScheduled(schedule.scheduledActivityById('s-a1')!);
    expect(c.plannedChange(ada), isNull, reason: 'already in it');
  });
}
