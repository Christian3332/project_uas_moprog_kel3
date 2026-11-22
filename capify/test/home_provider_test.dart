import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:capify/models/feed_beranda.dart';
import 'package:capify/models/lagu.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';
import 'package:capify/services/feed_service.dart';
import 'package:capify/services/supabase_feed_service.dart';

import 'feed_server_palsu.dart';
import 'pemutar_audio_palsu.dart';

const Lagu laguUjiCoba = Lagu(
  judul: 'Lagu Uji Coba',
  penyanyi: 'Si Capy',
  urlCover: '',
  durasi: Duration(minutes: 2),
);

const Duration waktuTungguLaguMulai = Duration(milliseconds: 800);

void main() {
  late HomeProvider home;

  setUp(() {
    home = HomeProvider();
  });

  tearDown(() {
    home.dispose();
  });

  List<String> judulLagu(List<Lagu> daftarLagu) {
    return daftarLagu.map((lagu) => lagu.judul).toList();
  }

  test('Beranda dimuat dengan riwayat terbaru di paling depan', () async {
    expect(home.isSudahPernahDimuat, isFalse);

    Future<void> prosesMuat = home.muatIsiBeranda();
    expect(home.isSedangMemuat, isTrue);
    await prosesMuat;

    expect(home.isSedangMemuat, isFalse);
    expect(home.isSudahPernahDimuat, isTrue);
    expect(home.pesanGagal, isNull);
    expect(home.laguUntukDilanjutkan?.lagu.judul, 'Evaluasi');
    expect(home.riwayatTerakhirDiputar.length, 6);
  });

  test('Racikan diurutkan dari genre yang paling sering diputar', () async {
    await home.muatIsiBeranda();

    List<String> namaRacikan = home.daftarRacikanUntukmu
        .map((racikan) => racikan.playlist.nama)
        .toList();

    expect(namaRacikan.first, 'Racikan Pop');
    expect(namaRacikan[1], 'Racikan R&B');
    expect(namaRacikan.last, 'Racikan Lo-Fi');
  });

  test('Lagu temuan tidak berisi lagu yang sudah ada di riwayat', () async {
    await home.muatIsiBeranda();

    List<String> judulTemuan = judulLagu(home.laguBelumPernahDidengar);

    expect(judulTemuan, contains('Hype Boy'));
    expect(judulTemuan, isNot(contains('Evaluasi')));
    expect(judulTemuan.toSet().length, judulTemuan.length);
  });

  test(
    'Lagu yang baru diputar pindah ke depan dan keluar dari temuan',
    () async {
      await home.muatIsiBeranda();
      Lagu laguJazz = home.laguBelumPernahDidengar.firstWhere(
        (lagu) => lagu.judul == 'Fly Me to the Moon',
      );

      home.catatLaguDiputar(laguJazz);

      expect(home.laguUntukDilanjutkan?.lagu.judul, 'Fly Me to the Moon');
      expect(home.laguUntukDilanjutkan?.teksWaktuDiputar, 'Baru saja');
      expect(
        judulLagu(home.laguBelumPernahDidengar),
        isNot(contains('Fly Me to the Moon')),
      );
      expect(
        home.daftarRacikanUntukmu
            .firstWhere((racikan) => racikan.playlist.nama == 'Racikan Jazz')
            .jumlahLaguFamiliar,
        1,
      );
    },
  );

  test('Memutar lagu yang sama dua kali tidak membuat riwayat dobel', () async {
    await home.muatIsiBeranda();
    Lagu laguKedua = home.riwayatTerakhirDiputar[1].lagu;

    home.catatLaguDiputar(laguKedua);
    home.catatLaguDiputar(laguKedua);

    expect(home.laguUntukDilanjutkan?.lagu.judul, laguKedua.judul);
    expect(home.riwayatTerakhirDiputar.length, 6);
  });

  test('Muat ulang tidak menghapus lagu yang baru dicatat', () async {
    await home.muatIsiBeranda();
    Lagu laguBaru = home.laguBelumPernahDidengar.first;
    home.catatLaguDiputar(laguBaru);

    await home.muatIsiBeranda(isPaksaMuatUlang: true);

    expect(home.laguUntukDilanjutkan?.lagu.judul, laguBaru.judul);
    expect(home.riwayatTerakhirDiputar.length, 7);
  });

  test('Memanggil muat berkali-kali hanya memuat sekali', () async {
    int jumlahPemberitahuan = 0;
    home.addListener(() => jumlahPemberitahuan++);

    await Future.wait([home.muatIsiBeranda(), home.muatIsiBeranda()]);
    await home.muatIsiBeranda();

    expect(jumlahPemberitahuan, 2);
  });

  group('Pantau pemutar', () {
    late AudioProvider audio;

    setUp(() {
      audio = AudioProvider(pemutarAudio: PemutarAudioPalsu());
    });

    tearDown(() {
      audio.dispose();
    });

    test('Lagu yang diputar dari mana saja tercatat otomatis', () async {
      await home.muatIsiBeranda();
      home.pantauPemutar(audio);

      audio.mulaiAntrian([laguUjiCoba], namaAntrian: 'Hasil Pencarian');
      await Future.delayed(waktuTungguLaguMulai);

      expect(home.laguUntukDilanjutkan?.lagu.judul, 'Lagu Uji Coba');
      expect(home.riwayatTerakhirDiputar.length, 7);
    });

    test('Lagu yang cuma masuk antrian belum tercatat', () async {
      await home.muatIsiBeranda();
      home.pantauPemutar(audio);

      audio.mulaiAntrian([laguUjiCoba], isLangsungDiputar: false);
      await Future.delayed(waktuTungguLaguMulai);

      expect(home.laguUntukDilanjutkan?.lagu.judul, 'Evaluasi');
    });

    test('Jeda lalu lanjut putar tidak membuat riwayat dobel', () async {
      await home.muatIsiBeranda();
      home.pantauPemutar(audio);
      audio.mulaiAntrian([laguUjiCoba]);
      await Future.delayed(waktuTungguLaguMulai);

      int jumlahRiwayatAwal = home.riwayatTerakhirDiputar.length;
      audio.jeda();
      audio.putar();
      await Future.delayed(waktuTungguLaguMulai);

      expect(home.riwayatTerakhirDiputar.length, jumlahRiwayatAwal);
      expect(home.laguUntukDilanjutkan?.lagu.judul, 'Lagu Uji Coba');
    });

    test('Lagu yang diputar sebelum beranda dimuat tidak hilang', () async {
      home.pantauPemutar(audio);
      audio.mulaiAntrian([laguUjiCoba]);
      await Future.delayed(waktuTungguLaguMulai);

      await home.muatIsiBeranda();

      expect(home.laguUntukDilanjutkan?.lagu.judul, 'Lagu Uji Coba');
      expect(home.riwayatTerakhirDiputar.length, 7);
    });

    test('Memantau pemutar yang sama dua kali tidak mencatat dobel', () async {
      await home.muatIsiBeranda();
      home.pantauPemutar(audio);
      home.pantauPemutar(audio);

      int jumlahPemberitahuan = 0;
      home.addListener(() => jumlahPemberitahuan++);

      audio.mulaiAntrian([laguUjiCoba]);
      await Future.delayed(waktuTungguLaguMulai);

      expect(jumlahPemberitahuan, 1);
    });
  });

  group('Genre favorit', () {
    List<String> urutanNamaRacikan() {
      return home.daftarRacikanUntukmu
          .map((racikan) => racikan.namaKategori)
          .toList();
    }

    test('Racikan genre favorit tampil paling depan sesuai urutan', () async {
      await home.muatIsiBeranda();

      home.simpanGenreFavorit(['Jazz', 'Indie']);

      expect(urutanNamaRacikan().take(4), ['Jazz', 'Indie', 'Pop', 'R&B']);
      expect(home.daftarRacikanUntukmu.first.isGenreFavorit, isTrue);
      expect(home.daftarRacikanUntukmu[2].isGenreFavorit, isFalse);
    });

    test('Genre dobel, asing, dan kelebihan tidak ikut disimpan', () {
      home.simpanGenreFavorit([
        'Jazz',
        'Jazz',
        'Dangdut',
        'Pop',
        'Indie',
        'K-Pop',
        'R&B',
        'Lo-Fi',
      ]);

      expect(home.genreFavorit, ['Jazz', 'Pop', 'Indie', 'K-Pop', 'R&B']);
      expect(home.isSudahPilihGenre, isTrue);
    });

    test('Lagu temuan dari genre favorit muncul duluan', () async {
      await home.muatIsiBeranda();

      home.simpanGenreFavorit(['Lo-Fi']);

      expect(home.laguBelumPernahDidengar.first.judul, 'Coffee');
    });

    test('Genre favorit tanpa lagu tidak merusak urutan racikan', () async {
      await home.muatIsiBeranda();

      home.simpanGenreFavorit(['Podcast']);

      expect(home.genreFavorit, ['Podcast']);
      expect(urutanNamaRacikan().first, 'Pop');
    });

    test('Menyimpan daftar kosong menghapus semua genre favorit', () async {
      await home.muatIsiBeranda();
      home.simpanGenreFavorit(['Jazz']);

      home.simpanGenreFavorit([]);

      expect(home.isSudahPilihGenre, isFalse);
      expect(urutanNamaRacikan().first, 'Pop');
    });
  });

  group('Feed dari server', () {
    test(
      'Server gagal memberi pesan dan beranda belum dianggap dimuat',
      () async {
        HomeProvider homeGagal = HomeProvider(
          feedService: const FeedService(
            lamaResponServer: Duration.zero,
            isSimulasiGagal: true,
          ),
        );

        await homeGagal.muatIsiBeranda();

        expect(homeGagal.isSudahPernahDimuat, isFalse);
        expect(homeGagal.isSedangMemuat, isFalse);
        expect(homeGagal.pesanGagal, contains('feed belum bisa diambil'));
        expect(homeGagal.riwayatTerakhirDiputar, isEmpty);
        homeGagal.dispose();
      },
    );

    test('Racikan dan temuan mengikuti katalog dari server', () async {
      HomeProvider homeKecil = HomeProvider(
        feedService: const FeedService(
          lamaResponServer: Duration.zero,
          responsServer: '''
{
  "tracks": [
    {"id": "1", "title": "Lagu Satu", "artist": "Capy", "duration_ms": 1000, "genre": "Jazz"},
    {"id": "2", "title": "Lagu Dua", "artist": "Capy", "duration_ms": 1000, "genre": "Jazz"}
  ],
  "recently_played": [{"track_id": "1", "played_minutes_ago": 10}]
}
''',
        ),
      );

      await homeKecil.muatIsiBeranda();

      expect(homeKecil.daftarRacikanUntukmu.length, 1);
      expect(homeKecil.daftarRacikanUntukmu.first.namaKategori, 'Jazz');
      expect(homeKecil.laguBelumPernahDidengar.map((lagu) => lagu.judul), [
        'Lagu Dua',
      ]);
      homeKecil.dispose();
    });

    test('Data mock biasa tidak dianggap data cadangan', () async {
      await home.muatIsiBeranda();

      expect(home.isMemakaiDataCadangan, isFalse);
    });

    test('Supabase gagal maka beranda tetap terisi data cadangan', () async {
      HomeProvider homeSupabase = HomeProvider(
        feedService: const SupabaseFeedService(),
      );

      await homeSupabase.muatIsiBeranda();

      expect(homeSupabase.isSudahPernahDimuat, isTrue);
      expect(homeSupabase.isMemakaiDataCadangan, isTrue);
      expect(homeSupabase.pesanGagal, isNull);
      expect(homeSupabase.laguUntukDilanjutkan?.lagu.judul, 'Evaluasi');
      homeSupabase.dispose();
    });

    test('Feed kosong dari server tetap aman', () async {
      HomeProvider homeKosong = HomeProvider(
        feedService: const FeedService(
          lamaResponServer: Duration.zero,
          responsServer: '{}',
        ),
      );

      await homeKosong.muatIsiBeranda();

      expect(homeKosong.isSudahPernahDimuat, isTrue);
      expect(homeKosong.laguUntukDilanjutkan, isNull);
      expect(homeKosong.daftarRacikanUntukmu, isEmpty);
      expect(homeKosong.laguBelumPernahDidengar, isEmpty);
      homeKosong.dispose();
    });
  });

  group('Status memuat', () {
    test('Tanda koneksi lambat menyala kalau server kelamaan', () async {
      HomeProvider homeLambat = HomeProvider(
        feedService: const FeedService(
          lamaResponServer: Duration(milliseconds: 300),
        ),
        batasSabarMenunggu: const Duration(milliseconds: 100),
      );

      Future<void> prosesMuat = homeLambat.muatIsiBeranda();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(homeLambat.isMemuatTerlaluLama, isFalse);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(homeLambat.isMemuatTerlaluLama, isTrue);
      expect(homeLambat.isMuatPertamaKali, isTrue);

      await prosesMuat;
      expect(homeLambat.isMemuatTerlaluLama, isFalse);
      expect(homeLambat.isMuatPertamaKali, isFalse);
      homeLambat.dispose();
    });

    test('Server yang cepat tidak memicu tanda lambat sama sekali', () async {
      HomeProvider homeCepat = HomeProvider(
        feedService: const FeedService(lamaResponServer: Duration.zero),
        batasSabarMenunggu: const Duration(milliseconds: 100),
      );
      await homeCepat.muatIsiBeranda();

      int jumlahPemberitahuan = 0;
      homeCepat.addListener(() => jumlahPemberitahuan++);
      await Future.delayed(const Duration(milliseconds: 200));

      expect(jumlahPemberitahuan, 0);
      expect(homeCepat.isMemuatTerlaluLama, isFalse);
      homeCepat.dispose();
    });

    test('Muat ulang dianggap menyegarkan, bukan muat pertama', () async {
      expect(home.isMuatPertamaKali, isTrue);
      expect(home.isSedangMenyegarkan, isFalse);
      await home.muatIsiBeranda();

      Future<void> prosesSegarkan = home.muatIsiBeranda(isPaksaMuatUlang: true);
      expect(home.isSedangMenyegarkan, isTrue);
      expect(home.isMuatPertamaKali, isFalse);

      await prosesSegarkan;
      expect(home.isSedangMenyegarkan, isFalse);
    });

    test('Provider dibuang saat memuat tidak membuat error', () async {
      HomeProvider homeSebentar = HomeProvider(
        feedService: const FeedService(
          lamaResponServer: Duration(milliseconds: 200),
        ),
        batasSabarMenunggu: const Duration(milliseconds: 50),
      );

      Future<void> prosesMuat = homeSebentar.muatIsiBeranda();
      homeSebentar.dispose();

      await prosesMuat;
      await Future.delayed(const Duration(milliseconds: 100));
    });
  });

  group('Beranda saat offline', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Offline memakai beranda terakhir lalu pulih saat online', () async {
      FeedServerPalsu server = FeedServerPalsu([
        null,
        FeedServerPalsu.galatOffline(),
        null,
      ]);
      HomeProvider homeOffline = HomeProvider(feedService: server);

      await homeOffline.muatIsiBeranda();
      expect(homeOffline.asalFeed, AsalFeed.server);
      expect(homeOffline.isSedangOffline, isFalse);

      await homeOffline.muatIsiBeranda(isPaksaMuatUlang: true);
      expect(homeOffline.asalFeed, AsalFeed.simpananTerakhir);
      expect(homeOffline.isSedangOffline, isTrue);
      expect(homeOffline.isMemakaiDataCadangan, isTrue);
      expect(homeOffline.waktuFeedDisimpan, isNotNull);
      expect(homeOffline.pesanGagal, isNull);

      await homeOffline.muatIsiBeranda(isPaksaMuatUlang: true);
      expect(homeOffline.asalFeed, AsalFeed.server);
      expect(homeOffline.isSedangOffline, isFalse);
      expect(homeOffline.waktuFeedDisimpan, isNull);
      homeOffline.dispose();
    });

    test(
      'Lagu yang diputar saat offline tidak hilang setelah online',
      () async {
        FeedServerPalsu server = FeedServerPalsu([
          FeedServerPalsu.galatOffline(),
          null,
        ]);
        HomeProvider homeOffline = HomeProvider(feedService: server);

        await homeOffline.muatIsiBeranda();
        homeOffline.catatLaguDiputar(laguUjiCoba);
        await homeOffline.muatIsiBeranda(isPaksaMuatUlang: true);

        expect(homeOffline.isSedangOffline, isFalse);
        expect(homeOffline.laguUntukDilanjutkan?.lagu.judul, 'Lagu Uji Coba');
        homeOffline.dispose();
      },
    );
  });
}
