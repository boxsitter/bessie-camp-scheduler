-- Live roster updates. Realtime applies RLS to every change it broadcasts, so
-- subscribers only ever see their organization's rows.

alter publication supabase_realtime add table
  public.campers,
  public.assignments,
  public.camper_preferences,
  public.scheduled_activities,
  public.blocks,
  public.session_cabins;

-- Filtered subscriptions (`session_id = eq.<id>`) need the full old row to
-- match DELETE events, not just the primary key.
alter table public.campers replica identity full;
alter table public.assignments replica identity full;
alter table public.camper_preferences replica identity full;
alter table public.scheduled_activities replica identity full;
alter table public.blocks replica identity full;
alter table public.session_cabins replica identity full;
