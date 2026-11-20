create table if not exists public.albums (
  id text primary key,
  title text not null,
  artist text not null,
  cover_url text not null default '',
  total_tracks integer not null default 0 check (total_tracks >= 0)
);

alter table public.albums enable row level security;

drop policy if exists "Katalog album boleh dilihat semua orang" on public.albums;
create policy "Katalog album boleh dilihat semua orang"
  on public.albums for select
  to anon, authenticated
  using (true);

insert into public.albums (id, title, artist, cover_url, total_tracks) values
  ('alb-001', 'Nine Track Mind', 'Charlie Puth', 'https://picsum.photos/seed/ninetrackmind/400', 13),
  ('alb-002', 'Starboy', 'The Weeknd', 'https://picsum.photos/seed/starboyalbum/400', 18),
  ('alb-003', 'OMG', 'NewJeans', 'https://picsum.photos/seed/newjeansomg/400', 4),
  ('alb-004', 'Case Study 01', 'Daniel Caesar', 'https://picsum.photos/seed/casestudy/400', 10),
  ('alb-005', 'Justice', 'Justin Bieber', 'https://picsum.photos/seed/justice/400', 16),
  ('alb-006', 'Menari Dengan Bayangan', 'Hindia', 'https://picsum.photos/seed/menaridenganbayangan/400', 15),
  ('alb-007', 'Manusia', 'Tulus', 'https://picsum.photos/seed/manusiatulus/400', 10)
on conflict (id) do update set
  title = excluded.title,
  artist = excluded.artist,
  cover_url = excluded.cover_url,
  total_tracks = excluded.total_tracks;
