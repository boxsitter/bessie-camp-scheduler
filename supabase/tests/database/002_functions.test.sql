-- Behavior of the RPCs the app relies on.
begin;
create extension if not exists pgtap with schema extensions;
select plan(23);

create temp table fx (key text primary key, id uuid not null);
grant all on fx to public;
create function pg_temp.fx(p_key text) returns uuid language sql as $$ select id from fx where key = p_key $$;

do $$
declare
  v_session public.sessions;
  v_b1 uuid;
  v_b2 uuid;
  v_double uuid;
begin
  select * into v_session from public.create_session(
    (select id from public.seasons limit 1), 'Func Session', date '2030-03-04', 3, 1, 2, 1);
  insert into fx values ('session', v_session.id);

  select b.id into v_b1 from public.blocks b join public.schedule_days d on d.id = b.day_id
   where b.session_id = v_session.id and d.day_index = 0 and b.title = 'Choice Activity 1';
  select b.id into v_b2 from public.blocks b join public.schedule_days d on d.id = b.day_id
   where b.session_id = v_session.id and d.day_index = 0 and b.title = 'Choice Activity 2';
  insert into fx values ('b1', v_b1), ('b2', v_b2);

  -- Offer: pottery (capacity 8), swimming, kayaking and archery skills in block 1; pottery again in block 2.
  insert into fx select 'pottery', id from public.activities where name = 'Pottery';
  insert into fx select 'swimming', id from public.activities where name = 'Swimming';
  insert into fx select 'kayaking', id from public.activities where name = 'Kayaking';
  insert into fx select 'skills', id from public.activities where name = 'Archery Skills';
  insert into fx select 'hidden', id from public.activities where name = 'Swim Test';
  insert into public.scheduled_activities (session_id, block_id, activity_id)
  select v_session.id, v_b1, a.id from public.activities a where a.name in ('Pottery', 'Swimming', 'Kayaking', 'Archery Skills', 'Swim Test');
  insert into public.scheduled_activities (session_id, block_id, activity_id)
  select v_session.id, v_b2, a.id from public.activities a where a.name = 'Pottery';
  insert into fx select 'pottery1', id from public.scheduled_activities where block_id = v_b1 and activity_id = pg_temp.fx('pottery');
  insert into fx select 'swim1', id from public.scheduled_activities where block_id = v_b1 and activity_id = pg_temp.fx('swimming');
  insert into fx select 'pottery2', id from public.scheduled_activities where block_id = v_b2 and activity_id = pg_temp.fx('pottery');

  insert into public.campers (session_id, first_name, last_name, birthdate)
  select v_session.id, 'Camper' || n, 'Number' || n, date '2017-01-01' from generate_series(1, 10) n;
  insert into fx select 'c' || substr(first_name, 7), id from public.campers where session_id = v_session.id;
end
$$;

create function pg_temp.act_as(p_email text) returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true); -- look the user up with full rights
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select id from auth.users where email = p_email), 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function pg_temp.act_as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

-- assign_campers -----------------------------------------------------------
select is(public.assign_campers(array[pg_temp.fx('c1'), pg_temp.fx('c2')], pg_temp.fx('pottery1')), 2,
  'assign_campers assigns every camper it is given');

select is(public.assign_campers(array[pg_temp.fx('c1')], pg_temp.fx('swim1')), 1, 'assign_campers moves a camper within a block by default');
select is((select scheduled_activity_id from public.assignments where camper_id = pg_temp.fx('c1') and block_id = pg_temp.fx('b1')),
  pg_temp.fx('swim1'), '...to the new activity');

select is(public.assign_campers(array[pg_temp.fx('c1')], pg_temp.fx('pottery1'), false), 0,
  'p_replace_existing = false leaves existing assignments alone');
select is((select scheduled_activity_id from public.assignments where camper_id = pg_temp.fx('c1') and block_id = pg_temp.fx('b1')),
  pg_temp.fx('swim1'), '...and they stay where they were');

select throws_ok(
  format($q$select public.assign_campers(array[%L, %L, %L, %L, %L, %L, %L, %L, %L]::uuid[], %L, true, true)$q$,
    pg_temp.fx('c1'), pg_temp.fx('c2'), pg_temp.fx('c3'), pg_temp.fx('c4'), pg_temp.fx('c5'),
    pg_temp.fx('c6'), pg_temp.fx('c7'), pg_temp.fx('c8'), pg_temp.fx('c9'), pg_temp.fx('pottery1')),
  'BS002', null, 'enforcing capacity rejects an over-full activity (pottery holds 8)');

select is(public.assign_campers(array[pg_temp.fx('c3'), pg_temp.fx('c4')], pg_temp.fx('pottery1'), true, true), 2,
  'capacity is only enforced when asked');

-- unassign_campers ---------------------------------------------------------
select is(public.unassign_campers(array[pg_temp.fx('c3')], null, pg_temp.fx('swim1')), 0,
  'unassigning from an activity the camper is not in does nothing');
