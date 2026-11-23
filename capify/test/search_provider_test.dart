import 'package:flutter_test/flutter_test.dart';

import 'package:capify/data/katalog_pencarian_dummy.dart';
import 'package:capify/models/lagu.dart';
import 'package:capify/providers/search_provider.dart';
import 'package:capify/services/search_service.dart';
import 'package:capify/services/supabase_search_service.dart';

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

    test('Ketikan berisi spasi saja dianggap kosong', () async {
      SearchProvider pencarian = providerUntukTes();
      await pencarian.cariSekarang('weeknd');

      pencarian.ketikKataKunci('    ');

      expect(pencarian.isKolomCariKosong, isTrue);
      expect(pencarian.hasilPencarian, isEmpty);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Hasil yang datang telat setelah dikosongkan dibuang', () async {
      SearchProvider pencarian = SearchProvider(
        searchService: SearchService(
          lamaMenunggu: const Duration(milliseconds: 60),
          responsTrackKhusus: trackUntukTes,
          responsAlbumServer: albumUntukTes,
        ),
        jedaSetelahMengetik: Duration.zero,
      );

      Future<void> pencarianYangBerjalan = pencarian.cariSekarang('weeknd');
      expect(pencarian.isSedangMencari, isTrue);

      pencarian.ketikKataKunci('');
      await pencarianYangBerjalan;

      expect(pencarian.jumlahPanggilanApi, 1);
      expect(pencarian.hasilPencarian, isEmpty);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Mengosongkan saat masih menunggu jeda tidak memanggil API', () async {
      SearchProvider pencarian = SearchProvider(
        searchService: serviceUntukTes(),
        jedaSetelahMengetik: const Duration(milliseconds: 60),
      );

      pencarian.ketikKataKunci('starboy');
      pencarian.ketikKataKunci('');
      await Future.delayed(const Duration(milliseconds: 150));

      expect(pencarian.jumlahPanggilanApi, 0);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Error dan saran ejaan tidak tertinggal', () async {
      SearchService service = serviceUntukTes()..isServerSedangGangguan = true;
      SearchProvider pencarian = providerUntukTes(service);
      await pencarian.cariSekarang('starboy');
      expect(pencarian.isAdaError, isTrue);

      pencarian.kosongkanPencarian();
      expect(pencarian.isAdaError, isFalse);
      expect(pencarian.pesanError, isNull);

      service.isServerSedangGangguan = false;
      await pencarian.cariSekarang('weekend');
      expect(pencarian.saranEjaan, isNotNull);

      pencarian.kosongkanPencarian();
      expect(pencarian.saranEjaan, isNull);
    });

    test('Filter kembali ke Semua, tapi tidak saat cuma kependekan', () async {
      SearchProvider pencarian = providerUntukTes();
      await pencarian.cariSekarang('weeknd');
      pencarian.gantiFilter(SearchProvider.filterJudul);

      pencarian.ketikKataKunci('w');
      expect(pencarian.filterAktif, SearchProvider.filterJudul);

      pencarian.ketikKataKunci('');
      expect(pencarian.filterAktif, SearchProvider.filterSemua);
    });

    test('Riwayat tetap ada setelah kolom dikosongkan', () async {
      SearchProvider pencarian = providerUntukTes();
      pencarian.simpanKeRiwayat('weeknd');
      await pencarian.cariSekarang('weeknd');

      pencarian.kosongkanPencarian();

      expect(pencarian.riwayatPencarian, ['weeknd']);
    });

    test('Bersihkan semua menghapus riwayat dan cache', () async {
      SearchProvider pencarian = providerUntukTes();
      pencarian.simpanKeRiwayat('weeknd');
      await pencarian.cariSekarang('weeknd');

      pencarian.bersihkanSemuaPencarian();
      expect(pencarian.riwayatPencarian, isEmpty);
      expect(pencarian.isKolomCariKosong, isTrue);

      await pencarian.cariSekarang('weeknd');
      expect(pencarian.jumlahPanggilanApi, 2);
    });
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

    test('Kata yang dikenal katalog dipilih untuk dicoba sendirian', () async {
      SearchProvider pencarian = providerUntukTes();

      await pencarian.cariSekarang('capybara starboy');
      expect(pencarian.kataTunggalUntukDicoba, 'starboy');

      await pencarian.cariSekarang('qwerty zz');
      expect(pencarian.kataTunggalUntukDicoba, 'qwerty');

      await pencarian.cariSekarang('weeknd');
      expect(pencarian.kataTunggalUntukDicoba, isNull);
    });

    test('Kamus kosong tidak bikin error', () async {
      SearchProvider pencarian = SearchProvider(
        searchService: serviceUntukTes(),
        jedaSetelahMengetik: Duration.zero,
        kamusSaranEjaan: [],
      );

      await pencarian.cariSekarang('weekend');

      expect(pencarian.isHasilKosong, isTrue);
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
      SearchProvider pencarian = providerDenganJeda();

      for (String ketikan in ['s', 'st', 'sta', 'star']) {
        pencarian.ketikKataKunci(ketikan);
      }

      expect(pencarian.isSedangMencari, isTrue);
      expect(pencarian.jumlahPanggilanApi, 0);

      await Future.delayed(tungguLewatJeda);

      expect(pencarian.jumlahPanggilanApi, 1);
      expect(judulHasil(pencarian), ['Starboy']);
      expect(pencarian.isSedangMencari, isFalse);
    });

    test('Tekan enter langsung mencari tanpa menunggu jeda', () async {
      SearchProvider pencarian = providerDenganJeda();

      pencarian.ketikKataKunci('harry');
      await pencarian.cariSekarang('harry');
      expect(pencarian.jumlahPanggilanApi, 1);
      expect(judulHasil(pencarian), ['Lights Up']);

      await Future.delayed(tungguLewatJeda);
      expect(pencarian.jumlahPanggilanApi, 1);
    });

    test('Kata kunci yang pernah dicari diambil dari cache', () async {
      SearchProvider pencarian = providerDenganJeda();
      await pencarian.cariSekarang('weeknd');
      await pencarian.cariSekarang('lights');

      pencarian.ketikKataKunci('Weeknd ');

      expect(pencarian.isSedangMencari, isFalse);
      expect(judulHasil(pencarian), ['Blinding Lights', 'Starboy']);
      await Future.delayed(tungguLewatJeda);
      expect(pencarian.jumlahPanggilanApi, 2);
    });

    test(
      'Kembali ke kata kunci yang sedang tampil tidak memanggil API',
      () async {
        SearchProvider pencarian = providerDenganJeda();
        await pencarian.cariSekarang('star');

        pencarian.ketikKataKunci('starb');
        pencarian.ketikKataKunci('star');

        expect(pencarian.isSedangMencari, isFalse);
        await Future.delayed(tungguLewatJeda);
        expect(pencarian.jumlahPanggilanApi, 1);
        expect(judulHasil(pencarian), ['Starboy']);
      },
    );

    test('Satu huruf belum dikirim ke server', () async {
      SearchProvider pencarian = providerDenganJeda();

      pencarian.ketikKataKunci(' a ');
      await Future.delayed(tungguLewatJeda);

      expect(pencarian.isKataKunciKependekan, isTrue);
      expect(pencarian.isHasilKosong, isFalse);
      expect(pencarian.jumlahPanggilanApi, 0);
    });

    test('Hasil dari data cadangan tidak disimpan di cache', () async {
      SearchProvider pencarian = providerDenganJeda(SupabaseSearchService());
      await pencarian.cariSekarang('hindia');
      expect(pencarian.isHasilDariCadangan, isTrue);
      await pencarian.cariSekarang('ditto');

      pencarian.ketikKataKunci('hindia');
      expect(pencarian.isSedangMencari, isTrue);

      await Future.delayed(tungguLewatJeda);
      expect(pencarian.jumlahPanggilanApi, 3);
    });

    test('Provider ditutup saat masih menunggu jeda tetap aman', () async {
      SearchProvider pencarian = providerDenganJeda();

      pencarian.ketikKataKunci('starboy');
      pencarian.dispose();
      await Future.delayed(tungguLewatJeda);

      expect(pencarian.jumlahPanggilanApi, 0);
    });
  });
}
