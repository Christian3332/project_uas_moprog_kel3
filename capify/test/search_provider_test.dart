import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/providers/search_provider.dart';

const List<Lagu> laguUntukTes = [
  Lagu(
    judul: 'Starboy',
    penyanyi: 'The Weeknd',
    urlCover: '',
    durasi: Duration(minutes: 3),
  ),
  Lagu(
    judul: 'Blinding Lights',
    penyanyi: 'The Weeknd',
    urlCover: '',
    durasi: Duration(minutes: 3),
  ),
  Lagu(
    judul: 'Lights Up',
    penyanyi: 'Harry Styles',
    urlCover: '',
    durasi: Duration(minutes: 3),
  ),
];

List<String> judulHasil(SearchProvider pencarian) {
  return pencarian.hasilPencarian.map((lagu) => lagu.judul).toList();
}

void main() {
  test('Kata kunci beberapa kata tetap ketemu walau urutannya acak', () async {
    SearchProvider pencarian = SearchProvider(sumberLagu: laguUntukTes);

    await pencarian.cariLagu('weeknd star');

    expect(judulHasil(pencarian), ['Starboy']);
  });

  test('Judul yang diawali kata kunci tampil paling atas', () async {
    SearchProvider pencarian = SearchProvider(sumberLagu: laguUntukTes);

    await pencarian.cariLagu('lights');

    expect(judulHasil(pencarian), ['Lights Up', 'Blinding Lights']);
  });

  test('Filter penyanyi langsung menyaring ulang tanpa loading', () async {
    SearchProvider pencarian = SearchProvider(sumberLagu: laguUntukTes);
    await pencarian.cariLagu('lights');

    pencarian.gantiFilter(SearchProvider.filterPenyanyi);

    expect(pencarian.isSedangMencari, isFalse);
    expect(pencarian.isHasilKosong, isTrue);
    expect(pencarian.kataSorotanJudul, isEmpty);

    pencarian.gantiFilter(SearchProvider.filterSemua);
    expect(judulHasil(pencarian), ['Lights Up', 'Blinding Lights']);
  });

  test('Ketikan lama tidak menimpa hasil ketikan terbaru', () async {
    SearchProvider pencarian = SearchProvider(sumberLagu: laguUntukTes);

    Future<void> ketikanPertama = pencarian.cariLagu('star');
    Future<void> ketikanKedua = pencarian.cariLagu('harry');
    await Future.wait([ketikanPertama, ketikanKedua]);

    expect(judulHasil(pencarian), ['Lights Up']);
  });

  test('Data dummy digabung tanpa lagu dobel', () {
    List<Lagu> semuaLagu = kumpulkanSemuaLaguDummy();
    Set<String> tandaUnik = semuaLagu
        .map((lagu) => '${lagu.judul}|${lagu.penyanyi}'.toLowerCase())
        .toSet();

    expect(semuaLagu.length, tandaUnik.length);
  });
}
