import 'package:bessie/src/shared/widgets/context_switcher/controller/session_selector_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../cli/support/fake_services.dart';

void main() {
  late TestWorld world;
  late SessionSelectorController controller;

  setUp(() {
    world = TestWorld(
      sessions: [campSession('s1', 'Session 1', DateTime(2026, 6, 15)), campSession('s2', 'Session 2', DateTime(2026, 7, 6))],
    )..loadSeason();
    controller = SessionSelectorController(context: world.context);
  });

  test('exposes the season\'s sessions and the current season and session names', () {
    expect(controller.sessions.map((s) => s.name), ['Session 1', 'Session 2']);
    expect(controller.seasonName, 'Summer 2026');
    expect(controller.sessionName, 'Session 1');
  });

  test('follows the context when the session changes elsewhere', () async {
    await world.context.switchSession('s2');

    expect(controller.sessionName, 'Session 2');
  });

  test('says there is no session when none is selected', () {
    world.context.session.value = null;
    world.context.season.value = null;

    expect(controller.sessionName, 'No session');
    expect(controller.seasonName, '');
  });

  test('the sessions list is the context\'s own reactive list', () {
    expect(controller.sessions, same(world.context.sessions));
  });

  test('a new choice starts at the current session, which cannot be "switched" to', () {
    controller.beginSelection();

    expect(controller.selectedSessionId.value, 's1');
    expect(controller.canSwitch, isFalse);
  });

  test('choosing another session enables switching, and switching changes the context only', () async {
    controller.beginSelection();
    controller.select('s2');
    expect(controller.canSwitch, isTrue);

    expect(await controller.switchToSelected(), isTrue);
    expect(world.context.session.value?.id, 's2');
    expect(controller.canSwitch, isFalse);
    expect(controller.isSwitching.value, isFalse);
  });

  test('a session that has disappeared is reported, not switched to', () async {
    controller.select('gone');

    expect(await controller.switchToSelected(), isFalse);
    expect(world.context.session.value?.id, 's1');
    expect(controller.isSwitching.value, isFalse);
  });

  test('switching with nothing chosen does nothing', () async {
    controller.select(null);

    expect(controller.canSwitch, isFalse);
    expect(await controller.switchToSelected(), isFalse);
  });
}
