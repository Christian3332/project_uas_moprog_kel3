import '../models/album.dart';
import '../models/lagu.dart';
import 'album_dummy.dart';
import 'lagu_dummy.dart';
import 'lagu_per_kategori_dummy.dart';

List<Lagu> kumpulkanSemuaLaguDummy() {
  List<Lagu> semuaLagu = [];
  Set<String> laguYangSudahMasuk = {};

  List<Lagu> laguMentah = [
    ...daftarLaguDummy,
    for (List<Lagu> laguSatuKategori in laguPerKategoriDummy.values)
      ...laguSatuKategori,
  ];

  for (Lagu lagu in laguMentah) {
    String tandaLagu = '${lagu.judul}|${lagu.penyanyi}'.toLowerCase();
    if (laguYangSudahMasuk.add(tandaLagu)) {
      semuaLagu.add(lagu);
    }
  }
  return semuaLagu;
}

List<Lagu> ambilLaguDariAlbum(Album album) {
  String penyanyiAlbum = album.penyanyi.toLowerCase();
  return kumpulkanSemuaLaguDummy()
      .where((lagu) => lagu.penyanyi.toLowerCase() == penyanyiAlbum)
      .toList();
}

Album? cariAlbumDariLagu(Lagu lagu) {
  String penyanyiLagu = lagu.penyanyi.toLowerCase();
  String judulLagu = lagu.judul.toLowerCase();
  Album? albumPenyanyiSama;

  for (Album album in daftarAlbumTersimpanDummy) {
    if (album.penyanyi.toLowerCase() != penyanyiLagu) continue;
    if (album.judul.toLowerCase() == judulLagu) return album;
    albumPenyanyiSama ??= album;
  }
  return albumPenyanyiSama;
}

List<String> susunSaranPenyanyiDummy({int batasSaran = 8}) {
  return kumpulkanSemuaLaguDummy()
      .map((lagu) => lagu.penyanyi)
      .toSet()
      .take(batasSaran)
      .toList();
}

List<String> susunKamusSaranDummy() {
  return {
    for (Lagu lagu in kumpulkanSemuaLaguDummy()) ...[lagu.judul, lagu.penyanyi],
    for (Album album in daftarAlbumTersimpanDummy) album.judul,
  }.toList();
}
