create table if not exists public.tracks (
  id text primary key,
  title text not null,
  artist text not null,
  cover_url text not null default '',
  audio_url text not null default '',
  duration_ms integer not null default 0 check (duration_ms >= 0),
  genre text not null default ''
);

create table if not exists public.recently_played (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  track_id text not null references public.tracks (id) on delete cascade,
  played_at timestamptz not null default now()
);

create index if not exists recently_played_per_pengguna
  on public.recently_played (user_id, played_at desc);

alter table public.tracks enable row level security;
alter table public.recently_played enable row level security;

drop policy if exists "Katalog lagu boleh dilihat semua orang" on public.tracks;
create policy "Katalog lagu boleh dilihat semua orang"
  on public.tracks for select
  to anon, authenticated
  using (true);

drop policy if exists "Pengguna hanya melihat riwayatnya sendiri" on public.recently_played;
create policy "Pengguna hanya melihat riwayatnya sendiri"
  on public.recently_played for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Pengguna hanya mencatat riwayatnya sendiri" on public.recently_played;
create policy "Pengguna hanya mencatat riwayatnya sendiri"
  on public.recently_played for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

insert into public.tracks (id, title, artist, cover_url, audio_url, duration_ms, genre) values
  ('feed-001', 'One Call Away', 'Charlie Puth', 'https://picsum.photos/seed/onecallaway/500', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', 194000, 'Pop'),
  ('feed-002', 'Peaches', 'Justin Bieber', 'https://picsum.photos/seed/peachesbieber/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', 198000, 'Pop'),
  ('feed-003', 'Attention', 'Charlie Puth', 'https://picsum.photos/seed/attentionputh/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', 211000, 'Pop'),
  ('feed-004', 'Evaluasi', 'Hindia', 'https://picsum.photos/seed/evaluasihindia/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', 227000, 'Indie'),
  ('feed-005', 'Rumah ke Rumah', 'Hindia', 'https://picsum.photos/seed/rumahkerumah/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', 292000, 'Indie'),
  ('feed-006', 'Ditto', 'NewJeans', 'https://picsum.photos/seed/ditto/500', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', 185000, 'K-Pop'),
  ('feed-007', 'Hype Boy', 'NewJeans', 'https://picsum.photos/seed/hypeboy/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', 179000, 'K-Pop'),
  ('feed-008', 'Get You', 'Daniel Caesar', 'https://picsum.photos/seed/getyoucaesar/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', 278000, 'R&B'),
  ('feed-009', 'Starboy', 'The Weeknd', 'https://picsum.photos/seed/starboy/500', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3', 230000, 'R&B'),
  ('feed-010', 'Fly Me to the Moon', 'Frank Sinatra', 'https://picsum.photos/seed/flymetothemoon/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3', 148000, 'Jazz'),
  ('feed-011', 'Coffee', 'Beabadoobee', 'https://picsum.photos/seed/coffeebea/400', 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3', 209000, 'Lo-Fi')
on conflict (id) do update set
  title = excluded.title,
  artist = excluded.artist,
  cover_url = excluded.cover_url,
  audio_url = excluded.audio_url,
  duration_ms = excluded.duration_ms,
  genre = excluded.genre;
