import '../data/album_dummy.dart';
import '../data/lagu_disukai_dummy.dart';
import '../data/playlist_dummy.dart';
import '../models/album.dart';
import '../models/lagu.dart';
import '../models/playlist.dart';

class KoleksiService {
  final Duration lamaResponServer;

  const KoleksiService({
    this.lamaResponServer = const Duration(milliseconds: 800),
  });

  Future<List<Playlist>> ambilPlaylistSaya() async {
    await Future.delayed(lamaResponServer);
    return List.of(daftarPlaylistDummy);
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
