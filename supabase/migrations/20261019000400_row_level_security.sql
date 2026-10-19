-- Row level security.
--
-- Access is scoped to the organization on the caller's profile and gated by
-- role: every active staff member can read their organization's data, and
-- root/director/admin can write session data. Only directors manage the
-- organization structure and other users' accounts. Counselors save camper
-- preferences through set_camper_preferences(), which performs its own checks.

------------------------------------------------------------------------------
-- Predicates. SECURITY DEFINER so they can read `profiles` without recursing
-- through its own policies; they only ever answer questions about the caller.
------------------------------------------------------------------------------

create function app.current_org_id() returns uuid
language sql stable security definer set search_path = ''
as $$
  select p.organization_id
  from public.profiles p
  where p.id = (select auth.uid()) and p.active
$$;

create function app.staff_role() returns public.staff_role
language sql stable security definer set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = (select auth.uid()) and p.active
$$;

create function app.is_writer() returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(app.staff_role() in ('root', 'director', 'admin'), false)
$$;

create function app.is_director() returns boolean
language sql stable security definer set search_path = ''
as $$
  select coalesce(app.staff_role() in ('root', 'director'), false)
$$;

create function app.visible_branch_ids() returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select b.id from public.branches b where b.organization_id = app.current_org_id()
$$;

create function app.visible_season_ids() returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select se.id
  from public.seasons se
  join public.branches b on b.id = se.branch_id
  where b.organization_id = app.current_org_id()
$$;

create function app.visible_session_ids() returns setof uuid
language sql stable security definer set search_path = ''
as $$
  select s.id
  from public.sessions s
  join public.seasons se on se.id = s.season_id
  join public.branches b on b.id = se.branch_id
  where b.organization_id = app.current_org_id()
$$;

grant execute on all functions in schema app to authenticated, service_role;

------------------------------------------------------------------------------
-- Privileges: nothing for `anon`; `authenticated` gets DML that RLS narrows.
------------------------------------------------------------------------------

revoke all on all tables in schema public from anon;
grant select, insert, update, delete on all tables in schema public to authenticated;
alter default privileges for role postgres in schema public revoke all on tables from anon;

------------------------------------------------------------------------------
-- Policies
------------------------------------------------------------------------------

alter table public.organizations enable row level security;
alter table public.branches enable row level security;
alter table public.seasons enable row level security;
alter table public.sessions enable row level security;
alter table public.activities enable row level security;
alter table public.cabins enable row level security;
alter table public.branch_block_templates enable row level security;
alter table public.profiles enable row level security;
alter table public.session_cabins enable row level security;
alter table public.schedule_days enable row level security;
alter table public.blocks enable row level security;
alter table public.scheduled_activities enable row level security;
alter table public.campers enable row level security;
alter table public.assignments enable row level security;
alter table public.camper_preferences enable row level security;

-- Organization structure ----------------------------------------------------

create policy "members read their organization" on public.organizations
  for select to authenticated
  using (id = (select app.current_org_id()));

create policy "directors rename their organization" on public.organizations
  for update to authenticated
  using (id = (select app.current_org_id()) and (select app.is_director()))
  with check (id = (select app.current_org_id()));

create policy "members read branches" on public.branches
  for select to authenticated
  using (id in (select app.visible_branch_ids()));

create policy "directors manage branches" on public.branches
  for all to authenticated
  using (id in (select app.visible_branch_ids()) and (select app.is_director()))
  with check (organization_id = (select app.current_org_id()) and (select app.is_director()));

create policy "members read seasons" on public.seasons
  for select to authenticated
  using (id in (select app.visible_season_ids()));

create policy "directors manage seasons" on public.seasons
  for all to authenticated
  using (id in (select app.visible_season_ids()) and (select app.is_director()))
  with check (branch_id in (select app.visible_branch_ids()) and (select app.is_director()));

create policy "members read sessions" on public.sessions
  for select to authenticated
  using (id in (select app.visible_session_ids()));

create policy "writers manage sessions" on public.sessions
  for all to authenticated
  using (id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (season_id in (select app.visible_season_ids()) and (select app.is_writer()));

-- Branch catalog -------------------------------------------------------------

create policy "members read activities" on public.activities
  for select to authenticated
  using (branch_id in (select app.visible_branch_ids()));

create policy "writers manage activities" on public.activities
  for all to authenticated
  using (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()))
  with check (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()));

create policy "members read cabins" on public.cabins
  for select to authenticated
  using (branch_id in (select app.visible_branch_ids()));

create policy "writers manage cabins" on public.cabins
  for all to authenticated
  using (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()))
  with check (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()));

create policy "members read block templates" on public.branch_block_templates
  for select to authenticated
  using (branch_id in (select app.visible_branch_ids()));

create policy "writers manage block templates" on public.branch_block_templates
  for all to authenticated
  using (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()))
  with check (branch_id in (select app.visible_branch_ids()) and (select app.is_writer()));

-- Session data ---------------------------------------------------------------

create policy "members read session cabins" on public.session_cabins
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage session cabins" on public.session_cabins
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read schedule days" on public.schedule_days
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage schedule days" on public.schedule_days
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read blocks" on public.blocks
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage blocks" on public.blocks
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read scheduled activities" on public.scheduled_activities
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage scheduled activities" on public.scheduled_activities
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read campers" on public.campers
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage campers" on public.campers
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read assignments" on public.assignments
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage assignments" on public.assignments
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

create policy "members read camper preferences" on public.camper_preferences
  for select to authenticated
  using (session_id in (select app.visible_session_ids()));
create policy "writers manage camper preferences" on public.camper_preferences
  for all to authenticated
  using (session_id in (select app.visible_session_ids()) and (select app.is_writer()))
  with check (session_id in (select app.visible_session_ids()) and (select app.is_writer()));

-- Staff profiles -------------------------------------------------------------

create policy "members read colleagues" on public.profiles
  for select to authenticated
  using (organization_id = (select app.current_org_id()) or id = (select auth.uid()));

create policy "users edit themselves, directors edit anyone" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()) or (organization_id = (select app.current_org_id()) and (select app.is_director())))
  with check (organization_id = (select app.current_org_id()));

-- RLS can't compare old and new values, so a trigger stops anyone but a
-- director from changing roles, org membership or account status.
create function app.guard_profile_update() returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- No JWT means a trusted context (service key, migrations, SQL console).
  if (select auth.uid()) is not null
     and not app.is_director()
     and (new.role is distinct from old.role
       or new.organization_id is distinct from old.organization_id
       or new.active is distinct from old.active
       or new.deactivation_reason is distinct from old.deactivation_reason)
  then
    raise exception 'Only a director can change roles or deactivate accounts'
      using errcode = '42501';
  end if;
  return new;
end
$$;

create trigger guard_profile_update before update on public.profiles
  for each row execute function app.guard_profile_update();
