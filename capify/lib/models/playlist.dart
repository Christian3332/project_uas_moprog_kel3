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
}
