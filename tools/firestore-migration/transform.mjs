// Turns an export of the old Firestore database into rows for the Supabase
// schema. Pure: no network, no database, no clock. See README.md.
//
// Input (`dump`):
//   { documents: [{ path: 'organization/o1/branch/b1/...', data: {...} }, ...],
//     authUsers: [{ uid, email }, ...] }
// Timestamps in `data` must already be ISO-8601 strings.

import { createHash } from 'node:crypto';

const NAMESPACE = 'b3d1a1c0-5d1e-4a6b-9f0b-2f6a0f5e8c11';

/** Deterministic UUID (v5) so re-running the migration produces the same ids. */
export function uuidv5(name, namespace = NAMESPACE) {
  const hash = createHash('sha1').update(Buffer.from(namespace.replaceAll('-', ''), 'hex')).update(name).digest();
  hash[6] = (hash[6] & 0x0f) | 0x50;
  hash[8] = (hash[8] & 0x3f) | 0x80;
  const hex = hash.subarray(0, 16).toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/** Wall-clock date and time of an instant in [timeZone]. */
export function wallClock(iso, timeZone) {
  const parts = Object.fromEntries(
    new Intl.DateTimeFormat('en-CA', {
      timeZone,
      hourCycle: 'h23',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
    })
      .formatToParts(new Date(iso))
      .map((p) => [p.type, p.value]),
  );
  return { date: `${parts.year}-${parts.month}-${parts.day}`, time: `${parts.hour}:${parts.minute}:00` };
}

const utcDate = (iso) => new Date(iso).toISOString().slice(0, 10);

function parsePath(path) {
  const segments = path.split('/');
  const ancestors = {};
  for (let i = 0; i + 1 < segments.length; i += 2) ancestors[segments[i]] = segments[i + 1];
  return { collection: segments.at(-2), id: segments.at(-1), ancestors, depth: segments.length };
}

// The old app hard-coded these two cases in code; they are data now.
const CABIN_DISPLAY_NAMES = { Squirt: 'Ernie' };
const NO_PREFERENCE_REQUIRED_ACTIVITY_IDS = new Set(['teen_skills_rec-principal_activity-brn-zDbCdF6']);

const CATEGORY = {
  creative: 'creative',
  sportsAndAthletics: 'sports_and_athletics',
  waterfront: 'waterfront',
  campClassics: 'camp_classics',
  silly: 'silly',
  skills: 'skills',
  hidden: 'other',
};
const GENDERS = new Set(['M', 'F', 'NB']);
const ROLES = new Set(['root', 'director', 'admin', 'counselor']);

/**
 * @param dump see above
 * @param options.timeZone IANA zone of the computer that created the data (the old app stored
 *        local times as UTC). Required; there is no safe default.
 * @param options.organization name or old id to attach staff to when the dump has several.
 */
export function transform(dump, { timeZone, organization } = {}) {
  if (!timeZone) throw new Error('timeZone is required (e.g. "America/Los_Angeles")');
  new Intl.DateTimeFormat('en-US', { timeZone }); // throws on an invalid zone

  const warnings = [];
  const warn = (message) => warnings.push(message);
  const docs = dump.documents.map((d) => ({ ...parsePath(d.path), data: d.data }));
  const of = (collection) => docs.filter((d) => d.collection === collection);
  const newId = (oldId) => uuidv5(oldId);

  const plan = {
    organizations: [],
    branches: [],
    seasons: [],
    sessions: [],
    activities: [],
    cabins: [],
    session_cabins: [],
    schedule_days: [],
    blocks: [],
    scheduled_activities: [],
    campers: [],
    assignments: [],
    camper_preferences: [],
    staff: [],
    warnings,
  };

  // Organization hierarchy ------------------------------------------------
  for (const d of of('organization').filter((d) => d.depth === 2)) {
    plan.organizations.push({ id: newId(d.id), name: d.data.name });
  }
  for (const d of of('branch')) {
    plan.branches.push({ id: newId(d.id), organization_id: newId(d.ancestors.organization), name: d.data.name });
  }
  for (const d of of('season')) {
    plan.seasons.push({
      id: newId(d.id),
      branch_id: newId(d.ancestors.branch),
      name: d.data.name,
      starts_on: wallClock(d.data.start, timeZone).date,
      ends_on: wallClock(d.data.end, timeZone).date,
    });
  }
  for (const d of of('session')) {
    plan.sessions.push({
      id: newId(d.id),
      season_id: newId(d.ancestors.season),
      name: d.data.name,
      starts_on: wallClock(d.data.start, timeZone).date,
      max_requests: d.data.maxRequests ?? 0,
      max_vetoes: d.data.maxVetoes ?? 0,
      max_skills_requests: d.data.maxSkillsRequests ?? 0,
      max_skills_vetoes: d.data.maxSkillsVetoes ?? 0,
    });
  }

  // Catalog ---------------------------------------------------------------
  const usedActivityNames = new Set();
  const activityBranch = new Map();
  for (const d of of('principal_activity')) {
    let name = d.data.name;
    const key = (n) => `${d.ancestors.branch}|${n}`;
    for (let n = 2; usedActivityNames.has(key(name)); n++) {
      name = `${d.data.name} (${n})`;
      warn(`Activity "${d.data.name}" appears more than once in a branch; renamed to "${name}".`);
    }
    usedActivityNames.add(key(name));
    activityBranch.set(d.id, d.ancestors.branch);
    plan.activities.push({
      id: newId(d.id),
      branch_id: newId(d.ancestors.branch),
      name,
      description: d.data.description ?? '',
      capacity: Math.max(1, d.data.capacity ?? 1),
      category: CATEGORY[d.data.category] ?? 'other',
      is_skills_rec: !!d.data.isSkillsRec,
      double_schedule: !!d.data.doubleSchedule,
      max_assignments: d.data.maxAssignments ?? null,
      is_hidden: d.data.category === 'hidden',
      preference_required: !NO_PREFERENCE_REQUIRED_ACTIVITY_IDS.has(d.id),
    });
  }

  const cabinBranch = new Map();
  for (const d of of('principal_cabin')) {
    cabinBranch.set(d.id, d.ancestors.branch);
    plan.cabins.push({
      id: newId(d.id),
      branch_id: newId(d.ancestors.branch),
      name: d.data.name,
      display_name: CABIN_DISPLAY_NAMES[d.data.name] ?? null,
      village: d.data.village ?? '',
      capacity: Math.max(1, d.data.capacity ?? 1),
      position: d.data.index ?? 0,
    });
  }

  // Session cabins: a cabin_dependent links a catalog cabin to a session.
  const cabinOfDependent = new Map(); // old cabin_dependent id -> { session, cabin }
  const sessionCabinKeys = new Set();
  for (const d of of('cabin_dependent')) {
    const cabin = d.data.principalPar;
    if (!cabinBranch.has(cabin)) {
      warn(`Cabin registration ${d.id} points at a cabin that no longer exists; ignored.`);
      continue;
    }
    cabinOfDependent.set(d.id, { session: d.ancestors.session, cabin });
    const key = `${d.ancestors.session}|${cabin}`;
    if (sessionCabinKeys.has(key)) continue;
    sessionCabinKeys.add(key);
    plan.session_cabins.push({ session_id: newId(d.ancestors.session), cabin_id: newId(cabin) });
  }

  // Schedule ----------------------------------------------------------------
  const dayOfBlock = new Map();
  const dayDates = new Map(); // day old id -> date
  const usedDayKeys = new Set();
  for (const d of of('schedule_day')) {
    const date = wallClock(d.data.start, timeZone).date;
    const indexKey = `${d.ancestors.session}|i${d.data.dayIndex}`;
    const dateKey = `${d.ancestors.session}|${date}`;
    if (usedDayKeys.has(indexKey) || usedDayKeys.has(dateKey)) {
      warn(`Schedule day ${d.id} duplicates another day's index or date; skipped.`);
      continue;
    }
    usedDayKeys.add(indexKey);
    usedDayKeys.add(dateKey);
    dayDates.set(d.id, { date, session: d.ancestors.session });
    for (const blockId of d.data.blockCmps ?? []) dayOfBlock.set(blockId, d.id);
    plan.schedule_days.push({ id: newId(d.id), session_id: newId(d.ancestors.session), day_index: d.data.dayIndex, date });
  }

  const blockDay = new Map(); // block old id -> day old id (for the blocks we keep)
  const keptBlocks = []; // for the overlap check
  for (const d of of('ama_block')) {
    const start = wallClock(d.data.start, timeZone);
    const end = wallClock(d.data.end, timeZone);
    let dayId = dayOfBlock.get(d.id);
    if (!dayId) {
      dayId = [...dayDates].find(([, v]) => v.session === d.ancestors.session && v.date === start.date)?.[0];
    }
    if (!dayId) {
      warn(`Block "${d.data.title}" (${d.id}) isn't on any schedule day; skipped.`);
      continue;
    }
    if (end.time <= start.time || end.date !== start.date) {
      warn(`Block "${d.data.title}" (${d.id}) doesn't start and end on the same day; skipped.`);
      continue;
    }
    const clash = keptBlocks.find((b) => b.day === dayId && start.time < b.end && b.start < end.time);
    if (clash) {
      warn(`Block "${d.data.title}" (${d.id}) overlaps "${clash.title}" on the same day; skipped.`);
      continue;
    }
    keptBlocks.push({ day: dayId, start: start.time, end: end.time, title: d.data.title });
    blockDay.set(d.id, dayId);
    plan.blocks.push({
      id: newId(d.id),
      session_id: newId(d.ancestors.session),
      day_id: newId(dayId),
      title: d.data.title,
      start_time: start.time,
      end_time: end.time,
      is_skills_rec: !!d.data.isSkillsRec,
    });
  }

  const scheduledKeys = new Set();
  const scheduledInfo = new Map(); // activity_dependent old id -> { block, activity }
  for (const d of of('activity_dependent')) {
    const { principalPar: activity, blockRef: block } = d.data;
    if (!blockDay.has(block) || !activityBranch.has(activity)) {
      warn(`Scheduled activity ${d.id} refers to a missing block or activity; skipped.`);
      continue;
    }
    const key = `${block}|${activity}`;
    if (scheduledKeys.has(key)) {
      warn(`Activity scheduled twice in one block (${d.id}); kept the first.`);
      continue;
    }
    scheduledKeys.add(key);
    scheduledInfo.set(d.id, { block, activity });
    plan.scheduled_activities.push({
      id: newId(d.id),
      session_id: newId(d.ancestors.session),
      block_id: newId(block),
      activity_id: newId(activity),
    });
  }

  // Campers -----------------------------------------------------------------
  const identity = new Set();
  const ultracamp = new Set();
  const activityDependents = new Map(of('activity_dependent').map((d) => [d.id, d]));
  let refMismatches = 0;

  for (const d of of('camper')) {
    const c = d.data;
    const session = d.ancestors.session;
    const birthdate = utcDate(c.birthdate);
    const key = `${session}|${c.firstName.toLowerCase()}|${c.lastName.toLowerCase()}|${birthdate}`;
    if (identity.has(key)) {
      warn(`Camper ${c.firstName} ${c.lastName} (${birthdate}) is registered twice in a session; kept the first.`);
      continue;
    }
    identity.add(key);

    let ultracampId = c.ultracampId || null;
    if (ultracampId && ultracamp.has(`${session}|${ultracampId}`)) {
      warn(`UltraCamp id ${ultracampId} is used by two campers in a session; cleared on ${c.firstName} ${c.lastName}.`);
      ultracampId = null;
    }
    if (ultracampId) ultracamp.add(`${session}|${ultracampId}`);

    let cabinId = null;
    if (c.cabinRef) {
      const dependent = cabinOfDependent.get(c.cabinRef);
      if (dependent && dependent.session === session) cabinId = newId(dependent.cabin);
      else warn(`${c.firstName} ${c.lastName}'s cabin registration no longer exists; left without a cabin.`);
    }

    const preferences = Object.entries(c.preferenceRefs ?? {});
    const started = preferences.some(([, value]) => value !== null && value !== undefined);

    plan.campers.push({
      id: newId(d.id),
      session_id: newId(session),
      first_name: c.firstName.trim(),
      preferred_name: c.preferredName?.trim() || null,
      last_name: c.lastName.trim(),
      gender: GENDERS.has(c.gender) ? c.gender : null,
      birthdate,
      note: c.note ?? '',
      cabin_id: cabinId,
      ultracamp_id: ultracampId,
      arrived: !!c.arrived,
      can_swim: !!c.canSwim,
      activity_satisfaction_index: c.activitySatisfactionIndex ?? null,
      preferences_submitted_at: started ? (c.updatedAt ?? null) : null,
    });

    for (const [activity, value] of preferences) {
      if (!activityBranch.has(activity)) continue;
      const kind = value === 1 ? 'request' : value === 0 ? 'veto' : null;
      if (kind) {
        plan.camper_preferences.push({ session_id: newId(session), camper_id: newId(d.id), activity_id: newId(activity), kind });
      }
    }

    for (const [block, dependentId] of Object.entries(c.activityAssignmentRefs ?? {})) {
      if (!dependentId) continue;
      const info = scheduledInfo.get(dependentId);
      if (!info || info.block !== block) {
        warn(`${c.firstName} ${c.lastName} was assigned to an activity that no longer exists; assignment dropped.`);
        continue;
      }
      if (!activityDependents.get(dependentId)?.data.camperRefs?.includes(d.id)) refMismatches++;
      plan.assignments.push({
        session_id: newId(session),
        camper_id: newId(d.id),
        block_id: newId(block),
        scheduled_activity_id: newId(dependentId),
      });
    }
  }
  if (refMismatches > 0) {
    warn(`${refMismatches} assignments were recorded on the camper but not on the activity's roster; the camper's record was used.`);
  }

  // Staff ---------------------------------------------------------------------
  const emailByUid = new Map((dump.authUsers ?? []).map((u) => [u.uid, u.email]));
  const orgs = plan.organizations;
  const targetOrg = organization
    ? orgs.find((o) => o.name === organization || o.id === newId(organization))
    : orgs.length === 1
      ? orgs[0]
      : undefined;
  for (const d of of('core_user')) {
    const u = d.data;
    const email = emailByUid.get(u.firebaseUid);
    if (!email) {
      warn(`User ${u.firstName} ${u.lastName} has no email in Firebase Auth; skipped.`);
      continue;
    }
    if (!targetOrg) {
      warn(`User ${email} skipped: the dump has ${orgs.length} organizations; pass --organization to choose one.`);
      continue;
    }
    plan.staff.push({
      email,
      first_name: u.firstName,
      last_name: u.lastName,
      preferred_name: u.preferredName || null,
      role: ROLES.has(u.role) ? u.role : 'counselor',
      active: u.active !== false,
      deactivation_reason: u.deactivationReason ?? null,
      organization_id: targetOrg.id,
    });
  }

  plan.stats = Object.fromEntries(Object.entries(plan).filter(([, v]) => Array.isArray(v) && v !== warnings).map(([k, v]) => [k, v.length]));
  return plan;
}
