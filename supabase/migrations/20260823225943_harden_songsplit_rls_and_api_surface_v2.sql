-- SongSplit live security hardening
-- Applied to the production Supabase project on 2026-08-23.
--
-- Goals:
--   * deny anonymous access to sensitive application tables
--   * require authenticated ownership/participation for session data
--   * keep email delivery queue service-side only
--   * make the session_summary view honor caller RLS
--   * remove direct execution of trigger/security-definer helpers
--   * default future public-schema objects to least privilege

begin;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

-- Existing public sessions are private by default after this migration.
update public.sessions set is_public = false where is_public is true;
alter table public.sessions alter column is_public set default false;

-- Helper functions used by RLS. SECURITY DEFINER avoids recursive RLS lookups;
-- access is restricted to authenticated callers and each function returns only
-- an authorization boolean.
create or replace function private.is_session_creator(p_session_id text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
  select exists (
    select 1
    from public.sessions s
    where s.id = p_session_id
      and s.created_by = auth.uid()
  );
$$;

create or replace function private.session_is_unfinalized(p_session_id text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $$
  select exists (
    select 1
    from public.sessions s
    where s.id = p_session_id
      and s.finalized = false
  );
$$;

create or replace function private.is_session_participant(p_session_id text)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
  select exists (
    select 1
    from public.sessions s
    where s.id = p_session_id
      and (
        s.created_by = auth.uid()
        or exists (
          select 1 from public.contributors c
          where c.session_id = s.id and c.user_id = auth.uid()
        )
        or exists (
          select 1 from public.collaborators c
          where c.session_id = s.id and c.user_id = auth.uid()
        )
      )
  );
$$;

revoke all on function private.is_session_creator(text) from public, anon;
revoke all on function private.session_is_unfinalized(text) from public, anon;
revoke all on function private.is_session_participant(text) from public, anon;
grant execute on function private.is_session_creator(text) to authenticated;
grant execute on function private.session_is_unfinalized(text) to authenticated;
grant execute on function private.is_session_participant(text) to authenticated;

-- Remove legacy permissive policies.
drop policy if exists "Allow all" on public.sessions;
drop policy if exists "Creators can update their sessions" on public.sessions;
drop policy if exists "Public sessions are viewable by everyone" on public.sessions;
drop policy if exists "Users can create sessions" on public.sessions;
drop policy if exists "Session participants can read" on public.sessions;
drop policy if exists "Authenticated users create sessions" on public.sessions;
drop policy if exists "Only creator can update unfinalized" on public.sessions;

drop policy if exists "Contributors are viewable by everyone" on public.contributors;
drop policy if exists "Users can delete contributors" on public.contributors;
drop policy if exists "Users can join sessions" on public.contributors;
drop policy if exists "Users can update contributors" on public.contributors;
drop policy if exists "Contributors readable by participants" on public.contributors;
drop policy if exists "Participants can add contributors" on public.contributors;
drop policy if exists "Only self can update own contributor" on public.contributors;
drop policy if exists "Only self can delete own contributor" on public.contributors;

drop policy if exists "Allow all" on public.collaborators;

drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
drop policy if exists "Public profiles readable" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users insert own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Users update own profile" on public.profiles;

drop policy if exists "Participants can manage samples" on public.samples;
drop policy if exists "Samples readable by participants" on public.samples;

drop policy if exists "Users can save sessions" on public.saved_sessions;
drop policy if exists "Users can unsave sessions" on public.saved_sessions;
drop policy if exists "Users can view own saved sessions" on public.saved_sessions;

drop policy if exists "Templates manageable by owner" on public.templates;
drop policy if exists "Templates readable by owner" on public.templates;

drop policy if exists "System can manage emails" on public.email_notifications;

-- Sessions: authenticated creator owns mutations; participants may read.
create policy "Participants can view sessions"
on public.sessions for select
to authenticated
using (private.is_session_participant(id));

create policy "Authenticated users create owned sessions"
on public.sessions for insert
to authenticated
with check (auth.uid() is not null and created_by = auth.uid());

create policy "Creators can update unfinalized sessions"
on public.sessions for update
to authenticated
using (created_by = auth.uid() and finalized = false)
with check (created_by = auth.uid());

create policy "Creators can delete unfinalized sessions"
on public.sessions for delete
to authenticated
using (created_by = auth.uid() and finalized = false);

-- Contributors: participants can read; creators control membership/terms;
-- a linked contributor may update their own row while the session is open.
create policy "Participants can view contributors"
on public.contributors for select
to authenticated
using (private.is_session_participant(session_id));

create policy "Creators can add contributors"
on public.contributors for insert
to authenticated
with check (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

create policy "Creator or self can update contributors"
on public.contributors for update
to authenticated
using (
  private.session_is_unfinalized(session_id)
  and (private.is_session_creator(session_id) or user_id = auth.uid())
)
with check (
  private.session_is_unfinalized(session_id)
  and (private.is_session_creator(session_id) or user_id = auth.uid())
);

create policy "Creators can delete contributors"
on public.contributors for delete
to authenticated
using (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

-- Legacy collaborators table: creator controls mutations, participants can read.
create policy "Participants can view collaborators"
on public.collaborators for select
to authenticated
using (private.is_session_participant(session_id));

create policy "Creators can add collaborators"
on public.collaborators for insert
to authenticated
with check (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

create policy "Creators can update collaborators"
on public.collaborators for update
to authenticated
using (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
)
with check (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

create policy "Creators can delete collaborators"
on public.collaborators for delete
to authenticated
using (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

-- Profiles are private to their owner.
create policy "Owners can view own profile"
on public.profiles for select
to authenticated
using (auth.uid() = id);

create policy "Owners can insert own profile"
on public.profiles for insert
to authenticated
with check (auth.uid() = id);

create policy "Owners can update own profile"
on public.profiles for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- Samples follow session participation; only the creator mutates them.
create policy "Participants can view samples"
on public.samples for select
to authenticated
using (private.is_session_participant(session_id));

create policy "Creators can add samples"
on public.samples for insert
to authenticated
with check (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

create policy "Creators can update samples"
on public.samples for update
to authenticated
using (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
)
with check (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

create policy "Creators can delete samples"
on public.samples for delete
to authenticated
using (
  private.is_session_creator(session_id)
  and private.session_is_unfinalized(session_id)
);

-- Saved sessions are strictly per-user.
create policy "Owners can view saved sessions"
on public.saved_sessions for select
to authenticated
using (auth.uid() = user_id);

create policy "Owners can save sessions"
on public.saved_sessions for insert
to authenticated
with check (
  auth.uid() = user_id
  and private.is_session_participant(session_id)
);

create policy "Owners can unsave sessions"
on public.saved_sessions for delete
to authenticated
using (auth.uid() = user_id);

-- Templates remain authenticated. Public templates are visible only after sign-in.
create policy "Authenticated users can view available templates"
on public.templates for select
to authenticated
using (user_id = auth.uid() or is_public = true);

create policy "Owners can create templates"
on public.templates for insert
to authenticated
with check (user_id = auth.uid());

create policy "Owners can update templates"
on public.templates for update
to authenticated
using (user_id = auth.uid())
with check (user_id = auth.uid());

create policy "Owners can delete templates"
on public.templates for delete
to authenticated
using (user_id = auth.uid());

-- Data API grants: anonymous clients cannot touch sensitive tables at all.
revoke all privileges on table public.sessions from anon;
revoke all privileges on table public.contributors from anon;
revoke all privileges on table public.collaborators from anon;
revoke all privileges on table public.profiles from anon;
revoke all privileges on table public.samples from anon;
revoke all privileges on table public.saved_sessions from anon;
revoke all privileges on table public.templates from anon;
revoke all privileges on table public.email_notifications from anon;

-- Authenticated clients get only application-table operations; RLS narrows rows.
grant select, insert, update, delete on table public.sessions to authenticated;
grant select, insert, update, delete on table public.contributors to authenticated;
grant select, insert, update, delete on table public.collaborators to authenticated;
grant select, insert, update on table public.profiles to authenticated;
grant select, insert, update, delete on table public.samples to authenticated;
grant select, insert, delete on table public.saved_sessions to authenticated;
grant select, insert, update, delete on table public.templates to authenticated;

-- Email queue is service-side only.
revoke all privileges on table public.email_notifications from authenticated;
grant all privileges on table public.email_notifications to service_role;

-- Views should honor the caller's RLS context.
alter view public.session_summary set (security_invoker = true);
revoke all privileges on table public.session_summary from anon;
grant select on table public.session_summary to authenticated;

-- Harden trigger/helper function execution and search paths.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public, auth
as $$
begin
  insert into public.profiles (id, email, legal_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create or replace function public.handle_updated_at()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
begin
  new.updated_at = timezone('utc'::text, now());
  return new;
end;
$$;

create or replace function public.increment_template_usage(template_id uuid)
returns void
language plpgsql
set search_path = pg_catalog, public, auth
as $$
begin
  update public.templates
  set usage_count = usage_count + 1,
      last_used_at = timezone('utc'::text, now())
  where id = template_id
    and user_id = auth.uid();
end;
$$;

create or replace function public.queue_email_notification(
  p_to_email text,
  p_to_name text,
  p_subject text,
  p_template_name text,
  p_template_data jsonb,
  p_session_id text default null
)
returns uuid
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  notification_id uuid;
begin
  insert into public.email_notifications (
    to_email, to_name, subject, template_name, template_data, session_id
  ) values (
    p_to_email, p_to_name, p_subject, p_template_name, p_template_data, p_session_id
  )
  returning id into notification_id;
  return notification_id;
end;
$$;

-- Fix finalization validation to use the session row's id (NEW.id), not NEW.session_id.
create or replace function public.validate_ownership_total()
returns trigger
language plpgsql
set search_path = pg_catalog, public
as $$
declare
  total_master_bps integer;
  total_publishing_bps integer;
  sample_deduction_master integer;
  sample_deduction_publishing integer;
begin
  select coalesce(sum(master_bps), 0) into total_master_bps
  from public.contributors
  where session_id = new.id and is_work_for_hire = false;

  select coalesce(sum(publishing_bps), 0) into total_publishing_bps
  from public.contributors
  where session_id = new.id and is_work_for_hire = false;

  select coalesce(sum(deduction_master_bps), 0) into sample_deduction_master
  from public.samples
  where session_id = new.id and affects_master = true;

  select coalesce(sum(deduction_publishing_bps), 0) into sample_deduction_publishing
  from public.samples
  where session_id = new.id and affects_publishing = true;

  if new.finalized = true and old.finalized = false then
    if (total_master_bps - sample_deduction_master) != 10000 then
      raise exception 'Master ownership must equal 100%%';
    end if;
    if (total_publishing_bps - sample_deduction_publishing) != 10000 then
      raise exception 'Publishing ownership must equal 100%%';
    end if;
  end if;

  return new;
end;
$$;

revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.handle_updated_at() from public, anon, authenticated;
revoke execute on function public.update_updated_at_column() from public, anon, authenticated;
revoke execute on function public.validate_ownership_total() from public, anon, authenticated;

revoke execute on function public.increment_template_usage(uuid) from public, anon;
grant execute on function public.increment_template_usage(uuid) to authenticated;

revoke execute on function public.queue_email_notification(text,text,text,text,jsonb,text) from public, anon, authenticated;
grant execute on function public.queue_email_notification(text,text,text,text,jsonb,text) to service_role;

-- New public-schema objects are opt-in rather than automatically exposed.
alter default privileges for role postgres in schema public
  revoke select, insert, update, delete, truncate, references, trigger on tables from anon, authenticated;
alter default privileges for role postgres in schema public
  revoke execute on functions from public, anon, authenticated;

commit;
