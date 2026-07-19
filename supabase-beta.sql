-- ═══════════════════════════════════════════════════════════════════
--  SUCROSE TACTIC (closed beta) — Supabase schema + row-level security
--  Project: sucrose-tactic (nauthibrxazwiywosmjz, ap-southeast-1)
--
--  This file documents the exact SQL applied to the beta database
--  (same pattern as supabase-setup.sql in the private repo).
--  Design: every org's scenarios are isolated by RLS — the anon key
--  alone can read nothing except hero names and the public logo wall.
--  Auth is Google OAuth + email magic links. Dashboard signups are
--  ENABLED (required for both flows to create invited users); the
--  beta_invites trigger at the bottom of this file is the actual gate.
--  Onboarding: see the "Beta invite gate" section below.
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

-- ── Beta invite gate (Google OAuth) ────────────────────────────────
-- Migration: beta_invites_gate. Google sign-in creates users on first
-- login, so the whitelist moves to an invite table enforced by
-- triggers on auth.users. New onboarding (replaces the 3 manual steps
-- in the header):
--   1. insert into orgs (name) values ('Org Name') returning id;
--   2. insert into beta_invites (email, org_id) values ('coach@team.gg', '<org id>');
-- First sign-in (Google or magic link) auto-inserts org_members.
-- Uninvited emails are rejected before the auth user is created.

create table beta_invites (
  email      text primary key check (email = lower(email)),
  org_id     uuid not null references orgs (id) on delete cascade,
  invited_at timestamptz not null default now()
);
-- No policies on purpose: invites are managed from the dashboard /
-- service role only; the anon + authenticated keys can read nothing.
alter table beta_invites enable row level security;

-- Gate: reject creation of any auth user whose email is not invited.
-- Also reject password-bearing signups outright: the site only offers
-- Google OAuth and magic links, so a password signup is an API-level
-- probe — and allowing it would let someone pre-empt an invited
-- coach's email with their own password before the coach's first login.
create or replace function public.gate_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.email is null
     or not exists (select 1 from beta_invites where email = lower(new.email)) then
    raise exception 'not invited to the beta';
  end if;
  if coalesce(new.encrypted_password, '') <> '' then
    raise exception 'password signups are not supported';
  end if;
  return new;
end $$;

-- Trigger functions are not API endpoints — no direct EXECUTE.
revoke execute on function public.gate_new_user() from public, anon, authenticated;
revoke execute on function public.link_new_user() from public, anon, authenticated;

create trigger beta_gate_before_user_created
  before insert on auth.users
  for each row execute function public.gate_new_user();

-- Auto-link: on first sign-in, attach the new user to their invited org.
create or replace function public.link_new_user()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare v_org uuid;
begin
  select org_id into v_org from beta_invites where email = lower(new.email);
  if v_org is not null then
    insert into org_members (user_id, org_id)
    values (new.id, v_org)
    on conflict (user_id) do nothing;
  end if;
  return new;
end $$;

create trigger beta_link_after_user_created
  after insert on auth.users
  for each row execute function public.link_new_user();

-- Backfill: every existing member is implicitly invited, so Google
-- identity-linking keeps working for accounts created by hand.
insert into beta_invites (email, org_id)
select lower(u.email), m.org_id
from auth.users u
join org_members m on m.user_id = u.id
where u.email is not null
on conflict (email) do nothing;

-- ── Admin onboarding helper ────────────────────────────────────────
-- Migration: admin_onboard_helper. One call per team, SQL editor only:
--   select admin_onboard('coach@team.gg', 'Team Name');
-- Creates the org if new, upserts the invite, and links the account
-- immediately if it already exists (pre-gate signups).
create or replace function public.admin_onboard(p_email text, p_org_name text)
returns text
language plpgsql security definer set search_path = public
as $$
declare v_org uuid; v_uid uuid;
begin
  p_email := lower(trim(p_email));
  select id into v_org from orgs where name = p_org_name;
  if v_org is null then
    insert into orgs (name) values (p_org_name) returning id into v_org;
  end if;
  insert into beta_invites (email, org_id) values (p_email, v_org)
  on conflict (email) do update set org_id = excluded.org_id;
  select id into v_uid from auth.users where lower(email) = p_email;
  if v_uid is not null then
    insert into org_members (user_id, org_id) values (v_uid, v_org)
    on conflict (user_id) do nothing;
    return p_email || ' invited + existing account linked to ' || p_org_name;
  end if;
  return p_email || ' invited — will be linked to ' || p_org_name || ' on first sign-in';
end $$;
-- Admin-only: not callable through the API.
revoke execute on function public.admin_onboard(text, text) from public, anon, authenticated;
