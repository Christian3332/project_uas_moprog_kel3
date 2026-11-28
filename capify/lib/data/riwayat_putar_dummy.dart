import '../models/lagu.dart';
import '../models/riwayat_putar.dart';

const List<RiwayatPutar> daftarRiwayatPutarDummy = [
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Evaluasi',
      penyanyi: 'Hindia',
      urlCover: 'https://picsum.photos/seed/evaluasihindia/400',
      durasi: Duration(minutes: 3, seconds: 47),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
    ),
    jarakSejakDiputar: Duration(minutes: 4),
  ),
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Ditto',
      penyanyi: 'NewJeans',
      urlCover: 'https://picsum.photos/seed/ditto/400',
      durasi: Duration(minutes: 3, seconds: 5),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
    ),
    jarakSejakDiputar: Duration(minutes: 38),
  ),
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Get You',
      penyanyi: 'Daniel Caesar',
      urlCover: 'https://picsum.photos/seed/getyoucaesar/400',
      durasi: Duration(minutes: 4, seconds: 38),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
    ),
    jarakSejakDiputar: Duration(hours: 3),
  ),
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Starboy',
      penyanyi: 'The Weeknd',
      urlCover: 'https://picsum.photos/seed/starboy/400',
      durasi: Duration(minutes: 3, seconds: 50),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
    ),
    jarakSejakDiputar: Duration(hours: 9),
  ),
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Attention',
      penyanyi: 'Charlie Puth',
      urlCover: 'https://picsum.photos/seed/attentionputh/400',
      durasi: Duration(minutes: 3, seconds: 31),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
    ),
    jarakSejakDiputar: Duration(hours: 27),
  ),
  RiwayatPutar(
    lagu: Lagu(
      judul: 'Peaches',
      penyanyi: 'Justin Bieber',
      urlCover: 'https://picsum.photos/seed/peachesbieber/400',
      durasi: Duration(minutes: 3, seconds: 18),
      urlAudio: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
    ),
    jarakSejakDiputar: Duration(days: 3),
  ),
];
