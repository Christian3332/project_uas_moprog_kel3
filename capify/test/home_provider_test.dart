import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/providers/audio_provider.dart';
import 'package:capify/providers/home_provider.dart';

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
      audio = AudioProvider();
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
}
