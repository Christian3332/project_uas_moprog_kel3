import '../data/album_dummy.dart';
import '../data/lagu_disukai_dummy.dart';
import '../data/playlist_dummy.dart';
import '../models/koleksi_pengguna.dart';
import '../models/lagu.dart';
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

    if (isSimulasiGagal) {
      throw Exception('Server Capify sedang sibuk, playlist belum bisa dibuat');
    }

    Playlist playlistTersimpan = Playlist(
      id: 'playlist-${DateTime.now().microsecondsSinceEpoch}',
      nama: nama,
      deskripsi: deskripsi,
      daftarLagu: const [],
    );
    _playlistDiServerPalsu.insert(0, playlistTersimpan);
    return playlistTersimpan;
  }

  Future<Playlist> tambahLaguKePlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    await Future.delayed(lamaResponServer);

    if (isSimulasiGagal) {
      throw Exception(
        'Server Capify sedang sibuk, lagu belum bisa ditambahkan',
      );
    }

    int posisiPlaylist = _playlistDiServerPalsu.indexWhere(
      (playlistDiServer) => playlistDiServer.id == playlist.id,
    );
    if (posisiPlaylist == -1) {
      throw Exception('Playlist ini belum tersimpan di server');
    }

    Playlist playlistDiServer = _playlistDiServerPalsu[posisiPlaylist];
    bool isLaguSudahAda = playlistDiServer.daftarLagu.any(
      (laguLama) => buatKunciLagu(laguLama) == buatKunciLagu(lagu),
    );
    if (isLaguSudahAda) throw Exception('Lagu ini sudah ada di playlist');

    Playlist playlistTerbaru = playlistDiServer.denganLaguTambahan(lagu);
    _playlistDiServerPalsu[posisiPlaylist] = playlistTerbaru;
    return playlistTerbaru;
  }

  Future<Playlist> hapusLaguDariPlaylist({
    required Playlist playlist,
    required Lagu lagu,
  }) async {
    await Future.delayed(lamaResponServer);

    if (isSimulasiGagal) {
      throw Exception('Server Capify sedang sibuk, lagu belum bisa dihapus');
    }

    int posisiPlaylist = _playlistDiServerPalsu.indexWhere(
      (playlistDiServer) => playlistDiServer.id == playlist.id,
    );
    if (posisiPlaylist == -1) {
      throw Exception('Playlist ini belum tersimpan di server');
    }

    Playlist playlistDiServer = _playlistDiServerPalsu[posisiPlaylist];
    bool isLaguMasihAda = playlistDiServer.daftarLagu.any(
      (laguLama) => buatKunciLagu(laguLama) == buatKunciLagu(lagu),
    );
    if (!isLaguMasihAda) {
      throw Exception('Lagu ini sudah tidak ada di playlist');
    }

    Playlist playlistTerbaru = playlistDiServer.denganLaguDihapus(lagu);
    _playlistDiServerPalsu[posisiPlaylist] = playlistTerbaru;
    return playlistTerbaru;
  }

  static String buatKunciLagu(Lagu lagu) {
    return '${lagu.judul}|${lagu.penyanyi}'.toLowerCase();
  }
}
