-- Atomic operations exposed as RPCs (POST /rest/v1/rpc/<name>).
--
-- Unless noted, functions are SECURITY INVOKER, so row level security applies
-- exactly as it would for direct table access.
--
-- Custom SQLSTATEs the client maps to friendly messages:
--   BS001  a per-session limit was exceeded (requests / vetoes)
--   BS002  an activity would exceed its capacity
--   BS003  a referenced row doesn't belong where it was used
--   BS004  contradictory input (e.g. requested and vetoed)

------------------------------------------------------------------------------
-- Sessions
------------------------------------------------------------------------------

-- Creates a session with its schedule days, the branch's template blocks and
-- (optionally) every cabin in the branch.
create function public.create_session(
  p_season_id uuid,
  p_name text,
  p_starts_on date,
  p_max_requests integer default 3,
  p_max_vetoes integer default 2,
  p_max_skills_requests integer default 2,
  p_max_skills_vetoes integer default 1,
  p_register_all_cabins boolean default true,
  p_days integer default null
) returns public.sessions
language plpgsql
set search_path = ''
as $$
declare
  v_branch uuid;
  v_session public.sessions;
  v_days integer;
begin
  select se.branch_id into v_branch from public.seasons se where se.id = p_season_id;
  if v_branch is null then
    raise exception 'Season not found' using errcode = 'P0002';
  end if;

  insert into public.sessions (season_id, name, starts_on, max_requests, max_vetoes, max_skills_requests, max_skills_vetoes)
  values (p_season_id, p_name, p_starts_on, p_max_requests, p_max_vetoes, p_max_skills_requests, p_max_skills_vetoes)
  returning * into v_session;

  select coalesce(p_days, max(t.day_offset) + 1, 5) into v_days
  from public.branch_block_templates t
  where t.branch_id = v_branch;

  insert into public.schedule_days (session_id, day_index, date)
  select v_session.id, d, p_starts_on + d
  from generate_series(0, v_days - 1) as d;

  insert into public.blocks (session_id, day_id, title, start_time, end_time, is_skills_rec)
  select v_session.id, sd.id, t.title, t.start_time, t.end_time, t.is_skills_rec
  from public.branch_block_templates t
  join public.schedule_days sd on sd.session_id = v_session.id and sd.day_index = t.day_offset
  where t.branch_id = v_branch;

  if p_register_all_cabins then
    insert into public.session_cabins (session_id, cabin_id)
    select v_session.id, c.id from public.cabins c where c.branch_id = v_branch;
  end if;

  return v_session;
end
$$;

-- Makes the session's cabins exactly `p_cabin_ids`. Campers in a removed cabin
-- stay on the roster without a cabin.
create function public.register_session_cabins(p_session_id uuid, p_cabin_ids uuid[])
returns void
language plpgsql
set search_path = ''
as $$
begin
  delete from public.session_cabins
  where session_id = p_session_id and cabin_id <> all (coalesce(p_cabin_ids, '{}'));

  insert into public.session_cabins (session_id, cabin_id)
  select p_session_id, id from unnest(coalesce(p_cabin_ids, '{}')) as id
  on conflict do nothing;
end
$$;

------------------------------------------------------------------------------
-- Campers
------------------------------------------------------------------------------

-- Bulk-registers campers from parsed CSV rows. Each row looks like
--   {"first_name": "...", "last_name": "...", "birthdate": "YYYY-MM-DD",
--    "preferred_name": "...", "gender": "M|F|NB", "cabin": "...",
--    "ultracamp_id": "...", "note": "..."}
-- Campers that already exist (same name and birthdate, or same UltraCamp id)
-- are skipped. An unknown cabin leaves the camper without one and is reported.
create function public.import_campers(p_session_id uuid, p_rows jsonb)
returns jsonb
language plpgsql
set search_path = ''
as $$
declare
  r jsonb;
  v_cabin_name text;
  v_cabin uuid;
  v_changed integer;
  v_inserted integer := 0;
  v_duplicates integer := 0;
  v_unknown_cabins text[] := array[]::text[];
begin
  for r in select * from jsonb_array_elements(p_rows) loop
    v_cabin := null;
    v_cabin_name := nullif(btrim(r ->> 'cabin'), '');

    if v_cabin_name is not null then
      select c.id into v_cabin
      from public.session_cabins sc
      join public.cabins c on c.id = sc.cabin_id
      where sc.session_id = p_session_id
        and (lower(c.name) = lower(v_cabin_name) or lower(c.display_name) = lower(v_cabin_name))
      limit 1;

      if v_cabin is null and not (v_cabin_name = any (v_unknown_cabins)) then
        v_unknown_cabins := v_unknown_cabins || v_cabin_name;
      end if;
    end if;

    insert into public.campers (
      session_id, first_name, preferred_name, last_name, gender, birthdate, note, cabin_id, ultracamp_id
    ) values (
      p_session_id,
      btrim(r ->> 'first_name'),
      nullif(btrim(r ->> 'preferred_name'), ''),
      btrim(r ->> 'last_name'),
      nullif(btrim(r ->> 'gender'), ''),
      (r ->> 'birthdate')::date,
      coalesce(r ->> 'note', ''),
      v_cabin,
      nullif(btrim(r ->> 'ultracamp_id'), '')
    )
    on conflict do nothing;

    get diagnostics v_changed = row_count;
    if v_changed = 1 then
      v_inserted := v_inserted + 1;
    else
      v_duplicates := v_duplicates + 1;
    end if;
  end loop;

  return jsonb_build_object(
    'inserted', v_inserted,
    'duplicates', v_duplicates,
    'unknown_cabins', to_jsonb(v_unknown_cabins)
  );
