-- Everything that belongs to a single session: its cabins, schedule, campers,
-- their assignments and their preferences.
--
-- Composite foreign keys carry `session_id` through the whole graph so the
-- database itself guarantees that, for example, a camper is never assigned to
-- a block from another session, or to a scheduled activity that isn't in that
-- block. This replaces the old hand-maintained reference tracker.

create table public.session_cabins (
  session_id uuid not null references public.sessions (id) on delete cascade,
  cabin_id uuid not null references public.cabins (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (session_id, cabin_id)
);
create index session_cabins_cabin_id_idx on public.session_cabins (cabin_id);

create table public.schedule_days (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  day_index smallint not null check (day_index >= 0),
  date date not null,
  unique (session_id, day_index),
  unique (session_id, date),
  unique (id, session_id)
);

-- A block is a slot in a day that campers are assigned an activity for.
-- Times are wall-clock times at camp, deliberately not timestamptz: the camp
-- lives in one place and timezone conversion only ever produced bugs.
create table public.blocks (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null,
  day_id uuid not null,
  title text not null check (btrim(title) <> ''),
  start_time time not null,
  end_time time not null,
  is_skills_rec boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (end_time > start_time),
  foreign key (day_id, session_id) references public.schedule_days (id, session_id) on delete cascade,
  unique (id, session_id),
  -- Blocks on the same day may not overlap.
  exclude using gist (
    day_id with =,
    tsrange(date '2000-01-01' + start_time, date '2000-01-01' + end_time, '[)') with &&
  )
);
create index blocks_session_id_idx on public.blocks (session_id);
create index blocks_day_id_idx on public.blocks (day_id);

-- An activity offered during a specific block.
create table public.scheduled_activities (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null,
  block_id uuid not null,
  -- Restrict: unschedule an activity everywhere before deleting it.
  activity_id uuid not null references public.activities (id) on delete restrict,
  created_at timestamptz not null default now(),
  foreign key (block_id, session_id) references public.blocks (id, session_id) on delete cascade,
  unique (block_id, activity_id),
  unique (id, block_id),
  unique (id, session_id)
);
create index scheduled_activities_session_id_idx on public.scheduled_activities (session_id);
create index scheduled_activities_activity_id_idx on public.scheduled_activities (activity_id);

create table public.campers (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions (id) on delete cascade,
  first_name text not null check (btrim(first_name) <> ''),
  preferred_name text check (preferred_name is null or btrim(preferred_name) <> ''),
  last_name text not null check (btrim(last_name) <> ''),
  gender text check (gender in ('M', 'F', 'NB')),
  birthdate date not null,
  note text not null default '',
  cabin_id uuid,
  ultracamp_id text check (ultracamp_id is null or btrim(ultracamp_id) <> ''),
  arrived boolean not null default false,
  can_swim boolean not null default false,
  -- Written by the auto-assignment run; see apply_assignments().
  activity_satisfaction_index real check (activity_satisfaction_index between 0 and 1),
  -- Set when a counselor has saved this camper's preferences (even if the
  -- camper chose to be flexible about everything).
  preferences_submitted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, session_id),
  -- A camper can only be in a cabin that is registered for their session.
  -- Deregistering a cabin leaves its campers cabin-less rather than deleting them.
  foreign key (session_id, cabin_id) references public.session_cabins (session_id, cabin_id)
    on delete set null (cabin_id)
);
create index campers_session_id_idx on public.campers (session_id);
create index campers_cabin_idx on public.campers (session_id, cabin_id);
create unique index campers_identity_key
  on public.campers (session_id, lower(first_name), lower(last_name), birthdate);
create unique index campers_ultracamp_id_key
  on public.campers (session_id, ultracamp_id) where ultracamp_id is not null;

-- One activity per camper per block. The primary key is what makes a double
-- booking impossible.
create table public.assignments (
  session_id uuid not null,
  camper_id uuid not null,
  block_id uuid not null,
  scheduled_activity_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (camper_id, block_id),
  foreign key (camper_id, session_id) references public.campers (id, session_id) on delete cascade,
  foreign key (block_id, session_id) references public.blocks (id, session_id) on delete cascade,
  -- Unscheduling an activity removes exactly the assignments to it.
  foreign key (scheduled_activity_id, block_id) references public.scheduled_activities (id, block_id) on delete cascade
);
create index assignments_session_id_idx on public.assignments (session_id);
create index assignments_block_id_idx on public.assignments (block_id);
create index assignments_scheduled_activity_id_idx on public.assignments (scheduled_activity_id);

create table public.camper_preferences (
  session_id uuid not null,
  camper_id uuid not null,
  activity_id uuid not null references public.activities (id) on delete cascade,
  kind public.preference_kind not null,
  created_at timestamptz not null default now(),
  primary key (camper_id, activity_id),
  foreign key (camper_id, session_id) references public.campers (id, session_id) on delete cascade
);
create index camper_preferences_session_id_idx on public.camper_preferences (session_id);
create index camper_preferences_activity_id_idx on public.camper_preferences (activity_id);

create trigger touch_updated_at before update on public.blocks for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.campers for each row execute function app.touch_updated_at();
create trigger touch_updated_at before update on public.assignments for each row execute function app.touch_updated_at();

-- Cabins and activities live at branch level, so the composite keys above
-- can't prove they belong to the session's branch. These triggers do.
create function app.enforce_catalog_branch() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session_branch uuid;
  v_catalog_branch uuid;
begin
  select se.branch_id into v_session_branch
  from public.sessions s
  join public.seasons se on se.id = s.season_id
  where s.id = new.session_id;

  if tg_table_name = 'session_cabins' then
    select branch_id into v_catalog_branch from public.cabins where id = new.cabin_id;
  else
    select branch_id into v_catalog_branch from public.activities where id = new.activity_id;
  end if;

  if v_catalog_branch is distinct from v_session_branch then
    raise exception 'The % row belongs to a different branch than the session', tg_table_name
      using errcode = 'BS003';
  end if;
  return new;
end
$$;

create trigger enforce_branch before insert or update on public.session_cabins
  for each row execute function app.enforce_catalog_branch();
create trigger enforce_branch before insert or update on public.scheduled_activities
  for each row execute function app.enforce_catalog_branch();
create trigger enforce_branch before insert or update on public.camper_preferences
  for each row execute function app.enforce_catalog_branch();

-- How full each scheduled activity is.
create view public.scheduled_activity_enrollment
with (security_invoker = true)
as
select
  sa.id as scheduled_activity_id,
  sa.session_id,
  sa.block_id,
  sa.activity_id,
  a.capacity,
  count(asg.camper_id)::integer as enrolled
from public.scheduled_activities sa
join public.activities a on a.id = sa.activity_id
left join public.assignments asg on asg.scheduled_activity_id = sa.id
group by sa.id, a.capacity;
