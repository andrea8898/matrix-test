-- Matrix Test API. Apply after 001_matrix_test.sql.
-- All client-facing access is through Edge Functions using a server-held service key.
-- RLS remains enabled with no direct policies for the anon role.

alter table public.profiles
  add column if not exists password_salt text not null default '',
  add column if not exists password_hash text not null default '',
  add column if not exists last_seen_at timestamptz;

create table if not exists public.device_sessions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  token_hash text not null unique,
  device_label text not null check (char_length(device_label) between 1 and 80),
  expires_at timestamptz not null,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create index if not exists device_sessions_token_active
  on public.device_sessions(token_hash) where revoked_at is null;
create index if not exists envelopes_recipient_created
  on public.envelopes(recipient_id, created_at);

-- Bootstrap Ghost / Black exactly once via the Edge Function and a deployment secret.
-- Do not put its bootstrap value, password or local device PIN in this SQL file.
create or replace function public.matrix_bootstrap_founder(
  p_display_name text, p_username citext, p_public_key text,
  p_password_salt text, p_password_hash text, p_token_hash text, p_device_label text
) returns table(profile_id uuid, public_code text, session_id uuid)
language plpgsql security definer set search_path = public as $$
declare new_id uuid; new_sequence bigint; new_session uuid;
begin
  if exists (select 1 from public.profiles where is_founder) then
    raise exception 'founder already exists';
  end if;
  if p_display_name <> 'Ghost' or p_username <> 'Black' then
    raise exception 'founder identity must be Ghost / Black';
  end if;
  insert into public.profiles(display_name, username, identity_public_key, password_salt, password_hash, is_founder, status, last_seen_at)
  values (p_display_name, p_username, decode(p_public_key, 'base64'), p_password_salt, p_password_hash, true, 'online', now())
  returning id, sequence_no into new_id, new_sequence;
  insert into public.device_sessions(profile_id, token_hash, device_label, expires_at)
  values (new_id, p_token_hash, p_device_label, now() + interval '30 days') returning id into new_session;
  return query select new_id, 'E' || new_sequence::text, new_session;
end; $$;

create or replace function public.matrix_register(
  p_display_name text, p_username citext, p_public_key text,
  p_password_salt text, p_password_hash text, p_token_hash text, p_device_label text
) returns table(profile_id uuid, public_code text, session_id uuid)
language plpgsql security definer set search_path = public as $$
declare new_id uuid; new_sequence bigint; new_session uuid;
begin
  if not exists (select 1 from public.profiles where is_founder) then
    raise exception 'service is not initialized';
  end if;
  if exists (select 1 from public.profiles where username = p_username) then
    raise exception 'username already in use';
  end if;
  insert into public.profiles(display_name, username, identity_public_key, password_salt, password_hash, status, last_seen_at)
  values (p_display_name, p_username, decode(p_public_key, 'base64'), p_password_salt, p_password_hash, 'online', now())
  returning id, sequence_no into new_id, new_sequence;
  insert into public.device_sessions(profile_id, token_hash, device_label, expires_at)
  values (new_id, p_token_hash, p_device_label, now() + interval '30 days') returning id into new_session;
  return query select new_id, 'E' || new_sequence::text, new_session;
end; $$;

-- Only service_role may execute these functions; never grant execute to anon/authenticated.
revoke all on function public.matrix_bootstrap_founder(text,citext,text,text,text,text,text) from public;
revoke all on function public.matrix_register(text,citext,text,text,text,text,text) from public;

create or replace view public.matrix_admin_summary with (security_invoker = true) as
select
  count(*) filter (where disabled_at is null) as registered_accounts,
  count(*) filter (where disabled_at is null and status = 'online') as online_accounts,
  count(*) filter (where disabled_at is not null) as disabled_accounts
from public.profiles;
