-- Foundation: private helper schema, enums and shared trigger functions.

-- `app` holds RLS predicates and trigger functions. It is deliberately NOT in
-- the API's exposed-schemas list (see supabase/config.toml), so nothing in it
-- is reachable over PostgREST.
create schema if not exists app;
comment on schema app is 'Private helpers (RLS predicates, triggers). Not exposed through the Data API.';
grant usage on schema app to authenticated, service_role;

create extension if not exists btree_gist with schema extensions;

create type public.staff_role as enum ('root', 'director', 'admin', 'counselor');
comment on type public.staff_role is
  'root/director: manage structure and users. admin: edit session data. counselor: read-only plus saving camper preferences.';

create type public.activity_category as enum (
  'creative',
  'sports_and_athletics',
  'waterfront',
  'camp_classics',
  'silly',
  'skills',
  'other'
);

-- Neutral ("flexible") is the absence of a row, so only the two explicit
-- choices are stored.
create type public.preference_kind as enum ('request', 'veto');

create function app.touch_updated_at() returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end
$$;
