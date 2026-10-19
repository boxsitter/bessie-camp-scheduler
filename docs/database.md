# Database

Bessie runs on Postgres through [Supabase](https://supabase.com). Everything lives in
[`supabase/`](../supabase):

```
supabase/
├── config.toml          local stack settings (only the services Bessie uses are enabled)
├── migrations/          the schema, in order; the source of truth
├── seed.sql             demo data and three staff accounts, local `db reset` only
└── tests/database/      pgTAP tests (`supabase test db`)
```

## Running it locally

You need Docker and the [Supabase CLI](https://supabase.com/docs/guides/local-development/cli/getting-started).

```bash
supabase start          # Postgres, Auth, REST API, Realtime, Studio, a mail catcher
supabase db reset       # re-apply every migration and the seed (wipes local data)
supabase test db        # pgTAP tests
supabase db lint        # plpgsql static checks
supabase stop
```

| | URL |
|---|---|
| API | http://127.0.0.1:54321 |
| Studio (browse data, SQL editor) | http://127.0.0.1:54323 |
| Mail catcher (password-reset emails) | http://127.0.0.1:54324 |
| Postgres | `postgresql://postgres:postgres@127.0.0.1:54322/postgres` |

The Flutter app talks to the local stack by default (see `lib/src/core/app_config.dart`).

**Demo accounts** (created by `seed.sql`, password `password123`):
`director@bessie.test`, `admin@bessie.test`, `counselor@bessie.test`.

### Changing the schema

Add a **new** migration; never edit one that has been applied anywhere shared.

```bash
supabase migration new add_something      # creates supabase/migrations/<timestamp>_add_something.sql
supabase db reset                         # apply and re-seed
supabase test db
```

Remember when adding objects: enable RLS and add policies on every new table, `revoke … from public, anon` /
`grant … to authenticated` on every new function that should be callable through the API, and add the table to the
`supabase_realtime` publication if the app should receive live changes.

## Data model

```mermaid
erDiagram
    organizations ||--o{ branches : has
    organizations ||--o{ profiles : employs
    branches ||--o{ seasons : has
    branches ||--o{ activities : "catalog"
    branches ||--o{ cabins : "catalog"
    branches ||--o{ branch_block_templates : "weekly rhythm"
    seasons ||--o{ sessions : has
    sessions ||--o{ session_cabins : registers
    cabins ||--o{ session_cabins : ""
    sessions ||--o{ schedule_days : has
    schedule_days ||--o{ blocks : has
    blocks ||--o{ scheduled_activities : offers
    activities ||--o{ scheduled_activities : ""
    sessions ||--o{ campers : enrolls
    session_cabins |o--o{ campers : sleeps_in
    campers ||--o{ assignments : "one per block"
    scheduled_activities ||--o{ assignments : ""
    campers ||--o{ camper_preferences : "requests / vetoes"
    activities ||--o{ camper_preferences : ""
```

| Table | What it is |
|---|---|
| `organizations`, `branches`, `seasons`, `sessions` | The hierarchy. A *session* (e.g. a camp week) is where almost everything happens. Sessions carry the limits on how many activities a camper may request or veto. |
| `activities` | A branch's catalog of things campers can do: capacity, category, skills rec, double-block, max assignments, hidden, whether it needs ranking. |
| `cabins` | A branch's cabins; `display_name` replaces `name` when set. |
| `branch_block_templates` | The blocks every new session starts with, as day offsets and wall-clock times. |
| `session_cabins` | Which cabins a session uses. |
| `schedule_days`, `blocks` | The session's days and the slots within them. Times are wall-clock `time` values, not timestamps: the camp lives in one place. Blocks on one day can't overlap (exclusion constraint). |
| `scheduled_activities` | An activity offered during a block. |
| `campers` | The roster. Names + birthdate are unique per session; `preferences_submitted_at` records that a counselor saved the camper's wishes. |
| `assignments` | The camper's activity for a block. **Primary key `(camper_id, block_id)`**: a camper cannot be double-booked. |
| `camper_preferences` | Explicit requests and vetoes. Being flexible is the absence of a row. |
| `profiles` | Staff, one per Auth user: organization, role, active flag, UI preferences. |

### Integrity the database enforces

Composite foreign keys carry `session_id` through the schedule, so these are impossible rather than merely
unlikely:

* assigning a camper into another session's schedule,
* assigning a camper to a scheduled activity that isn't in that block,
* two activities for one camper in one block,
* overlapping blocks on a day,
* a cabin or activity from a different branch being used in a session (trigger).

Unscheduling an activity deletes exactly the assignments to it. Deregistering a cabin leaves its campers on the
roster without a cabin. An activity that is still scheduled can't be deleted from the catalog.

## Security

Row level security is on for every table, and `anon` has no privileges at all.

* Access is scoped to the organization on the caller's `profiles` row. A deactivated profile sees nothing.
* **Roles** (`staff_role`): `root` and `director` manage structure (branches, seasons) and other people;
  `admin` edits session data and the catalog; `counselor` is read-only but can save camper preferences.
* `profiles` can't be used for privilege escalation: a trigger stops anyone but a director changing roles,
  organization or active status.
* Sign-up is disabled. Staff are created with the service key (`scripts/create-staff-user.sh`); a trigger turns the
  user's `app_metadata` (`organization_id`, `role`) into the profile. `app_metadata` can only be written with the
  service key, never by the user.

Policies and helper predicates are in `20261019000400_row_level_security.sql`. The predicates live in a private
`app` schema that the API doesn't expose.

## RPCs

Operations that must be atomic or that need checks RLS can't express are Postgres functions, callable as
`POST /rest/v1/rpc/<name>`. They are `SECURITY INVOKER` (RLS applies) except `set_camper_preferences`, which runs
as definer so counselors can save wishes, and verifies membership itself.

| Function | Purpose |
|---|---|
| `create_session` | New session with its days, template blocks and (optionally) every cabin |
| `register_session_cabins` | Make a session's cabins exactly a given list |
| `import_campers` | Bulk-register roster rows; skips duplicates, reports unknown cabins |
| `swap_camper_cabins` | Send each selected camper to the other of exactly two cabins |
| `set_camper_preferences` | Replace a camper's requests/vetoes; enforces the session limits |
| `clear_camper_preferences` | Forget preferences |
| `assign_campers` / `unassign_campers` | Manual assignment (optionally enforcing capacity) |
| `apply_assignments` | Store an auto-assignment run in one transaction |
| `reset_session_assignments` | Wipe assignments (optionally preferences) for a session |

Errors raised on purpose use custom SQLSTATEs the app turns into friendly messages: `BS001` limit exceeded,
`BS002` capacity exceeded, `BS003` row doesn't belong there, `BS004` contradictory input.

## Realtime

`campers`, `assignments`, `camper_preferences`, `scheduled_activities`, `blocks` and `session_cabins` are in the
`supabase_realtime` publication (with `REPLICA IDENTITY FULL` so filtered subscriptions also see deletes). The roster
screen subscribes per session and refetches when anything changes, so several people can work at once.

## Moving an existing Firestore database over

See [`tools/firestore-migration`](../tools/firestore-migration/README.md).
