// A small Firestore export in the OLD app's shape (see the removed Dart models'
// toJson()). Times were created on a computer in America/Los_Angeles (UTC-7 in
// July), which is how the old app ended up storing local times as UTC.

const ORG = 'bessie-organization-rot-AAAAAAA';
const BRANCH = 'main-branch-org-BBBBBBB';
const SEASON = 'summer-season-brn-CCCCCCC';
const SESSION = 'session_1-session-sea-DDDDDDD';
const SESSION2 = 'session_2-session-sea-EEEEEEE';

const base = `organization/${ORG}/branch/${BRANCH}`;
const seasonPath = `${base}/season/${SEASON}`;
const sessionPath = `${seasonPath}/session/${SESSION}`;

const doc = (path, data) => ({ path, data: { id: path.split('/').at(-1), ...data } });

export const ids = {
  ORG, BRANCH, SEASON, SESSION, SESSION2,
  pottery: 'pottery-principal_activity-brn-P000001',
  swimming: 'swimming-principal_activity-brn-P000002',
  teenSkills: 'teen_skills_rec-principal_activity-brn-zDbCdF6',
  swimTest: 'swim_test-principal_activity-brn-P000004',
  oak: 'oak-principal_cabin-brn-K000001',
  squirt: 'squirt-principal_cabin-brn-K000002',
  oakDep: 'oak-cabin_dependent-ses-D000001',
  squirtDep: 'squirt-cabin_dependent-ses-D000002',
  day0: '0_monday-schedule_day-ses-Y000000',
  day1: '1_tuesday-schedule_day-ses-Y000001',
  choice1: 'choice_activity_1-ama_block-ses-B000001',
  choice2: 'choice_activity_2-ama_block-ses-B000002',
  overlapping: 'overlapping-ama_block-ses-B000003',
  potteryDep: 'pottery-activity_dependent-ses-S000001',
  swimmingDep: 'swimming-activity_dependent-ses-S000002',
  ada: 'ada_l-camper-ses-C000001',
  grace: 'grace_h-camper-ses-C000002',
  graceDupe: 'grace_h-camper-ses-C000003',
  lonely: 'lonely_x-camper-ses-C000004',
  staff: 'dana_d-core_user-rot-U000001',
  staffNoEmail: 'nobody_n-core_user-rot-U000002',
};

