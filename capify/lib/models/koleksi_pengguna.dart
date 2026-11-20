import 'album.dart';
import 'lagu.dart';
import 'playlist.dart';

class KoleksiPengguna {
  final List<Playlist> daftarPlaylist;
  final List<Album> daftarAlbumTersimpan;
  final List<Lagu> daftarLaguDisukai;
  final bool isDariCadangan;

  const KoleksiPengguna({
    required this.daftarPlaylist,
    required this.daftarAlbumTersimpan,
    required this.daftarLaguDisukai,
    this.isDariCadangan = false,
  });

  bool get isKosong {
    return daftarPlaylist.isEmpty &&
        daftarAlbumTersimpan.isEmpty &&
        daftarLaguDisukai.isEmpty;
  }

  KoleksiPengguna tandaiSebagaiCadangan() {
    return KoleksiPengguna(
      daftarPlaylist: daftarPlaylist,
      daftarAlbumTersimpan: daftarAlbumTersimpan,
      daftarLaguDisukai: daftarLaguDisukai,
      isDariCadangan: true,
    );
  }
}