select is(public.unassign_campers(array[pg_temp.fx('c3')], pg_temp.fx('b1')), 1, 'unassigning from a block removes that assignment');
select is(public.unassign_campers(array[pg_temp.fx('c2'), pg_temp.fx('c4')]), 2, 'unassigning with no filter removes everything');

-- apply_assignments --------------------------------------------------------
select is(
  public.apply_assignments(pg_temp.fx('session'),
    jsonb_build_array(
      jsonb_build_object('camper_id', pg_temp.fx('c1'), 'scheduled_activity_id', pg_temp.fx('pottery1')),  -- already in swim1: kept
      jsonb_build_object('camper_id', pg_temp.fx('c5'), 'scheduled_activity_id', pg_temp.fx('pottery2'))), -- new
    jsonb_build_array(jsonb_build_object('camper_id', pg_temp.fx('c5'), 'score', 0.75))),
  1, 'apply_assignments inserts only free slots');
select is((select scheduled_activity_id from public.assignments where camper_id = pg_temp.fx('c1') and block_id = pg_temp.fx('b1')),
  pg_temp.fx('swim1'), '...never overwriting an existing assignment');
select is((select activity_satisfaction_index from public.campers where id = pg_temp.fx('c5')), 0.75::real,
  '...and records satisfaction scores');

-- preferences (counselors have read-only table access but may rank campers) --
select pg_temp.act_as('counselor@bessie.test');
select lives_ok(
  format($q$select public.set_camper_preferences(%L, array[%L]::uuid[], array[%L]::uuid[])$q$,
    pg_temp.fx('c1'), pg_temp.fx('pottery'), pg_temp.fx('kayaking')),
  'set_camper_preferences accepts valid choices');
select ok((select preferences_submitted_at is not null from public.campers where id = pg_temp.fx('c1')),
  '...and marks the preferences as submitted');
select throws_ok(
  format($q$select public.set_camper_preferences(%L, array[%L]::uuid[], array[%L, %L]::uuid[])$q$,
    pg_temp.fx('c1'), pg_temp.fx('pottery'), pg_temp.fx('kayaking'), pg_temp.fx('swimming')),
  'BS001', null, 'the session''s veto limit (1) is enforced by the database');
select throws_ok(
  format($q$select public.set_camper_preferences(%L, array[%L]::uuid[], array[%L]::uuid[])$q$,
    pg_temp.fx('c1'), pg_temp.fx('pottery'), pg_temp.fx('pottery')),
  'BS004', null, 'an activity cannot be both requested and vetoed');
select throws_ok(
  format($q$select public.set_camper_preferences(%L, array[%L]::uuid[], '{}')$q$, pg_temp.fx('c1'), pg_temp.fx('hidden')),
  'BS003', null, 'hidden activities cannot be ranked');

select pg_temp.act_as_postgres();

-- create_session as a signed-in admin (RETURNING must pass the SELECT policy) --
select pg_temp.act_as('admin@bessie.test');
select lives_ok(
  $q$select public.create_session((select id from public.seasons limit 1), 'Created By Admin', date '2030-05-06')$q$,
  'admins can create sessions through the RPC');
select is((select count(*)::int from public.blocks b join public.sessions s on s.id = b.session_id where s.name = 'Created By Admin'), 10,
  '...and see the blocks it created');
select pg_temp.act_as_postgres();

-- import_campers -----------------------------------------------------------
select is(
  public.import_campers(pg_temp.fx('session'), jsonb_build_array(
    jsonb_build_object('first_name', 'Ada', 'last_name', 'Lovelace', 'birthdate', '2016-05-05', 'gender', 'F', 'cabin', 'oak'),
    jsonb_build_object('first_name', 'ADA', 'last_name', 'lovelace', 'birthdate', '2016-05-05'),
    jsonb_build_object('first_name', 'Bob', 'last_name', 'Builder', 'birthdate', '2015-05-05', 'cabin', 'Ernie'),
    jsonb_build_object('first_name', 'Cy', 'last_name', 'Young', 'birthdate', '2015-05-05', 'cabin', 'Nowhere'))),
  jsonb_build_object('inserted', 3, 'duplicates', 1, 'unknown_cabins', jsonb_build_array('Nowhere')),
  'import_campers inserts new campers, skips duplicates case-insensitively and reports unknown cabins');
select is((select c.name from public.campers p join public.cabins c on c.id = p.cabin_id
           where p.session_id = pg_temp.fx('session') and p.first_name = 'Bob'), 'Squirt',
  '...and resolves cabins by their display name');

-- swap_camper_cabins -------------------------------------------------------
update public.campers set cabin_id = (select id from public.cabins where name = 'Oak') where id = pg_temp.fx('c6');
update public.campers set cabin_id = (select id from public.cabins where name = 'Fox') where id = pg_temp.fx('c7');
select public.swap_camper_cabins(array[pg_temp.fx('c6'), pg_temp.fx('c7')]);
select is((select c.name from public.campers p join public.cabins c on c.id = p.cabin_id where p.id = pg_temp.fx('c6')), 'Fox',
  'swap_camper_cabins sends each camper to the other cabin');

select * from finish();
rollback;
