import '../models/lagu.dart';
import '../models/playlist.dart';

const List<Playlist> daftarPlaylistDummy = [
  Playlist(
    nama: 'Teman Begadang',
    deskripsi: 'Lagu santai buat nemenin ngerjain tugas sampai pagi',
    daftarLagu: [
      Lagu(
        judul: 'One Call Away',
        penyanyi: 'Charlie Puth',
        urlCover: 'https://picsum.photos/seed/onecallaway/500',
        durasi: Duration(minutes: 3, seconds: 14),
      ),
      Lagu(
        judul: 'Evaluasi',
        penyanyi: 'Hindia',
        urlCover: 'https://picsum.photos/seed/evaluasihindia/400',
        durasi: Duration(minutes: 3, seconds: 47),
      ),
      Lagu(
        judul: 'Ditto',
        penyanyi: 'NewJeans',
        urlCover: 'https://picsum.photos/seed/ditto/500',
        durasi: Duration(minutes: 3, seconds: 5),
      ),
    ],
  ),
  Playlist(
    nama: 'Semangat Pagi',
    deskripsi: 'Biar nggak ngantuk waktu berangkat kuliah',
    daftarLagu: [
      Lagu(
        judul: 'Starboy',
        penyanyi: 'The Weeknd',
        urlCover: 'https://picsum.photos/seed/starboy/500',
        durasi: Duration(minutes: 3, seconds: 50),
      ),
      Lagu(
        judul: 'Peaches',
        penyanyi: 'Justin Bieber',
        urlCover: 'https://picsum.photos/seed/peachesbieber/400',
        durasi: Duration(minutes: 3, seconds: 18),
      ),
    ],
  ),
  Playlist(
    nama: 'Playlist Baruku',
    deskripsi: 'Belum sempat diisi',
    daftarLagu: [],
  ),
];
