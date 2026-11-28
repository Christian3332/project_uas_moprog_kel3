import 'package:flutter_test/flutter_test.dart';

import 'package:capify/data/katalog_pencarian_dummy.dart';
import 'package:capify/models/hasil_pencarian.dart';
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

class SearchServicePenghitung extends SearchService {
  int jumlahPanggilan = 0;

  SearchServicePenghitung({super.lamaMenunggu = Duration.zero})
    : super(
        responsTrackKhusus: trackUntukTes,
        responsAlbumServer: albumUntukTes,
      );

  @override
  Future<HasilPencarian> cari(
    String kataKunci, {
    String jenis = SearchService.jenisSemua,
    int batasPerJenis = 10,
  }) {
    jumlahPanggilan++;
    return super.cari(kataKunci, jenis: jenis, batasPerJenis: batasPerJenis);
  }
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

    await pencarian.cariSekarang('weeknd star');

    expect(judulHasil(pencarian), ['Starboy']);
    expect(pencarian.albumDitemukan, isEmpty);
  });

  test('Hasil dari service berisi lagu dan album sekaligus', () async {
    SearchProvider pencarian = providerUntukTes();

    await pencarian.cariSekarang('weeknd');

    expect(judulHasil(pencarian), ['Blinding Lights', 'Starboy']);
    expect(pencarian.albumDitemukan.single.judul, 'After Hours');
    expect(pencarian.isHasilDariCadangan, isFalse);
  });

  test('Judul yang diawali kata kunci tampil paling atas', () async {
    SearchProvider pencarian = providerUntukTes();

    await pencarian.cariSekarang('lights');

    expect(judulHasil(pencarian), ['Lights Up', 'Blinding Lights']);
  });

  test('Filter penyanyi menyaring ulang tanpa memanggil server lagi', () async {
    SearchService service = serviceUntukTes();
    SearchProvider pencarian = providerUntukTes(service);
    await pencarian.cariSekarang('lights');

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

    Future<void> ketikanPertama = pencarian.cariSekarang('star');
    Future<void> ketikanKedua = pencarian.cariSekarang('harry');
    await Future.wait([ketikanPertama, ketikanKedua]);

    expect(judulHasil(pencarian), ['Lights Up']);
    expect(pencarian.albumDitemukan.single.judul, 'Fine Line');
  });

  test('Server gangguan menampilkan pesan lalu bisa dicoba lagi', () async {
    SearchService service = serviceUntukTes()..isServerSedangGangguan = true;
    SearchProvider pencarian = providerUntukTes(service);

    await pencarian.cariSekarang('starboy');

    expect(pencarian.isAdaError, isTrue);
    expect(pencarian.pesanError, contains('gangguan'));
    expect(pencarian.isHasilKosong, isFalse);
    expect(pencarian.hasilPencarian, isEmpty);

    service.isServerSedangGangguan = false;
    await pencarian.cobaLagi();

    expect(pencarian.isAdaError, isFalse);
    expect(judulHasil(pencarian), ['Starboy']);
  });

  group('Mengosongkan kolom cari', () {
    test('Hasil, album, dan jumlah tersembunyi ikut hilang', () async {
      SearchProvider pencarian = providerUntukTes();
      await pencarian.cariSekarang('weeknd');

      pencarian.kosongkanPencarian();

      expect(pencarian.isKolomCariKosong, isTrue);
      expect(pencarian.hasilPencarian, isEmpty);
      expect(pencarian.albumDitemukan, isEmpty);
      expect(pencarian.jumlahHasilTanpaFilter, 0);
      expect(pencarian.isHasilKosong, isFalse);
    });

    test('Mengosongkan saat masih menunggu jeda tidak memanggil API', () async {
      SearchServicePenghitung service = SearchServicePenghitung();
      SearchProvider pencarian = SearchProvider(
        searchService: service,
        jedaSetelahMengetik: const Duration(milliseconds: 60),
      );

      pencarian.ketikKataKunci('starboy');
      pencarian.ketikKataKunci('');
      await Future.delayed(const Duration(milliseconds: 150));

      expect(service.jumlahPanggilan, 0);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Riwayat tetap ada setelah kolom dikosongkan', () async {
      SearchProvider pencarian = providerUntukTes();
      pencarian.simpanKeRiwayat('weeknd');
      await pencarian.cariSekarang('weeknd');

      pencarian.kosongkanPencarian();

      expect(pencarian.riwayatPencarian, ['weeknd']);
    });

    test('Bersihkan semua menghapus riwayat dan kolom cari', () async {
      SearchProvider pencarian = providerUntukTes();
      pencarian.simpanKeRiwayat('weeknd');
      await pencarian.cariSekarang('weeknd');

      pencarian.bersihkanSemuaPencarian();
      expect(pencarian.riwayatPencarian, isEmpty);
      expect(pencarian.isKolomCariKosong, isTrue);
      expect(pencarian.hasilPencarian, isEmpty);
    });
  });

  test('Data dummy digabung tanpa lagu dobel', () {
    List<Lagu> semuaLagu = kumpulkanSemuaLaguDummy();
    Set<String> tandaUnik = semuaLagu
        .map((lagu) => '${lagu.judul}|${lagu.penyanyi}'.toLowerCase())
        .toSet();

    expect(semuaLagu.length, tandaUnik.length);
  });

  group('Hasil pencarian kosong', () {
    test('Salah ketik memberi saran ejaan dari katalog', () async {
      SearchProvider pencarian = providerUntukTes();

      await pencarian.cariSekarang('weekend');

      expect(pencarian.isHasilKosong, isTrue);
      expect(pencarian.saranEjaan, 'The Weeknd');
    });

    test('Saran ejaan tidak muncul kalau hasilnya ada', () async {
      SearchProvider pencarian = providerUntukTes();

      await pencarian.cariSekarang('weeknd');

      expect(pencarian.saranEjaan, isNull);
      expect(pencarian.isHasilTersembunyiOlehFilter, isFalse);
    });

    test('Filter yang menyembunyikan hasil bisa dihitung', () async {
      SearchProvider pencarian = providerUntukTes();
      await pencarian.cariSekarang('lights');

      pencarian.gantiFilter(SearchProvider.filterPenyanyi);

      expect(pencarian.isHasilTersembunyiOlehFilter, isTrue);
      expect(pencarian.jumlahHasilTanpaFilter, 2);
      expect(pencarian.saranEjaan, isNull);
    });
  });

  group('Debounce kolom pencarian', () {
    const Duration jedaTes = Duration(milliseconds: 60);
    const Duration tungguLewatJeda = Duration(milliseconds: 150);

    SearchProvider providerDenganJeda([SearchService? service]) {
      return SearchProvider(
        searchService: service ?? serviceUntukTes(),
        jedaSetelahMengetik: jedaTes,
      );
    }

    test('Mengetik cepat hanya memanggil API sekali', () async {
      SearchServicePenghitung service = SearchServicePenghitung();
      SearchProvider pencarian = providerDenganJeda(service);

      for (String ketikan in ['s', 'st', 'sta', 'star']) {
        pencarian.ketikKataKunci(ketikan);
      }

      expect(pencarian.isSedangMencari, isTrue);
      expect(service.jumlahPanggilan, 0);

      await Future.delayed(tungguLewatJeda);

      expect(service.jumlahPanggilan, 1);
      expect(judulHasil(pencarian), ['Starboy']);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Tekan enter langsung mencari tanpa menunggu jeda', () async {
      SearchServicePenghitung service = SearchServicePenghitung();
      SearchProvider pencarian = providerDenganJeda(service);

      pencarian.ketikKataKunci('harry');
      await pencarian.cariSekarang('harry');
      expect(service.jumlahPanggilan, 1);
      expect(judulHasil(pencarian), ['Lights Up']);

      await Future.delayed(tungguLewatJeda);
      expect(service.jumlahPanggilan, 1);
    });

    test('Satu huruf belum dikirim ke server', () async {
      SearchServicePenghitung service = SearchServicePenghitung();
      SearchProvider pencarian = providerDenganJeda(service);

      pencarian.ketikKataKunci(' a ');
      await Future.delayed(tungguLewatJeda);

      expect(pencarian.isKataKunciKependekan, isTrue);
      expect(pencarian.isHasilKosong, isFalse);
      expect(service.jumlahPanggilan, 0);
    });
  });
}
