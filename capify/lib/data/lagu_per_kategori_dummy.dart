import '../models/lagu.dart';

const Map<String, List<Lagu>> laguPerKategoriDummy = {
  'Pop': [
    Lagu(
      judul: 'One Call Away',
      penyanyi: 'Charlie Puth',
      urlCover: 'https://picsum.photos/seed/onecallaway/500',
      durasi: Duration(minutes: 3, seconds: 14),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
    ),
    Lagu(
      judul: 'Peaches',
      penyanyi: 'Justin Bieber',
      urlCover: 'https://picsum.photos/seed/peachesbieber/400',
      durasi: Duration(minutes: 3, seconds: 18),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    Lagu(
      judul: 'Attention',
      penyanyi: 'Charlie Puth',
      urlCover: 'https://picsum.photos/seed/attentionputh/400',
      durasi: Duration(minutes: 3, seconds: 31),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
  ],
  'Indie': [
    Lagu(
      judul: 'Evaluasi',
      penyanyi: 'Hindia',
      urlCover: 'https://picsum.photos/seed/evaluasihindia/400',
      durasi: Duration(minutes: 3, seconds: 47),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    Lagu(
      judul: 'Rumah ke Rumah',
      penyanyi: 'Hindia',
      urlCover: 'https://picsum.photos/seed/rumahkerumah/400',
      durasi: Duration(minutes: 4, seconds: 52),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3',
    ),
  ],
  'K-Pop': [
    Lagu(
      judul: 'Ditto',
      penyanyi: 'NewJeans',
      urlCover: 'https://picsum.photos/seed/ditto/500',
      durasi: Duration(minutes: 3, seconds: 5),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    ),
    Lagu(
      judul: 'Hype Boy',
      penyanyi: 'NewJeans',
      urlCover: 'https://picsum.photos/seed/hypeboy/400',
      durasi: Duration(minutes: 2, seconds: 59),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3',
    ),
  ],
  'R&B': [
    Lagu(
      judul: 'Get You',
      penyanyi: 'Daniel Caesar',
      urlCover: 'https://picsum.photos/seed/getyoucaesar/400',
      durasi: Duration(minutes: 4, seconds: 38),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    ),
    Lagu(
      judul: 'Starboy',
      penyanyi: 'The Weeknd',
      urlCover: 'https://picsum.photos/seed/starboy/500',
      durasi: Duration(minutes: 3, seconds: 50),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    ),
  ],
  'Jazz': [
    Lagu(
      judul: 'Fly Me to the Moon',
      penyanyi: 'Frank Sinatra',
      urlCover: 'https://picsum.photos/seed/flymetothemoon/400',
      durasi: Duration(minutes: 2, seconds: 28),
      urlAudio:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-10.mp3',
    ),
  ],
  'Lo-Fi': [
    Lagu(
      judul: 'Coffee',
      penyanyi: 'Beabadoobee',
      urlCover: 'https://picsum.photos/seed/coffeebea/400',
      durasi: Duration(minutes: 3, seconds: 29),
      urlAudio:
          'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-11.mp3',
    ),
  ],
};
