-- ═══════════════════════════════════════════════════════════════════
--  SUCROSE TACTIC (closed beta) — Supabase schema + row-level security
--  Project: sucrose-tactic (nauthibrxazwiywosmjz, ap-southeast-1)
--
--  This file documents the exact SQL applied to the beta database
--  (same pattern as supabase-setup.sql in the private repo).
--  Design: every org's scenarios are isolated by RLS — the anon key
--  alone can read nothing except hero names and the public logo wall.
--  Auth is Supabase email magic links; signups are DISABLED in the
--  dashboard. Each beta org is onboarded by hand:
--    1. Dashboard → Auth → create the user by email
--    2. insert into orgs (name) values ('Org Name') returning id;
--    3. insert into org_members (user_id, org_id) values ('<auth uid>', '<org id>');
-- ═══════════════════════════════════════════════════════════════════

-- ── Tables ─────────────────────────────────────────────────────────

create table orgs (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  logo_url   text,                -- Storage public bucket 'logos/'; null = not on the wall
  created_at timestamptz not null default now()
);

create table org_members (
  user_id      uuid primary key references auth.users (id) on delete cascade,
  org_id       uuid not null references orgs (id) on delete cascade,
  role         text not null default 'member',
  display_name text               -- shown on "last edited by"; never an email
);

-- helper: the caller's org. SECURITY DEFINER so policies on org_members
-- itself can use it without recursing into their own table.
create or replace function my_org_id() returns uuid
language sql stable security definer set search_path = public
as $$ select org_id from org_members where user_id = auth.uid() $$;
-- Postgres grants EXECUTE to PUBLIC on new functions by default — lock
-- this one down to signed-in users only.
revoke execute on function my_org_id() from public;
revoke execute on function my_org_id() from anon;
grant execute on function my_org_id() to authenticated;

create table scenarios (
  id            uuid primary key default gen_random_uuid(),
  org_id        uuid not null references orgs (id) on delete cascade,
  name          text not null,
  tags          text[] not null default '{}',
  board_state   jsonb,
  preview_image text,             -- small JPEG data-URL thumbnail
  updated_by    uuid references auth.users (id),
  updated_at    timestamptz not null default now()
);

-- copied once from the main project; service-role write only
create table heroes (
  name  text primary key,
  roles jsonb
);

-- ── Row-level security ─────────────────────────────────────────────
-- RLS on for EVERY table. A leak must require a policy bug, not a
-- client bug.

alter table orgs        enable row level security;
alter table org_members enable row level security;
alter table scenarios   enable row level security;
alter table heroes      enable row level security;

-- scenarios: members can do everything, but only inside their own org
create policy scenarios_by_org on scenarios
  for all to authenticated
  using     (org_id = (select org_id from org_members where user_id = auth.uid()))
  with check (org_id = (select org_id from org_members where user_id = auth.uid()));

-- org_members: members see their org-mates (for "last edited by") and can
-- edit their own display name; no anon access
create policy members_read_org on org_members
  for select to authenticated
  using (org_id = my_org_id());
create policy members_update_self on org_members
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid() and org_id = my_org_id());

-- orgs: members can read their own org's row (no anon access)
create policy orgs_read_own on orgs
  for select to authenticated
  using (id = (select org_id from org_members where user_id = auth.uid()));

-- heroes: public read-only (anon + signed-in); no write policy at all
create policy heroes_public_read on heroes
  for select to anon, authenticated
  using (true);

-- ── Public logo wall ───────────────────────────────────────────────
-- The landing page renders beta-team logos without a login. Org
-- existence is public ONLY when a logo was provided. The view runs as
-- its owner (not the caller), which is what lets anon read these two
-- columns while the orgs table itself stays locked.

create view public_logo_wall as
  select name, logo_url from orgs where logo_url is not null;

grant select on public_logo_wall to anon, authenticated;
