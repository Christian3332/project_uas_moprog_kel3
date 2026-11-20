import '../data/album_dummy.dart';
import '../data/lagu_disukai_dummy.dart';
import '../data/playlist_dummy.dart';
import '../models/koleksi_pengguna.dart';
import '../models/playlist.dart';

final List<Playlist> _playlistDiServerPalsu = List.of(daftarPlaylistDummy);

class KoleksiService {
  final Duration lamaResponServer;
  final bool isSimulasiGagal;

  const KoleksiService({
    this.lamaResponServer = const Duration(milliseconds: 800),
    this.isSimulasiGagal = false,
  });

  Future<KoleksiPengguna> ambilKoleksiPengguna() async {
    await Future.delayed(lamaResponServer);

    if (isSimulasiGagal) {
      throw Exception('Server Capify sedang sibuk, koleksi belum bisa diambil');
    }

    return KoleksiPengguna(
      daftarPlaylist: List.of(_playlistDiServerPalsu),
      daftarAlbumTersimpan: List.of(daftarAlbumTersimpanDummy),
      daftarLaguDisukai: List.of(daftarLaguDisukaiDummy),
    );
  }

  Future<Playlist> simpanPlaylistBaru({
    required String nama,
    required String deskripsi,
  }) async {
    await Future.delayed(lamaResponServer);

    Playlist playlistTersimpan = Playlist(
      id: 'playlist-${DateTime.now().microsecondsSinceEpoch}',
      nama: nama,
      deskripsi: deskripsi,
      daftarLagu: const [],
    );
    _playlistDiServerPalsu.insert(0, playlistTersimpan);
    return playlistTersimpan;
  }
}
