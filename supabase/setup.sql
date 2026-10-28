-- Pourover Log database setup.
-- Paste this whole file into Supabase → SQL Editor → New query, then click Run.
-- Safe to run more than once.

-- One row per brew. The brew's details live in `data` (JSON), so adding new
-- fields to the app later doesn't need any database changes.
create table if not exists public.brews (
  id          uuid primary key,
  user_id     uuid not null default auth.uid() references auth.users (id) on delete cascade,
  data        jsonb not null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create index if not exists brews_user_id_idx on public.brews (user_id);

-- Row Level Security: the database itself makes sure each signed-in user can
-- only see and change their own brews, even though the app's code is public.
alter table public.brews enable row level security;

drop policy if exists "Users can read their own brews" on public.brews;
create policy "Users can read their own brews"
  on public.brews for select
  to authenticated
  using ((select auth.uid()) = user_id);
drop policy if exists "Users can add their own brews" on public.brews;
create policy "Users can add their own brews"
  on public.brews for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update their own brews" on public.brews;
create policy "Users can update their own brews"
  on public.brews for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "Users can delete their own brews" on public.brews;
create policy "Users can delete their own brews"
  on public.brews for delete
  to authenticated
  using ((select auth.uid()) = user_id);
