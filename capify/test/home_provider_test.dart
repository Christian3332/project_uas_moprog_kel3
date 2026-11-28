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

class FeedPenghitung extends FeedService {
  final List<String> urutanRespons;
  int jumlahPanggilan = 0;

  FeedPenghitung(this.urutanRespons, {super.lamaResponServer = Duration.zero});

  @override
  Future<FeedBeranda> ambilFeedBeranda() async {
    int urutan = jumlahPanggilan < urutanRespons.length
        ? jumlahPanggilan
        : urutanRespons.length - 1;
    jumlahPanggilan++;
    await Future.delayed(lamaResponServer);
    return FeedService.ubahJsonKeFeed(urutanRespons[urutan]);
  }
}

class FeedPencatatRiwayat extends FeedService {
  final List<String> laguYangDicatat = [];

  FeedPencatatRiwayat() : super(lamaResponServer: Duration.zero);

  @override
  Future<void> catatRiwayatPutar(Lagu lagu) async {
    laguYangDicatat.add(lagu.judul);
  }
}

const String responsKatalogKecil = '''
{
  "tracks": [
    {"id": "x1", "title": "Lagu Baru", "artist": "Capy", "duration_ms": 1000, "genre": "Jazz"}
  ],
  "recently_played": []
}
''';

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

  test('Lagu yang diputar ikut dikirim ke service riwayat', () {
    FeedPencatatRiwayat server = FeedPencatatRiwayat();
    HomeProvider homeTercatat = HomeProvider(feedService: server);

    homeTercatat.catatLaguDiputar(laguUjiCoba);

    expect(server.laguYangDicatat, ['Lagu Uji Coba']);
    homeTercatat.dispose();
  });

  test('Muat ulang tidak menghapus lagu yang baru dicatat', () async {
    await home.muatIsiBeranda();
    Lagu laguBaru = home.laguBelumPernahDidengar.first;
    home.catatLaguDiputar(laguBaru);

    await home.muatIsiBeranda(isPaksaMuatUlang: true);

    expect(home.laguUntukDilanjutkan?.lagu.judul, laguBaru.judul);
    expect(home.riwayatTerakhirDiputar.length, 7);
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

  group('Tarik untuk menyegarkan', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Menyegarkan mengambil ulang data dari server', () async {
      FeedPenghitung server = FeedPenghitung([FeedService.responsServerDummy]);
      HomeProvider homeUji = HomeProvider(feedService: server);
      await homeUji.muatIsiBeranda();

      HasilSegarkan hasil = await homeUji.segarkanBeranda();

      expect(hasil, HasilSegarkan.berhasil);
      expect(server.jumlahPanggilan, 2);
      expect(homeUji.waktuTerakhirDiperbarui, isNotNull);
      homeUji.dispose();
    });

    test('Menyegarkan saat offline, server error, atau gagal', () async {
      HomeProvider homeOffline = HomeProvider(
        feedService: FeedServerPalsu([FeedServerPalsu.galatOffline()]),
      );
      HomeProvider homeServerError = HomeProvider(
        feedService: FeedServerPalsu([FeedServerPalsu.galatServer()]),
      );
      HomeProvider homeGagalTotal = HomeProvider(
        feedService: const FeedService(
          lamaResponServer: Duration.zero,
          isSimulasiGagal: true,
        ),
      );

      expect(await homeOffline.segarkanBeranda(), HasilSegarkan.gagal);
      expect(await homeServerError.segarkanBeranda(), HasilSegarkan.gagal);
      expect(await homeGagalTotal.segarkanBeranda(), HasilSegarkan.gagal);
      expect(homeOffline.isSedangOffline, isTrue);
      expect(homeOffline.waktuTerakhirDiperbarui, isNull);

      homeOffline.dispose();
      homeServerError.dispose();
      homeGagalTotal.dispose();
    });

    test('Beranda offline berhasil disegarkan setelah online', () async {
      FeedServerPalsu server = FeedServerPalsu([
        FeedServerPalsu.galatOffline(),
        null,
      ]);
      HomeProvider homeUji = HomeProvider(feedService: server);
      await homeUji.muatIsiBeranda();

      HasilSegarkan hasil = await homeUji.segarkanBeranda();

      expect(hasil, HasilSegarkan.berhasil);
      expect(server.jumlahPanggilanServer, 2);
      homeUji.dispose();
    });
  });
}
