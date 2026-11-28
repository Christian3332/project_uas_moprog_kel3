import '../models/lagu.dart';
import '../models/playlist.dart';

const List<Playlist> daftarPlaylistDummy = [
  Playlist(
    id: 'playlist-teman-begadang',
    nama: 'Teman Begadang',
    deskripsi: 'Lagu santai buat nemenin ngerjain tugas sampai pagi',
    daftarLagu: [
      Lagu(
        judul: 'One Call Away',
        penyanyi: 'Charlie Puth',
        urlCover: 'https://picsum.photos/seed/onecallaway/500',
        durasi: Duration(minutes: 3, seconds: 14),
        urlAudio:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      ),
      Lagu(
        judul: 'Evaluasi',
        penyanyi: 'Hindia',
        urlCover: 'https://picsum.photos/seed/evaluasihindia/400',
        durasi: Duration(minutes: 3, seconds: 47),
        urlAudio:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
      ),
      Lagu(
        judul: 'Ditto',
        penyanyi: 'NewJeans',
        urlCover: 'https://picsum.photos/seed/ditto/500',
        durasi: Duration(minutes: 3, seconds: 5),
        urlAudio:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3',
      ),
    ],
  ),
  Playlist(
    id: 'playlist-semangat-pagi',
    nama: 'Semangat Pagi',
    deskripsi: 'Biar nggak ngantuk waktu berangkat kuliah',
    daftarLagu: [
      Lagu(
        judul: 'Starboy',
        penyanyi: 'The Weeknd',
        urlCover: 'https://picsum.photos/seed/starboy/500',
        durasi: Duration(minutes: 3, seconds: 50),
        urlAudio:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-9.mp3',
      ),
      Lagu(
        judul: 'Peaches',
        penyanyi: 'Justin Bieber',
        urlCover: 'https://picsum.photos/seed/peachesbieber/400',
        durasi: Duration(minutes: 3, seconds: 18),
        urlAudio:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      ),
    ],
  ),
  Playlist(
    id: 'playlist-baruku',
    nama: 'Playlist Baruku',
    deskripsi: 'Belum sempat diisi',
    daftarLagu: [],
  ),
];
