-- Organization hierarchy and the per-branch catalog (activities, cabins,
-- weekly block template) plus staff profiles.
--
--   organizations 1─* branches 1─* seasons 1─* sessions
--                        │
--                        ├─* activities            (what campers can do)
--                        ├─* cabins                (where campers sleep)
--                        └─* branch_block_templates (a session's weekly rhythm)

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (btrim(name) <> ''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (name)
);

create table public.branches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, name)
);
create index branches_organization_id_idx on public.branches (organization_id);

create table public.seasons (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  starts_on date not null,
  ends_on date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (ends_on >= starts_on),
  unique (branch_id, name)
);
create index seasons_branch_id_idx on public.seasons (branch_id);

create table public.sessions (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.seasons (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  starts_on date not null,
  -- How many activities a camper may request / veto. "Skills recs" are
  -- limited separately from the standard choice activities.
  max_requests integer not null default 3 check (max_requests >= 0),
  max_vetoes integer not null default 2 check (max_vetoes >= 0),
  max_skills_requests integer not null default 2 check (max_skills_requests >= 0),
  max_skills_vetoes integer not null default 1 check (max_skills_vetoes >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (season_id, name)
);
create index sessions_season_id_idx on public.sessions (season_id);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  description text not null default '',
  -- Campers per scheduled instance of the activity.
  capacity integer not null check (capacity > 0),
  category public.activity_category not null default 'other',
  is_skills_rec boolean not null default false,
  -- Occupies two consecutive blocks on the same day.
  double_schedule boolean not null default false,
  -- Most times one camper may be assigned to this activity in a session.
  max_assignments integer check (max_assignments is null or max_assignments > 0),
  -- Hidden activities keep campers busy during a block but are never offered
  -- for preferences and never auto-assigned (e.g. swim tests).
  is_hidden boolean not null default false,
  -- False for activities campers are slotted into without ranking them.
  preference_required boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (branch_id, name)
);
create index activities_branch_id_idx on public.activities (branch_id);

create table public.cabins (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  name text not null check (btrim(name) <> ''),
  -- Shown instead of `name` when set (e.g. the name campers actually use).
  display_name text check (display_name is null or btrim(display_name) <> ''),
  village text not null default '',
  capacity integer not null check (capacity > 0),
  position integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (branch_id, name)
);
create index cabins_branch_id_idx on public.cabins (branch_id);

-- The blocks every new session starts with, as offsets from its first day.
create table public.branch_block_templates (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches (id) on delete cascade,
  day_offset smallint not null check (day_offset between 0 and 13),
  title text not null check (btrim(title) <> ''),
  start_time time not null,
  end_time time not null,
  is_skills_rec boolean not null default false,
  check (end_time > start_time),
  unique (branch_id, day_offset, start_time)
);
create index branch_block_templates_branch_id_idx on public.branch_block_templates (branch_id);

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  organization_id uuid not null references public.organizations (id) on delete restrict,
  first_name text not null check (btrim(first_name) <> ''),
  last_name text not null check (btrim(last_name) <> ''),
  preferred_name text check (preferred_name is null or btrim(preferred_name) <> ''),
  note text not null default '',
  role public.staff_role not null default 'counselor',
  active boolean not null default true,
  deactivation_reason text,
  -- Per-user UI settings (table columns, view toggles, ...).
  preferences jsonb not null default '{}'::jsonb check (jsonb_typeof(preferences) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index profiles_organization_id_idx on public.profiles (organization_id);

create trigger touch_updated_at before update on public.organizations for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.branches for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.seasons for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.sessions for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.activities for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.cabins for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.profiles for each row execute function app.touch_updated_at();

-- Staff are provisioned by an administrator through the Auth admin API (sign-up
-- is disabled). The profile is derived from `app_metadata` (writable only with
-- the service key) and `user_metadata` (names only).
create function app.handle_new_user() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid;
begin
  v_org := nullif(new.raw_app_meta_data ->> 'organization_id', '')::uuid;
  if v_org is null then
    return new; -- not a staff account; it simply has no access
  end if;

  insert into public.profiles (id, organization_id, first_name, last_name, preferred_name, role)
  values (
    new.id,
    v_org,
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'first_name'), ''), 'New'),
    coalesce(nullif(btrim(new.raw_user_meta_data ->> 'last_name'), ''), 'User'),
    nullif(btrim(new.raw_user_meta_data ->> 'preferred_name'), ''),
    coalesce(nullif(new.raw_app_meta_data ->> 'role', '')::public.staff_role, 'counselor')
  );
  return new;
end
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_user();
