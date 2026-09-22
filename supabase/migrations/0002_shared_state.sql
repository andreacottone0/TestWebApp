-- ============================================================================
-- Atlas — shared public state
-- One single organigramma shared by everyone who has the link (no login).
-- The app still signs in anonymously, but reads/writes the row id='main'.
-- ============================================================================

create table if not exists public.atlas_shared (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.atlas_shared enable row level security;

drop policy if exists "atlas_shared read"   on public.atlas_shared;
drop policy if exists "atlas_shared insert" on public.atlas_shared;
drop policy if exists "atlas_shared update" on public.atlas_shared;

create policy "atlas_shared read"   on public.atlas_shared for select to anon, authenticated using (true);
create policy "atlas_shared insert" on public.atlas_shared for insert to anon, authenticated with check (id = 'main');
create policy "atlas_shared update" on public.atlas_shared for update to anon, authenticated using (id = 'main') with check (id = 'main');
-- No delete policy: the shared row can't be wiped from the browser.

drop trigger if exists trg_touch_atlas_shared on public.atlas_shared;
create trigger trg_touch_atlas_shared
  before update on public.atlas_shared
  for each row execute function public.touch_updated_at();

-- Seed with the most recent real state (2026-07-07)
insert into public.atlas_shared (id, data)
select 'main', data from public.app_state
where user_id = '5b074bad-40ef-41a2-bcc7-4cbbad4d8e46'
on conflict (id) do nothing;
