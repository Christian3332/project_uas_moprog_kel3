import '../data/album_dummy.dart';
import '../data/lagu_disukai_dummy.dart';
import '../data/playlist_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';

final List<Playlist> _playlistDiServerPalsu = List.of(daftarPlaylistDummy);

class KoleksiService {
  final Duration lamaResponServer;

  const KoleksiService({
    this.lamaResponServer = const Duration(milliseconds: 800),
  });

  Future<List<Playlist>> ambilPlaylistSaya() async {
    await Future.delayed(lamaResponServer);
    return List.of(_playlistDiServerPalsu);
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

  Future<List<Album>> ambilAlbumTersimpan() async {
    await Future.delayed(lamaResponServer);
    return List.of(daftarAlbumTersimpanDummy);
  }

  Future<List<Lagu>> ambilLaguDisukai() async {
    await Future.delayed(lamaResponServer);
    return List.of(daftarLaguDisukaiDummy);
  }
}
