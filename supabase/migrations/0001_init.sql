-- ============================================================================
-- Atlas — Prototype schema (single-user blob storage)
--
-- This is a USAGE-TESTING prototype, not a production schema. The real
-- web app will use a proper relational schema with businesses/persons/
-- activities tables; here we just persist the full client state as JSON
-- so we can ship a working multi-user prototype in 15 minutes.
--
-- Apply via Supabase Dashboard → SQL Editor → New query → paste → Run.
-- ============================================================================

create extension if not exists "pgcrypto";

-- ----------------------------------------------------------------------------
-- One row per authenticated user. Holds the entire app state as a JSON blob.
-- ----------------------------------------------------------------------------
create table if not exists public.app_state (
  user_id    uuid primary key references auth.users on delete cascade,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- ----------------------------------------------------------------------------
-- RLS: each user sees and writes only their own row
-- ----------------------------------------------------------------------------
alter table public.app_state enable row level security;

drop policy if exists "app_state read own" on public.app_state;
create policy "app_state read own"
  on public.app_state for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "app_state insert own" on public.app_state;
create policy "app_state insert own"
  on public.app_state for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists "app_state update own" on public.app_state;
create policy "app_state update own"
  on public.app_state for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

drop policy if exists "app_state delete own" on public.app_state;
create policy "app_state delete own"
  on public.app_state for delete to authenticated
  using (user_id = auth.uid());

-- ----------------------------------------------------------------------------
-- Auto-touch updated_at on update
-- ----------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;

drop trigger if exists trg_touch_app_state on public.app_state;
create trigger trg_touch_app_state
  before update on public.app_state
  for each row execute function public.touch_updated_at();
