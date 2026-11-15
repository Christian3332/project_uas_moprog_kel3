import '../models/lagu.dart';

const Map<String, List<Lagu>> laguPerKategoriDummy = {
  'Pop': [
    Lagu(
      judul: 'One Call Away',
      penyanyi: 'Charlie Puth',
      urlCover: 'https://picsum.photos/seed/onecallaway/500',
      durasi: Duration(minutes: 3, seconds: 14),
    ),
    Lagu(
      judul: 'Peaches',
      penyanyi: 'Justin Bieber',
      urlCover: 'https://picsum.photos/seed/peachesbieber/400',
      durasi: Duration(minutes: 3, seconds: 18),
    ),
    Lagu(
      judul: 'Attention',
      penyanyi: 'Charlie Puth',
      urlCover: 'https://picsum.photos/seed/attentionputh/400',
      durasi: Duration(minutes: 3, seconds: 31),
    ),
  ],
  'Indie': [
    Lagu(
      judul: 'Evaluasi',
      penyanyi: 'Hindia',
      urlCover: 'https://picsum.photos/seed/evaluasihindia/400',
      durasi: Duration(minutes: 3, seconds: 47),
    ),
    Lagu(
      judul: 'Rumah ke Rumah',
      penyanyi: 'Hindia',
      urlCover: 'https://picsum.photos/seed/rumahkerumah/400',
      durasi: Duration(minutes: 4, seconds: 52),
    ),
  ],
  'K-Pop': [
    Lagu(
      judul: 'Ditto',
      penyanyi: 'NewJeans',
      urlCover: 'https://picsum.photos/seed/ditto/500',
      durasi: Duration(minutes: 3, seconds: 5),
    ),
    Lagu(
      judul: 'Hype Boy',
      penyanyi: 'NewJeans',
      urlCover: 'https://picsum.photos/seed/hypeboy/400',
      durasi: Duration(minutes: 2, seconds: 59),
    ),
  ],
  'R&B': [
    Lagu(
      judul: 'Get You',
      penyanyi: 'Daniel Caesar',
      urlCover: 'https://picsum.photos/seed/getyoucaesar/400',
      durasi: Duration(minutes: 4, seconds: 38),
    ),
    Lagu(
      judul: 'Starboy',
      penyanyi: 'The Weeknd',
      urlCover: 'https://picsum.photos/seed/starboy/500',
      durasi: Duration(minutes: 3, seconds: 50),
    ),
  ],
  'Jazz': [
    Lagu(
      judul: 'Fly Me to the Moon',
      penyanyi: 'Frank Sinatra',
      urlCover: 'https://picsum.photos/seed/flymetothemoon/400',
      durasi: Duration(minutes: 2, seconds: 28),
    ),
  ],
  'Lo-Fi': [
    Lagu(
      judul: 'Coffee',
      penyanyi: 'Beabadoobee',
      urlCover: 'https://picsum.photos/seed/coffeebea/400',
      durasi: Duration(minutes: 3, seconds: 29),
    ),
  ],
};
