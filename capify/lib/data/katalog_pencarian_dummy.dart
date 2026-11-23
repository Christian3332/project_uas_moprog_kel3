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
