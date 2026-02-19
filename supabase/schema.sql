-- SplitSheet Database Schema - Music Ownership Agreement Engine
-- Run this in your Supabase SQL Editor

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES TABLE (extends auth.users)
-- ============================================
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  legal_name text,
  artist_name text,
  email text,
  pro_affiliation text default 'ASCAP',
  ipi_number text,
  avatar_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- ============================================
-- SESSIONS TABLE (Recording Session)
-- ============================================
create table if not exists public.sessions (
  id text primary key,
  song_title text default '',
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  finalized boolean default false not null,
  finalized_at timestamp with time zone,
  hash text,
  is_public boolean default true
);

-- ============================================
-- CONTRIBUTORS TABLE (Artists, Producers, Writers, etc.)
-- ============================================
create table if not exists public.contributors (
  id uuid default gen_random_uuid() primary key,
  session_id text references public.sessions(id) on delete cascade not null,
  user_id uuid references auth.users(id) on delete set null,
  
  -- Identity
  legal_name text not null default '',
  email text,
  
  -- Role in the creation process
  role text default 'Writer', -- Artist, Producer, Writer, Engineer, Featured, Other
  
  -- Rights ownership type
  rights_type text default 'Both', -- Master, Publishing, Both
  
  -- Ownership percentage (0-100)
  percentage integer default 0 check (percentage >= 0 and percentage <= 100),
  
  -- PRO Information
  pro_affiliation text default 'ASCAP',
  ipi_number text,
  
  -- Digital signature
  signature_data text,
  signed_at timestamp with time zone,
  
  -- Metadata
  is_creator boolean default false not null,
  device_id text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Unique constraint - only one entry per user/device per session
CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_contributor 
ON public.contributors (session_id, COALESCE(user_id, device_id));

-- ============================================
-- SAVED SESSIONS
-- ============================================
create table if not exists public.saved_sessions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references auth.users(id) on delete cascade not null,
  session_id text references public.sessions(id) on delete cascade not null,
  saved_at timestamp with time zone default timezone('utc'::text, now()) not null,
  notes text,
  unique(user_id, session_id)
);

-- ============================================
-- INDEXES
-- ============================================
create index if not exists idx_contributors_session on public.contributors(session_id);
create index if not exists idx_contributors_user on public.contributors(user_id);
create index if not exists idx_contributors_device on public.contributors(device_id);
create index if not exists idx_sessions_created_by on public.sessions(created_by);
create index if not exists idx_sessions_finalized on public.sessions(finalized);
create index if not exists idx_saved_sessions_user on public.saved_sessions(user_id);
create index if not exists idx_profiles_email on public.profiles(email);

-- ============================================
-- ENABLE REALTIME (Safe version)
-- ============================================
DO $$
DECLARE
  tables_to_add text[] := ARRAY['sessions', 'contributors', 'profiles'];
  t text;
BEGIN
  FOREACH t IN ARRAY tables_to_add LOOP
    BEGIN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    EXCEPTION 
      WHEN duplicate_object THEN
        RAISE NOTICE 'Table % already in publication', t;
      WHEN OTHERS THEN
        RAISE NOTICE 'Could not add table %: %', t, SQLERRM;
    END;
  END LOOP;
END $$;

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Profiles
alter table public.profiles enable row level security;

drop policy if exists "Public profiles are viewable by everyone" on public.profiles;
create policy "Public profiles are viewable by everyone"
  on public.profiles for select using (true);

drop policy if exists "Users can insert their own profile" on public.profiles;
create policy "Users can insert their own profile"
  on public.profiles for insert with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update using (auth.uid() = id);

-- Sessions
alter table public.sessions enable row level security;

drop policy if exists "Public sessions are viewable by everyone" on public.sessions;
create policy "Public sessions are viewable by everyone"
  on public.sessions for select using (is_public = true or auth.uid() = created_by);

drop policy if exists "Users can create sessions" on public.sessions;
create policy "Users can create sessions"
  on public.sessions for insert with check (true);

drop policy if exists "Creators can update their sessions" on public.sessions;
create policy "Creators can update their sessions"
  on public.sessions for update using (auth.uid() = created_by or created_by is null);

-- Contributors
alter table public.contributors enable row level security;

drop policy if exists "Contributors are viewable by everyone" on public.contributors;
create policy "Contributors are viewable by everyone"
  on public.contributors for select using (true);

drop policy if exists "Users can join sessions" on public.contributors;
create policy "Users can join sessions"
  on public.contributors for insert with check (true);

drop policy if exists "Users can update contributors" on public.contributors;
create policy "Users can update contributors"
  on public.contributors for update using (true);

drop policy if exists "Users can delete contributors" on public.contributors;
create policy "Users can delete contributors"
  on public.contributors for delete using (true);

-- Saved Sessions
alter table public.saved_sessions enable row level security;

drop policy if exists "Users can view own saved sessions" on public.saved_sessions;
create policy "Users can view own saved sessions"
  on public.saved_sessions for select using (auth.uid() = user_id);

drop policy if exists "Users can save sessions" on public.saved_sessions;
create policy "Users can save sessions"
  on public.saved_sessions for insert with check (auth.uid() = user_id);

drop policy if exists "Users can unsave sessions" on public.saved_sessions;
create policy "Users can unsave sessions"
  on public.saved_sessions for delete using (auth.uid() = user_id);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Auto-update timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply triggers
DROP TRIGGER IF EXISTS on_profile_updated ON public.profiles;
CREATE TRIGGER on_profile_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS on_contributor_updated ON public.contributors;
CREATE TRIGGER on_contributor_updated
  BEFORE UPDATE ON public.contributors
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create profile on user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, legal_name)
  VALUES (
    NEW.id, 
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- VIEWS
-- ============================================

DROP VIEW IF EXISTS public.session_summary;
CREATE OR REPLACE VIEW public.session_summary AS
SELECT 
  s.id,
  s.song_title,
  s.created_by,
  s.created_at,
  s.finalized,
  s.finalized_at,
  s.hash,
  s.is_public,
  p.legal_name as creator_name,
  COUNT(c.id) as contributor_count,
  SUM(c.percentage) as total_percentage,
  BOOL_AND(c.signature_data IS NOT NULL) as all_signed
FROM public.sessions s
LEFT JOIN public.profiles p ON s.created_by = p.id
LEFT JOIN public.contributors c ON s.id = c.session_id
GROUP BY s.id, s.song_title, s.created_by, s.created_at, s.finalized, s.finalized_at, s.hash, s.is_public, p.legal_name;

-- Comments
COMMENT ON TABLE public.profiles IS 'User profiles extending auth.users';
COMMENT ON TABLE public.sessions IS 'Recording sessions for music ownership agreements';
COMMENT ON TABLE public.contributors IS 'Artists, producers, writers, and their ownership stakes';
COMMENT ON TABLE public.saved_sessions IS 'User saved/archived ownership agreements';
