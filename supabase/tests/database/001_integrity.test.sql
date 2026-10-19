-- The database, not application code, keeps the schedule consistent.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

create temp table fx (key text primary key, id uuid not null);
grant all on fx to public;
create function pg_temp.fx(p_key text) returns uuid language sql as $$ select id from fx where key = p_key $$;

do $$
declare
  v_session public.sessions;
  v_other public.sessions;
  v_block1 uuid;
  v_block2 uuid;
begin
  select * into v_session from public.create_session((select id from public.seasons limit 1), 'Test Session', date '2030-01-07');
  select * into v_other from public.create_session((select id from public.seasons limit 1), 'Other Session', date '2030-02-04');
  insert into fx values ('session', v_session.id), ('other_session', v_other.id);

  select b.id into v_block1 from public.blocks b join public.schedule_days d on d.id = b.day_id
   where b.session_id = v_session.id and d.day_index = 0 and b.title = 'Choice Activity 1';
  select b.id into v_block2 from public.blocks b join public.schedule_days d on d.id = b.day_id
   where b.session_id = v_session.id and d.day_index = 0 and b.title = 'Choice Activity 2';
  insert into fx values ('block1', v_block1), ('block2', v_block2);
  insert into fx select 'other_block', b.id from public.blocks b where b.session_id = v_other.id limit 1;

  insert into fx select 'swimming', id from public.activities where name = 'Swimming';
  insert into fx select 'soccer', id from public.activities where name = 'Soccer';

  insert into public.scheduled_activities (session_id, block_id, activity_id) values
    (v_session.id, v_block1, (select id from fx where key = 'swimming')),
    (v_session.id, v_block1, (select id from fx where key = 'soccer')),
    (v_session.id, v_block2, (select id from fx where key = 'swimming'));
  insert into fx select 'swim1', id from public.scheduled_activities where block_id = v_block1 and activity_id = pg_temp.fx('swimming');
  insert into fx select 'soccer1', id from public.scheduled_activities where block_id = v_block1 and activity_id = pg_temp.fx('soccer');
  insert into fx select 'swim2', id from public.scheduled_activities where block_id = v_block2 and activity_id = pg_temp.fx('swimming');

  insert into public.campers (session_id, first_name, last_name, birthdate) values
    (v_session.id, 'Ada', 'Lovelace', date '2018-01-01'),
    (v_session.id, 'Grace', 'Hopper', date '2017-01-01'),
    (v_other.id, 'Linus', 'Torvalds', date '2017-01-01');
  insert into fx select 'ada', id from public.campers where first_name = 'Ada' and session_id = v_session.id;
  insert into fx select 'grace', id from public.campers where first_name = 'Grace' and session_id = v_session.id;
  insert into fx select 'linus', id from public.campers where first_name = 'Linus' and session_id = v_other.id;
end
$$;

-- create_session ----------------------------------------------------------
select is((select count(*)::int from public.blocks where session_id = pg_temp.fx('session')), 10,
  'create_session copies the weekly template (5 + 4 choice blocks and 1 skills rec)');
select is((select count(*)::int from public.schedule_days where session_id = pg_temp.fx('session')), 5,
  'create_session creates one day per template day');
select is((select count(*)::int from public.session_cabins where session_id = pg_temp.fx('session')),
          (select count(*)::int from public.cabins), 'create_session registers every cabin by default');

-- One block, one activity per camper ---------------------------------------
insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
values (pg_temp.fx('session'), pg_temp.fx('ada'), pg_temp.fx('block1'), pg_temp.fx('swim1'));

select throws_ok(
  format($q$insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
            values (%L, %L, %L, %L)$q$, pg_temp.fx('session'), pg_temp.fx('ada'), pg_temp.fx('block1'), pg_temp.fx('soccer1')),
  '23505', null, 'a camper cannot be in two activities during one block');

select throws_ok(
  format($q$insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
            values (%L, %L, %L, %L)$q$, pg_temp.fx('session'), pg_temp.fx('grace'), pg_temp.fx('block2'), pg_temp.fx('swim1')),
  '23503', null, 'the scheduled activity must belong to the block it is assigned in');

select throws_ok(
  format($q$insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
            values (%L, %L, %L, %L)$q$, pg_temp.fx('session'), pg_temp.fx('linus'), pg_temp.fx('block1'), pg_temp.fx('swim1')),
  '23503', null, 'a camper cannot be assigned into another session''s schedule');

-- Scheduling ---------------------------------------------------------------
select throws_ok(
  format($q$insert into public.blocks (session_id, day_id, title, start_time, end_time)
            values (%L, (select day_id from public.blocks where id = %L), 'Overlap', time '10:30', time '11:00')$q$,
         pg_temp.fx('session'), pg_temp.fx('block1')),
  '23P01', null, 'blocks on the same day cannot overlap');

select throws_ok(
  format($q$insert into public.scheduled_activities (session_id, block_id, activity_id)
            values (%L, %L, %L)$q$, pg_temp.fx('session'), pg_temp.fx('block1'), pg_temp.fx('swimming')),
  '23505', null, 'an activity can only be scheduled once per block');

do $$
declare v_branch uuid;
begin
  insert into public.organizations (name) values ('Other Camp');
  insert into public.branches (organization_id, name)
    select id, 'Other Branch' from public.organizations where name = 'Other Camp' returning id into v_branch;
  insert into public.activities (branch_id, name, capacity) values (v_branch, 'Foreign Activity', 5);
  insert into fx select 'foreign_activity', id from public.activities where name = 'Foreign Activity';
end $$;
select throws_ok(
  format($q$insert into public.scheduled_activities (session_id, block_id, activity_id)
            values (%L, %L, %L)$q$, pg_temp.fx('session'), pg_temp.fx('block2'), pg_temp.fx('foreign_activity')),
  'BS003', null, 'an activity from another branch cannot be scheduled');

-- Cascades -----------------------------------------------------------------
insert into public.assignments (session_id, camper_id, block_id, scheduled_activity_id)
values (pg_temp.fx('session'), pg_temp.fx('grace'), pg_temp.fx('block1'), pg_temp.fx('soccer1'));

delete from public.scheduled_activities where id = pg_temp.fx('swim1');
select is((select count(*)::int from public.assignments where session_id = pg_temp.fx('session')), 1,
  'unscheduling an activity removes only the assignments to it');
select is((select camper_id from public.assignments where session_id = pg_temp.fx('session')), pg_temp.fx('grace'),
  '...and leaves other campers in the same block alone');

update public.campers set cabin_id = (select cabin_id from public.session_cabins where session_id = pg_temp.fx('session') limit 1)
 where id = pg_temp.fx('ada');
select public.register_session_cabins(pg_temp.fx('session'), '{}');
select is((select cabin_id from public.campers where id = pg_temp.fx('ada')), null,
  'deregistering a cabin leaves its campers cabin-less');
select ok(exists (select 1 from public.campers where id = pg_temp.fx('ada')),
  '...and does not delete them');

delete from public.sessions where id = pg_temp.fx('session');
select is((select count(*)::int from public.assignments where session_id = pg_temp.fx('session')), 0,
  'deleting a session cascades through its whole schedule');
select is((select count(*)::int from public.campers where session_id = pg_temp.fx('session')), 0,
  '...including its campers');

select * from finish();
rollback;
