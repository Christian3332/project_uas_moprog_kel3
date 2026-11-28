import '../utils/kunci_lagu.dart';
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

  bool isPunyaLagu(Lagu laguDicari) {
    String kunciDicari = kunciUnikLagu(laguDicari);
    return daftarLagu.any((lagu) => kunciUnikLagu(lagu) == kunciDicari);
  }

  Playlist denganLaguTambahan(Lagu laguBaru) {
    return _salinDenganDaftarLagu([...daftarLagu, laguBaru]);
  }

  Playlist denganLaguDihapus(Lagu laguDihapus) {
    String kunciDihapus = kunciUnikLagu(laguDihapus);
    return _salinDenganDaftarLagu(
      daftarLagu.where((lagu) => kunciUnikLagu(lagu) != kunciDihapus).toList(),
    );
  }

  Playlist _salinDenganDaftarLagu(List<Lagu> daftarLaguBaru) {
    return Playlist(
      id: id,
      nama: nama,
      deskripsi: deskripsi,
      daftarLagu: daftarLaguBaru,
    );
  }
}
