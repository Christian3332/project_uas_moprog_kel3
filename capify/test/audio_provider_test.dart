import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:capify/models/lagu.dart';
import 'package:capify/models/mode_ulang.dart';
import 'package:capify/providers/audio_provider.dart';

import 'pemutar_audio_palsu.dart';

void main() {
  const List<Lagu> laguTes = [
    Lagu(
      judul: 'Lagu A',
      penyanyi: 'Penyanyi A',
      urlCover: '',
      durasi: Duration(minutes: 3),
    ),
    Lagu(
      judul: 'Lagu B',
      penyanyi: 'Penyanyi B',
      urlCover: '',
      durasi: Duration(minutes: 2),
    ),
  ];

  late AudioProvider audio;

  setUp(() {
    audio = AudioProvider();
    audio.mulaiAntrian(laguTes, isLangsungDiputar: false);
  });

  tearDown(() => audio.dispose());

  test('Antrian kosong tidak punya lagu sekarang', () {
    AudioProvider audioKosong = AudioProvider();
    expect(audioKosong.laguSekarang, isNull);
    expect(audioKosong.laguBerikutnya(), isFalse);
    audioKosong.dispose();
  });

  test('Next berhenti di lagu terakhir kalau mode ulang mati', () {
    expect(audio.laguBerikutnya(), isTrue);
    expect(audio.laguSekarang?.judul, 'Lagu B');
    expect(audio.laguBerikutnya(), isFalse);
    expect(audio.isLaguSedangDiputar, isFalse);
  });

  test('Next kembali ke lagu pertama kalau mode ulang semua', () {
    audio.gantiModeUlang();
    expect(audio.modeUlang, ModeUlang.semua);
    audio.laguBerikutnya();
    expect(audio.laguBerikutnya(), isTrue);
    expect(audio.laguSekarang?.judul, 'Lagu A');
  });

  test('Previous mengulang lagu kalau sudah lewat tiga detik', () {
    audio.laguBerikutnya();
    audio.geserKe(const Duration(seconds: 30));
    audio.laguSebelumnya();
    expect(audio.laguSekarang?.judul, 'Lagu B');
    expect(audio.posisiSekarang, Duration.zero);

    audio.laguSebelumnya();
    expect(audio.laguSekarang?.judul, 'Lagu A');
  });

  test('Geser seekbar tidak bisa melewati durasi lagu', () {
    audio.geserKe(const Duration(minutes: 10));
    expect(audio.posisiSekarang, const Duration(minutes: 3));
    audio.geserKe(const Duration(seconds: -5));
    expect(audio.posisiSekarang, Duration.zero);
  });

  group('Pemutaran audio dengan just_audio', () {
    late PemutarAudioPalsu pemutarPalsu;
    late AudioProvider audioAsli;

    Future<void> tungguStreamTerkirim() => Future<void>.delayed(Duration.zero);

    setUp(() {
      pemutarPalsu = PemutarAudioPalsu();
      audioAsli = AudioProvider(pemutarAudio: pemutarPalsu);
      audioAsli.mulaiAntrian(laguTes, isLangsungDiputar: false);
    });

    tearDown(() => audioAsli.dispose());

    test('Putar memuat audio lalu durasi diambil dari file aslinya', () async {
      await audioAsli.putar();
      await tungguStreamTerkirim();

      expect(pemutarPalsu.urlTerakhirDimuat, AudioProvider.urlAudioCadangan);
      expect(audioAsli.isLaguSedangDiputar, isTrue);
      expect(audioAsli.durasiLaguSekarang, const Duration(minutes: 5));
    });

    test('Jeda menghentikan pemutar audio', () async {
      await audioAsli.putar();
      audioAsli.jeda();
      await tungguStreamTerkirim();

      expect(pemutarPalsu.isSedangMemutar, isFalse);
      expect(audioAsli.isLaguSedangDiputar, isFalse);
    });

    test('Geser seekbar diteruskan ke pemutar audio', () async {
      await audioAsli.putar();
      audioAsli.geserKe(const Duration(seconds: 42));

      expect(pemutarPalsu.posisiTerakhirDiseek, const Duration(seconds: 42));
    });

    test('Lagu yang selesai otomatis lanjut ke lagu berikutnya', () async {
      await audioAsli.putar();
      await tungguStreamTerkirim();

      pemutarPalsu.selesaikanLagu();
      await tungguStreamTerkirim();
      await tungguStreamTerkirim();

      expect(audioAsli.laguSekarang?.judul, 'Lagu B');
      expect(audioAsli.isLaguSedangDiputar, isTrue);
    });

    test('Gagal memuat audio memunculkan pesan error', () async {
      AudioProvider audioGagal = AudioProvider(
        pemutarAudio: PemutarAudioPalsu(isHarusGagal: true),
      )..mulaiAntrian(laguTes, isLangsungDiputar: false);

      await audioGagal.putar();

      expect(audioGagal.pesanError, isNotNull);
      expect(audioGagal.isLaguSedangDiputar, isFalse);
      expect(audioGagal.isSedangMemuat, isFalse);
      audioGagal.dispose();
    });
  });

  group('Buffering dan penanganan error', () {
    late PemutarAudioPalsu pemutarPalsu;
    late AudioProvider audioAsli;

    Future<void> tungguStreamTerkirim() => Future<void>.delayed(Duration.zero);

    setUp(() {
      pemutarPalsu = PemutarAudioPalsu(lamaMemuat: Duration.zero);
      audioAsli = AudioProvider(pemutarAudio: pemutarPalsu);
      audioAsli.mulaiAntrian(laguTes, isLangsungDiputar: false);
    });

    tearDown(() => audioAsli.dispose());

    test('Status buffering terbaca tanpa menghentikan lagu', () async {
      await audioAsli.putar();
      await tungguStreamTerkirim();

      pemutarPalsu.mulaiBuffering();
      await tungguStreamTerkirim();
      expect(audioAsli.isSedangBuffering, isTrue);
      expect(audioAsli.isLaguSedangDiputar, isTrue);

      pemutarPalsu.selesaiBuffering();
      await tungguStreamTerkirim();
      expect(audioAsli.isSedangBuffering, isFalse);
    });

    test('Koneksi putus di tengah lagu bisa dicoba lagi', () async {
      await audioAsli.putar();
      audioAsli.geserKe(const Duration(seconds: 30));
      await tungguStreamTerkirim();

      pemutarPalsu.putuskanKoneksiDiTengahLagu();
      await tungguStreamTerkirim();
      expect(audioAsli.pesanError, isNotNull);
      expect(audioAsli.isLaguSedangDiputar, isFalse);

      audioAsli.cobaLagi();
      await tungguStreamTerkirim();
      await tungguStreamTerkirim();
      expect(audioAsli.pesanError, isNull);
      expect(audioAsli.isLaguSedangDiputar, isTrue);
      expect(pemutarPalsu.jumlahDimuat, 2);
    });

    test('Memuat terlalu lama dianggap gagal karena koneksi lambat', () async {
      AudioProvider audioLambat = AudioProvider(
        pemutarAudio: PemutarAudioPalsu(
          lamaMemuat: const Duration(milliseconds: 300),
        ),
        batasWaktuMemuat: const Duration(milliseconds: 50),
      )..mulaiAntrian(laguTes, isLangsungDiputar: false);

      await audioLambat.putar();

      expect(audioLambat.pesanError, contains('lambat'));
      expect(audioLambat.isSedangMemuat, isFalse);
      expect(audioLambat.isLaguSedangDiputar, isFalse);
      audioLambat.dispose();
    });
  });

  group('Interupsi pemutaran', () {
    late PemutarAudioPalsu pemutarPalsu;
    late AudioProvider audioAsli;

    Future<void> tungguStreamTerkirim() => Future<void>.delayed(Duration.zero);

    setUp(() async {
      pemutarPalsu = PemutarAudioPalsu(lamaMemuat: Duration.zero);
      audioAsli = AudioProvider(pemutarAudio: pemutarPalsu);
      audioAsli.mulaiAntrian(laguTes, isLangsungDiputar: false);
      await audioAsli.putar();
      await tungguStreamTerkirim();
    });

    tearDown(() => audioAsli.dispose());

    test('Telepon masuk menjeda lagu lalu lanjut setelah selesai', () async {
      audioAsli.saatAdaInterupsi(
        AudioInterruptionEvent(true, AudioInterruptionType.pause),
      );
      await tungguStreamTerkirim();
      expect(audioAsli.isLaguSedangDiputar, isFalse);
      expect(audioAsli.pesanInterupsi, isNotNull);

      audioAsli.saatAdaInterupsi(
        AudioInterruptionEvent(false, AudioInterruptionType.pause),
      );
      await tungguStreamTerkirim();
      expect(audioAsli.isLaguSedangDiputar, isTrue);
      expect(audioAsli.pesanInterupsi, isNull);
    });

    test('Headset dicabut langsung menjeda lagu', () async {
      audioAsli.saatHeadsetDicabut();
      await tungguStreamTerkirim();

      expect(audioAsli.isLaguSedangDiputar, isFalse);
      expect(pemutarPalsu.isSedangMemutar, isFalse);
      expect(audioAsli.pesanInterupsi, contains('Headset'));
    });
  });

  group('Seekbar dan timeline', () {
    test('Posisi dari pemutar audio memperbarui timeline', () async {
      PemutarAudioPalsu pemutarPalsu = PemutarAudioPalsu(
        lamaMemuat: Duration.zero,
      );
      AudioProvider audioUji = AudioProvider(pemutarAudio: pemutarPalsu)
        ..mulaiAntrian(laguTes, isLangsungDiputar: false);
      await audioUji.putar();

      pemutarPalsu.pengirimPosisi.add(const Duration(seconds: 75));
      await Future<void>.delayed(Duration.zero);

      expect(audioUji.posisiSekarang, const Duration(seconds: 75));
      audioUji.dispose();
    });
  });

  group('Antrian lanjut ke lagu berikutnya', () {
    List<Lagu> buatAntrian(int jumlahLagu) {
      return List.generate(
        jumlahLagu,
        (urutan) => Lagu(
          judul: 'Lagu ${urutan + 1}',
          penyanyi: 'Penyanyi Tes',
          urlCover: '',
          durasi: const Duration(minutes: 3),
        ),
      );
    }

    List<String> putarSampaiHabis(AudioProvider audioUji, int batasPutar) {
      List<String> laguYangDiputar = [audioUji.laguSekarang!.judul];
      for (int putaran = 0; putaran < batasPutar; putaran++) {
        if (!audioUji.laguBerikutnya()) break;
        laguYangDiputar.add(audioUji.laguSekarang!.judul);
      }
      return laguYangDiputar;
    }

    test('Mode acak memutar semua lagu tepat sekali lalu berhenti', () {
      AudioProvider audioUji = AudioProvider()
        ..mulaiAntrian(buatAntrian(5), indexMulai: 2, isLangsungDiputar: false)
        ..toggleAcak();

      expect(audioUji.laguSekarang?.judul, 'Lagu 3');

      List<String> laguYangDiputar = putarSampaiHabis(audioUji, 20);
      expect(laguYangDiputar.length, 5);
      expect(laguYangDiputar.toSet().length, 5);
      expect(laguYangDiputar.first, 'Lagu 3');
      audioUji.dispose();
    });

    test('Previous saat acak kembali ke lagu yang tadi diputar', () {
      AudioProvider audioUji = AudioProvider()
        ..mulaiAntrian(buatAntrian(5), isLangsungDiputar: false)
        ..toggleAcak();

      String laguPertama = audioUji.laguSekarang!.judul;
      audioUji.laguBerikutnya();
      String laguKedua = audioUji.laguSekarang!.judul;
      audioUji.laguBerikutnya();

      audioUji.laguSebelumnya();
      expect(audioUji.laguSekarang?.judul, laguKedua);
      audioUji.laguSebelumnya();
      expect(audioUji.laguSekarang?.judul, laguPertama);
      audioUji.dispose();
    });

    test('Sinyal selesai dari lagu lama tidak melompati lagu', () async {
      PemutarAudioPalsu pemutarPalsu = PemutarAudioPalsu(
        lamaMemuat: const Duration(milliseconds: 50),
      );
      AudioProvider audioUji = AudioProvider(pemutarAudio: pemutarPalsu)
        ..mulaiAntrian(buatAntrian(3), isLangsungDiputar: false);
      await audioUji.putar();
      await Future<void>.delayed(Duration.zero);

      audioUji.laguBerikutnya();
      pemutarPalsu.selesaikanLagu();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(audioUji.laguSekarang?.judul, 'Lagu 2');
      audioUji.dispose();
    });
  });
}
