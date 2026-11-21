import 'lagu.dart';

class Playlist {
  final String id;
  final String nama;
  final String deskripsi;
  final List<Lagu> daftarLagu;

  const Playlist({
    this.id = '',
    required this.nama,
    required this.deskripsi,
    required this.daftarLagu,
  });

  String get urlCoverPlaylist {
    if (daftarLagu.isEmpty) return '';
    return daftarLagu.first.urlCover;
  }

  Playlist denganLaguTambahan(Lagu laguBaru) {
    return Playlist(
      id: id,
      nama: nama,
      deskripsi: deskripsi,
      daftarLagu: [...daftarLagu, laguBaru],
    );
  }

  Playlist denganLaguDihapus(Lagu laguDihapus) {
    String judulDihapus = laguDihapus.judul.toLowerCase();
    String penyanyiDihapus = laguDihapus.penyanyi.toLowerCase();

    List<Lagu> sisaLagu = daftarLagu.where((lagu) {
      bool isJudulSama = lagu.judul.toLowerCase() == judulDihapus;
      bool isPenyanyiSama = lagu.penyanyi.toLowerCase() == penyanyiDihapus;
      return !(isJudulSama && isPenyanyiSama);
    }).toList();

    return Playlist(
      id: id,
      nama: nama,
      deskripsi: deskripsi,
      daftarLagu: sisaLagu,
    );
  }
}
