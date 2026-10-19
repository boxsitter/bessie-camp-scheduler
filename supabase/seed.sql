-- Local development seed. Runs on `supabase db reset` only, never in production.
--
-- Creates a demo camp (organization, catalog, two sessions with a weekly
-- schedule, campers with preferences) and three staff accounts:
--
--   director@bessie.test / password123   (director: manages everything)
--   admin@bessie.test    / password123   (admin: edits session data)
--   counselor@bessie.test / password123  (counselor: read-only + preferences)
--
-- Dates are relative to "today" so the app always opens on a current session.

do $seed$
declare
  v_org constant uuid := '00000000-0000-4000-8000-000000000001';
  v_branch constant uuid := '00000000-0000-4000-8000-000000000002';
  v_season constant uuid := '00000000-0000-4000-8000-000000000003';
  v_monday date := date_trunc('week', current_date)::date;
  v_session public.sessions;
  v_session_no integer;
begin
  ----------------------------------------------------------------------------
  -- Organization, branch, season
  ----------------------------------------------------------------------------
  insert into public.organizations (id, name) values (v_org, 'Camp Bessie');
  insert into public.branches (id, organization_id, name) values (v_branch, v_org, 'Main Camp');
  insert into public.seasons (id, branch_id, name, starts_on, ends_on)
  values (v_season, v_branch, 'Summer ' || extract(year from v_monday)::int, v_monday, v_monday + 27);

  ----------------------------------------------------------------------------
  -- Activities
  ----------------------------------------------------------------------------
  insert into public.activities (branch_id, name, description, capacity, category, is_skills_rec, double_schedule, max_assignments, is_hidden, preference_required)
  values
    (v_branch, 'Arts & Crafts',        'Painting, beading and friendship bracelets.',        14, 'creative',             false, false, 2,    false, true),
    (v_branch, 'Pottery',              'Throw and glaze a piece on the wheel.',               8, 'creative',             false, false, 2,    false, true),
    (v_branch, 'Tie-Dye',              'Dye a shirt in every color of the rainbow.',         16, 'creative',             false, false, 1,    false, true),
    (v_branch, 'Drama',                'Improv games and scene work.',                       14, 'creative',             false, false, 2,    false, true),
    (v_branch, 'Photography',          'Learn composition with a real camera.',               8, 'creative',             false, false, 2,    false, true),
    (v_branch, 'Woodworking',          'Hammers, saws and birdhouses.',                       8, 'creative',             false, false, 2,    false, true),
    (v_branch, 'Soccer',               'Pick-up games on the big field.',                    20, 'sports_and_athletics', false, false, 3,    false, true),
    (v_branch, 'Basketball',           'Shooting drills and scrimmages.',                    16, 'sports_and_athletics', false, false, 3,    false, true),
    (v_branch, 'Ultimate Frisbee',     'Fast, friendly and a lot of running.',               18, 'sports_and_athletics', false, false, 3,    false, true),
    (v_branch, 'Archery',              'Range safety and target practice.',                  10, 'sports_and_athletics', false, false, 2,    false, true),
    (v_branch, 'Climbing Wall',        'Top-rope climbing for all levels.',                  10, 'sports_and_athletics', false, false, 2,    false, true),
    (v_branch, 'Gaga Ball',            'Dodge-ball in the pit.',                             16, 'sports_and_athletics', false, false, 3,    false, true),
    (v_branch, 'Swimming',             'Free swim and games in the lake.',                   24, 'waterfront',           false, false, 3,    false, true),
    (v_branch, 'Kayaking',             'Paddle around the cove.',                            10, 'waterfront',           false, false, 2,    false, true),
    (v_branch, 'Canoeing',             'Learn strokes, then race.',                          12, 'waterfront',           false, false, 2,    false, true),
    (v_branch, 'Paddleboarding',       'Stand up and stay dry (maybe).',                      8, 'waterfront',           false, false, 2,    false, true),
    (v_branch, 'Campfire Cooking',     'Foil dinners and s''mores.',                         12, 'camp_classics',        false, false, 2,    false, true),
    (v_branch, 'Nature Walk',          'Spot birds, tracks and mushrooms.',                  16, 'camp_classics',        false, false, 2,    false, true),
    (v_branch, 'Capture the Flag',     'The camp classic.',                                  24, 'camp_classics',        false, false, 2,    false, true),
    (v_branch, 'Geocaching',           'Treasure hunting with GPS units.',                   12, 'camp_classics',        false, false, 2,    false, true),
    (v_branch, 'Ropes Course',         'A two-block adventure high in the trees.',           10, 'camp_classics',        false, true,  1,    false, true),
    (v_branch, 'Slip ''N Slide',       'Exactly what it sounds like.',                       20, 'silly',                false, false, 2,    false, true),
    (v_branch, 'Water Balloon Games',  'Bring a towel.',                                     20, 'silly',                false, false, 2,    false, true),
    (v_branch, 'Silly Olympics',       'Egg-and-spoon, sack races and more.',                24, 'silly',                false, false, 2,    false, true),
    (v_branch, 'Archery Skills',       'Skills rec: work toward your archery badge.',        10, 'skills',               true,  false, 1,    false, true),
    (v_branch, 'Swim Skills',          'Skills rec: stroke clinics and endurance.',          12, 'skills',               true,  false, 1,    false, true),
    (v_branch, 'Climbing Skills',      'Skills rec: knots, belaying and technique.',         10, 'skills',               true,  false, 1,    false, true),
    (v_branch, 'Teen Skills Rec',      'Skills rec: assigned to teens without ranking.',     16, 'skills',               true,  false, 1,    false, false),
    (v_branch, 'Swim Test',            'Keeps new campers busy while they are evaluated.',    6, 'waterfront',           false, false, 1,    true,  false);

  ----------------------------------------------------------------------------
  -- Cabins ("Squirt" shows up as "Ernie" to demonstrate display_name)
  ----------------------------------------------------------------------------
  insert into public.cabins (branch_id, name, display_name, village, capacity, position)
  values
    (v_branch, 'Oak',    null,   'Pines',  10, 1),
    (v_branch, 'Maple',  null,   'Pines',  10, 2),
    (v_branch, 'Birch',  null,   'Pines',  10, 3),
    (v_branch, 'Cedar',  null,   'Pines',  10, 4),
    (v_branch, 'Fox',    null,   'Meadow', 10, 5),
    (v_branch, 'Otter',  null,   'Meadow', 10, 6),
    (v_branch, 'Heron',  null,   'Meadow', 10, 7),
    (v_branch, 'Squirt', 'Ernie', 'Meadow',  8, 8);

  ----------------------------------------------------------------------------
  -- Weekly rhythm every new session starts from (Mon-Fri)
  ----------------------------------------------------------------------------
  insert into public.branch_block_templates (branch_id, day_offset, title, start_time, end_time, is_skills_rec)
  select v_branch, d, 'Choice Activity 1', time '10:15', time '11:15', false from generate_series(0, 4) d
  union all
  select v_branch, d, 'Choice Activity 2', time '11:20', time '12:20', false from generate_series(0, 3) d
  union all
  select v_branch, 1, 'Skills Rec', time '09:15', time '10:10', true;

  ----------------------------------------------------------------------------
  -- Two sessions, scheduled with a rotating set of activities
  ----------------------------------------------------------------------------
  for v_session_no in 1..2 loop
    v_session := public.create_session(
      v_season,
      'Session ' || v_session_no,
      v_monday + (v_session_no - 1) * 7,
      3, 2, 2, 1,
      true
    );

    -- Standard blocks: 14 deterministic-but-varied choices each, never the
    -- double-schedule or hidden activities (handled below).
    insert into public.scheduled_activities (session_id, block_id, activity_id)
    select b.session_id, b.id, picked.id
    from public.blocks b
    cross join lateral (
      select a.id
      from public.activities a
      where a.branch_id = v_branch and not a.is_skills_rec and not a.is_hidden and not a.double_schedule
      order by md5(b.id::text || a.id::text)
      limit 14
    ) picked
    where b.session_id = v_session.id and not b.is_skills_rec;

    -- Skills blocks offer the skills recs.
    insert into public.scheduled_activities (session_id, block_id, activity_id)
    select b.session_id, b.id, a.id
    from public.blocks b
    join public.activities a on a.branch_id = v_branch and a.is_skills_rec
    where b.session_id = v_session.id and b.is_skills_rec;

    -- The ropes course spans both choice blocks on Monday-Thursday.
    insert into public.scheduled_activities (session_id, block_id, activity_id)
    select b.session_id, b.id, a.id
    from public.blocks b
    join public.schedule_days sd on sd.id = b.day_id
    join public.activities a on a.branch_id = v_branch and a.double_schedule
    where b.session_id = v_session.id and not b.is_skills_rec and sd.day_index in (0, 1, 2, 3);
  end loop;

  ----------------------------------------------------------------------------
  -- Campers: 64 in session 1, 40 in session 2
  ----------------------------------------------------------------------------
  insert into public.campers (session_id, first_name, preferred_name, last_name, gender, birthdate, cabin_id, arrived, can_swim)
  select
    s.id,
    f.name,
    case when (n % 9) = 0 then substr(f.name, 1, 3) end,
    l.name,
    (array['M', 'F', 'NB'])[1 + (n % 3)],
    date '2018-06-15' - ((n * 37) % 2400),
    cab.id,
    (n % 4) <> 0,
    (n % 5) <> 0
  from public.sessions s
  cross join lateral generate_series(1, case s.name when 'Session 1' then 64 else 40 end) n
  cross join lateral (
    select (array['Avery','Blake','Casey','Devon','Emerson','Finley','Gray','Harper','Indigo','Jules','Kai','Logan',
                  'Morgan','Noel','Oakley','Parker','Quinn','Reese','Sage','Taylor','Uma','Vesper','Wren','Yael'])[1 + (n % 24)] as name
  ) f
  cross join lateral (
    select (array['Abbott','Brooks','Chavez','Dunn','Ellis','Foster','Garcia','Hughes','Ito','Jensen','Khan','Lopez',
                  'Murphy','Nguyen','Ortiz','Patel','Quigley','Rossi','Singh','Tran','Underwood','Voss','Walker','Young'])[1 + ((n * 7 + n / 24) % 24)] as name
  ) l
  join lateral (
    select sc.cabin_id as id
    from public.session_cabins sc
    join public.cabins c on c.id = sc.cabin_id
    where sc.session_id = s.id
    order by c.position
    offset (n % 8) limit 1
  ) cab on true
  where s.name in ('Session 1', 'Session 2')
  on conflict do nothing;

  -- Roughly 70% of campers have already told us what they want: two
  -- requests and one veto among the standard activities they could be given.
  insert into public.camper_preferences (session_id, camper_id, activity_id, kind)
  select c.session_id, c.id, pick.activity_id, pick.kind
  from public.campers c
  cross join lateral (
    select ranked.activity_id,
           case when ranked.rn <= 2 then 'request'::public.preference_kind else 'veto'::public.preference_kind end as kind
    from (
      select a.id as activity_id,
             row_number() over (order by md5(c.id::text || a.id::text)) as rn
      from public.activities a
      where a.branch_id = v_branch and not a.is_skills_rec and not a.is_hidden
    ) ranked
    where ranked.rn <= 3
  ) pick
  where (('x' || substr(md5(c.id::text), 1, 4))::bit(16)::int % 10) < 7;

  update public.campers c
  set preferences_submitted_at = now()
  where exists (select 1 from public.camper_preferences p where p.camper_id = c.id);

  ----------------------------------------------------------------------------
  -- Staff accounts (GoTrue needs the empty-string token columns)
  ----------------------------------------------------------------------------
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, email_change, email_change_token_new, recovery_token
  )
  select
    '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated', u.email,
    extensions.crypt('password123', extensions.gen_salt('bf')), now(),
    jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email'),
                       'organization_id', v_org, 'role', u.role),
    jsonb_build_object('first_name', u.first_name, 'last_name', u.last_name),
    now(), now(), '', '', '', ''
  from (values
    ('00000000-0000-4000-8000-0000000000a1'::uuid, 'director@bessie.test',  'director',  'Dana',  'Director'),
    ('00000000-0000-4000-8000-0000000000a2'::uuid, 'admin@bessie.test',     'admin',     'Alex',  'Admin'),
    ('00000000-0000-4000-8000-0000000000a3'::uuid, 'counselor@bessie.test', 'counselor', 'Casey', 'Counselor')
  ) as u(id, email, role, first_name, last_name);

  insert into auth.identities (id, user_id, provider_id, provider, identity_data, last_sign_in_at, created_at, updated_at)
  select
    gen_random_uuid(), u.id, u.id::text, 'email',
    jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
    now(), now(), now()
  from auth.users u
  where u.email like '%@bessie.test';
end
$seed$;
