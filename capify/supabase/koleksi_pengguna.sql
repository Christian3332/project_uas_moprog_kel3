create table if not exists public.playlists (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  name text not null check (char_length(trim(name)) between 1 and 40),
  description text not null default '',
  created_at timestamptz not null default now()
);

create table if not exists public.playlist_tracks (
  playlist_id text not null references public.playlists (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (playlist_id, track_id)
);

create table if not exists public.liked_tracks (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  liked_at timestamptz not null default now(),
  primary key (user_id, track_id)
);

create table if not exists public.saved_albums (
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  album_id text not null references public.albums (id) on delete cascade,
  saved_at timestamptz not null default now(),
  primary key (user_id, album_id)
);

create index if not exists playlists_per_pengguna
  on public.playlists (user_id, created_at desc);

alter table public.playlists enable row level security;
alter table public.playlist_tracks enable row level security;
alter table public.liked_tracks enable row level security;
alter table public.saved_albums enable row level security;

drop policy if exists "Pengguna hanya melihat playlistnya sendiri" on public.playlists;
create policy "Pengguna hanya melihat playlistnya sendiri"
  on public.playlists for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Pengguna hanya melihat isi playlistnya sendiri" on public.playlist_tracks;
create policy "Pengguna hanya melihat isi playlistnya sendiri"
  on public.playlist_tracks for select
  to authenticated
  using (
    exists (
      select 1 from public.playlists
      where playlists.id = playlist_tracks.playlist_id
        and playlists.user_id = (select auth.uid())
    )
  );

drop policy if exists "Pengguna hanya melihat lagu yang dia sukai" on public.liked_tracks;
create policy "Pengguna hanya melihat lagu yang dia sukai"
  on public.liked_tracks for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Pengguna hanya melihat album yang dia simpan" on public.saved_albums;
create policy "Pengguna hanya melihat album yang dia simpan"
  on public.saved_albums for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Pengguna hanya menambah lagu ke playlistnya sendiri" on public.playlist_tracks;
create policy "Pengguna hanya menambah lagu ke playlistnya sendiri"
  on public.playlist_tracks for insert
  to authenticated
  with check (
    exists (
      select 1 from public.playlists
      where playlists.id = playlist_tracks.playlist_id
        and playlists.user_id = (select auth.uid())
    )
  );
