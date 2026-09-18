-- MATRIX TEST: run in a new dedicated Supabase project only.
-- This is deliberately a schema/bootstrap plan. Authentication and all privileged actions
-- must run in Edge Functions or another server environment, never in the iPhone client.

create extension if not exists pgcrypto;
create extension if not exists citext;

create table public.profiles (
  id uuid primary key default gen_random_uuid(),
  sequence_no bigint generated always as identity unique not null
    check (sequence_no between 1 and 10000000000),
  username citext not null unique check (username ~ '^[A-Za-z0-9_.-]{3,24}$'),
  display_name text not null check (char_length(display_name) between 1 and 24),
  public_key bytea not null,
  status text not null default 'offline' check (status in ('online', 'offline')),
  is_founder boolean not null default false,
  disabled_at timestamptz,
  created_at timestamptz not null default now()
);

create unique index exactly_one_founder on public.profiles (is_founder) where is_founder;

create view public.directory as
select id, ('E' || sequence_no::text) as public_code, username, display_name, status
from public.profiles
where disabled_at is null;

create table public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  state text not null default 'pending' check (state in ('pending', 'accepted', 'rejected')),
  created_at timestamptz not null default now(),
  unique (sender_id, recipient_id), check (sender_id <> recipient_id)
);

-- Only ciphertext, encryption metadata and expiration are stored. No plaintext column.
create table public.envelopes (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  ciphertext bytea not null,
  encryption_header bytea not null,
  media_ciphertext bytea,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null
);

-- Enable RLS before exposing any table. Policies are intentionally not permissive here.
alter table public.profiles enable row level security;
alter table public.friend_requests enable row level security;
alter table public.envelopes enable row level security;

-- SECURITY REQUIREMENTS
-- 1. Create accounts through a server-only function that checks duplicate usernames.
-- 2. Provision Ghost / Black as the single founder through server secrets, never SQL literals
--    for password or local code. Only the server may set is_founder.
-- 3. Ban/disable actions must be server-only and must not expose ciphertext to the founder.
-- 4. Add rate limiting, device abuse protections and audit logging before external testers.
