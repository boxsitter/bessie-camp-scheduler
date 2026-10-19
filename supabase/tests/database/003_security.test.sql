-- Who can see and change what.
begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

create function pg_temp.act_as(p_email text) returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true); -- look the user up with full rights
  perform set_config('request.jwt.claims',
    json_build_object('sub', (select id from auth.users where email = p_email), 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end $$;
create function pg_temp.act_as_anon() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
  perform set_config('role', 'anon', true);
end $$;
create function pg_temp.act_as_postgres() returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end $$;

-- A second organization with its own staff member and data.
do $$
declare
  v_org uuid;
  v_branch uuid;
begin
  insert into public.organizations (name) values ('Rival Camp') returning id into v_org;
  insert into public.branches (organization_id, name) values (v_org, 'Rival Branch') returning id into v_branch;
  insert into auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
                          raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
                          confirmation_token, email_change, email_change_token_new, recovery_token)
  values ('00000000-0000-0000-0000-000000000000', gen_random_uuid(), 'authenticated', 'authenticated',
          'rival@example.test', 'x', now(),
          jsonb_build_object('organization_id', v_org, 'role', 'director'),
          '{"first_name":"Riva","last_name":"Rival"}', now(), now(), '', '', '', '');
end $$;

select is((select role::text from public.profiles where id = (select id from auth.users where email = 'rival@example.test')),
  'director', 'new auth users get a profile from their app_metadata');

-- Anonymous visitors ---------------------------------------------------------
select pg_temp.act_as_anon();
select throws_ok('select * from public.campers', '42501', null, 'anonymous visitors cannot read campers');
select throws_ok('select * from public.profiles', '42501', null, 'anonymous visitors cannot read profiles');
select pg_temp.act_as_postgres();
select ok(not has_function_privilege('anon', 'public.assign_campers(uuid[],uuid,boolean,boolean)', 'execute'),
  'anonymous visitors cannot call RPCs');
select ok(has_function_privilege('authenticated', 'public.assign_campers(uuid[],uuid,boolean,boolean)', 'execute'),
  'signed-in users can call RPCs');

-- Counselors: read-only -------------------------------------------------------
select pg_temp.act_as('counselor@bessie.test');
select ok((select count(*) from public.campers) > 100, 'counselors can read campers');
select is((select count(*)::int from public.organizations), 1, 'counselors only see their own organization');

select throws_ok(
  $$insert into public.campers (session_id, first_name, last_name, birthdate)
    select id, 'Sneaky', 'Insert', date '2017-01-01' from public.sessions limit 1$$,
  '42501', null, 'counselors cannot add campers');

with changed as (update public.campers set note = 'tampered' returning 1)
select is((select count(*)::int from changed), 0, 'counselors cannot edit campers');
with removed as (delete from public.assignments returning 1)
select is((select count(*)::int from removed), 0, 'counselors cannot delete assignments');

select throws_ok($$update public.profiles set role = 'director' where id = (select auth.uid())$$,
  '42501', null, 'counselors cannot promote themselves');

-- Admins: edit session data, not structure ---------------------------------------
select pg_temp.act_as('admin@bessie.test');
with changed as (update public.campers set note = 'updated by admin' where id = (select id from public.campers limit 1) returning 1)
select is((select count(*)::int from changed), 1, 'admins can edit campers');
select throws_ok($$insert into public.branches (organization_id, name) select id, 'Nope' from public.organizations$$,
  '42501', null, 'admins cannot create branches');

-- Directors: manage structure and people -------------------------------------------
select pg_temp.act_as('director@bessie.test');
select lives_ok($$insert into public.branches (organization_id, name) select id, 'Second Branch' from public.organizations$$,
  'directors can create branches');
select lives_ok($$update public.profiles set role = 'admin' where id = '00000000-0000-4000-8000-0000000000a3'$$,
  'directors can change roles');
select pg_temp.act_as_postgres();
update public.profiles set role = 'counselor' where id = '00000000-0000-4000-8000-0000000000a3';

-- Tenant isolation -------------------------------------------------------------------
select pg_temp.act_as('rival@example.test');
select is((select count(*)::int from public.campers), 0, 'another organization cannot see our campers');
select is((select count(*)::int from public.organizations), 1, '...or our organization');
select is((select count(*)::int from public.profiles where organization_id <> (select organization_id from public.profiles where id = (select auth.uid()))), 0,
  '...or our staff');

-- Deactivated accounts ---------------------------------------------------------------
select pg_temp.act_as_postgres();
update public.profiles set active = false where id = (select id from auth.users where email = 'admin@bessie.test');
select pg_temp.act_as('admin@bessie.test');
select is((select count(*)::int from public.campers), 0, 'deactivated staff lose access immediately');

select * from finish();
rollback;
