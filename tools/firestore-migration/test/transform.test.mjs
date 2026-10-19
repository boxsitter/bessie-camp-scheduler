import assert from 'node:assert/strict';
import { test } from 'node:test';

import { transform, uuidv5, wallClock } from '../transform.mjs';
import { fixture, ids } from './fixture.mjs';

const run = (options = {}) => transform(fixture(), { timeZone: 'America/Los_Angeles', ...options });
const byName = (rows, name) => rows.find((r) => r.name === name);

test('uuidv5 is deterministic and well-formed', () => {
  assert.equal(uuidv5('x'), uuidv5('x'));
  assert.notEqual(uuidv5('x'), uuidv5('y'));
  assert.match(uuidv5('x'), /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
});

test('wallClock converts stored UTC back to camp-local wall time', () => {
  assert.deepEqual(wallClock('2025-07-07T17:15:00.000Z', 'America/Los_Angeles'), { date: '2025-07-07', time: '10:15:00' });
  assert.deepEqual(wallClock('2025-12-07T18:15:00.000Z', 'America/Los_Angeles'), { date: '2025-12-07', time: '10:15:00' }, 'standard time');
  assert.deepEqual(wallClock('2025-07-07T07:00:00.000Z', 'UTC'), { date: '2025-07-07', time: '07:00:00' });
});

test('requires a valid time zone', () => {
  assert.throws(() => transform(fixture(), {}), /timeZone is required/);
  assert.throws(() => transform(fixture(), { timeZone: 'Mars/Olympus' }));
});

test('is deterministic, so re-running is idempotent', () => {
  assert.deepEqual(run(), run());
});

test('maps the hierarchy and uses the camp time zone for dates', () => {
  const plan = run();
  assert.equal(plan.organizations.length, 1);
  assert.equal(plan.branches[0].organization_id, plan.organizations[0].id);
  assert.equal(plan.seasons[0].starts_on, '2025-06-23');
  assert.equal(plan.seasons[0].ends_on, '2025-08-22');
  const session1 = byName(plan.sessions, 'Session 1');
  assert.equal(session1.season_id, plan.seasons[0].id);
  assert.equal(session1.starts_on, '2025-07-07');
  assert.equal(session1.max_requests, 3);
  assert.equal(byName(plan.sessions, 'Session 2').max_requests, 0, 'missing limits default to zero like the old model');
});

test('turns the hard-coded special cases into data', () => {
  const plan = run();
  assert.equal(byName(plan.cabins, 'Squirt').display_name, 'Ernie');
  assert.equal(byName(plan.cabins, 'Squirt').position, 2);
  assert.equal(byName(plan.cabins, 'Oak').display_name, null);
  assert.equal(byName(plan.activities, 'Teen Skills Rec').preference_required, false);
  assert.equal(byName(plan.activities, 'Pottery').preference_required, true);
});

test('maps activities', () => {
  const plan = run();
  const swimTest = byName(plan.activities, 'Swim Test');
  assert.equal(swimTest.is_hidden, true);
  assert.equal(swimTest.category, 'other');
  const swimming = byName(plan.activities, 'Swimming');
  assert.equal(swimming.category, 'waterfront');
  assert.equal(swimming.double_schedule, true);
  assert.equal(swimming.max_assignments, null);
  assert.equal(byName(plan.activities, 'Teen Skills Rec').is_skills_rec, true);
  assert.ok(byName(plan.activities, 'Pottery (2)'), 'duplicate names in a branch are made unique');
  assert.ok(plan.warnings.some((w) => w.includes('Pottery') && w.includes('renamed')));
});

test('session cabins come from cabin registrations and ignore dangling ones', () => {
  const plan = run();
  assert.equal(plan.session_cabins.length, 2);
  assert.ok(plan.warnings.some((w) => w.includes('no longer exists') && w.includes('Cabin registration')));
});

test('schedule: days, blocks in wall-clock time, overlaps rejected', () => {
  const plan = run();
  assert.deepEqual(plan.schedule_days.map((d) => [d.day_index, d.date]), [[0, '2025-07-07'], [1, '2025-07-08']]);
  const choice1 = byName(plan.blocks.map((b) => ({ ...b, name: b.title })), 'Choice Activity 1');
  assert.equal(choice1.start_time, '10:15:00');
  assert.equal(choice1.end_time, '11:15:00');
  assert.equal(choice1.day_id, plan.schedule_days[0].id);
  assert.equal(plan.blocks.length, 2, 'the overlapping block is dropped');
  assert.ok(plan.warnings.some((w) => w.includes('overlaps')));
  assert.equal(plan.scheduled_activities.length, 2);
});

test('campers: dates, cabins, genders and de-duplication', () => {
  const plan = run();
  assert.equal(plan.campers.length, 3, 'the duplicate Grace is dropped');
  const ada = plan.campers.find((c) => c.first_name === 'Ada');
  assert.equal(ada.birthdate, '2015-12-10', 'the 21:00Z storage hack still yields the right date');
  assert.equal(ada.gender, 'F');
  assert.equal(ada.preferred_name, null);
  assert.equal(ada.ultracamp_id, '1001');
  assert.equal(ada.cabin_id, byName(plan.cabins, 'Oak').id);

  const grace = plan.campers.find((c) => c.first_name === 'Grace');
  assert.equal(grace.preferred_name, 'Gracie');
  assert.equal(grace.gender, 'NB');
  assert.equal(grace.cabin_id, byName(plan.cabins, 'Squirt').id);
  assert.equal(grace.ultracamp_id, null, 'a duplicated UltraCamp id is cleared on the later camper');

  const lonely = plan.campers.find((c) => c.first_name === 'Lonely');
  assert.equal(lonely.gender, null);
  assert.equal(lonely.cabin_id, null);
  assert.ok(plan.warnings.some((w) => w.includes('registered twice')));
  assert.ok(plan.warnings.some((w) => w.includes('UltraCamp id 1001')));
});

test('preferences: only explicit requests and vetoes survive; "submitted" means the camper had started', () => {
  const plan = run();
  const ada = plan.campers.find((c) => c.first_name === 'Ada');
  const kinds = plan.camper_preferences.filter((p) => p.camper_id === ada.id).map((p) => p.kind).sort();
  assert.deepEqual(kinds, ['request', 'veto']);
  assert.equal(ada.preferences_submitted_at, '2025-07-01T12:00:00.000Z');
  assert.equal(plan.campers.find((c) => c.first_name === 'Grace').preferences_submitted_at, null);
});

test('assignments follow the camper record and drop dangling ones', () => {
  const plan = run();
  const ada = plan.campers.find((c) => c.first_name === 'Ada');
  const grace = plan.campers.find((c) => c.first_name === 'Grace');
  assert.equal(plan.assignments.length, 2);
  const adaAssignment = plan.assignments.find((a) => a.camper_id === ada.id);
  assert.equal(adaAssignment.block_id, plan.blocks.find((b) => b.title === 'Choice Activity 1').id);
  assert.equal(adaAssignment.scheduled_activity_id, plan.scheduled_activities.find((s) => s.activity_id === byName(plan.activities, 'Pottery').id).id);
  assert.ok(plan.assignments.find((a) => a.camper_id === grace.id), 'recorded only on the camper, still migrated');
  assert.ok(plan.warnings.some((w) => w.includes('no longer exists; assignment dropped')));
  assert.ok(plan.warnings.some((w) => w.includes('not on the activity') || w.includes("activity's roster")));
});

test('staff need an email and are attached to the organization', () => {
  const plan = run();
  assert.equal(plan.staff.length, 1);
  assert.deepEqual(plan.staff[0], {
    email: 'dana@example.com', first_name: 'Dana', last_name: 'Director', preferred_name: 'D', role: 'director',
    active: true, deactivation_reason: null, organization_id: plan.organizations[0].id,
  });
  assert.ok(plan.warnings.some((w) => w.includes('has no email')));
});

test('unknown roles become counselors', () => {
  const dump = fixture();
  dump.authUsers.push({ uid: 'uid-nobody', email: 'nobody@example.com' });
  const plan = transform(dump, { timeZone: 'UTC' });
  const nobody = plan.staff.find((s) => s.email === 'nobody@example.com');
  assert.equal(nobody.role, 'counselor');
  assert.equal(nobody.active, false);
});

test('stats count every table', () => {
  const plan = run();
  assert.equal(plan.stats.campers, 3);
  assert.equal(plan.stats.blocks, 2);
  assert.equal(plan.stats.assignments, 2);
});
