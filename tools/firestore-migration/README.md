# Firestore → Supabase migration

A one-off tool that copies an existing Bessie Firestore database into the Supabase schema. It is
split into three steps so you can inspect the result before anything is written:

1. **`extract`** reads Firestore (and the staff emails from Firebase Auth) into a JSON dump.
2. **`plan`** transforms the dump into relational rows and prints counts plus every data problem it found. Nothing is written.
3. **`load`** writes the rows to Postgres in a single transaction, then creates the staff accounts.

The transform (`transform.mjs`) is a pure function covered by tests (`npm test`).

## What changes on the way over

| Firestore (old) | Supabase (new) |
|---|---|
| String ids like `ada_l-camper-ses-AbC1234` | UUIDs, derived deterministically from the old id, so **re-running is idempotent** |
| `principal_activity` / `principal_cabin` | `activities` / `cabins` |
| `cabin_dependent`, `activity_dependent`, `ama_block` | `session_cabins`, `scheduled_activities`, `blocks` |
| `camper.activityAssignmentRefs` **and** `activity_dependent.camperRefs` (kept in sync by hand) | one `assignments` row per camper and block (the camper's record wins on disagreement) |
| `preferenceRefs` (0.0–1.0) | `camper_preferences`: exactly `1.0` → request, `0.0` → veto, everything else is neutral |
| `category: hidden` | `is_hidden = true`, category `other` |
| Hard-coded "Teen Skills Rec needs no ranking" id | `activities.preference_required = false` |
| Hard-coded `Squirt → Ernie` alias | `cabins.display_name` |
| Times stored as UTC but created as *local* times; birthdates at 21:00 UTC | wall-clock `date` / `time` columns |
| `refTracker`, `principalDependentLinkTracker`, `schedule` | gone: foreign keys do that job |
| `core_user` + Firebase Auth | Supabase Auth user + `profiles` |

Anything inconsistent in the old data (a dangling cabin, an assignment to a deleted activity, two campers with
the same name and birthday, overlapping blocks, duplicate UltraCamp ids…) is **skipped with a warning** rather
than failing the whole migration. Read the warnings.

## Running it

```bash
cd tools/firestore-migration
npm install                    # add --omit=optional if you won't run `extract` from this machine

# 1. Export. Needs a service-account key (Firebase console → Project settings → Service accounts).
node migrate.mjs extract --service-account ./key.json --out dump.json

# 2. Dry run. The time zone must be the one of the computer that created the data:
#    the old app stored local times as UTC and nothing in the data records which zone it was.
node migrate.mjs plan dump.json --timezone America/Los_Angeles

# 3. Load into an EMPTY Supabase project (run `supabase db reset` first locally, or `supabase db push`
#    on a new hosted project without running the demo seed).
node migrate.mjs load dump.json --timezone America/Los_Angeles \
  --database-url "postgresql://postgres:<password>@db.<ref>.supabase.co:5432/postgres" \
  --supabase-url https://<ref>.supabase.co --service-key "$SUPABASE_SERVICE_ROLE_KEY"
```

`load` refuses to run if the database already contains organizations that aren't in the dump (pass
`--allow-existing` to override, e.g. for experiments against the local demo data).

## Staff accounts and passwords

Firebase password hashes can't be copied with the Auth admin API, so each staff member is created with a random
password they are never told. Ask them to use **Forgot password** on the login screen to choose their own
(this needs outgoing email configured in Supabase). To keep existing passwords instead, use Supabase's
Firebase-scrypt user import before running `load`, and let `load` leave those emails alone (it skips users that
already exist).

## Limits

* `extract` talks to Firebase and could only be exercised against synthetic data; try it on a copy of your
  project first, and compare the counts in `plan` with the Firestore console.
* Session preference limits that were never set become `0` (that is what the old model defaulted to); set real
  values under *Session setup* afterwards.