export function fixture() {
  const camperBase = { gender: 'F', note: '', arrived: true, canSwim: true, activitySatisfactionIndex: 0.8, preferredName: '', ultracampId: null, cabinRef: null };
  const documents = [
    doc(`organization/${ORG}`, { name: 'Bessie Camp' }),
    doc(base, { name: 'Main Camp' }),
    doc(seasonPath, { name: 'Summer 2025', start: '2025-06-23T07:00:00.000Z', end: '2025-08-22T07:00:00.000Z' }),
    doc(sessionPath, { name: 'Session 1', start: '2025-07-07T07:00:00.000Z', maxRequests: 3, maxVetoes: 2, maxSkillsRequests: 1, maxSkillsVetoes: 1, refTracker: {}, principalDependentLinkTracker: {} }),
    doc(`${seasonPath}/session/${SESSION2}`, { name: 'Session 2', start: '2025-07-14T07:00:00.000Z' }),

    doc(`${base}/principal_activity/${ids.pottery}`, { name: 'Pottery', capacity: 8, description: 'Clay', isSkillsRec: false, doubleSchedule: false, maxAssignments: 2, category: 'creative' }),
    doc(`${base}/principal_activity/${ids.swimming}`, { name: 'Swimming', capacity: 24, description: '', isSkillsRec: false, doubleSchedule: true, maxAssignments: null, category: 'waterfront' }),
    doc(`${base}/principal_activity/${ids.teenSkills}`, { name: 'Teen Skills Rec', capacity: 16, description: '', isSkillsRec: true, category: 'skills' }),
    doc(`${base}/principal_activity/${ids.swimTest}`, { name: 'Swim Test', capacity: 6, description: '', isSkillsRec: false, category: 'hidden' }),
    doc(`${base}/principal_activity/pottery-principal_activity-brn-P000009`, { name: 'Pottery', capacity: 4, description: 'Duplicate name', isSkillsRec: false, category: 'creative' }),
    doc(`${base}/principal_cabin/${ids.oak}`, { name: 'Oak', capacity: 10, village: 'Pines', index: 1 }),
    doc(`${base}/principal_cabin/${ids.squirt}`, { name: 'Squirt', capacity: 8, village: 'Meadow', index: 2 }),

    doc(`${sessionPath}/cabin_dependent/${ids.oakDep}`, { principalPar: ids.oak, camperRefs: [ids.ada] }),
    doc(`${sessionPath}/cabin_dependent/${ids.squirtDep}`, { principalPar: ids.squirt, camperRefs: [ids.grace] }),
    doc(`${sessionPath}/cabin_dependent/ghost-cabin_dependent-ses-D000009`, { principalPar: 'gone-principal_cabin-brn-K000099', camperRefs: [] }),

    doc(`${sessionPath}/schedule`, { scheduleDayCmps: [ids.day0, ids.day1] }),
    doc(`${sessionPath}/schedule_day/${ids.day0}`, { dayIndex: 0, start: '2025-07-07T07:00:00.000Z', blockCmps: [ids.choice1, ids.choice2] }),
    doc(`${sessionPath}/schedule_day/${ids.day1}`, { dayIndex: 1, start: '2025-07-08T07:00:00.000Z', blockCmps: [] }),
    // 10:15-11:15 and 11:20-12:20 local (UTC-7).
    doc(`${sessionPath}/ama_block/${ids.choice1}`, { title: 'Choice Activity 1', isTemplate: false, start: '2025-07-07T17:15:00.000Z', end: '2025-07-07T18:15:00.000Z', isSkillsRec: false, activityDependentCmps: [ids.potteryDep] }),
    doc(`${sessionPath}/ama_block/${ids.choice2}`, { title: 'Choice Activity 2', isTemplate: false, start: '2025-07-07T18:20:00.000Z', end: '2025-07-07T19:20:00.000Z', isSkillsRec: false, activityDependentCmps: [ids.swimmingDep] }),
    doc(`${sessionPath}/ama_block/${ids.overlapping}`, { title: 'Overlaps Choice 1', isTemplate: false, start: '2025-07-07T17:30:00.000Z', end: '2025-07-07T18:00:00.000Z', isSkillsRec: false, activityDependentCmps: [] }),
    doc(`${sessionPath}/activity_dependent/${ids.potteryDep}`, { principalPar: ids.pottery, blockRef: ids.choice1, camperRefs: [ids.ada] }),
    doc(`${sessionPath}/activity_dependent/${ids.swimmingDep}`, { principalPar: ids.swimming, blockRef: ids.choice2, camperRefs: [] }),

    // Ada: in Oak, assigned pottery, requested pottery, vetoed swimming. Birthdates are stored 21:00 UTC.
    doc(`${sessionPath}/camper/${ids.ada}`, { ...camperBase, firstName: 'Ada', lastName: 'Lovelace', birthdate: '2015-12-10T21:00:00.000Z', cabinRef: ids.oakDep, ultracampId: '1001',
      preferenceRefs: { [ids.pottery]: 1.0, [ids.swimming]: 0.0, [ids.teenSkills]: null }, preferenceWeightRefs: { [ids.pottery]: 1.0 },
      activityAssignmentRefs: { [ids.choice1]: ids.potteryDep, [ids.choice2]: null }, updatedAt: '2025-07-01T12:00:00.000Z' }),
    // Grace: in Squirt, never ranked, assignment recorded only on her side.
    doc(`${sessionPath}/camper/${ids.grace}`, { ...camperBase, gender: 'NB', preferredName: 'Gracie', firstName: 'Grace', lastName: 'Hopper', birthdate: '2014-01-02T21:00:00.000Z', cabinRef: ids.squirtDep, ultracampId: '1001',
      preferenceRefs: { [ids.pottery]: null }, activityAssignmentRefs: { [ids.choice2]: ids.swimmingDep } }),
    doc(`${sessionPath}/camper/${ids.graceDupe}`, { ...camperBase, firstName: 'grace', lastName: 'HOPPER', birthdate: '2014-01-02T21:00:00.000Z', preferenceRefs: {}, activityAssignmentRefs: {} }),
    // Lonely: dangling cabin, an assignment to an activity that was deleted, odd gender.
    doc(`${sessionPath}/camper/${ids.lonely}`, { ...camperBase, gender: '', firstName: 'Lonely', lastName: 'Xavier', birthdate: '2016-05-05T21:00:00.000Z', cabinRef: 'old-cabin_dependent-ses-D000077',
      preferenceRefs: {}, activityAssignmentRefs: { [ids.choice1]: 'deleted-activity_dependent-ses-S000099' } }),

    doc(`core_user/${ids.staff}`, { firebaseUid: 'uid-dana', firstName: 'Dana', lastName: 'Director', preferredName: 'D', note: '', role: 'director', active: true, deactivationReason: null, frontendPrefs: {} }),
    doc(`core_user/${ids.staffNoEmail}`, { firebaseUid: 'uid-nobody', firstName: 'No', lastName: 'Body', role: 'nullRole', active: false }),
  ];
  return { documents, authUsers: [{ uid: 'uid-dana', email: 'dana@example.com' }] };
}
