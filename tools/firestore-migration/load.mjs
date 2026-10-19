// Writes a transform() plan into the Supabase database. All table data goes in
// ONE transaction (all or nothing); staff accounts are then created through
// the Auth admin API, because passwords can't be copied from Firebase.

import { randomBytes } from 'node:crypto';
import pg from 'pg';

// Parents before children. Types are what jsonb_to_recordset needs.
export const TABLES = [
  ['organizations', ['id uuid', 'name text']],
  ['branches', ['id uuid', 'organization_id uuid', 'name text']],
  ['seasons', ['id uuid', 'branch_id uuid', 'name text', 'starts_on date', 'ends_on date']],
  ['sessions', ['id uuid', 'season_id uuid', 'name text', 'starts_on date', 'max_requests int', 'max_vetoes int', 'max_skills_requests int', 'max_skills_vetoes int']],
  ['activities', ['id uuid', 'branch_id uuid', 'name text', 'description text', 'capacity int', 'category public.activity_category', 'is_skills_rec boolean', 'double_schedule boolean', 'max_assignments int', 'is_hidden boolean', 'preference_required boolean']],
  ['cabins', ['id uuid', 'branch_id uuid', 'name text', 'display_name text', 'village text', 'capacity int', 'position int']],
  ['session_cabins', ['session_id uuid', 'cabin_id uuid']],
  ['schedule_days', ['id uuid', 'session_id uuid', 'day_index smallint', 'date date']],
  ['blocks', ['id uuid', 'session_id uuid', 'day_id uuid', 'title text', 'start_time time', 'end_time time', 'is_skills_rec boolean']],
  ['scheduled_activities', ['id uuid', 'session_id uuid', 'block_id uuid', 'activity_id uuid']],
  ['campers', ['id uuid', 'session_id uuid', 'first_name text', 'preferred_name text', 'last_name text', 'gender text', 'birthdate date', 'note text', 'cabin_id uuid', 'ultracamp_id text', 'arrived boolean', 'can_swim boolean', 'activity_satisfaction_index real', 'preferences_submitted_at timestamptz']],
  ['assignments', ['session_id uuid', 'camper_id uuid', 'block_id uuid', 'scheduled_activity_id uuid']],
  ['camper_preferences', ['session_id uuid', 'camper_id uuid', 'activity_id uuid', 'kind public.preference_kind']],
];

export function insertStatement(table, columns) {
  const names = columns.map((c) => c.split(' ')[0]).join(', ');
  return `insert into public.${table} (${names}) select ${names} from jsonb_to_recordset($1::jsonb) as x(${columns.join(', ')}) on conflict do nothing`;
}

export async function load(plan, { databaseUrl, supabaseUrl, serviceKey, allowExisting = false, log = console.log }) {
  const client = new pg.Client({ connectionString: databaseUrl });
  await client.connect();
  try {
    const planned = new Set(plan.organizations.map((o) => o.id));
    const { rows } = await client.query('select id from public.organizations');
    const foreign = rows.filter((r) => !planned.has(r.id));
    if (foreign.length > 0 && !allowExisting) {
      throw new Error(
        `The database already contains ${foreign.length} other organization(s). Run this against an empty database, ` +
          'or pass --allow-existing if you know what you are doing.',
      );
    }

    await client.query('begin');
    try {
      for (const [table, columns] of TABLES) {
        const result = await client.query(insertStatement(table, columns), [JSON.stringify(plan[table])]);
        log(`  ${table}: ${result.rowCount} of ${plan[table].length} rows inserted`);
      }
      await client.query('commit');
    } catch (error) {
      await client.query('rollback');
      throw error;
    }

    if (plan.staff.length > 0) {
      if (!supabaseUrl || !serviceKey) {
        log(`Skipping ${plan.staff.length} staff accounts (pass --supabase-url and --service-key to create them).`);
      } else {
        await createStaff(plan.staff, { client, supabaseUrl, serviceKey, log });
      }
    }
  } finally {
    await client.end();
  }
}

async function createStaff(staff, { client, supabaseUrl, serviceKey, log }) {
  log('Creating staff accounts:');
  for (const person of staff) {
    const password = randomBytes(12).toString('base64url');
    const response = await fetch(`${supabaseUrl}/auth/v1/admin/users`, {
      method: 'POST',
      headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: person.email,
        password,
        email_confirm: true,
        user_metadata: { first_name: person.first_name, last_name: person.last_name, preferred_name: person.preferred_name },
        app_metadata: { organization_id: person.organization_id, role: person.role },
      }),
    });
    if (response.status === 422) {
      log(`  ${person.email}: already exists, left unchanged`);
      continue;
    }
    if (!response.ok) throw new Error(`Creating ${person.email} failed (HTTP ${response.status}): ${await response.text()}`);
    const { id } = await response.json();
    if (!person.active) {
      await client.query('update public.profiles set active = false, deactivation_reason = $2 where id = $1', [id, person.deactivation_reason]);
    }
    log(`  ${person.email}: created as ${person.role} (they should use "Forgot password" to set their own password)`);
  }
}