end
$$;

-- Moves each selected camper to the other cabin. The selection must span
-- exactly two cabins.
create function public.swap_camper_cabins(p_camper_ids uuid[])
returns void
language plpgsql
set search_path = ''
as $$
declare
  v_cabins uuid[];
begin
  select array_agg(distinct c.cabin_id) into v_cabins
  from public.campers c
  where c.id = any (p_camper_ids) and c.cabin_id is not null;

  if coalesce(cardinality(v_cabins), 0) <> 2 then
    raise exception 'Select campers from exactly two cabins to swap them' using errcode = 'BS003';
  end if;

  update public.campers c
  set cabin_id = case when c.cabin_id = v_cabins[1] then v_cabins[2] else v_cabins[1] end
  where c.id = any (p_camper_ids) and c.cabin_id = any (v_cabins);
end
$$;

------------------------------------------------------------------------------
-- Preferences
------------------------------------------------------------------------------

-- Replaces a camper's requests and vetoes. SECURITY DEFINER so counselors
-- (who have read-only table access) can record preferences; the function
-- verifies the caller is active staff in the camper's organization and enforces
-- the session's limits itself.
create function public.set_camper_preferences(
  p_camper_id uuid,
  p_requests uuid[],
  p_vetoes uuid[]
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_session public.sessions;
  v_requests uuid[];
  v_vetoes uuid[];
  v_standard_requests integer;
  v_skills_requests integer;
  v_standard_vetoes integer;
  v_skills_vetoes integer;
begin
  if app.staff_role() is null then
    raise exception 'Not signed in as active staff' using errcode = '42501';
  end if;

  select s.* into v_session
  from public.campers c
  join public.sessions s on s.id = c.session_id
  where c.id = p_camper_id
    and s.id in (select app.visible_session_ids());
  if not found then
    raise exception 'Camper not found' using errcode = 'P0002';
  end if;

  v_requests := array(select distinct unnest(coalesce(p_requests, '{}')));
  v_vetoes := array(select distinct unnest(coalesce(p_vetoes, '{}')));

  if v_requests && v_vetoes then
    raise exception 'An activity cannot be both requested and vetoed' using errcode = 'BS004';
  end if;

  -- Only activities actually on offer in this session can be ranked.
  if exists (
    select 1
    from unnest(v_requests || v_vetoes) as chosen(id)
    where not exists (
      select 1
      from public.scheduled_activities sa
      join public.activities a on a.id = sa.activity_id
      where sa.session_id = v_session.id and a.id = chosen.id and not a.is_hidden
    )
  ) then
    raise exception 'Some of those activities are not offered in this session' using errcode = 'BS003';
  end if;

  select count(*) filter (where not a.is_skills_rec), count(*) filter (where a.is_skills_rec)
  into v_standard_requests, v_skills_requests
  from public.activities a where a.id = any (v_requests);

  select count(*) filter (where not a.is_skills_rec), count(*) filter (where a.is_skills_rec)
  into v_standard_vetoes, v_skills_vetoes
  from public.activities a where a.id = any (v_vetoes);

  if v_standard_requests > v_session.max_requests then
    raise exception 'You can request at most % activities', v_session.max_requests using errcode = 'BS001';
  elsif v_skills_requests > v_session.max_skills_requests then
    raise exception 'You can request at most % skills recs', v_session.max_skills_requests using errcode = 'BS001';
  elsif v_standard_vetoes > v_session.max_vetoes then
    raise exception 'You can veto at most % activities', v_session.max_vetoes using errcode = 'BS001';
  elsif v_skills_vetoes > v_session.max_skills_vetoes then
    raise exception 'You can veto at most % skills recs', v_session.max_skills_vetoes using errcode = 'BS001';
  end if;

  delete from public.camper_preferences where camper_id = p_camper_id;

  insert into public.camper_preferences (session_id, camper_id, activity_id, kind)
  select v_session.id, p_camper_id, id, 'request'::public.preference_kind from unnest(v_requests) as id
  union all
  select v_session.id, p_camper_id, id, 'veto'::public.preference_kind from unnest(v_vetoes) as id;

  update public.campers set preferences_submitted_at = now() where id = p_camper_id;
end
$$;

create function public.clear_camper_preferences(p_camper_ids uuid[])
returns void
language plpgsql
set search_path = ''
as $$
begin
  delete from public.camper_preferences where camper_id = any (p_camper_ids);
  update public.campers set preferences_submitted_at = null where id = any (p_camper_ids);
end
$$;

------------------------------------------------------------------------------
-- Assignments
------------------------------------------------------------------------------

-- Puts campers into a scheduled activity. By default a camper already in
-- another activity during the same block is moved.
create function public.assign_campers(
  p_camper_ids uuid[],
  p_scheduled_activity_id uuid,
  p_replace_existing boolean default true,
  p_enforce_capacity boolean default false
) returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_session uuid;
  v_block uuid;
  v_capacity integer;
  v_others integer;
  v_changed integer;
begin
  select sa.session_id, sa.block_id, a.capacity
  into v_session, v_block, v_capacity
  from public.scheduled_activities sa
  join public.activities a on a.id = sa.activity_id
  where sa.id = p_scheduled_activity_id;

  if not found then
    raise exception 'Scheduled activity not found' using errcode = 'P0002';
  end if;

  if p_enforce_capacity then
    select count(*) into v_others
    from public.assignments asg
    where asg.scheduled_activity_id = p_scheduled_activity_id
      and asg.camper_id <> all (p_camper_ids);

    if v_others + cardinality(p_camper_ids) > v_capacity then
      raise exception 'That activity only has room for % campers', v_capacity using errcode = 'BS002';
    end if;
  end if;

  insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
  select v_session, c.id, v_block, p_scheduled_activity_id
  from public.campers c
  where c.id = any (p_camper_ids) and c.session_id = v_session
  on conflict (camper_id, block_id) do update
    set scheduled_activity_id = excluded.scheduled_activity_id
    where p_replace_existing and public.assignments.scheduled_activity_id <> excluded.scheduled_activity_id;

  get diagnostics v_changed = row_count;
  return v_changed;
end
$$;

-- Removes campers' assignments: from one scheduled activity, from one block,
-- or (with neither filter) from everything.
create function public.unassign_campers(
  p_camper_ids uuid[],
  p_block_id uuid default null,
  p_scheduled_activity_id uuid default null
) returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_removed integer;
begin
  delete from public.assignments
  where camper_id = any (p_camper_ids)
    and (p_block_id is null or block_id = p_block_id)
    and (p_scheduled_activity_id is null or scheduled_activity_id = p_scheduled_activity_id);

  get diagnostics v_removed = row_count;
  return v_removed;
end
$$;

-- Stores the outcome of an auto-assignment run in one transaction.
--   p_assignments:  [{"camper_id": "...", "scheduled_activity_id": "..."}, ...]
--   p_satisfaction: [{"camper_id": "...", "score": 0.0-1.0}, ...]
-- A camper who already has an assignment for the block keeps it.
create function public.apply_assignments(
  p_session_id uuid,
  p_assignments jsonb,
  p_satisfaction jsonb default '[]'::jsonb
) returns integer
language plpgsql
set search_path = ''
as $$
declare
  v_inserted integer;
begin
  insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
  select p_session_id, c.id, sa.block_id, sa.id
  from jsonb_array_elements(p_assignments) as e
  join public.scheduled_activities sa
    on sa.id = (e ->> 'scheduled_activity_id')::uuid and sa.session_id = p_session_id
  join public.campers c
    on c.id = (e ->> 'camper_id')::uuid and c.session_id = p_session_id
  on conflict (camper_id, block_id) do nothing;

  get diagnostics v_inserted = row_count;

  update public.campers c
  set activity_satisfaction_index = s.score
  from (
    select (e ->> 'camper_id')::uuid as id, (e ->> 'score')::real as score
    from jsonb_array_elements(p_satisfaction) as e
  ) s
  where c.id = s.id and c.session_id = p_session_id;

  return v_inserted;
end
$$;

create function public.reset_session_assignments(
  p_session_id uuid,
  p_clear_preferences boolean default false
) returns void
language plpgsql
set search_path = ''
as $$
begin
  delete from public.assignments where session_id = p_session_id;
  update public.campers set activity_satisfaction_index = null where session_id = p_session_id;

  if p_clear_preferences then
    delete from public.camper_preferences where session_id = p_session_id;
    update public.campers set preferences_submitted_at = null where session_id = p_session_id;
  end if;
end
$$;

------------------------------------------------------------------------------
-- Privileges: RPCs are for signed-in users only.
------------------------------------------------------------------------------

do $$
declare
  r record;
begin
  for r in
    select p.oid::regprocedure as signature
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.prokind = 'f'
  loop
    execute format('revoke all on function %s from public, anon', r.signature);
    execute format('grant execute on function %s to authenticated', r.signature);
  end loop;
end
$$;
