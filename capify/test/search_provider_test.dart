import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/providers/search_provider.dart';
import 'package:capify/services/search_service.dart';

const String trackUntukTes = '''
[
  {"id": "t1", "title": "Starboy", "artist": "The Weeknd", "duration_ms": 230000},
  {"id": "t2", "title": "Blinding Lights", "artist": "The Weeknd", "duration_ms": 200000},
  {"id": "t3", "title": "Lights Up", "artist": "Harry Styles", "duration_ms": 172000}
]
''';

const String albumUntukTes = '''
[
  {"id": "a1", "title": "After Hours", "artist": "The Weeknd", "total_tracks": 14},
  {"id": "a2", "title": "Fine Line", "artist": "Harry Styles", "total_tracks": 12}
]
''';

SearchService serviceUntukTes() {
  return SearchService(
    lamaMenunggu: Duration.zero,
    responsTrackKhusus: trackUntukTes,
    responsAlbumServer: albumUntukTes,
  );
}

SearchProvider providerUntukTes([SearchService? service]) {
  return SearchProvider(
    searchService: service ?? serviceUntukTes(),
    jedaSetelahMengetik: Duration.zero,
  );
}

List<String> judulHasil(SearchProvider pencarian) {
  return pencarian.hasilPencarian.map((lagu) => lagu.judul).toList();
}

void main() {
  test('Kata kunci beberapa kata tetap ketemu walau urutannya acak', () async {
    SearchProvider pencarian = providerUntukTes();

    await pencarian.cariLagu('weeknd star');

    expect(judulHasil(pencarian), ['Starboy']);
    expect(pencarian.albumDitemukan, isEmpty);
  });

  test('Hasil dari service berisi lagu dan album sekaligus', () async {
    SearchProvider pencarian = providerUntukTes();

    await pencarian.cariLagu('weeknd');

    expect(judulHasil(pencarian), ['Blinding Lights', 'Starboy']);
    expect(pencarian.albumDitemukan.single.judul, 'After Hours');
    expect(pencarian.isHasilDariCadangan, isFalse);
  });

  test('Judul yang diawali kata kunci tampil paling atas', () async {
    SearchProvider pencarian = providerUntukTes();

    await pencarian.cariLagu('lights');

    expect(judulHasil(pencarian), ['Lights Up', 'Blinding Lights']);
  });

  test('Filter penyanyi menyaring ulang tanpa memanggil server lagi', () async {
    SearchService service = serviceUntukTes();
    SearchProvider pencarian = providerUntukTes(service);
    await pencarian.cariLagu('lights');

    service.isServerSedangGangguan = true;
    pencarian.gantiFilter(SearchProvider.filterPenyanyi);

    expect(pencarian.isSedangMencari, isFalse);
    expect(pencarian.isAdaError, isFalse);
    expect(pencarian.isHasilKosong, isTrue);
    expect(pencarian.kataSorotanJudul, isEmpty);

    pencarian.gantiFilter(SearchProvider.filterSemua);
    expect(judulHasil(pencarian), ['Lights Up', 'Blinding Lights']);
  });

  test('Ketikan lama tidak menimpa hasil ketikan terbaru', () async {
    SearchProvider pencarian = providerUntukTes();

    Future<void> ketikanPertama = pencarian.cariLagu('star');
    Future<void> ketikanKedua = pencarian.cariLagu('harry');
    await Future.wait([ketikanPertama, ketikanKedua]);

    expect(judulHasil(pencarian), ['Lights Up']);
    expect(pencarian.albumDitemukan.single.judul, 'Fine Line');
  });

  test('Server gangguan menampilkan pesan lalu bisa dicoba lagi', () async {
    SearchService service = serviceUntukTes()..isServerSedangGangguan = true;
    SearchProvider pencarian = providerUntukTes(service);

    await pencarian.cariLagu('starboy');

    expect(pencarian.isAdaError, isTrue);
    expect(pencarian.pesanError, contains('gangguan'));
    expect(pencarian.isHasilKosong, isFalse);
    expect(pencarian.hasilPencarian, isEmpty);

    service.isServerSedangGangguan = false;
    await pencarian.cobaLagi();

    expect(pencarian.isAdaError, isFalse);
    expect(judulHasil(pencarian), ['Starboy']);
  });

  test('Mengosongkan kolom cari menghapus hasil dan error', () async {
    SearchProvider pencarian = providerUntukTes();
    await pencarian.cariLagu('weeknd');

    pencarian.kosongkanPencarian();

    expect(pencarian.isKolomCariKosong, isTrue);
    expect(pencarian.hasilPencarian, isEmpty);
    expect(pencarian.albumDitemukan, isEmpty);
    expect(pencarian.isAdaError, isFalse);
  });

  test('Data dummy digabung tanpa lagu dobel', () {
    List<Lagu> semuaLagu = kumpulkanSemuaLaguDummy();
    Set<String> tandaUnik = semuaLagu
        .map((lagu) => '${lagu.judul}|${lagu.penyanyi}'.toLowerCase())
        .toSet();

    expect(semuaLagu.length, tandaUnik.length);
  });

  test('Semua saran penyanyi bisa ditemukan di katalog cadangan', () async {
    SearchService service = SearchService(lamaMenunggu: Duration.zero);
    SearchProvider pencarian = SearchProvider(searchService: service);

    for (String penyanyi in pencarian.saranPencarian) {
      expect((await service.cari(penyanyi)).isKosong, isFalse);
    }
  });
}
